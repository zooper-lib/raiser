# Raiser - Domain Event Library for Dart

A type-safe domain event library designed for clean architecture in Dart applications.

## Vision

Raiser aims to be the go-to domain event solution for Dart/Flutter projects that follow clean architecture principles. It provides a robust, type-safe event system with flexibility for both simple and complex use cases.

## Core Features

### 1. Type-Safe Event Base Class

- Generic `DomainEvent` base class
- Built-in metadata: timestamp, event ID, aggregate ID (optional)
- Immutable by design

### 2. Type-Safe Event Handlers

- Generic `EventHandler<T extends DomainEvent>` interface
- Compile-time type checking — handlers only receive their specific event type
- Async-first design (`Future<void> handle()`)

### 3. Event Bus / Dispatcher

- Central mechanism to publish events and route to registered handlers
- Supports both sync and async event publishing
- Clean registration/unregistration API

### 4. Flexible Instance Management

#### Instance-First Design
- `EventBus` works as a standalone instance with no static dependencies
- Fully compatible with dependency injection
- Multiple independent buses can coexist

#### Optional Singleton Registry
- `Raiser` static class provides optional convenience layer
- Default bus accessor: `Raiser.instance`
- Named buses for bounded contexts: `Raiser.register('orders', bus)`
- Not required — purely opt-in convenience
- `Raiser.reset()` for test isolation

### 5. Hierarchical / Scoped Event Buses

- Parent-child relationships via constructor: `EventBus(parent: rootBus)`
- Configurable bubble strategies:
  - `none` — events stay local
  - `afterLocal` — local handlers first, then bubble to parent
  - `beforeLocal` — parent handles first, then local
- Enables bounded context isolation with optional cross-context communication

### 6. Middleware Pipeline

- Pre/post processing hooks for cross-cutting concerns
- Use cases: logging, metrics, validation, transaction boundaries
- Middleware can short-circuit or transform events

### 7. Handler Priority

- Priority-based execution order for handlers
- Deterministic ordering when multiple handlers subscribe to same event

### 8. Event Filtering

- Predicate-based filtering before handler invocation
- Handlers can declare conditions for when they should be triggered

### 9. Error Handling Strategies

- Configurable behavior when handlers throw:
  - `stop` — halt propagation on first error
  - `continueOnError` — execute all handlers, collect errors
  - `swallow` — log and continue silently
- Error callbacks for centralized error handling

### 10. Handler Lifecycle Hooks

- `onSubscribe` / `onUnsubscribe` callbacks
- Resource management for handlers that hold state

## Differentiators from Existing Libraries

| Aspect | Typical Libraries | Raiser |
|--------|------------------|--------|
| Type safety | Often use dynamic/Object | Full generic type safety |
| Singleton | Forced global singleton | Instance-first, opt-in registry |
| Scoping | Global only | Hierarchical with bubbling |
| Middleware | Uncommon | First-class pipeline support |
| Handler priority | Rarely supported | Built-in priority ordering |
| Error handling | Swallowed or throws | Configurable strategies |
| Testability | Afterthought | Built-in test utilities |
| Dependencies | Often has deps | Zero dependencies, pure Dart |

## Package Structure

```
raiser/                    # Core library (this repo)
├── lib/
│   ├── raiser.dart        # Public API exports
│   └── src/
│       ├── events/        # DomainEvent base, metadata
│       ├── handlers/      # EventHandler interface
│       ├── bus/           # EventBus implementation
│       ├── middleware/    # Middleware pipeline
│       ├── registry/      # Raiser static registry
│       └── testing/       # Test utilities

raiser_annotation/         # Shared annotations (lightweight)
├── @RaiserHandler()
├── @RaiserMiddleware()

raiser_generator/          # Code generation (build_runner)
├── Auto-discovers annotated handlers
├── Generates registration code
```

## Code Generation (Optional)

### Annotations

```dart
@RaiserHandler()
class OrderCreatedHandler extends EventHandler<OrderCreatedEvent> {
  @override
  Future<void> handle(OrderCreatedEvent event) async {
    // handle logic
  }
}
```

### Generated Output

```dart
// raiser.g.dart
void initRaiser(EventBus bus) {
  bus.register(OrderCreatedHandler());
  bus.register(PaymentProcessedHandler());
  // ... all discovered handlers
}
```

### Benefits
- Zero boilerplate registration
- Compile-time discovery of all handlers
- Still supports manual registration for flexibility

## Usage Patterns

### Pattern A: Simple Singleton

```dart
void main() {
  Raiser.setDefault(EventBus());
  Raiser.instance.publish(MyEvent());
}
```

### Pattern B: Dependency Injection

```dart
class OrderService {
  final EventBus _bus;
  OrderService(this._bus);
  
  void createOrder() => _bus.publish(OrderCreated());
}
```

### Pattern C: Multiple Bounded Contexts

```dart
void main() {
  Raiser.register('orders', EventBus());
  Raiser.register('payments', EventBus());
  
  Raiser.get('orders').publish(OrderCreated());
}
```

### Pattern D: Scoped with Bubbling

```dart
void main() {
  final root = EventBus();
  Raiser.setDefault(root);
  
  // Feature module creates scoped bus
  final featureBus = EventBus(parent: root, bubbleUp: true);
  featureBus.publish(LocalEvent()); // handled locally + bubbles to root
}
```

## Test Utilities

- `FakeEventBus` — captures published events for assertions
- `TestEventHandler` — records invocations
- Event history / replay support
- `Raiser.reset()` — clears registry between tests

## No Forced Base Classes

Raiser does not require users to extend its base classes. The library works with any event type.

### Approach

```dart
// Option A: Use Raiser's base class (recommended for convenience)
class OrderCreated extends DomainEvent {
  final String orderId;
  OrderCreated(this.orderId);
  // Inherits: id, timestamp, aggregateId, metadata helpers
}

// Option B: Use your own class (zero coupling)
class OrderCreated {
  final String orderId;
  final DateTime createdAt;
  OrderCreated(this.orderId, this.createdAt);
}

// Both work with EventBus
bus.publish(OrderCreated(...));
```

### How It Works

- `EventBus.publish<T>(T event)` accepts any type `T`
- Handlers are registered by type: `bus.on<OrderCreated>((event) => ...)`
- Type matching uses Dart's runtime type system

### Base Class Benefits (Opt-In)

When users extend `DomainEvent`, they get:
- Auto-generated unique event ID
- Timestamp automatically set
- Optional aggregate ID for DDD patterns
- `copyWith` / metadata helpers
- Consistent serialization interface (if needed)

### Handler Flexibility

```dart
// Option A: Extend EventHandler<T> base class
class OrderHandler extends EventHandler<OrderCreated> {
  @override
  Future<void> handle(OrderCreated event) async { ... }
}

// Option B: Just use a function
bus.on<OrderCreated>((event) async { ... });

// Option C: Implement the interface without extending
class OrderHandler implements EventHandler<OrderCreated> {
  @override
  Future<void> handle(OrderCreated event) async { ... }
}
```

This keeps Raiser non-invasive — users adopt only what they need.

## Design Principles

1. **Instance-first** — No forced singletons, works with any DI solution
2. **Type-safe** — Leverage Dart's type system, no dynamic casting
3. **Non-invasive** — No forced base classes, works with any event/handler types
4. **Async-native** — Built for real-world I/O operations
5. **Zero dependencies** — Pure Dart, works everywhere
6. **Testable** — First-class testing support
7. **Progressive complexity** — Simple for simple cases, powerful when needed
8. **Clean architecture aligned** — Supports bounded contexts and layered architecture
