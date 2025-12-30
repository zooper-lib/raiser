# Requirements Document

## Introduction

This specification defines the core event system for Raiser, a type-safe domain event library for Dart. The core system establishes the foundational components: the `DomainEvent` base class, `EventHandler` interface, and `EventBus` dispatcher. These components form the backbone upon which all other features (middleware, hierarchical buses, registry) will be built.

## Glossary

- **DomainEvent**: A base class representing an event that occurred in the domain, containing metadata such as timestamp, unique ID, and optional aggregate ID.
- **EventHandler**: An interface that defines a contract for handling a specific type of event.
- **EventBus**: A central dispatcher that routes published events to their registered handlers.
- **Handler**: A component that processes events of a specific type.
- **Subscription**: A registration of a handler to receive events of a particular type, which can be cancelled.
- **Aggregate ID**: An optional identifier linking an event to a domain aggregate (DDD pattern).

## Requirements

### Requirement 1

**User Story:** As a developer, I want a type-safe base class for domain events, so that I can create events with consistent metadata and behavior.

#### Acceptance Criteria

1. WHEN a DomainEvent is instantiated THEN the DomainEvent SHALL automatically generate a unique string identifier.
2. WHEN a DomainEvent is instantiated THEN the DomainEvent SHALL automatically capture the current timestamp.
3. WHERE an aggregate ID is provided THEN the DomainEvent SHALL store the aggregate ID for later retrieval.
4. WHEN a DomainEvent is created THEN the DomainEvent SHALL be immutable after construction.
5. WHEN serializing a DomainEvent THEN the DomainEvent SHALL provide a method to convert its metadata to a Map representation.
6. WHEN deserializing a DomainEvent THEN the DomainEvent SHALL provide a method to reconstruct from a Map representation (round-trip).

### Requirement 2

**User Story:** As a developer, I want a type-safe event handler interface, so that I can create handlers that only receive their specific event type.

#### Acceptance Criteria

1. WHEN defining an EventHandler THEN the EventHandler SHALL be generic over the event type it handles.
2. WHEN an EventHandler processes an event THEN the EventHandler SHALL return a Future<void> to support async operations.
3. WHEN implementing an EventHandler THEN the EventHandler SHALL enforce compile-time type checking for the event parameter.

### Requirement 3

**User Story:** As a developer, I want an event bus to publish and route events, so that I can decouple event producers from consumers.

#### Acceptance Criteria

1. WHEN a handler is registered on the EventBus THEN the EventBus SHALL store the handler for the specified event type.
2. WHEN an event is published THEN the EventBus SHALL invoke all handlers registered for that event's type.
3. WHEN an event is published THEN the EventBus SHALL invoke handlers asynchronously and await their completion.
4. WHEN a subscription is cancelled THEN the EventBus SHALL remove the handler and stop delivering events to the cancelled handler.
5. WHEN multiple handlers are registered for the same event type THEN the EventBus SHALL invoke all matching handlers.
6. WHEN no handlers are registered for an event type THEN the EventBus SHALL complete without error.
7. WHEN registering a handler THEN the EventBus SHALL return a Subscription object that can be used to cancel the registration.

### Requirement 4

**User Story:** As a developer, I want to register handlers using either classes or functions, so that I can choose the style that fits my use case.

#### Acceptance Criteria

1. WHEN registering an EventHandler class instance THEN the EventBus SHALL accept and invoke the handler's handle method.
2. WHEN registering a function handler THEN the EventBus SHALL accept and invoke the function directly.
3. WHEN using either registration style THEN the EventBus SHALL provide equivalent type safety guarantees.

### Requirement 5

**User Story:** As a developer, I want to publish events of any type without requiring a base class, so that I can use Raiser with existing event classes.

#### Acceptance Criteria

1. WHEN publishing an event that does not extend DomainEvent THEN the EventBus SHALL route the event to matching handlers.
2. WHEN registering a handler for a custom event type THEN the EventBus SHALL match events by their runtime type.
3. WHEN using custom event types THEN the EventBus SHALL maintain the same type safety as with DomainEvent subclasses.

### Requirement 6

**User Story:** As a developer, I want handlers to execute in a deterministic order based on priority, so that I can control the sequence of event processing.

#### Acceptance Criteria

1. WHEN registering a handler with a priority value THEN the EventBus SHALL store the priority for ordering.
2. WHEN multiple handlers are registered for the same event type THEN the EventBus SHALL invoke handlers in descending priority order (higher priority first).
3. WHEN handlers have equal priority THEN the EventBus SHALL invoke handlers in registration order.

### Requirement 7

**User Story:** As a developer, I want configurable error handling when handlers fail, so that I can choose the appropriate behavior for my application.

#### Acceptance Criteria

1. WHEN a handler throws an exception and error strategy is "stop" THEN the EventBus SHALL halt propagation and rethrow the error.
2. WHEN a handler throws an exception and error strategy is "continueOnError" THEN the EventBus SHALL continue invoking remaining handlers and collect all errors.
3. WHEN a handler throws an exception and error strategy is "swallow" THEN the EventBus SHALL continue invoking remaining handlers without collecting errors.
4. WHEN an error callback is configured THEN the EventBus SHALL invoke the callback for each handler error.
5. WHEN error strategy is "continueOnError" and multiple handlers fail THEN the EventBus SHALL throw an aggregate exception containing all collected errors after all handlers complete.

