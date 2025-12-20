import 'parameter_info.dart';

/// Information about a class constructor for code generation.
class ConstructorInfo {
  /// Whether the constructor has any parameters.
  final bool hasParameters;

  /// The list of constructor parameters.
  final List<ParameterInfo> parameters;

  const ConstructorInfo({
    required this.hasParameters,
    required this.parameters,
  });

  /// Creates a ConstructorInfo for a no-arg constructor.
  const ConstructorInfo.noArgs()
      : hasParameters = false,
        parameters = const [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstructorInfo &&
          runtimeType == other.runtimeType &&
          hasParameters == other.hasParameters &&
          _listEquals(parameters, other.parameters);

  static bool _listEquals(List<ParameterInfo> a, List<ParameterInfo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => hasParameters.hashCode ^ parameters.hashCode;

  @override
  String toString() =>
      'ConstructorInfo(hasParameters: $hasParameters, parameters: $parameters)';
}
