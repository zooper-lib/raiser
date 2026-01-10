/// Raiser - A type-safe domain event library for Dart.
///
/// Provides a clean, async-first event bus for Dart applications
/// following clean architecture principles.
///
/// ## Core Components
///
/// - [RaiserEvent]: Base class for domain events with metadata
/// - [EventHandler]: Interface for type-safe event handlers
/// - [EventBus]: Central dispatcher for publishing and routing events
/// - [Subscription]: Handle for cancelling handler registrations
///
/// ## Error Handling
///
/// - [ErrorStrategy]: Configures how handler exceptions are handled
/// - [AggregateException]: Collects multiple errors when using continueOnError
///
/// ## Example
///
/// ```dart
/// import 'package:raiser/raiser.dart';
///
/// class UserCreated extends RaiserEvent {
///   final String userId;
///   UserCreated(this.userId);
///
///   @override
///   Map<String, dynamic> toMetadataMap() => {
///     ...super.toMetadataMap(),
///     'userId': userId,
///   };
/// }
///
/// void main() async {
///   final bus = EventBus();
///
///   bus.on<UserCreated>((event) async {
///     print('User created: ${event.userId}');
///   });
///
///   await bus.publish(UserCreated('123'));
/// }
/// ```
library;

import 'src/events/raiser_event.dart';
import 'src/handlers/event_handler.dart';
import 'src/handlers/subscription.dart';

// Event bus and error handling
export 'src/bus/error_strategy.dart';
export 'src/bus/event_bus.dart';

// Core event types
export 'src/events/raiser_event.dart';

// Handler interfaces
export 'src/handlers/event_handler.dart';
export 'src/handlers/subscription.dart';
