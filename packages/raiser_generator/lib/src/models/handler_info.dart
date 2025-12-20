import 'constructor_info.dart';

/// Information about a handler class for code generation.
class HandlerInfo {
  /// The name of the handler class.
  final String className;

  /// The event type this handler processes.
  final String eventType;

  /// The priority value for handler registration.
  final int priority;

  /// The optional bus name for named bus registration.
  final String? busName;

  /// The source file path where the handler is defined.
  final String sourceFile;

  /// Constructor information for dependency injection.
  final ConstructorInfo constructor;

  const HandlerInfo({
    required this.className,
    required this.eventType,
    required this.priority,
    this.busName,
    required this.sourceFile,
    required this.constructor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HandlerInfo &&
          runtimeType == other.runtimeType &&
          className == other.className &&
          eventType == other.eventType &&
          priority == other.priority &&
          busName == other.busName &&
          sourceFile == other.sourceFile &&
          constructor == other.constructor;

  @override
  int get hashCode =>
      className.hashCode ^
      eventType.hashCode ^
      priority.hashCode ^
      busName.hashCode ^
      sourceFile.hashCode ^
      constructor.hashCode;

  @override
  String toString() =>
      'HandlerInfo(className: $className, eventType: $eventType, '
      'priority: $priority, busName: $busName, sourceFile: $sourceFile, '
      'constructor: $constructor)';
}
