/// Abstract interface for type-safe event handlers.
///
/// Implement this interface to create handlers that process specific
/// event types. The generic type parameter [T] ensures compile-time
/// type checking for the event parameter.
///
/// Example:
/// ```dart
/// class UserCreatedHandler implements EventHandler<UserCreated> {
///   @override
///   Future<void> handle(UserCreated event) async {
///     print('User created: ${event.userId}');
///   }
/// }
/// ```
abstract class EventHandler<T> {
  /// Handles an event of type [T] asynchronously.
  ///
  /// This method is invoked by the EventBus when an event of type [T]
  /// is published. The handler should process the event and return
  /// a Future that completes when processing is done.
  ///
  /// Throwing an exception from this method will be handled according
  /// to the EventBus's configured error strategy.
  Future<void> handle(T event);
}
