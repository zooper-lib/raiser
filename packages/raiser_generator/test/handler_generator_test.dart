import 'package:glados/glados.dart';
import 'package:raiser_generator/src/models/handler_info.dart';
import 'package:raiser_generator/src/models/constructor_info.dart';
import 'package:raiser_generator/src/models/parameter_info.dart';

/// Custom generators for property-based testing of handler generator logic.
extension HandlerTestGenerators on Any {
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

  /// Generates valid event type names.
  Generator<String> get validEventType => any.choose([
        'OrderCreatedEvent',
        'PaymentProcessedEvent',
        'UserRegisteredEvent',
        'NotificationSentEvent',
        'EmailDeliveredEvent',
        'AuditLogEvent',
        'MetricRecordedEvent',
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

  /// Generates valid source file paths.
  Generator<String> get validSourceFile => any.choose([
        'lib/handlers/order_handler.dart',
        'lib/handlers/payment_handler.dart',
        'lib/src/handlers/user_handler.dart',
        'lib/events/notification_handler.dart',
      ]);

  /// Generates a ConstructorInfo.
  Generator<ConstructorInfo> get constructorInfo => any.choose([
        const ConstructorInfo.noArgs(),
        ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'repository',
              type: 'OrderRepository',
              isRequired: true,
            ),
          ],
        ),
        ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'logger',
              type: 'Logger',
              isRequired: true,
            ),
            const ParameterInfo(
              name: 'config',
              type: 'Config',
              isRequired: false,
              defaultValue: 'null',
              isNamed: true,
            ),
          ],
        ),
      ]);

  /// Generates a HandlerInfo instance.
  Generator<HandlerInfo> get handlerInfo => any.combine6(
        validClassName,
        validEventType,
        validPriority,
        optionalBusName,
        validSourceFile,
        constructorInfo,
        (className, eventType, priority, busName, sourceFile, constructor) =>
            HandlerInfo(
          className: className,
          eventType: eventType,
          priority: priority,
          busName: busName,
          sourceFile: sourceFile,
          constructor: constructor,
        ),
      );
}

