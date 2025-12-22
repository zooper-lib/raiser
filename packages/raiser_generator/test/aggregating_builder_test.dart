/// Tests for the aggregating builder that produces a single output file.
///
/// These tests verify that the builder correctly collects metadata from
/// multiple source files and produces a consolidated output.

import 'package:raiser_generator/raiser_generator.dart';
import 'package:test/test.dart';

void main() {
  group('RaiserAggregatingBuilder Output', () {
    late CodeEmitter emitter;

    setUp(() {
      emitter = CodeEmitter();
    });

    group('Multi-file Aggregation', () {
      test('combines handlers from multiple source files', () {
        final handlers = [
          HandlerInfo(
            className: 'UserHandler',
            eventType: 'UserEvent',
            priority: 0,
            sourceFile: 'lib/handlers/user_handler.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'OrderHandler',
            eventType: 'OrderEvent',
            priority: 0,
            sourceFile: 'lib/handlers/order_handler.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'PaymentHandler',
            eventType: 'PaymentEvent',
            priority: 0,
            sourceFile: 'lib/handlers/payment_handler.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        expect(result, contains('UserHandler'));
        expect(result, contains('OrderHandler'));
        expect(result, contains('PaymentHandler'));
      });

      test('combines middleware from multiple source files', () {
        final middleware = [
          MiddlewareInfo(
            className: 'LoggingMiddleware',
            priority: 100,
            sourceFile: 'lib/middleware/logging.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          MiddlewareInfo(
            className: 'AuthMiddleware',
            priority: 50,
            sourceFile: 'lib/middleware/auth.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        expect(result, contains('LoggingMiddleware'));
        expect(result, contains('AuthMiddleware'));
      });

      test('combines handlers and middleware in correct order', () {
        final handlers = [
          HandlerInfo(
            className: 'TestHandler',
            eventType: 'TestEvent',
            priority: 0,
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final middleware = [
          MiddlewareInfo(
            className: 'TestMiddleware',
            priority: 0,
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, middleware);

        // Middleware should be registered before handlers
        final middlewareIndex = result.indexOf('addMiddleware');
        final handlerIndex = result.indexOf('register<TestEvent>');

        expect(middlewareIndex, lessThan(handlerIndex));
      });
    });

    group('Bus Name Grouping', () {
      test('groups handlers by bus name', () {
        final handlersDefault = [
          HandlerInfo(
            className: 'DefaultHandler',
            eventType: 'DefaultEvent',
            priority: 0,
            busName: null,
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final handlersPayments = [
          HandlerInfo(
            className: 'PaymentHandler',
            eventType: 'PaymentEvent',
            priority: 0,
            busName: 'payments',
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final defaultResult = emitter.emitInitFunction(null, handlersDefault, []);
        final paymentsResult = emitter.emitInitFunction('payments', handlersPayments, []);

        expect(defaultResult, contains('void initRaiser(EventBus bus)'));
        expect(paymentsResult, contains('void initRaiserPaymentsBus(EventBus bus)'));
      });

      test('groupHandlersByBus correctly partitions handlers', () {
        final handlers = [
          HandlerInfo(
            className: 'Handler1',
            eventType: 'Event1',
            priority: 0,
            busName: null,
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'Handler2',
            eventType: 'Event2',
            priority: 0,
            busName: 'orders',
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'Handler3',
            eventType: 'Event3',
            priority: 0,
            busName: 'orders',
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'Handler4',
            eventType: 'Event4',
            priority: 0,
            busName: 'inventory',
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final grouped = emitter.groupHandlersByBus(handlers);

        expect(grouped.keys.length, equals(3)); // null, orders, inventory
        expect(grouped[null]!.length, equals(1));
        expect(grouped['orders']!.length, equals(2));
        expect(grouped['inventory']!.length, equals(1));
      });

      test('groupMiddlewareByBus correctly partitions middleware', () {
        final middleware = [
          MiddlewareInfo(
            className: 'Middleware1',
            priority: 0,
            busName: null,
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          MiddlewareInfo(
            className: 'Middleware2',
            priority: 0,
            busName: 'payments',
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final grouped = emitter.groupMiddlewareByBus(middleware);

        expect(grouped.keys.length, equals(2));
        expect(grouped[null]!.length, equals(1));
        expect(grouped['payments']!.length, equals(1));
      });

      test('emitAllInitFunctions generates functions for all buses', () {
        final handlers = [
          HandlerInfo(
            className: 'DefaultHandler',
            eventType: 'DefaultEvent',
            priority: 0,
            busName: null,
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'OrderHandler',
            eventType: 'OrderEvent',
            priority: 0,
            busName: 'orders',
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitAllInitFunctions(handlers, []);

        expect(result, contains('void initRaiser(EventBus bus)'));
        expect(result, contains('void initRaiserOrdersBus(EventBus bus)'));
      });
    });

    group('Dependency Injection Factories', () {
      test('generates factory typedef for handler with dependencies', () {
        final handlers = [
          HandlerInfo(
            className: 'LoggingHandler',
            eventType: 'LogEvent',
            priority: 0,
            sourceFile: 'lib/handlers.dart',
            constructor: ConstructorInfo(
              hasParameters: true,
              parameters: [
                const ParameterInfo(
                  name: 'logger',
                  type: 'Logger',
                  isRequired: true,
                ),
              ],
            ),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        expect(result, contains('typedef LoggingHandlerFactory = LoggingHandler Function()'));
        expect(result, contains('initRaiserWithFactories'));
        expect(result, contains('required LoggingHandlerFactory createLoggingHandler'));
      });

      test('generates factory typedef for middleware with dependencies', () {
        final middleware = [
          MiddlewareInfo(
            className: 'AuthMiddleware',
            priority: 50,
            sourceFile: 'lib/middleware.dart',
            constructor: ConstructorInfo(
              hasParameters: true,
              parameters: [
                const ParameterInfo(
                  name: 'authService',
                  type: 'AuthService',
                  isRequired: true,
                ),
              ],
            ),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        expect(result, contains('typedef AuthMiddlewareFactory = AuthMiddleware Function()'));
        expect(result, contains('required AuthMiddlewareFactory createAuthMiddleware'));
      });

      test('initRaiserWithFactories uses factory functions', () {
        final handlers = [
          HandlerInfo(
            className: 'ServiceHandler',
            eventType: 'ServiceEvent',
            priority: 0,
            sourceFile: 'lib/handlers.dart',
            constructor: ConstructorInfo(
              hasParameters: true,
              parameters: [
                const ParameterInfo(
                  name: 'service',
                  type: 'MyService',
                  isRequired: true,
                ),
              ],
            ),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        expect(result, contains('createServiceHandler()'));
      });

      test('mixes no-arg and factory handlers correctly', () {
        final handlers = [
          HandlerInfo(
            className: 'SimpleHandler',
            eventType: 'SimpleEvent',
            priority: 0,
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'ComplexHandler',
            eventType: 'ComplexEvent',
            priority: 0,
            sourceFile: 'lib/handlers.dart',
            constructor: ConstructorInfo(
              hasParameters: true,
              parameters: [
                const ParameterInfo(
                  name: 'dep',
                  type: 'Dependency',
                  isRequired: true,
                ),
              ],
            ),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        // initRaiser should only register no-arg handlers
        expect(result, contains('void initRaiser(EventBus bus)'));
        final initRaiserSection = result.substring(
          result.indexOf('void initRaiser'),
          result.indexOf('typedef'),
        );
        expect(initRaiserSection, contains('SimpleHandler()'));
        expect(initRaiserSection, isNot(contains('ComplexHandler')));

        // initRaiserWithFactories should register all handlers
        expect(result, contains('void initRaiserWithFactories'));
        expect(result, contains('createComplexHandler()'));
      });
    });

    group('Priority Ordering', () {
      test('middleware is sorted by priority in output', () {
        final middleware = [
          MiddlewareInfo(
            className: 'LowPriorityMiddleware',
            priority: -10,
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          MiddlewareInfo(
            className: 'HighPriorityMiddleware',
            priority: 100,
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          MiddlewareInfo(
            className: 'MediumPriorityMiddleware',
            priority: 50,
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        final highIndex = result.indexOf('HighPriorityMiddleware');
        final medIndex = result.indexOf('MediumPriorityMiddleware');
        final lowIndex = result.indexOf('LowPriorityMiddleware');

        // Higher priority should come first
        expect(highIndex, lessThan(medIndex));
        expect(medIndex, lessThan(lowIndex));
      });

      test('priority value is included in registration', () {
        final middleware = [
          MiddlewareInfo(
            className: 'PriorityMiddleware',
            priority: 75,
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        expect(result, contains('priority: 75'));
      });

      test('zero priority omits priority parameter', () {
        final middleware = [
          MiddlewareInfo(
            className: 'DefaultPriorityMiddleware',
            priority: 0,
            sourceFile: 'lib/middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        expect(result, contains('addMiddleware(DefaultPriorityMiddleware())'));
        expect(result, isNot(contains('priority: 0')));
      });
    });

    group('Source Comments', () {
      test('includes source file comment for handlers', () {
        final handlers = [
          HandlerInfo(
            className: 'MyHandler',
            eventType: 'MyEvent',
            priority: 0,
            sourceFile: 'lib/handlers/my_handler.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        expect(result, contains('// Handler: MyHandler from lib/handlers/my_handler.dart'));
      });

      test('includes source file comment for middleware', () {
        final middleware = [
          MiddlewareInfo(
            className: 'MyMiddleware',
            priority: 50,
            sourceFile: 'lib/middleware/my_middleware.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        expect(result, contains('// Middleware: MyMiddleware from lib/middleware/my_middleware.dart'));
      });

      test('includes priority comment', () {
        final handlers = [
          HandlerInfo(
            className: 'PriorityHandler',
            eventType: 'PriorityEvent',
            priority: 42,
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        expect(result, contains('// Priority: 42'));
      });
    });

    group('Named Bus Functions', () {
      test('generates correctly named function for named bus', () {
        final handlers = [
          HandlerInfo(
            className: 'OrderHandler',
            eventType: 'OrderEvent',
            priority: 0,
            busName: 'orders',
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction('orders', handlers, []);

        expect(result, contains('void initRaiserOrdersBus(EventBus bus)'));
      });

      test('generates WithFactories variant for named bus', () {
        final handlers = [
          HandlerInfo(
            className: 'OrderHandler',
            eventType: 'OrderEvent',
            priority: 0,
            busName: 'orders',
            sourceFile: 'lib/handlers.dart',
            constructor: ConstructorInfo(
              hasParameters: true,
              parameters: [
                const ParameterInfo(
                  name: 'service',
                  type: 'OrderService',
                  isRequired: true,
                ),
              ],
            ),
          ),
        ];

        final result = emitter.emitInitFunction('orders', handlers, []);

        expect(result, contains('void initRaiserOrdersBusWithFactories'));
      });

      test('includes bus name in documentation', () {
        final result = emitter.emitInitFunction('payments', [], []);

        expect(result, contains("'payments' bus"));
      });
    });

    group('Edge Cases', () {
      test('handles empty handlers and middleware', () {
        final result = emitter.emitInitFunction(null, [], []);

        expect(result, contains('void initRaiser(EventBus bus)'));
        expect(result, contains('{'));
        expect(result, contains('}'));
      });

      test('handles very long class names', () {
        final handlers = [
          HandlerInfo(
            className: 'VeryLongAndDescriptiveHandlerNameForTestingPurposes',
            eventType: 'VeryLongAndDescriptiveEventNameForTestingPurposes',
            priority: 0,
            sourceFile: 'lib/handlers.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        expect(result, contains('VeryLongAndDescriptiveHandlerNameForTestingPurposes'));
        expect(result, contains('VeryLongAndDescriptiveEventNameForTestingPurposes'));
      });

      test('handles special characters in source file paths', () {
        final handlers = [
          HandlerInfo(
            className: 'Handler',
            eventType: 'Event',
            priority: 0,
            sourceFile: 'lib/handlers/sub_folder/my_handler.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        expect(result, contains('lib/handlers/sub_folder/my_handler.dart'));
      });
    });
  });
}
