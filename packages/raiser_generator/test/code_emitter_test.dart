import 'package:glados/glados.dart';
import 'package:raiser_generator/src/code_emitter.dart';
import 'package:raiser_generator/src/models/constructor_info.dart';
import 'package:raiser_generator/src/models/handler_info.dart';
import 'package:raiser_generator/src/models/middleware_info.dart';
import 'package:raiser_generator/src/models/parameter_info.dart';

/// Custom generators for property-based testing of CodeEmitter.
extension CodeEmitterTestGenerators on Any {
  /// Generates valid Dart class names.
  Generator<String> get validClassName => any.choose([
        'OrderHandler',
        'PaymentHandler',
        'UserCreatedHandler',
        'NotificationHandler',
        'EmailHandler',
        'LoggingHandler',
        'AuditHandler',
        'MetricsHandler',
      ]);

  /// Generates valid middleware class names.
  Generator<String> get validMiddlewareClassName => any.choose([
        'LoggingMiddleware',
        'AuthMiddleware',
        'ValidationMiddleware',
        'CachingMiddleware',
        'MetricsMiddleware',
        'RateLimitMiddleware',
      ]);

  /// Generates valid event type names.
  Generator<String> get validEventType => any.choose([
        'OrderCreatedEvent',
        'PaymentProcessedEvent',
        'UserRegisteredEvent',
        'NotificationSentEvent',
        'EmailDeliveredEvent',
      ]);

  /// Generates valid priority values.
  Generator<int> get validPriority => any.intInRange(-100, 100);

  /// Generates optional bus names.
  Generator<String?> get optionalBusName => any.choose([
        null,
        'orders',
        'payments',
        'notifications',
        'audit',
      ]);

  /// Generates non-null bus names.
  Generator<String> get busName => any.choose([
        'orders',
        'payments',
        'notifications',
        'audit',
      ]);

  /// Generates valid source file paths.
  Generator<String> get validSourceFile => any.choose([
        'lib/handlers/order_handler.dart',
        'lib/handlers/payment_handler.dart',
        'lib/src/handlers/user_handler.dart',
        'lib/events/notification_handler.dart',
      ]);

  /// Generates a no-args ConstructorInfo.
  Generator<ConstructorInfo> get noArgsConstructor =>
      any.always(const ConstructorInfo.noArgs());

  /// Generates a HandlerInfo with no constructor parameters.
  Generator<HandlerInfo> get simpleHandlerInfo => any.combine5(
        validClassName,
        validEventType,
        validPriority,
        validSourceFile,
        noArgsConstructor,
        (className, eventType, priority, sourceFile, constructor) =>
            HandlerInfo(
          className: className,
          eventType: eventType,
          priority: priority,
          busName: null,
          sourceFile: sourceFile,
          constructor: constructor,
        ),
      );

  /// Generates a MiddlewareInfo with no constructor parameters.
  Generator<MiddlewareInfo> get simpleMiddlewareInfo => any.combine4(
        validMiddlewareClassName,
        validPriority,
        validSourceFile,
        noArgsConstructor,
        (className, priority, sourceFile, constructor) => MiddlewareInfo(
          className: className,
          priority: priority,
          busName: null,
          sourceFile: sourceFile,
          constructor: constructor,
        ),
      );

  /// Generates a list of simple handlers.
  Generator<List<HandlerInfo>> get handlerList =>
      any.listWithLengthInRange(1, 5, simpleHandlerInfo);

  /// Generates a list of simple middleware.
  Generator<List<MiddlewareInfo>> get middlewareList =>
      any.listWithLengthInRange(0, 3, simpleMiddlewareInfo);
}

