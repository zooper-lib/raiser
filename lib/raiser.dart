/// Raiser - A type-safe domain event library for Dart.
///
/// Provides a clean, async-first event bus for Dart applications
/// following clean architecture principles.
library;

// Legacy export (to be removed once new components are ready)
export 'src/raiser_base.dart';

// Core event types
export 'src/events/domain_event.dart';

// Handler interfaces
export 'src/handlers/event_handler.dart';
export 'src/handlers/subscription.dart';

// Event bus
// export 'src/bus/event_bus.dart';
// export 'src/bus/error_strategy.dart';
// export 'src/bus/aggregate_exception.dart';
