/// Subscription class for managing handler registrations.
///
/// Represents a handler registration that can be cancelled to stop
/// receiving events.
library;

/// Represents a handler registration that can be cancelled.
///
/// When a handler is registered with the EventBus, a Subscription is
/// returned. Call [cancel] to unregister the handler and stop receiving
/// events.
///
/// Example:
/// ```dart
/// final subscription = eventBus.on<UserCreated>((event) async {
///   print('User created: ${event.userId}');
/// });
///
/// // Later, when you want to stop receiving events:
/// subscription.cancel();
/// ```
class Subscription {
  final void Function() _cancel;
  bool _isCancelled = false;

  /// Creates a new subscription with the given cancel callback.
  ///
  /// The [_cancel] function is called when [cancel] is invoked for
  /// the first time.
  Subscription(this._cancel);

  /// Whether this subscription has been cancelled.
  ///
  /// Returns `true` if [cancel] has been called, `false` otherwise.
  bool get isCancelled => _isCancelled;

  /// Cancels this subscription.
  ///
  /// After cancellation, the associated handler will no longer receive
  /// events. This method is idempotent - calling it multiple times has
  /// no additional effect after the first call.
  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      _cancel();
    }
  }
}