void main() {
  final emitter = CodeEmitter();

  group('InitRaiser Function Structure', () {
    /// **Feature: code-generator, Property 8: InitRaiser Function Structure**
    /// **Validates: Requirements 3.1**
    ///
    /// *For any* generated output, there SHALL exist a function named
    /// `initRaiser` (or `initRaiser{BusName}Bus` for named buses) that
    /// accepts an `EventBus` parameter.
    Glados2(any.handlerList, any.middlewareList).test(
      'Property 8: initRaiser function exists with EventBus parameter',
      (handlers, middleware) {
        final output = emitter.emitInitFunction(null, handlers, middleware);

        // Verify function name is 'initRaiser'
        expect(output, contains('void initRaiser(EventBus bus)'));

        // Verify function has proper structure
        expect(output, contains('{'));
        expect(output, contains('}'));
      },
    );

    /// Property test: Named bus generates correct function name
    Glados(any.busName).test(
      'Property 8: named bus generates initRaiser{BusName}Bus function',
      (busName) {
        final handler = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: 0,
          busName: busName,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final output = emitter.emitInitFunction(busName, [handler], []);

        // Verify function name follows pattern initRaiser{BusName}Bus
        final capitalizedBusName =
            busName[0].toUpperCase() + busName.substring(1);
        final expectedFunctionName = 'initRaiser${capitalizedBusName}Bus';

        expect(output, contains('void $expectedFunctionName(EventBus bus)'));
      },
    );

    /// Property test: Function accepts EventBus parameter
    Glados2(any.optionalBusName, any.handlerList).test(
      'function always accepts EventBus parameter',
      (busName, handlers) {
        final output = emitter.emitInitFunction(busName, handlers, []);

        // Verify EventBus parameter is present
        expect(output, contains('EventBus bus'));
      },
    );

    /// Property test: Empty handlers and middleware produces valid function
    test('empty handlers and middleware produces valid function', () {
      final output = emitter.emitInitFunction(null, [], []);

      expect(output, contains('void initRaiser(EventBus bus)'));
      expect(output, contains('{'));
      expect(output, contains('}'));
    });
  });

  group('Handler Registration', () {
    /// Property test: All handlers are registered
    Glados(any.handlerList).test(
      'all handlers are registered in output',
      (handlers) {
        final output = emitter.emitInitFunction(null, handlers, []);

        for (final handler in handlers) {
          // Each handler should have a registration call
          expect(output, contains('bus.register<${handler.eventType}>'));
          expect(output, contains('${handler.className}()'));
        }
      },
    );

    /// **Feature: code-generator, Property 3: Multiple Handler Registration**
    /// **Validates: Requirements 1.3**
    ///
    /// *For any* event type T with multiple handlers registered, the generated
    /// `initRaiser` function SHALL register all handlers for that event type.
    Glados2(any.validEventType, any.intInRange(2, 5)).test(
      'Property 3: multiple handlers for same event type are all registered',
      (eventType, handlerCount) {
        // Create multiple handlers for the same event type
        final handlers = List.generate(
          handlerCount,
          (i) => HandlerInfo(
            className: 'Handler$i',
            eventType: eventType,
            priority: i * 10,
            sourceFile: 'lib/handler_$i.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        );

        final output = emitter.emitInitFunction(null, handlers, []);

        // Verify ALL handlers are registered
        for (final handler in handlers) {
          // Each handler should have its own registration call
          expect(
            output,
            contains('bus.register<$eventType>(${handler.className}()'),
            reason: 'Handler ${handler.className} should be registered',
          );
        }

        // Count the number of registration calls for this event type
        final registrationPattern = RegExp(
          r'bus\.register<' + RegExp.escape(eventType) + r'>',
        );
        final matches = registrationPattern.allMatches(output).length;

        // Should have exactly handlerCount registrations
        expect(
          matches,
          equals(handlerCount),
          reason: 'Should have $handlerCount registrations for $eventType',
        );
      },
    );

    /// Property test: Handler registration includes event type
    Glados(any.simpleHandlerInfo).test(
      'handler registration includes correct event type',
      (handler) {
        final registration = emitter.emitHandlerRegistration(handler);

        expect(registration, contains('bus.register<${handler.eventType}>'));
      },
    );

    /// Property test: Non-zero priority is included in registration
    Glados(any.intInRange(1, 100)).test(
      'non-zero priority is included in handler registration',
      (priority) {
        final handler = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final registration = emitter.emitHandlerRegistration(handler);

        expect(registration, contains('priority: $priority'));
      },
    );

    /// Property test: Zero priority omits priority parameter
    test('zero priority omits priority parameter', () {
      final handler = HandlerInfo(
        className: 'TestHandler',
        eventType: 'TestEvent',
        priority: 0,
        sourceFile: 'lib/test.dart',
        constructor: const ConstructorInfo.noArgs(),
      );

      final registration = emitter.emitHandlerRegistration(handler);

      expect(registration, isNot(contains('priority:')));
    });
  });

  group('Factory Function Generation', () {
    /// Property test: Factory typedef is generated for handlers with dependencies
    test('factory typedef is generated for handlers with dependencies', () {
      final handler = HandlerInfo(
        className: 'OrderHandler',
        eventType: 'OrderCreatedEvent',
        priority: 0,
        sourceFile: 'lib/handlers/order_handler.dart',
        constructor: ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'repository',
              type: 'OrderRepository',
              isRequired: true,
            ),
            const ParameterInfo(
              name: 'logger',
              type: 'Logger',
              isRequired: true,
            ),
          ],
        ),
      );

      final typedef = emitter.emitFactoryTypedef(handler);

      // Factory typedef should be a no-arg function
      expect(typedef, contains('typedef OrderHandlerFactory'));
      expect(typedef, contains('OrderHandler Function()'));
    });

    /// Property test: Factory function preserves parameter names and types
    Glados(any.validClassName).test(
      'factory typedef preserves class name',
      (className) {
        final handler = HandlerInfo(
          className: className,
          eventType: 'TestEvent',
          priority: 0,
          sourceFile: 'lib/test.dart',
          constructor: ConstructorInfo(
            hasParameters: true,
            parameters: [
              const ParameterInfo(
                name: 'service',
                type: 'TestService',
                isRequired: true,
              ),
            ],
          ),
        );

        final typedef = emitter.emitFactoryTypedef(handler);

        expect(typedef, contains('typedef ${className}Factory'));
        expect(typedef, contains('$className Function()'));
      },
    );

    /// Property test: initRaiserWithFactories is generated when handlers have dependencies
    test('initRaiserWithFactories is generated for handlers with dependencies',
        () {
      final handlerWithDeps = HandlerInfo(
        className: 'OrderHandler',
        eventType: 'OrderCreatedEvent',
        priority: 10,
        sourceFile: 'lib/handlers/order_handler.dart',
        constructor: ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'repository',
              type: 'OrderRepository',
              isRequired: true,
            ),
          ],
        ),
      );

      final simpleHandler = HandlerInfo(
        className: 'SimpleHandler',
        eventType: 'SimpleEvent',
        priority: 0,
        sourceFile: 'lib/handlers/simple_handler.dart',
        constructor: const ConstructorInfo.noArgs(),
      );

      final output =
          emitter.emitInitFunction(null, [handlerWithDeps, simpleHandler], []);

      // Should have both regular initRaiser and factory variant
      expect(output, contains('void initRaiser(EventBus bus)'));
      expect(output, contains('void initRaiserWithFactories('));
      expect(output, contains('required OrderHandlerFactory createOrderHandler'));
    });

    /// Property test: Named parameters are formatted correctly
    test('named parameters are formatted correctly in factory typedef', () {
      final handler = HandlerInfo(
        className: 'ConfigurableHandler',
        eventType: 'TestEvent',
        priority: 0,
        sourceFile: 'lib/test.dart',
        constructor: ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'required_param',
              type: 'String',
              isRequired: true,
              isNamed: true,
            ),
            const ParameterInfo(
              name: 'optional_param',
              type: 'int',
              isRequired: false,
              isNamed: true,
            ),
            const ParameterInfo(
              name: 'default_param',
              type: 'bool',
              isRequired: false,
              defaultValue: 'true',
              isNamed: true,
            ),
          ],
        ),
      );

      final typedef = emitter.emitFactoryTypedef(handler);

      // Factory typedef should be a no-arg function that returns the handler
      // The user provides a closure that captures the dependencies
      expect(typedef, contains('typedef ConfigurableHandlerFactory'));
      expect(typedef, contains('ConfigurableHandler Function()'));
    });

    /// Property test: Middleware factory typedef is generated correctly
    test('middleware factory typedef is generated correctly', () {
      final middleware = MiddlewareInfo(
        className: 'LoggingMiddleware',
        priority: 100,
        sourceFile: 'lib/middleware/logging.dart',
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
      );

      final typedef = emitter.emitMiddlewareFactoryTypedef(middleware);

      // Factory typedef should be a no-arg function
      expect(typedef, contains('typedef LoggingMiddlewareFactory'));
      expect(typedef, contains('LoggingMiddleware Function()'));
    });
  });

  group('Middleware Registration', () {
    /// Property test: All middleware are registered
    Glados(any.middlewareList).test(
      'all middleware are registered in output',
      (middleware) {
        if (middleware.isEmpty) return;

        final output = emitter.emitInitFunction(null, [], middleware);

        for (final m in middleware) {
          expect(output, contains('bus.addMiddleware'));
          expect(output, contains('${m.className}()'));
        }
      },
    );

    /// Property test: Middleware registration format
    Glados(any.simpleMiddlewareInfo).test(
      'middleware registration uses addMiddleware',
      (middleware) {
        final registration = emitter.emitMiddlewareRegistration(middleware);

        expect(registration, contains('bus.addMiddleware'));
        expect(registration, contains('${middleware.className}()'));
      },
    );

    /// Property test: Non-zero priority is included in middleware registration
    Glados(any.intInRange(1, 100)).test(
      'non-zero priority is included in middleware registration',
      (priority) {
        final middleware = MiddlewareInfo(
          className: 'TestMiddleware',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final registration = emitter.emitMiddlewareRegistration(middleware);

        expect(registration, contains('priority: $priority'));
      },
    );
  });

  group('Named Bus Support', () {
    /// **Feature: code-generator, Property 7: Bus Name Segregation**
    /// **Validates: Requirements 2.3, 3.4**
    ///
    /// *For any* handlers or middleware specifying a busName, the generator
    /// SHALL produce a separate initialization function for each unique bus name.
    Glados(any.intInRange(2, 4)).test(
      'Property 7: separate init functions for each unique bus name',
      (busCount) {
        final busNames = ['orders', 'payments', 'notifications', 'audit']
            .take(busCount)
            .toList();

        // Create handlers for each bus
        final handlers = <HandlerInfo>[];
        for (var i = 0; i < busNames.length; i++) {
          handlers.add(HandlerInfo(
            className: 'Handler$i',
            eventType: 'Event$i',
            priority: 0,
            busName: busNames[i],
            sourceFile: 'lib/handler_$i.dart',
            constructor: const ConstructorInfo.noArgs(),
          ));
        }

        final output = emitter.emitAllInitFunctions(handlers, []);

        // Verify each bus has its own init function
        for (final busName in busNames) {
          final capitalizedBusName =
              busName[0].toUpperCase() + busName.substring(1);
          expect(
            output,
            contains('void initRaiser${capitalizedBusName}Bus(EventBus bus)'),
          );
        }
      },
    );

    /// Property test: Handlers are grouped by bus name
    test('handlers are grouped by bus name correctly', () {
      final handlers = [
        HandlerInfo(
          className: 'OrderHandler',
          eventType: 'OrderEvent',
          priority: 0,
          busName: 'orders',
          sourceFile: 'lib/order.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        HandlerInfo(
          className: 'PaymentHandler',
          eventType: 'PaymentEvent',
          priority: 0,
          busName: 'payments',
          sourceFile: 'lib/payment.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        HandlerInfo(
          className: 'DefaultHandler',
          eventType: 'DefaultEvent',
          priority: 0,
          busName: null,
          sourceFile: 'lib/default.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        HandlerInfo(
          className: 'AnotherOrderHandler',
          eventType: 'AnotherOrderEvent',
          priority: 0,
          busName: 'orders',
          sourceFile: 'lib/another_order.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
      ];

      final grouped = emitter.groupHandlersByBus(handlers);

      expect(grouped.keys, containsAll([null, 'orders', 'payments']));
      expect(grouped['orders']!.length, equals(2));
      expect(grouped['payments']!.length, equals(1));
      expect(grouped[null]!.length, equals(1));
    });

    /// Property test: Middleware are grouped by bus name
    test('middleware are grouped by bus name correctly', () {
      final middleware = [
        MiddlewareInfo(
          className: 'OrdersLogging',
          priority: 100,
          busName: 'orders',
          sourceFile: 'lib/orders_logging.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        MiddlewareInfo(
          className: 'GlobalLogging',
          priority: 100,
          busName: null,
          sourceFile: 'lib/global_logging.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
      ];

      final grouped = emitter.groupMiddlewareByBus(middleware);

      expect(grouped.keys, containsAll([null, 'orders']));
      expect(grouped['orders']!.length, equals(1));
      expect(grouped[null]!.length, equals(1));
    });

    /// Property test: Separate init functions are generated for each bus
    test('separate init functions are generated for each bus', () {
      final handlers = [
        HandlerInfo(
          className: 'OrderHandler',
          eventType: 'OrderEvent',
          priority: 0,
          busName: 'orders',
          sourceFile: 'lib/order.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        HandlerInfo(
          className: 'PaymentHandler',
          eventType: 'PaymentEvent',
          priority: 0,
          busName: 'payments',
          sourceFile: 'lib/payment.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        HandlerInfo(
          className: 'DefaultHandler',
          eventType: 'DefaultEvent',
          priority: 0,
          busName: null,
          sourceFile: 'lib/default.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
      ];

      final output = emitter.emitAllInitFunctions(handlers, []);

      // Should have three separate init functions
      expect(output, contains('void initRaiser(EventBus bus)'));
      expect(output, contains('void initRaiserOrdersBus(EventBus bus)'));
      expect(output, contains('void initRaiserPaymentsBus(EventBus bus)'));

      // Each handler should be in the correct function
      // OrderHandler should be in initRaiserOrdersBus
      expect(
        output.indexOf('initRaiserOrdersBus') <
            output.indexOf('OrderHandler()'),
        isTrue,
      );
    });

    /// Property test: Named bus function name follows pattern
    Glados(any.busName).test(
      'named bus function name follows initRaiser{BusName}Bus pattern',
      (busName) {
        final handler = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: 0,
          busName: busName,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final output = emitter.emitInitFunction(busName, [handler], []);

        final capitalizedBusName =
            busName[0].toUpperCase() + busName.substring(1);
        expect(output, contains('initRaiser${capitalizedBusName}Bus'));
      },
    );
  });

  group('Source File Comments', () {
    /// **Feature: code-generator, Property 12: Source File Comments**
    /// **Validates: Requirements 7.1, 7.3**
    ///
    /// *For any* generated handler registration, the output SHALL include
    /// a comment indicating the source file path where the handler is defined.
    Glados(any.simpleHandlerInfo).test(
      'Property 12: handler registration includes source file comment',
      (handler) {
        final registration = emitter.emitHandlerRegistration(handler);

        // Verify source file comment is present
        expect(registration, contains('// Handler:'));
        expect(registration, contains(handler.className));
        expect(registration, contains('from'));
        expect(registration, contains(handler.sourceFile));
      },
    );

    /// Property test: Middleware registration includes source file comment
    Glados(any.simpleMiddlewareInfo).test(
      'middleware registration includes source file comment',
      (middleware) {
        final registration = emitter.emitMiddlewareRegistration(middleware);

        // Verify source file comment is present
        expect(registration, contains('// Middleware:'));
        expect(registration, contains(middleware.className));
        expect(registration, contains('from'));
        expect(registration, contains(middleware.sourceFile));
      },
    );

    /// Property test: Priority comment is included
    Glados(any.simpleHandlerInfo).test(
      'handler registration includes priority comment',
      (handler) {
        final registration = emitter.emitHandlerRegistration(handler);

        // Verify priority comment is present
        expect(registration, contains('// Priority:'));
        expect(registration, contains(handler.priority.toString()));
      },
    );

    /// Property test: Middleware priority comment is included
    Glados(any.simpleMiddlewareInfo).test(
      'middleware registration includes priority comment',
      (middleware) {
        final registration = emitter.emitMiddlewareRegistration(middleware);

        // Verify priority comment is present
        expect(registration, contains('// Priority:'));
        expect(registration, contains(middleware.priority.toString()));
      },
    );

    /// Property test: Source file path is preserved exactly
    Glados(any.validSourceFile).test(
      'source file path is preserved exactly in comments',
      (sourceFile) {
        final handler = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: 0,
          sourceFile: sourceFile,
          constructor: const ConstructorInfo.noArgs(),
        );

        final registration = emitter.emitHandlerRegistration(handler);

        expect(registration, contains(sourceFile));
      },
    );
  });

  group('Code Formatting Compliance', () {
    /// **Feature: code-generator, Property 13: Code Formatting Compliance**
    /// **Validates: Requirements 7.2**
    ///
    /// *For any* generated output, running `dart format` on the output
    /// SHALL produce no changes (output is already properly formatted).
    ///
    /// This test validates that the generated code follows Dart style guidelines
    /// by checking structural formatting rules.
    Glados(any.simpleHandlerInfo).test(
      'Property 13: handler registration follows Dart style guidelines',
      (handler) {
        final registration = emitter.emitHandlerRegistration(handler);

        // Check proper indentation (2 spaces)
        final lines = registration.split('\n').where((l) => l.isNotEmpty);
        for (final line in lines) {
          // Lines should start with proper indentation
          expect(line, startsWith('  '));
        }

        // Check proper semicolon usage
        final codeLines = lines.where((l) => !l.trim().startsWith('//'));
        for (final line in codeLines) {
          if (line.trim().isNotEmpty) {
            expect(line.trim(), endsWith(';'));
          }
        }
      },
    );

    /// Property test: Init function follows Dart style guidelines
    Glados2(any.handlerList, any.middlewareList).test(
      'init function follows Dart style guidelines',
      (handlers, middleware) {
        final output = emitter.emitInitFunction(null, handlers, middleware);

        // Check function declaration format
        expect(output, contains('void initRaiser(EventBus bus) {'));

        // Check proper closing brace
        expect(output, contains('}'));

        // Check doc comments use triple slash
        expect(output, contains('///'));
      },
    );

    /// Property test: Generated code uses proper spacing
    test('generated code uses proper spacing around operators', () {
      final handler = HandlerInfo(
        className: 'TestHandler',
        eventType: 'TestEvent',
        priority: 10,
        sourceFile: 'lib/test.dart',
        constructor: const ConstructorInfo.noArgs(),
      );

      final registration = emitter.emitHandlerRegistration(handler);

      // Check proper spacing around colon in named parameters
      expect(registration, contains('priority: 10'));
    });

    /// Property test: Factory typedef follows Dart style
    test('factory typedef follows Dart style guidelines', () {
      final handler = HandlerInfo(
        className: 'OrderHandler',
        eventType: 'OrderEvent',
        priority: 0,
        sourceFile: 'lib/order.dart',
        constructor: ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'repository',
              type: 'OrderRepository',
              isRequired: true,
            ),
          ],
        ),
      );

      final typedef = emitter.emitFactoryTypedef(handler);

      // Check typedef format
      expect(typedef, startsWith('typedef'));
      expect(typedef, contains('='));
      expect(typedef, contains('Function'));
      expect(typedef, endsWith(';'));
    });

    /// Property test: Comments follow Dart style
    Glados(any.simpleHandlerInfo).test(
      'comments follow Dart style guidelines',
      (handler) {
        final registration = emitter.emitHandlerRegistration(handler);

        // Comments should use // format
        expect(registration, contains('//'));

        // Comments should have space after //
        final commentLines = registration
            .split('\n')
            .where((l) => l.trim().startsWith('//'));
        for (final line in commentLines) {
          final trimmed = line.trim();
          // After //, there should be a space
          expect(trimmed.substring(2, 3), equals(' '));
        }
      },
    );
  });
}
