import '../handlers/event_handler.dart';
import '../handlers/subscription.dart';
import 'error_strategy.dart';

export 'error_strategy.dart';

/// Callback type for error handling.
typedef ErrorCallback = void Function(Object error, StackTrace stackTrace);

/// Middleware function signature.
///
/// Middleware receives the event and a `next` function to call the next
/// middleware or handler in the pipeline.
typedef Middleware = Future<void> Function(dynamic event, Future<void> Function() next);

/// Internal class for storing handler registrations with metadata.
///
/// Stores handlers in a type-erased manner to enable inheritance-aware
/// type matching. The [canHandle] predicate checks if an event is assignable
/// to the handler's expected type, and [invoke] wraps the typed handler
/// to allow invocation with a dynamic event.
class _HandlerEntry {
  /// Type-erased handler invocation.
  ///
  /// Wraps the original typed handler and performs the cast internally.
  /// This is safe because [canHandle] guarantees type compatibility.
  final Future<void> Function(dynamic) invoke;

  /// Priority for ordering (higher = earlier execution).
  final int priority;

  /// Registration order for stable sorting within same priority.
  final int registrationOrder;

  /// Type predicate to check if an event is assignable to this handler's type.
  ///
  /// Uses runtime type checking to support inheritance and sealed class
  /// hierarchies. This allows a handler registered for `BaseEvent` to receive
  /// events of type `SubclassEvent`.
  final bool Function(dynamic) canHandle;

  _HandlerEntry(this.invoke, this.priority, this.registrationOrder, this.canHandle);
}

/// Internal class for storing middleware registrations with metadata.
class _MiddlewareEntry {
  /// The middleware function to invoke.
  final Middleware middleware;

  /// Priority for ordering (higher = earlier/outer execution).
  final int priority;

  /// Registration order for stable sorting within same priority.
  final int registrationOrder;

  _MiddlewareEntry(this.middleware, this.priority, this.registrationOrder);
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

  /// Counter for assigning registration order to middleware.
  int _middlewareCounter = 0;

  /// Flat list of all registered handler entries.
  ///
  /// We use a flat list instead of a type-keyed map to support
  /// inheritance-aware type matching. Each entry contains a type predicate
  /// that checks if an event is assignable to the handler's expected type.
  final List<_HandlerEntry> _handlers = [];

  /// Middleware pipeline.
  final List<_MiddlewareEntry> _middleware = [];

  /// The error handling strategy for this bus.
  final ErrorStrategy errorStrategy;

  /// Optional callback invoked when a handler throws an error.
  final ErrorCallback? onError;

  /// Creates a new EventBus instance.
  ///
  /// [errorStrategy] configures how handler exceptions are handled.
  /// Defaults to [ErrorStrategy.stop].
  ///
  /// [onError] is an optional callback invoked for each handler error,
  /// regardless of the error strategy.
  EventBus({this.errorStrategy = ErrorStrategy.stop, this.onError});

  /// Adds a middleware to the pipeline with optional priority.
  ///
  /// Middleware wraps the handler execution and can perform pre/post
  /// processing, short-circuit the pipeline, or transform events.
  ///
  /// Higher priority middleware executes first (outer layer).
  ///
  /// Returns a [Subscription] that can be used to remove the middleware.
  Subscription addMiddleware(dynamic middleware, {int priority = 0}) {
    Middleware middlewareFunc;

    // Support both function middleware and class-based middleware with call()
    if (middleware is Middleware) {
      middlewareFunc = middleware;
    } else {
      // Assume it's a class with a call method
      middlewareFunc = (event, next) async {
        await (middleware as dynamic).call(event, next);
      };
    }

    final entry = _MiddlewareEntry(middlewareFunc, priority, _middlewareCounter++);
    _middleware.add(entry);

    return Subscription(() {
      _middleware.remove(entry);
    });
  }

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
  Subscription on<T>(Future<void> Function(T event) handler, {int priority = 0}) {
    return _addHandler<T>(handler, priority);
  }

