/// Domain event base class providing consistent metadata for all events.
///
/// This abstract class provides:
/// - Automatic unique ID generation
/// - Automatic timestamp capture
/// - Optional aggregate ID for DDD patterns
/// - Serialization support via metadata maps
library;

/// Abstract base class for domain events with consistent metadata.
///
/// Events are immutable after construction. Each event automatically
/// receives a unique ID and timestamp unless explicitly provided.
///
/// Example:
/// ```dart
/// class UserCreated extends DomainEvent {
///   final String userId;
///   final String email;
///
///   UserCreated({required this.userId, required this.email, super.aggregateId});
///
///   @override
///   Map<String, dynamic> toMetadataMap() => {
///     ...super.toMetadataMap(),
///     'userId': userId,
///     'email': email,
///   };
/// }
/// ```
abstract class DomainEvent {
  /// Unique identifier for this event instance.
  final String id;

  /// Timestamp when the event was created.
  final DateTime timestamp;

  /// Optional aggregate ID for DDD patterns.
  final String? aggregateId;

  /// Counter for generating unique IDs within the same process.
  static int _idCounter = 0;

  /// Creates a new domain event.
  ///
  /// If [id] is not provided, a unique ID is automatically generated.
  /// If [timestamp] is not provided, the current time is used.
  /// [aggregateId] is optional and links the event to a domain aggregate.
  DomainEvent({
    String? id,
    DateTime? timestamp,
    this.aggregateId,
  })  : id = id ?? _generateId(),
        timestamp = timestamp ?? DateTime.now();

  /// Generates a unique ID for an event.
  ///
  /// Uses a combination of timestamp and counter to ensure uniqueness
  /// within the same process without external dependencies.
  static String _generateId() {
    final now = DateTime.now();
    final counter = _idCounter++;
    return '${now.microsecondsSinceEpoch}-$counter';
  }

  /// Converts event metadata to a Map for serialization.
  ///
  /// Subclasses should override this method and include their own
  /// fields in addition to the base metadata:
  /// ```dart
  /// @override
  /// Map<String, dynamic> toMetadataMap() => {
  ///   ...super.toMetadataMap(),
  ///   'myField': myField,
  /// };
  /// ```
  Map<String, dynamic> toMetadataMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'aggregateId': aggregateId,
      };
}
