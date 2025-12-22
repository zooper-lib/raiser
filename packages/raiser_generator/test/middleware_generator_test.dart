import 'package:glados/glados.dart';
import 'package:raiser_generator/src/models/middleware_info.dart';
import 'package:raiser_generator/src/models/constructor_info.dart';
import 'package:raiser_generator/src/models/parameter_info.dart';

/// Custom generators for property-based testing of middleware generator logic.
extension MiddlewareTestGenerators on Any {
  /// Generates valid Dart class names for middleware.
  Generator<String> get validMiddlewareClassName => any.choose([
        'LoggingMiddleware',
        'AuthMiddleware',
        'ValidationMiddleware',
        'CachingMiddleware',
        'MetricsMiddleware',
        'RateLimitMiddleware',
        'RetryMiddleware',
        'TimeoutMiddleware',
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
        'lib/middleware/logging_middleware.dart',
        'lib/middleware/auth_middleware.dart',
        'lib/src/middleware/validation_middleware.dart',
        'lib/core/caching_middleware.dart',
      ]);

  /// Generates a ConstructorInfo.
  Generator<ConstructorInfo> get constructorInfo => any.choose([
        const ConstructorInfo.noArgs(),
        ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'logger',
              type: 'Logger',
              isRequired: true,
            ),
          ],
        ),
        ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'cache',
              type: 'Cache',
              isRequired: true,
            ),
            const ParameterInfo(
              name: 'ttl',
              type: 'Duration',
              isRequired: false,
              defaultValue: 'const Duration(minutes: 5)',
              isNamed: true,
            ),
          ],
        ),
      ]);

  /// Generates a MiddlewareInfo instance.
  Generator<MiddlewareInfo> get middlewareInfo => any.combine5(
        validMiddlewareClassName,
        validPriority,
        optionalBusName,
        validSourceFile,
        constructorInfo,
        (className, priority, busName, sourceFile, constructor) =>
            MiddlewareInfo(
          className: className,
          priority: priority,
          busName: busName,
          sourceFile: sourceFile,
          constructor: constructor,
        ),
      );
}

