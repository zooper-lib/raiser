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
  raiser: ^1.0.0
```

## Quick Start

```dart
import 'package:raiser/raiser.dart';

// Define an event
class UserCreated extends DomainEvent {
  final String userId;
  final String email;

  UserCreated({required this.userId, required this.email});

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'userId': userId,
    'email': email,
  };
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

## Domain Events

All events extend `DomainEvent`, which provides automatic metadata:

| Property | Description |
|----------|-------------|
| `id` | Unique identifier (auto-generated) |
| `timestamp` | Creation time (auto-captured) |
| `aggregateId` | Optional link to a domain aggregate |

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
bus.addMiddleware((event, next) async {
  print('Before: ${event.runtimeType}');
  await next();
  print('After: ${event.runtimeType}');
}, priority: 100);

// Middleware with higher priority wraps those with lower priority
bus.addMiddleware((event, next) async {
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
  raiser: ^1.0.0
  raiser_annotation: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.0
  raiser_generator: ^1.0.0
```

See [raiser_generator](https://pub.dev/packages/raiser_generator) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.
