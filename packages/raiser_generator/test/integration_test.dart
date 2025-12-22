/// Integration tests for the Raiser code generator.
///
/// These tests verify that the CodeEmitter produces expected output
/// and that the generated code structure is correct.
import 'package:raiser_generator/raiser_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Tests', () {
    late CodeEmitter emitter;

    setUp(() {
      emitter = CodeEmitter();
    });

    group('InitRaiser function generation', () {
      /// **Feature: code-generator, Property 8: InitRaiser Function Structure**
      ///
      /// Tests that the emitter produces a function named `initRaiser`
      /// that accepts an `EventBus` parameter.
      test('generates initRaiser function for basic handler', () {
        final handlers = [
          HandlerInfo(
            className: 'TestHandler',
            eventType: 'TestEvent',
            priority: 0,
            sourceFile: 'lib/handlers/test_handler.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        // Verify initRaiser function is generated
        expect(result, contains('void initRaiser(EventBus bus)'));
        expect(result, contains('bus.register<TestEvent>(TestHandler())'));
      });

      /// Tests that multiple handlers for the same event type are all registered.
      test('generates registration for multiple handlers of same event type',
          () {
        final handlers = [
          HandlerInfo(
            className: 'OrderHandler1',
            eventType: 'OrderEvent',
            priority: 0,
            sourceFile: 'lib/handlers/order_handler1.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'OrderHandler2',
            eventType: 'OrderEvent',
            priority: 0,
            sourceFile: 'lib/handlers/order_handler2.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        // Both handlers should be registered
        expect(result, contains('bus.register<OrderEvent>(OrderHandler1())'));
        expect(result, contains('bus.register<OrderEvent>(OrderHandler2())'));
      });

      /// Tests that priority is included in registration calls.
      test('includes priority in registration call', () {
        final handlers = [
          HandlerInfo(
            className: 'HighPriorityHandler',
            eventType: 'PriorityEvent',
            priority: 100,
            sourceFile: 'lib/handlers/priority_handler.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        // Priority should be included
        expect(
          result,
          contains(
              'bus.register<PriorityEvent>(HighPriorityHandler(), priority: 100)'),
        );
      });

      /// Tests that middleware is registered with initRaiser.
      test('generates middleware registration', () {
        final middleware = [
          MiddlewareInfo(
            className: 'LoggingMiddleware',
            priority: 0,
            sourceFile: 'lib/middleware/logging.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        // Middleware should be registered
        expect(result, contains('void initRaiser(EventBus bus)'));
        expect(result, contains('bus.addMiddleware(LoggingMiddleware())'));
      });

      /// Tests that middleware priority ordering is correct.
      test('orders middleware by priority (descending)', () {
        final middleware = [
          MiddlewareInfo(
            className: 'LowPriorityMiddleware',
            priority: 10,
            sourceFile: 'lib/middleware/low.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          MiddlewareInfo(
            className: 'HighPriorityMiddleware',
            priority: 100,
            sourceFile: 'lib/middleware/high.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, [], middleware);

        // High priority middleware should appear before low priority
        final highIndex = result.indexOf('HighPriorityMiddleware');
        final lowIndex = result.indexOf('LowPriorityMiddleware');
        expect(highIndex, lessThan(lowIndex),
            reason: 'Higher priority middleware should be registered first');
      });
    });

    group('Named bus generation', () {
      /// **Feature: code-generator, Property 7: Bus Name Segregation**
      test('generates separate init functions for named buses', () {
        final handlers = [
          HandlerInfo(
            className: 'PaymentHandler',
            eventType: 'PaymentEvent',
            priority: 0,
            busName: 'payments',
            sourceFile: 'lib/handlers/payment.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'InventoryHandler',
            eventType: 'InventoryEvent',
            priority: 0,
            busName: 'inventory',
            sourceFile: 'lib/handlers/inventory.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitAllInitFunctions(handlers, []);

        // Separate init functions for each bus
        expect(result, contains('void initRaiserPaymentsBus(EventBus bus)'));
        expect(result, contains('void initRaiserInventoryBus(EventBus bus)'));
      });

      /// Tests mixed default and named bus handlers.
      test('generates both default and named bus functions', () {
        final handlers = [
          HandlerInfo(
            className: 'DefaultHandler',
            eventType: 'DefaultEvent',
            priority: 0,
            sourceFile: 'lib/handlers/default.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
          HandlerInfo(
            className: 'NamedHandler',
            eventType: 'NamedEvent',
            priority: 0,
            busName: 'custom',
            sourceFile: 'lib/handlers/named.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitAllInitFunctions(handlers, []);

        // Both functions should be generated
        expect(result, contains('void initRaiser(EventBus bus)'));
        expect(result, contains('void initRaiserCustomBus(EventBus bus)'));
      });
    });

    group('Dependency injection', () {
      /// Tests that handlers with dependencies generate factory functions.
      test('generates factory functions for handlers with dependencies', () {
        final handlers = [
          HandlerInfo(
            className: 'LoggingHandler',
            eventType: 'TestEvent',
            priority: 0,
            sourceFile: 'lib/handlers/logging.dart',
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

        // Factory typedef should be generated (no-arg function)
        expect(
          result,
          contains('typedef LoggingHandlerFactory = LoggingHandler Function()'),
        );

        // Factory variant function should be generated
        expect(result, contains('initRaiserWithFactories'));
        expect(result, contains('required LoggingHandlerFactory'));
      });

      /// Tests factory function with multiple parameters.
      test('generates factory with multiple parameters', () {
        final handlers = [
          HandlerInfo(
            className: 'ComplexHandler',
            eventType: 'ComplexEvent',
            priority: 0,
            sourceFile: 'lib/handlers/complex.dart',
            constructor: ConstructorInfo(
              hasParameters: true,
              parameters: [
                const ParameterInfo(
                  name: 'repository',
                  type: 'Repository',
                  isRequired: true,
                ),
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

        // Factory typedef should be a no-arg function
        expect(result, contains('typedef ComplexHandlerFactory = ComplexHandler Function()'));
      });
    });

    group('Source file comments', () {
      /// **Feature: code-generator, Property 12: Source File Comments**
      test('includes source file comments in generated code', () {
        final handlers = [
          HandlerInfo(
            className: 'CommentedHandler',
            eventType: 'TestEvent',
            priority: 50,
            sourceFile: 'lib/handlers/commented.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        // Source file comment should be present
        expect(result, contains('// Handler: CommentedHandler from'));

        // Priority comment should be present
        expect(result, contains('// Priority: 50'));
      });
    });

    group('Combined handlers and middleware', () {
      /// Tests combined handlers and middleware in same file.
      test('generates combined registration for handlers and middleware', () {
        final handlers = [
          HandlerInfo(
            className: 'TestHandler',
            eventType: 'TestEvent',
            priority: 0,
            sourceFile: 'lib/handlers/test.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final middleware = [
          MiddlewareInfo(
            className: 'TestMiddleware',
            priority: 100,
            sourceFile: 'lib/middleware/test.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, middleware);

        // Both should be in the same initRaiser function
        expect(result, contains('void initRaiser(EventBus bus)'));
        expect(result, contains('bus.addMiddleware(TestMiddleware()'));
        expect(result, contains('bus.register<TestEvent>(TestHandler())'));
      });

      /// Tests that middleware is registered before handlers.
      test('registers middleware before handlers', () {
        final handlers = [
          HandlerInfo(
            className: 'TestHandler',
            eventType: 'TestEvent',
            priority: 0,
            sourceFile: 'lib/handlers/test.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final middleware = [
          MiddlewareInfo(
            className: 'TestMiddleware',
            priority: 0,
            sourceFile: 'lib/middleware/test.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, middleware);

        // Middleware should appear before handler
        final middlewareIndex = result.indexOf('addMiddleware');
        final handlerIndex = result.indexOf('register<TestEvent>');
        expect(middlewareIndex, lessThan(handlerIndex),
            reason: 'Middleware should be registered before handlers');
      });
    });

    group('Generated code structure', () {
      /// Tests that generated code is syntactically valid Dart.
      test('generated code has balanced braces', () {
        final handlers = [
          HandlerInfo(
            className: 'ValidHandler',
            eventType: 'TestEvent',
            priority: 10,
            sourceFile: 'lib/handlers/valid.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final middleware = [
          MiddlewareInfo(
            className: 'ValidMiddleware',
            priority: 50,
            sourceFile: 'lib/middleware/valid.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, middleware);

        // Check for balanced braces
        final openBraces = '{'.allMatches(result).length;
        final closeBraces = '}'.allMatches(result).length;
        expect(openBraces, equals(closeBraces),
            reason: 'Braces should be balanced');

        // Check for balanced parentheses
        final openParens = '('.allMatches(result).length;
        final closeParens = ')'.allMatches(result).length;
        expect(openParens, equals(closeParens),
            reason: 'Parentheses should be balanced');
      });

      /// Tests that generated code contains proper documentation.
      test('generated code contains documentation comments', () {
        final handlers = [
          HandlerInfo(
            className: 'DocumentedHandler',
            eventType: 'TestEvent',
            priority: 0,
            sourceFile: 'lib/handlers/documented.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        // Documentation comments should be present
        expect(result, contains('/// Initializes all Raiser handlers'));
      });
    });

    group('Edge cases', () {
      /// Tests empty handler and middleware lists.
      test('handles empty handler and middleware lists', () {
        final result = emitter.emitInitFunction(null, [], []);

        // Should still generate a valid function
        expect(result, contains('void initRaiser(EventBus bus)'));
        expect(result, contains('{'));
        expect(result, contains('}'));
      });

      /// Tests handler with zero priority (should not include priority param).
      test('omits priority parameter when priority is zero', () {
        final handlers = [
          HandlerInfo(
            className: 'ZeroPriorityHandler',
            eventType: 'TestEvent',
            priority: 0,
            sourceFile: 'lib/handlers/zero.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        ];

        final result = emitter.emitInitFunction(null, handlers, []);

        // Should not include priority parameter
        expect(result, contains('bus.register<TestEvent>(ZeroPriorityHandler())'));
        expect(result, isNot(contains('priority: 0')));
      });
    });
  });
}