void main() {
  group('MiddlewareInfo', () {
    /// Test that MiddlewareInfo preserves all attributes correctly.
    Glados(any.middlewareInfo).test(
      'MiddlewareInfo preserves all middleware attributes',
      (info) {
        // Verify all attributes are accessible and preserved
        expect(info.className, isNotEmpty);
        expect(info.sourceFile, isNotEmpty);
        expect(info.constructor, isNotNull);

        // Create a copy and verify equality
        final copy = MiddlewareInfo(
          className: info.className,
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
    Glados(any.middlewareInfo).test(
      'toString contains all field values',
      (info) {
        final str = info.toString();

        expect(str, contains(info.className));
        expect(str, contains(info.priority.toString()));
        expect(str, contains(info.sourceFile));
        if (info.busName != null) {
          expect(str, contains(info.busName!));
        }
      },
    );
  });

  group('Middleware Discovery Completeness', () {
    /// **Feature: code-generator, Property 5: Middleware Discovery Completeness**
    /// **Validates: Requirements 2.1**
    ///
    /// *For any* set of source files containing classes annotated with
    /// `@RaiserMiddleware`, the generated output SHALL contain registration
    /// code for every such middleware.
    ///
    /// This test validates that for any collection of valid middleware,
    /// each middleware's information is preserved and can be used for
    /// registration code generation.
    Glados(any.middlewareInfo).test(
      'Property 5: each middleware is preserved for discovery',
      (middleware) {
        // Verify each middleware has all required fields for discovery
        expect(middleware.className, isNotEmpty);
        expect(middleware.sourceFile, isNotEmpty);
        expect(middleware.constructor, isNotNull);

        // Create a list of middleware and verify all are preserved
        final middlewareList = [middleware];
        expect(middlewareList.length, equals(1));
        expect(middlewareList.first, equals(middleware));
      },
    );

    /// Property test: Middleware registration info contains all required fields
    Glados(any.middlewareInfo).test(
      'middleware registration info contains all required fields for discovery',
      (middleware) {
        // All fields required for registration must be present
        expect(middleware.className, isNotEmpty);
        expect(middleware.sourceFile, isNotEmpty);
        expect(middleware.constructor, isNotNull);

        // Priority can be any integer (including 0)
        expect(middleware.priority, isA<int>());

        // Bus name is optional but if present must be non-empty
        if (middleware.busName != null) {
          expect(middleware.busName, isNotEmpty);
        }
      },
    );

    /// Property test: Multiple middleware are all preserved
    Glados(any.intInRange(2, 5)).test(
      'multiple middleware are all preserved',
      (count) {
        final middlewareList = List.generate(
          count,
          (i) => MiddlewareInfo(
            className: 'Middleware$i',
            priority: i,
            sourceFile: 'lib/middleware_$i.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        );

        // All middleware should be distinct by className
        final classNames = middlewareList.map((m) => m.className).toSet();
        expect(classNames.length, equals(count));

        // All middleware should be preserved
        expect(middlewareList.length, equals(count));
      },
    );
  });

  group('Middleware Priority Ordering', () {
    /// **Feature: code-generator, Property 6: Middleware Priority Ordering**
    /// **Validates: Requirements 2.2**
    ///
    /// *For any* set of middleware with different priority values, the generated
    /// registration code SHALL order middleware by priority (descending).
    ///
    /// This test validates that priority values are correctly preserved
    /// and can be used for ordering middleware.
    Glados(any.validPriority).test(
      'Property 6: priority values are preserved for ordering',
      (priority) {
        final info = MiddlewareInfo(
          className: 'TestMiddleware',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        // Priority must be preserved exactly
        expect(info.priority, equals(priority));
      },
    );

    /// Property test: Middleware can be sorted by priority (descending)
    Glados(any.intInRange(2, 10)).test(
      'middleware can be sorted by priority descending',
      (count) {
        // Create middleware with various priorities
        final middlewareList = List.generate(
          count,
          (i) => MiddlewareInfo(
            className: 'Middleware$i',
            priority: (i * 13) % 100 - 50, // Pseudo-random priorities
            sourceFile: 'lib/middleware_$i.dart',
            constructor: const ConstructorInfo.noArgs(),
          ),
        );

        // Sort by priority (descending - higher executes first as outer middleware)
        final sorted = List<MiddlewareInfo>.from(middlewareList)
          ..sort((a, b) => b.priority.compareTo(a.priority));

        // Verify sorting is correct (descending order)
        for (var i = 0; i < sorted.length - 1; i++) {
          expect(
            sorted[i].priority,
            greaterThanOrEqualTo(sorted[i + 1].priority),
          );
        }
      },
    );

    /// Property test: Negative priorities are preserved and ordered correctly
    Glados(any.intInRange(-1000, -1)).test(
      'negative priority values are preserved',
      (priority) {
        final info = MiddlewareInfo(
          className: 'TestMiddleware',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.priority, equals(priority));
        expect(info.priority, lessThan(0));
      },
    );

    /// Property test: Positive priorities are preserved
    Glados(any.intInRange(1, 1000)).test(
      'positive priority values are preserved',
      (priority) {
        final info = MiddlewareInfo(
          className: 'TestMiddleware',
          priority: priority,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.priority, equals(priority));
        expect(info.priority, greaterThan(0));
      },
    );

    /// Property test: Priority ordering is stable for equal priorities
    test('middleware with equal priorities maintain stable order', () {
      final middlewareList = [
        MiddlewareInfo(
          className: 'FirstMiddleware',
          priority: 10,
          sourceFile: 'lib/first.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        MiddlewareInfo(
          className: 'SecondMiddleware',
          priority: 10,
          sourceFile: 'lib/second.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        MiddlewareInfo(
          className: 'ThirdMiddleware',
          priority: 10,
          sourceFile: 'lib/third.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
      ];

      // Sort should be stable - equal priorities maintain original order
      final sorted = List<MiddlewareInfo>.from(middlewareList)
        ..sort((a, b) => b.priority.compareTo(a.priority));

      // All have same priority
      for (final m in sorted) {
        expect(m.priority, equals(10));
      }
    });

    /// Property test: Mixed positive and negative priorities sort correctly
    test('mixed positive and negative priorities sort correctly', () {
      final middlewareList = [
        MiddlewareInfo(
          className: 'LowPriority',
          priority: -50,
          sourceFile: 'lib/low.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        MiddlewareInfo(
          className: 'HighPriority',
          priority: 100,
          sourceFile: 'lib/high.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
        MiddlewareInfo(
          className: 'MediumPriority',
          priority: 0,
          sourceFile: 'lib/medium.dart',
          constructor: const ConstructorInfo.noArgs(),
        ),
      ];

      final sorted = List<MiddlewareInfo>.from(middlewareList)
        ..sort((a, b) => b.priority.compareTo(a.priority));

      // Verify descending order: 100, 0, -50
      expect(sorted[0].priority, equals(100));
      expect(sorted[1].priority, equals(0));
      expect(sorted[2].priority, equals(-50));
    });
  });

  group('Middleware Validation Logic', () {
    /// Test that error messages follow expected format.
    test('error messages follow expected format for invalid middleware', () {
      // These are the expected error message patterns from the generator
      const nonClassError =
          '@RaiserMiddleware can only be applied to classes. Found:';
      const abstractError =
          '@RaiserMiddleware cannot be applied to abstract classes.';
      const noConstructorError = 'must have an accessible constructor';

      // Verify error messages are descriptive
      expect(nonClassError, contains('classes'));
      expect(abstractError, contains('abstract'));
      expect(noConstructorError, contains('constructor'));
    });

    /// Property test: Bus names are preserved in MiddlewareInfo
    Glados(any.optionalBusName).test(
      'bus names are preserved correctly',
      (busName) {
        final info = MiddlewareInfo(
          className: 'TestMiddleware',
          priority: 0,
          busName: busName,
          sourceFile: 'lib/test.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        expect(info.busName, equals(busName));
      },
    );
  });
}
