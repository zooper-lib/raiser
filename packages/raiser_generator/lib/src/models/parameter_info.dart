/// Information about a constructor parameter for code generation.
class ParameterInfo {
  /// The name of the parameter.
  final String name;

  /// The type of the parameter as a string.
  final String type;

  /// Whether the parameter is required.
  final bool isRequired;

  /// The default value of the parameter, if any.
  final String? defaultValue;

  /// Whether the parameter is named (vs positional).
  final bool isNamed;

  const ParameterInfo({
    required this.name,
    required this.type,
    required this.isRequired,
    this.defaultValue,
    this.isNamed = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParameterInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          isRequired == other.isRequired &&
          defaultValue == other.defaultValue &&
          isNamed == other.isNamed;

  @override
  int get hashCode =>
      name.hashCode ^
      type.hashCode ^
      isRequired.hashCode ^
      defaultValue.hashCode ^
      isNamed.hashCode;

  @override
  String toString() =>
      'ParameterInfo(name: $name, type: $type, isRequired: $isRequired, '
      'defaultValue: $defaultValue, isNamed: $isNamed)';
}