  /// Internal method to add a handler to the registry.
  ///
  /// Creates a handler entry with a type predicate that uses runtime type
  /// checking to support inheritance hierarchies (e.g., sealed classes with
  /// multiple subclasses). The handler is wrapped in a type-erased invocation
  /// function that performs the cast internally.
  Subscription _addHandler<T>(Future<void> Function(T) handler, int priority) {
    // Create a type predicate that checks if an event is assignable to T.
    // This enables inheritance-aware matching where a handler for BaseEvent
    // will receive events of SubclassEvent.
    bool canHandle(dynamic event) => event is T;

    // Wrap the typed handler in a type-erased function that performs the cast.
    // This is safe because canHandle guarantees the event is of type T.
    Future<void> invoke(dynamic event) => handler(event as T);

    final entry = _HandlerEntry(invoke, priority, _registrationCounter++, canHandle);
    _handlers.add(entry);

    return Subscription(() {
      _handlers.remove(entry);
    });
  }

  /// Publishes an event to all registered handlers.
  ///
  /// Routes the event to handlers registered for type [T] and awaits
  /// all handler completions before returning.
  ///
  /// If middleware is registered, the event passes through the middleware
  /// pipeline before reaching handlers.
  ///
  /// If no handlers are registered for the event type, completes
  /// without error.
  ///
  /// Error handling behavior depends on [errorStrategy]:
  /// - [ErrorStrategy.stop]: Halts on first error and rethrows
  /// - [ErrorStrategy.continueOnError]: Invokes all handlers, throws [AggregateException]
  /// - [ErrorStrategy.swallow]: Invokes all handlers, errors only go to callback
  Future<void> publish<T>(T event) async {
    // If we have middleware, wrap the handler execution
    if (_middleware.isNotEmpty) {
      await _executeWithMiddleware(event);
    } else {
      await _executeHandlers(event);
    }
  }

  /// Executes the event through the middleware pipeline.
  Future<void> _executeWithMiddleware<T>(T event) async {
    // Sort middleware by priority (descending) then by registration order
    final sortedMiddleware = List<_MiddlewareEntry>.from(_middleware)
      ..sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.registrationOrder.compareTo(b.registrationOrder);
      });

    // Build the middleware chain from innermost to outermost
    Future<void> Function() chain = () => _executeHandlers(event);

    for (final entry in sortedMiddleware.reversed) {
      final next = chain;
      chain = () => entry.middleware(event, next);
    }

    // Execute the chain
    await chain();
  }

  /// Executes handlers for the given event.
  ///
  /// Uses inheritance-aware type matching to find all handlers that can
  /// process the event. This supports sealed class hierarchies where a
  /// handler registered for a base class receives subclass events.
  Future<void> _executeHandlers<T>(T event) async {
    // Find all handlers whose type predicate matches the event.
    // This enables inheritance: a handler for BaseEvent will match SubclassEvent.
    final matchingEntries = _handlers.where((entry) => entry.canHandle(event)).toList();

    if (matchingEntries.isEmpty) {
      return;
    }

    // Sort by priority (descending) then by registration order (ascending)
    matchingEntries.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.registrationOrder.compareTo(b.registrationOrder);
    });

    final errors = <Object>[];
    final stackTraces = <StackTrace>[];

    for (final entry in matchingEntries) {
      try {
        // The canHandle predicate guarantees the event is assignable to the
        // handler's type, so the internal cast in invoke is safe.
        await entry.invoke(event);
      } catch (error, stackTrace) {
        // Always invoke the error callback if configured
        onError?.call(error, stackTrace);

        switch (errorStrategy) {
          case ErrorStrategy.stop:
            // Halt propagation and rethrow immediately
            rethrow;
          case ErrorStrategy.continueOnError:
            // Collect errors and continue
            errors.add(error);
            stackTraces.add(stackTrace);
          case ErrorStrategy.swallow:
            // Continue silently (callback already invoked above)
            break;
        }
      }
    }

    // After all handlers complete, throw aggregate if errors were collected
    if (errorStrategy == ErrorStrategy.continueOnError && errors.isNotEmpty) {
      throw AggregateException(errors, stackTraces);
    }
  }
}
