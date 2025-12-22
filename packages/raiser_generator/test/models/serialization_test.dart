/// Tests for JSON serialization/deserialization of model classes.
///
/// These tests ensure that model objects can be correctly serialized
/// to JSON for the intermediate .raiser.json files and deserialized back.

import 'package:raiser_generator/raiser_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Model JSON Serialization', () {
    group('ParameterInfo', () {
      test('serializes required parameter correctly', () {
        const param = ParameterInfo(
          name: 'logger',
          type: 'Logger',
          isRequired: true,
        );

        final json = param.toJson();

        expect(json['name'], equals('logger'));
        expect(json['type'], equals('Logger'));
        expect(json['isRequired'], isTrue);
        expect(json['defaultValue'], isNull);
        expect(json['isNamed'], isFalse);
      });

      test('serializes optional named parameter correctly', () {
        const param = ParameterInfo(
          name: 'timeout',
          type: 'Duration',
          isRequired: false,
          defaultValue: 'const Duration(seconds: 30)',
          isNamed: true,
        );

        final json = param.toJson();

        expect(json['name'], equals('timeout'));
        expect(json['type'], equals('Duration'));
        expect(json['isRequired'], isFalse);
        expect(json['defaultValue'], equals('const Duration(seconds: 30)'));
        expect(json['isNamed'], isTrue);
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'name': 'service',
          'type': 'MyService',
          'isRequired': true,
          'defaultValue': null,
          'isNamed': false,
        };

        final param = ParameterInfo.fromJson(json);

        expect(param.name, equals('service'));
        expect(param.type, equals('MyService'));
        expect(param.isRequired, isTrue);
        expect(param.defaultValue, isNull);
        expect(param.isNamed, isFalse);
      });

      test('roundtrip serialization preserves all fields', () {
        const original = ParameterInfo(
          name: 'config',
          type: 'Configuration',
          isRequired: false,
          defaultValue: 'Configuration.defaults()',
          isNamed: true,
        );

        final json = original.toJson();
        final restored = ParameterInfo.fromJson(json);

        expect(restored, equals(original));
      });

      test('handles missing isNamed field (backward compatibility)', () {
        final json = {
          'name': 'param',
          'type': 'String',
          'isRequired': true,
          'defaultValue': null,
          // isNamed is missing
        };

        final param = ParameterInfo.fromJson(json);

        expect(param.isNamed, isFalse); // Should default to false
      });
    });

    group('ConstructorInfo', () {
      test('serializes no-args constructor correctly', () {
        const ctor = ConstructorInfo.noArgs();

        final json = ctor.toJson();

        expect(json['hasParameters'], isFalse);
        expect(json['parameters'], isEmpty);
      });

      test('serializes constructor with parameters correctly', () {
        final ctor = ConstructorInfo(
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
              isNamed: true,
            ),
          ],
        );

        final json = ctor.toJson();

        expect(json['hasParameters'], isTrue);
        expect(json['parameters'], hasLength(2));
        expect(json['parameters'][0]['name'], equals('logger'));
        expect(json['parameters'][1]['name'], equals('config'));
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'hasParameters': true,
          'parameters': [
            {
              'name': 'service',
              'type': 'Service',
              'isRequired': true,
              'defaultValue': null,
              'isNamed': false,
            },
          ],
        };

        final ctor = ConstructorInfo.fromJson(json);

        expect(ctor.hasParameters, isTrue);
        expect(ctor.parameters, hasLength(1));
        expect(ctor.parameters[0].name, equals('service'));
      });

      test('roundtrip serialization preserves all fields', () {
        final original = ConstructorInfo(
          hasParameters: true,
          parameters: [
            const ParameterInfo(
              name: 'dep1',
              type: 'Dep1',
              isRequired: true,
            ),
            const ParameterInfo(
              name: 'dep2',
              type: 'Dep2',
              isRequired: false,
              defaultValue: 'Dep2()',
              isNamed: true,
            ),
          ],
        );

        final json = original.toJson();
        final restored = ConstructorInfo.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('HandlerInfo', () {
      test('serializes basic handler correctly', () {
        final handler = HandlerInfo(
          className: 'UserCreatedHandler',
          eventType: 'UserCreatedEvent',
          priority: 0,
          busName: null,
          sourceFile: 'lib/handlers/user_handler.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final json = handler.toJson();

        expect(json['className'], equals('UserCreatedHandler'));
        expect(json['eventType'], equals('UserCreatedEvent'));
        expect(json['priority'], equals(0));
        expect(json['busName'], isNull);
        expect(json['sourceFile'], equals('lib/handlers/user_handler.dart'));
        expect(json['constructor']['hasParameters'], isFalse);
      });

      test('serializes handler with all options correctly', () {
        final handler = HandlerInfo(
          className: 'PaymentHandler',
          eventType: 'PaymentEvent',
          priority: 100,
          busName: 'payments',
          sourceFile: 'lib/handlers/payment_handler.dart',
          constructor: ConstructorInfo(
            hasParameters: true,
            parameters: [
              const ParameterInfo(
                name: 'paymentService',
                type: 'PaymentService',
                isRequired: true,
              ),
            ],
          ),
        );

        final json = handler.toJson();

        expect(json['className'], equals('PaymentHandler'));
        expect(json['priority'], equals(100));
        expect(json['busName'], equals('payments'));
        expect(json['constructor']['hasParameters'], isTrue);
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'className': 'TestHandler',
          'eventType': 'TestEvent',
          'priority': 50,
          'busName': 'test',
          'sourceFile': 'lib/handlers.dart',
          'constructor': {
            'hasParameters': false,
            'parameters': [],
          },
        };

        final handler = HandlerInfo.fromJson(json);

        expect(handler.className, equals('TestHandler'));
        expect(handler.eventType, equals('TestEvent'));
        expect(handler.priority, equals(50));
        expect(handler.busName, equals('test'));
        expect(handler.sourceFile, equals('lib/handlers.dart'));
        expect(handler.constructor.hasParameters, isFalse);
      });

      test('roundtrip serialization preserves all fields', () {
        final original = HandlerInfo(
          className: 'OrderHandler',
          eventType: 'OrderEvent',
          priority: -10,
          busName: 'orders',
          sourceFile: 'lib/handlers/order.dart',
          constructor: ConstructorInfo(
            hasParameters: true,
            parameters: [
              const ParameterInfo(
                name: 'repo',
                type: 'OrderRepository',
                isRequired: true,
              ),
            ],
          ),
        );

        final json = original.toJson();
        final restored = HandlerInfo.fromJson(json);

        expect(restored, equals(original));
      });

      test('handles null busName correctly', () {
        final handler = HandlerInfo(
          className: 'Handler',
          eventType: 'Event',
          priority: 0,
          busName: null,
          sourceFile: 'lib/handlers.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final json = handler.toJson();
        final restored = HandlerInfo.fromJson(json);

        expect(restored.busName, isNull);
      });

      test('handles negative priority correctly', () {
        final handler = HandlerInfo(
          className: 'LowPriorityHandler',
          eventType: 'Event',
          priority: -100,
          busName: null,
          sourceFile: 'lib/handlers.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final json = handler.toJson();
        final restored = HandlerInfo.fromJson(json);

        expect(restored.priority, equals(-100));
      });
    });

    group('MiddlewareInfo', () {
      test('serializes basic middleware correctly', () {
        final middleware = MiddlewareInfo(
          className: 'LoggingMiddleware',
          priority: 0,
          busName: null,
          sourceFile: 'lib/middleware/logging.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final json = middleware.toJson();

        expect(json['className'], equals('LoggingMiddleware'));
        expect(json['priority'], equals(0));
        expect(json['busName'], isNull);
        expect(json['sourceFile'], equals('lib/middleware/logging.dart'));
        expect(json['constructor']['hasParameters'], isFalse);
      });

      test('serializes middleware with all options correctly', () {
        final middleware = MiddlewareInfo(
          className: 'AuthMiddleware',
          priority: 100,
          busName: 'secure',
          sourceFile: 'lib/middleware/auth.dart',
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
        );

        final json = middleware.toJson();

        expect(json['className'], equals('AuthMiddleware'));
        expect(json['priority'], equals(100));
        expect(json['busName'], equals('secure'));
        expect(json['constructor']['hasParameters'], isTrue);
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'className': 'TestMiddleware',
          'priority': 75,
          'busName': null,
          'sourceFile': 'lib/middleware.dart',
          'constructor': {
            'hasParameters': false,
            'parameters': [],
          },
        };

        final middleware = MiddlewareInfo.fromJson(json);

        expect(middleware.className, equals('TestMiddleware'));
        expect(middleware.priority, equals(75));
        expect(middleware.busName, isNull);
        expect(middleware.sourceFile, equals('lib/middleware.dart'));
        expect(middleware.constructor.hasParameters, isFalse);
      });

      test('roundtrip serialization preserves all fields', () {
        final original = MiddlewareInfo(
          className: 'CachingMiddleware',
          priority: 50,
          busName: 'cache',
          sourceFile: 'lib/middleware/caching.dart',
          constructor: ConstructorInfo(
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
                defaultValue: 'Duration(minutes: 5)',
                isNamed: true,
              ),
            ],
          ),
        );

        final json = original.toJson();
        final restored = MiddlewareInfo.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('Complex Scenarios', () {
      test('handles deeply nested parameters', () {
        final handler = HandlerInfo(
          className: 'ComplexHandler',
          eventType: 'ComplexEvent',
          priority: 0,
          sourceFile: 'lib/handlers.dart',
          constructor: ConstructorInfo(
            hasParameters: true,
            parameters: [
              const ParameterInfo(
                name: 'map',
                type: 'Map<String, List<int>>',
                isRequired: true,
              ),
              const ParameterInfo(
                name: 'callback',
                type: 'void Function(String, int)',
                isRequired: false,
                isNamed: true,
              ),
            ],
          ),
        );

        final json = handler.toJson();
        final restored = HandlerInfo.fromJson(json);

        expect(restored.constructor.parameters[0].type, equals('Map<String, List<int>>'));
        expect(restored.constructor.parameters[1].type, equals('void Function(String, int)'));
      });

      test('handles empty string values', () {
        final handler = HandlerInfo(
          className: 'Handler',
          eventType: 'Event',
          priority: 0,
          busName: '', // Empty string, not null
          sourceFile: 'lib/handlers.dart',
          constructor: const ConstructorInfo.noArgs(),
        );

        final json = handler.toJson();
        final restored = HandlerInfo.fromJson(json);

        expect(restored.busName, equals(''));
      });

      test('handles special characters in names', () {
        final param = ParameterInfo(
          name: 'value_with_underscore',
          type: 'Type\$WithDollar',
          isRequired: true,
        );

        final json = param.toJson();
        final restored = ParameterInfo.fromJson(json);

        expect(restored.name, equals('value_with_underscore'));
        expect(restored.type, equals('Type\$WithDollar'));
      });

      test('handles very long default values', () {
        final longDefault = 'SomeClass.veryLongMethodName(parameter1: "value1", parameter2: 42, parameter3: true, parameter4: [1, 2, 3, 4, 5])';
        
        final param = ParameterInfo(
          name: 'config',
          type: 'Config',
          isRequired: false,
          defaultValue: longDefault,
          isNamed: true,
        );

        final json = param.toJson();
        final restored = ParameterInfo.fromJson(json);

        expect(restored.defaultValue, equals(longDefault));
      });
    });
  });
}
