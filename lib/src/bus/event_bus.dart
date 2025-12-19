/// EventBus - Central dispatcher for publishing events and managing handlers.
///
/// Provides type-safe event routing with support for:
/// - Class-based and function-based handlers
/// - Priority-based handler ordering
/// - Configurable error handling strategies
library;

import '../handlers/event_handler.dart';
import '../handlers/subscription.dart';

/// Callback type for error handling.
typedef ErrorCallback = void Function(Object error, StackTrace stackTrace);

/// Internal class for storing handler registrations with metadata.
class _HandlerEntry<T> {
  /// The handler function to invoke.
  final Future<void> Function(T) handler;

  /// Priority for ordering (higher = earlier execution).
  final int priority;

  /// Registration order for stable sorting within same priority.
  final int registrationOrder;

  _HandlerEntry(this.handler, this.priority, this.registrationOrder);
}

/// Central dispatcher for publishing events and managing handlers.
///
/// The EventBus routes published events to their registered handlers
/// based on runtime type matching. Handlers can be registered using
/// either class-based [EventHandler] instances or function callbacks.
///
/// Example:
/// ```dart
/// final bus = EventBus();
///
/// // Register a function handler
/// bus.on<UserCreated>((event) async {
///   print('User created: ${event.userId}');
/// });
///
/// // Publish an event
/// await bus.publish(UserCreated(userId: '123'));
/// ```
class EventBus {
  /// Counter for assigning registration order to handlers.
  int _registrationCounter = 0;

  /// Type-based handler storage.
  /// Maps runtime types to lists of handler entries.
  final Map<Type, List<_HandlerEntry<dynamic>>> _handlers = {};

  /// Creates a new EventBus instance.
  EventBus();

  /// Registers a class-based handler with optional priority.
  ///
  /// The handler's [handle] method will be invoked when events of type [T]
  /// are published. Higher priority handlers execute first.
  ///
  /// Returns a [Subscription] that can be used to cancel the registration.
  Subscription register<T>(EventHandler<T> handler, {int priority = 0}) {
    return _addHandler<T>(handler.handle, priority);
  }

  /// Registers a function handler with optional priority.
  ///
  /// The function will be invoked when events of type [T] are published.
  /// Higher priority handlers execute first.
  ///
  /// Returns a [Subscription] that can be used to cancel the registration.
  Subscription on<T>(Future<void> Function(T event) handler,
      {int priority = 0}) {
    return _addHandler<T>(handler, priority);
  }

  /// Internal method to add a handler to the registry.
  Subscription _addHandler<T>(
      Future<void> Function(T) handler, int priority) {
    final entry = _HandlerEntry<T>(handler, priority, _registrationCounter++);

    _handlers.putIfAbsent(T, () => []);
    _handlers[T]!.add(entry);

    return Subscription(() {
      _handlers[T]?.remove(entry);
    });
  }

  /// Publishes an event to all registered handlers.
  ///
  /// Routes the event to handlers registered for type [T] and awaits
  /// all handler completions before returning.
  ///
  /// If no handlers are registered for the event type, completes
  /// without error.
  Future<void> publish<T>(T event) async {
    final entries = _handlers[T];
    if (entries == null || entries.isEmpty) {
      return;
    }

    // Sort by priority (descending) then by registration order (ascending)
    final sortedEntries = List<_HandlerEntry<dynamic>>.from(entries)
      ..sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.registrationOrder.compareTo(b.registrationOrder);
      });

    for (final entry in sortedEntries) {
      await (entry as _HandlerEntry<T>).handler(event);
    }
  }
}
