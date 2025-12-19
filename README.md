# Raiser

A type-safe, async-first domain event library for Dart. Raiser provides a clean event bus implementation following clean architecture principles, perfect for decoupling components in your application.

## Features

- **Type-safe event handling** — Generic handlers ensure compile-time type checking
- **Async-first design** — All handlers are asynchronous by default
- **Priority-based ordering** — Control handler execution order with priorities
- **Flexible error strategies** — Choose how errors are handled during event propagation
- **Subscription management** — Cancel handlers when no longer needed
- **Domain event metadata** — Built-in support for event IDs, timestamps, and aggregate IDs
- **DDD-friendly** — Designed with Domain-Driven Design patterns in mind

## Installation

Add Raiser to your `pubspec.yaml`:

```yaml
dependencies:
  raiser: <latest>
```

## Quick Start

```dart
import 'package:raiser/raiser.dart';

// Define an event
class UserCreated extends DomainEvent {
  final String userId;
  final String email;

  UserCreated({required this.userId, required this.email});
}

void main() async {
  final bus = EventBus();

  // Subscribe to events
  bus.on<UserCreated>((event) async {
    print('Welcome ${event.email}!');
  });

  // Publish events
  await bus.publish(UserCreated(userId: '123', email: 'alice@example.com'));
}
```

## Core Concepts

### Domain Events

All events extend `DomainEvent`, which provides automatic metadata:

| Property | Description |
|----------|-------------|
| `id` | Unique identifier (auto-generated) |
| `timestamp` | Creation time (auto-captured) |
| `aggregateId` | Optional link to a domain aggregate |

Override `toMetadataMap()` to include your event's fields for serialization:

```dart
class OrderPlaced extends DomainEvent {
  final String orderId;
  final double amount;

  OrderPlaced({required this.orderId, required this.amount, super.aggregateId});

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'orderId': orderId,
    'amount': amount,
  };
}
```

### Event Handlers

Register handlers using either function callbacks or class-based handlers.

**Function handlers** — Quick and inline:

```dart
bus.on<UserCreated>((event) async {
  await sendWelcomeEmail(event.email);
});
```

**Class-based handlers** — Better for complex logic and testing:

```dart
class WelcomeEmailHandler implements EventHandler<UserCreated> {
  @override
  Future<void> handle(UserCreated event) async {
    await sendWelcomeEmail(event.email);
  }
}

bus.register<UserCreated>(WelcomeEmailHandler());
```

### Handler Priority

Control execution order with priorities. Higher values execute first:

```dart
bus.on<OrderPlaced>((e) async => print('Runs second'), priority: 0);
bus.on<OrderPlaced>((e) async => print('Runs first'), priority: 10);
bus.on<OrderPlaced>((e) async => print('Runs last'), priority: -5);
```

Handlers with the same priority execute in registration order.

### Subscriptions

Both `on()` and `register()` return a `Subscription` for lifecycle management:

```dart
final subscription = bus.on<UserCreated>((event) async {
  // Handle event
});

// Later, stop receiving events
subscription.cancel();

// Check status
print(subscription.isCancelled); // true
```

## Error Handling

Configure how the EventBus handles exceptions with `ErrorStrategy`:

| Strategy | Behavior |
|----------|----------|
| `stop` | Halt on first error, rethrow immediately (default) |
| `continueOnError` | Run all handlers, throw `AggregateException` with collected errors |
| `swallow` | Run all handlers, errors only go to callback |

```dart
// Stop on first error (default)
final bus = EventBus(errorStrategy: ErrorStrategy.stop);

// Collect all errors
final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);

// Silent failures with logging
final bus = EventBus(
  errorStrategy: ErrorStrategy.swallow,
  onError: (error, stackTrace) => logger.error('Handler failed: $error'),
);
```

### AggregateException

When using `continueOnError`, failed handlers result in an `AggregateException`:

```dart
try {
  await bus.publish(event);
} on AggregateException catch (e) {
  print('${e.errors.length} handlers failed');
  for (final error in e.errors) {
    print('  - $error');
  }
}
```

## Advanced Patterns

### Aggregate IDs for DDD

Link events to domain aggregates for event sourcing patterns:

```dart
await bus.publish(OrderPlaced(
  orderId: 'order-123',
  amount: 99.99,
  aggregateId: 'user-456', // Links to user aggregate
));
```

### Multiple Event Buses

Separate concerns with dedicated buses:

```dart
final domainBus = EventBus(errorStrategy: ErrorStrategy.stop);
final integrationBus = EventBus(errorStrategy: ErrorStrategy.continueOnError);
final notificationBus = EventBus(errorStrategy: ErrorStrategy.swallow);
```

### Event Replay

Rebuild state by replaying stored events through a new bus:

```dart
final replayBus = EventBus();
replayBus.register<OrderPlaced>(orderProjection);

for (final event in storedEvents) {
  await replayBus.publish(event);
}
```

## Examples

See the `/example` folder for complete working examples:

- **raiser_example.dart** — Basic usage, priorities, subscriptions, error handling
- **advanced_example.dart** — Event sourcing, sagas, projections, multi-bus architecture

## License

MIT License - see [LICENSE](LICENSE) for details.
