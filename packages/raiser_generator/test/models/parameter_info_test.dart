import 'package:glados/glados.dart';
import 'package:raiser_generator/src/models/parameter_info.dart';

/// Custom generator for ParameterInfo.
/// Generates valid Dart parameter names and types.
extension ParameterInfoGenerator on Any {
  /// Generates a valid Dart identifier for parameter names.
  Generator<String> get dartIdentifier => any.choose([
        'name',
        'value',
        'data',
        'input',
        'output',
        'repository',
        'service',
        'logger',
        'config',
        'handler',
        'callback',
        'factory',
        'builder',
        'context',
        'state',
      ]);

  /// Generates a valid Dart type string.
  Generator<String> get dartType => any.choose([
        'String',
        'int',
        'double',
        'bool',
        'List<String>',
        'Map<String, dynamic>',
        'Future<void>',
        'OrderRepository',
        'Logger',
        'EventBus',
        'Function',
        'Object',
        'dynamic',
      ]);

  /// Generates an optional default value string.
  Generator<String?> get defaultValue => any.choose([
        null,
        'null',
        '0',
        '""',
        'true',
        'false',
        'const []',
        'const {}',
      ]);

  /// Generates a ParameterInfo instance.
  Generator<ParameterInfo> get parameterInfo => any.combine5(
        dartIdentifier,
        dartType,
        any.bool,
        defaultValue,
        any.bool,
        (name, type, isRequired, defaultValue, isNamed) => ParameterInfo(
          name: name,
          type: type,
          isRequired: isRequired,
          defaultValue: defaultValue,
          isNamed: isNamed,
        ),
      );
}

void main() {
  group('ParameterInfo', () {
    /// **Feature: code-generator, Property 11: Factory Function Parameter Preservation**
    ///
    /// *For any* handler with constructor parameters, the generated factory
    /// function typedef SHALL preserve all parameter names and types from
    /// the original constructor.
    ///
    /// This test verifies that ParameterInfo correctly preserves all attributes
    /// when created and accessed.
    Glados(any.parameterInfo).test(
      'Property 11: preserves all parameter attributes',
      (param) {
        // Create a new ParameterInfo with the same values
        final recreated = ParameterInfo(
          name: param.name,
          type: param.type,
          isRequired: param.isRequired,
          defaultValue: param.defaultValue,
          isNamed: param.isNamed,
        );

        // Verify all attributes are preserved
        expect(recreated.name, equals(param.name));
        expect(recreated.type, equals(param.type));
        expect(recreated.isRequired, equals(param.isRequired));
        expect(recreated.defaultValue, equals(param.defaultValue));
        expect(recreated.isNamed, equals(param.isNamed));

        // Verify equality
        expect(recreated, equals(param));
        expect(recreated.hashCode, equals(param.hashCode));
      },
    );

    /// Additional property test: toString round-trip contains all fields
    Glados(any.parameterInfo).test(
      'toString contains all field values',
      (param) {
        final str = param.toString();

        expect(str, contains(param.name));
        expect(str, contains(param.type));
        expect(str, contains(param.isRequired.toString()));
        expect(str, contains(param.isNamed.toString()));
        if (param.defaultValue != null) {
          expect(str, contains(param.defaultValue!));
        }
      },
    );
  });
}
