# Raiser

<p align="center">
  <img src="icon.png" alt="Raiser Logo" width="200"/>
</p>

A type-safe, async-first domain event library for Dart. Raiser provides a clean event bus implementation following clean architecture principles, perfect for decoupling components in your application.

## Features

- **Type-safe event handling** — Generic handlers ensure compile-time type checking
- **Async-first design** — All handlers are asynchronous by default
- **Priority-based ordering** — Control handler execution order with priorities
- **Middleware support** — Wrap handler execution with cross-cutting concerns
- **Flexible error strategies** — Choose how errors are handled during event propagation
- **Subscription management** — Cancel handlers when no longer needed
- **Domain event metadata** — Built-in support for event IDs, timestamps, and aggregate IDs
- **DDD-friendly** — Designed with Domain-Driven Design patterns in mind

## Installation

```yaml
dependencies:
  raiser: ^3.0.0
```

## Quick Start

**EventBus works with ANY type** - you don't need to use `RaiserEvent` at all:

```dart
import 'package:raiser/raiser.dart';

// Define an event - just a simple class!
final class UserCreated {
  UserCreated({
    required this.userId,
    required this.email,
  });

  final String userId;
  final String email;
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

## RaiserEvent (Optional)

**You don't have to use `RaiserEvent`!** The `EventBus` is fully generic and works with any type.

However, if you want standardized domain event metadata, you can optionally implement `RaiserEvent`, which is an interface extending `ZooperDomainEvent` from [zooper_flutter_core](https://pub.dev/packages/zooper_flutter_core). This provides:

| Property | Type | Description |
|----------|------|-------------|
| `id` | `EventId` | Unique identifier (ULID-based) |
| `occurredOn` | `DateTime` | When the event occurred |
| `metadata` | `Map<String, Object?>` | Additional event context |

`RaiserEvent` is intentionally an **interface** (not a base class) to avoid forcing single inheritance. If you choose to use it, implement it explicitly:

```dart
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

final class OrderPlaced implements RaiserEvent {
  OrderPlaced({
    required this.orderId,
    required this.amount,
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final String orderId;
  final double amount;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}
```

### Aggregate IDs

Store aggregate identifiers in the `metadata` map:

```dart
final event = OrderPlaced(
  orderId: 'order-123',
  amount: 99.99,
  metadata: {'aggregateId': 'user-456'},
);

// Access via metadata
final aggregateId = event.metadata['aggregateId'] as String?;
```

## Event Handlers

### Function Handlers

Quick inline handlers:

```dart
bus.on<UserCreated>((event) async {
  await sendWelcomeEmail(event.email);
});
```

### Class-Based Handlers

Better for complex logic and testing:

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

Higher values execute first:

```dart
bus.on<OrderPlaced>((e) async => print('Second'), priority: 0);
bus.on<OrderPlaced>((e) async => print('First'), priority: 10);
bus.on<OrderPlaced>((e) async => print('Last'), priority: -5);
```

## Middleware

Wrap handler execution with cross-cutting concerns like logging, timing, or validation:

```dart
// Add middleware that wraps all handler execution
bus.addMiddleware((Object event, Future<void> Function() next) async {
  print('Before: ${event.runtimeType}');
  await next();
  print('After: ${event.runtimeType}');
}, priority: 100);

// Middleware with higher priority wraps those with lower priority
bus.addMiddleware((Object event, Future<void> Function() next) async {
  final stopwatch = Stopwatch()..start();
  await next();
  print('Took ${stopwatch.elapsedMilliseconds}ms');
}, priority: 50);
```

## Subscriptions

Both `on()`, `register()`, and `addMiddleware()` return a `Subscription`:

```dart
final subscription = bus.on<UserCreated>((event) async {
  // Handle event
});

// Stop receiving events
subscription.cancel();

// Check status
print(subscription.isCancelled); // true
```

## Error Handling

Configure error behavior with `ErrorStrategy`:

| Strategy | Behavior |
|----------|----------|
| `stop` | Halt on first error, rethrow immediately (default) |
| `continueOnError` | Run all handlers, throw `AggregateException` |
| `swallow` | Run all handlers, errors only go to callback |

```dart
// Stop on first error (default)
final bus = EventBus(errorStrategy: ErrorStrategy.stop);

// Collect all errors
final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);

// Silent failures with logging
final bus = EventBus(
  errorStrategy: ErrorStrategy.swallow,
  onError: (error, stackTrace) => logger.error('Failed: $error'),
);
```

### AggregateException

When using `continueOnError`:

```dart
try {
  await bus.publish(event);
} on AggregateException catch (e) {
  print('${e.errors.length} handlers failed');
}
```

## Code Generation

For automatic handler discovery and registration, use the companion packages:

```yaml
dependencies:
  raiser: ^3.0.0
  raiser_annotation: ^3.0.0

dev_dependencies:
  build_runner: ^2.4.0
  raiser_generator: ^3.0.0
```

See [raiser_generator](https://pub.dev/packages/raiser_generator) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.