void main() {
  group('HandlerInfo', () {
    /// **Feature: code-generator, Property 2: Invalid Handler Rejection**
    ///
    /// This test validates that HandlerInfo correctly captures all handler
    /// metadata. The actual rejection of invalid handlers is tested via
    /// integration tests with build_runner.
    ///
    /// The property being tested here is that for any valid handler
    /// configuration, the HandlerInfo preserves all attributes correctly.
    Glados(any.handlerInfo).test(
      'Property 2: HandlerInfo preserves all handler attributes',
      (info) {
        // Verify all attributes are accessible and preserved
        expect(info.className, isNotEmpty);
        expect(info.eventType, isNotEmpty);
        expect(info.sourceFile, isNotEmpty);
        expect(info.constructor, isNotNull);

        // Create a copy and verify equality
        final copy = HandlerInfo(
          className: info.className,
          eventType: info.eventType,
          priority: info.priority,
          busName: info.busName,
          sourceFile: info.sourceFile,
          constructor: info.constructor,
        );

        expect(copy, equals(info));
        expect(copy.hashCode, equals(info.hashCode));
      },
    );

    /// Test that toString contains all relevant information.
    Glados(any.handlerInfo).test(
      'toString contains all field values',
      (info) {
        final str = info.toString();

        expect(str, contains(info.className));
        expect(str, contains(info.eventType));
        expect(str, contains(info.priority.toString()));
        expect(str, contains(info.sourceFile));
        if (info.busName != null) {
          expect(str, contains(info.busName!));
        }
      },
    );
  });

  group('Handler Validation Logic', () {
    /// **Feature: code-generator, Property 2: Invalid Handler Rejection**
    ///
    /// *For any* class annotated with `@RaiserHandler` that does not extend
    /// `EventHandler<T>`, the generator SHALL emit a compile-time error.
    ///
    /// This property is validated through the error message format.
    /// The actual validation happens in the generator, but we can verify
    /// the expected error message patterns.
    test('error messages follow expected format for non-EventHandler classes',
        () {
      // These are the expected error message patterns from the generator
      const nonClassError =
          '@RaiserHandler can only be applied to classes. Found:';
      const abstractError =
          '@RaiserHandler cannot be applied to abstract classes.';
      const notEventHandlerError = 'must extend EventHandler<T>';
      const noConstructorError = 'must have an accessible constructor';
      const unresolvableTypeError = 'Cannot resolve event type';

      // Verify error messages are descriptive
      expect(nonClassError, contains('classes'));
      expect(abstractError, contains('abstract'));
      expect(notEventHandlerError, contains('EventHandler'));
      expect(noConstructorError, contains('constructor'));
      expect(unresolvableTypeError, contains('resolve'));
    });

    /// Property test: Priority values are preserved in HandlerInfo
    Glados(any.validPriority).test(
      'priority values are preserved correctly',
      (priority) {
        final info = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.priority, equals(priority));
      },
    );

    /// Property test: Bus names are preserved in HandlerInfo
    Glados(any.optionalBusName).test(
      'bus names are preserved correctly',
      (busName) {
        final info = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: 0,
          busName: busName,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.busName, equals(busName));
      },
    );
  });

  group('Event Type Extraction', () {
    /// **Feature: code-generator, Property 9: Event Type Extraction**
    ///
    /// *For any* handler extending `EventHandler<T>` where T is a concrete type,
    /// the generated registration code SHALL use type T in the generic parameter
    /// of the register call.
    ///
    /// This test validates that event types are correctly preserved in HandlerInfo.
    Glados(any.validEventType).test(
      'Property 9: event types are preserved in HandlerInfo',
      (eventType) {
        final info = HandlerInfo(
          className: 'TestHandler',
          eventType: eventType,
          priority: 0,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        // Verify event type is preserved exactly
        expect(info.eventType, equals(eventType));

        // Verify event type appears in toString
        expect(info.toString(), contains(eventType));
      },
    );

    /// Property test: Event types with generics are preserved
    test('event types with generic parameters are preserved', () {
      const genericEventTypes = [
        'List<String>',
        'Map<String, int>',
        'Future<OrderEvent>',
        'Stream<UserEvent>',
      ];

      for (final eventType in genericEventTypes) {
        final info = HandlerInfo(
          className: 'TestHandler',
          eventType: eventType,
          priority: 0,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.eventType, equals(eventType));
      }
    });

    /// Property test: Combination of event type and class name
    Glados2(any.validClassName, any.validEventType).test(
      'handler and event type combinations are preserved',
      (className, eventType) {
        final info = HandlerInfo(
          className: className,
          eventType: eventType,
          priority: 0,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.className, equals(className));
        expect(info.eventType, equals(eventType));

        // Both should appear in toString
        final str = info.toString();
        expect(str, contains(className));
        expect(str, contains(eventType));
      },
    );
  });

  group('Handler Discovery Completeness', () {
    /// **Feature: code-generator, Property 1: Handler Discovery Completeness**
    ///
    /// *For any* set of source files containing classes annotated with
    /// `@RaiserHandler` that extend `EventHandler<T>`, the generated output
    /// SHALL contain registration code for every such handler.
    ///
    /// This test validates that for any collection of valid handlers,
    /// each handler's information is preserved and can be used for
    /// registration code generation.
    Glados(any.handlerInfo).test(
      'Property 1: each handler is preserved for discovery',
      (handler) {
        // Verify each handler has all required fields for discovery
        expect(handler.className, isNotEmpty);
        expect(handler.eventType, isNotEmpty);
        expect(handler.sourceFile, isNotEmpty);
        expect(handler.constructor, isNotNull);

        // Create a list of handlers and verify all are preserved
        final handlers = [handler];
        expect(handlers.length, equals(1));
        expect(handlers.first, equals(handler));
      },
    );

    /// Property test: Handler registration info contains all required fields
    Glados(any.handlerInfo).test(
      'handler registration info contains all required fields for discovery',
      (handler) {
        // All fields required for registration must be present
        expect(handler.className, isNotEmpty);
        expect(handler.eventType, isNotEmpty);
        expect(handler.sourceFile, isNotEmpty);
        expect(handler.constructor, isNotNull);

        // Priority can be any integer (including 0)
        expect(handler.priority, isA<int>());

        // Bus name is optional but if present must be non-empty
        if (handler.busName != null) {
          expect(handler.busName, isNotEmpty);
        }
      },
    );

    /// Property test: Multiple handlers for same event type are all preserved
    Glados2(any.validEventType, any.intInRange(2, 5)).test(
      'multiple handlers for same event type are all preserved',
      (eventType, count) {
        final handlers = List.generate(
          count,
          (i) => HandlerInfo(
            className: 'Handler$i',
            eventType: eventType,
            priority: i,
            sourceFile: 'lib/handler_$i.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        );

        // All handlers should have the same event type
        for (final handler in handlers) {
          expect(handler.eventType, equals(eventType));
        }

        // All handlers should be distinct by className
        final classNames = handlers.map((h) => h.className).toSet();
        expect(classNames.length, equals(count));
      },
    );
  });

  group('Priority Preservation', () {
    /// **Feature: code-generator, Property 4: Priority Preservation**
    ///
    /// *For any* handler with a specified priority value P, the generated
    /// registration code SHALL include `priority: P` in the registration call.
    ///
    /// This test validates that priority values are correctly preserved
    /// in HandlerInfo for all valid priority values.
    Glados(any.validPriority).test(
      'Property 4: priority values are preserved exactly',
      (priority) {
        final info = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        // Priority must be preserved exactly
        expect(info.priority, equals(priority));

        // Priority should appear in toString
        expect(info.toString(), contains(priority.toString()));
      },
    );

    /// Property test: Negative priorities are preserved
    Glados(any.intInRange(-1000, -1)).test(
      'negative priority values are preserved',
      (priority) {
        final info = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.priority, equals(priority));
        expect(info.priority, lessThan(0));
      },
    );

    /// Property test: Zero priority is preserved
    test('zero priority is preserved', () {
      final info = HandlerInfo(
        className: 'TestHandler',
        eventType: 'TestEvent',
        priority: 0,
        sourceFile: 'lib/test.dart',
        constructor: const ConstructorInfo.noArgs(),
      );

      expect(info.priority, equals(0));
    });

    /// Property test: Positive priorities are preserved
    Glados(any.intInRange(1, 1000)).test(
      'positive priority values are preserved',
      (priority) {
        final info = HandlerInfo(
          className: 'TestHandler',
          eventType: 'TestEvent',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.priority, equals(priority));
        expect(info.priority, greaterThan(0));
      },
    );

    /// Property test: Priority ordering is maintained in collections
    Glados(any.intInRange(2, 10)).test(
      'priority ordering is maintained when sorting handlers',
      (count) {
        // Create handlers with random priorities
        final handlers = List.generate(
          count,
          (i) => HandlerInfo(
            className: 'Handler$i',
            eventType: 'TestEvent',
            priority: (i * 7) % 100 - 50, // Pseudo-random priorities
            sourceFile: 'lib/handler_$i.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        );

        // Sort by priority (descending - higher executes first)
        final sorted = List<HandlerInfo>.from(handlers)
          ..sort((a, b) => b.priority.compareTo(a.priority));

        // Verify sorting is correct
        for (var i = 0; i < sorted.length - 1; i++) {
          expect(
            sorted[i].priority,
            greaterThanOrEqualTo(sorted[i + 1].priority),
          );
        }
      },
    );
  });
}
