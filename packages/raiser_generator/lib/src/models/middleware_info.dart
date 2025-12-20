import 'constructor_info.dart';

/// Information about a middleware class for code generation.
class MiddlewareInfo {
  /// The name of the middleware class.
  final String className;

  /// The priority value for middleware registration.
  final int priority;

  /// The optional bus name for named bus registration.
  final String? busName;

  /// The source file path where the middleware is defined.
  final String sourceFile;

  /// Constructor information for dependency injection.
  final ConstructorInfo constructor;

  const MiddlewareInfo({
    required this.className,
    required this.priority,
    this.busName,
    required this.sourceFile,
    required this.constructor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiddlewareInfo &&
          runtimeType == other.runtimeType &&
          className == other.className &&
          priority == other.priority &&
          busName == other.busName &&
          sourceFile == other.sourceFile &&
          constructor == other.constructor;

  @override
  int get hashCode =>
      className.hashCode ^
      priority.hashCode ^
      busName.hashCode ^
      sourceFile.hashCode ^
      constructor.hashCode;

  @override
  String toString() =>
      'MiddlewareInfo(className: $className, priority: $priority, '
      'busName: $busName, sourceFile: $sourceFile, constructor: $constructor)';
}
