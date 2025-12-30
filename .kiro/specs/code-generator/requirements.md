# Requirements Document

## Introduction

This document specifies the requirements for the Raiser Code Generator feature. The generator auto-discovers classes annotated with `@RaiserHandler` and `@RaiserMiddleware`, then generates registration code that eliminates manual handler/middleware registration boilerplate. Users simply annotate their handlers and run `build_runner` to get a fully wired event system.

## Glossary

- **Raiser_Generator**: The code generation package that processes annotations and produces registration code
- **Handler**: A class implementing `EventHandler<T>` that processes domain events of type T
- **Middleware**: A class that intercepts event processing for cross-cutting concerns (logging, validation, etc.)
- **Registration Code**: Generated Dart code that registers all discovered handlers and middleware with an EventBus
- **Priority**: An integer value determining execution order (higher values execute first)
- **Named Bus**: An EventBus instance identified by a string name for bounded context isolation
- **Build Runner**: Dart's code generation tool that invokes generators during the build process

## Requirements

### Requirement 1

**User Story:** As a developer, I want handlers annotated with `@RaiserHandler` to be automatically discovered, so that I don't need to manually register each handler with the EventBus.

#### Acceptance Criteria

1. WHEN a class is annotated with `@RaiserHandler` and extends `EventHandler<T>` THEN the Raiser_Generator SHALL include that class in the generated registration code
2. WHEN a class is annotated with `@RaiserHandler` but does not extend `EventHandler<T>` THEN the Raiser_Generator SHALL emit a compile-time error with a descriptive message
3. WHEN multiple handlers exist for the same event type THEN the Raiser_Generator SHALL register all handlers for that event type
4. WHEN a handler specifies a priority value THEN the Raiser_Generator SHALL include the priority in the registration call

### Requirement 2

**User Story:** As a developer, I want middleware annotated with `@RaiserMiddleware` to be automatically discovered, so that cross-cutting concerns are registered without manual wiring.

#### Acceptance Criteria

1. WHEN a class is annotated with `@RaiserMiddleware` THEN the Raiser_Generator SHALL include that class in the generated middleware registration code
2. WHEN middleware specifies a priority value THEN the Raiser_Generator SHALL order middleware registration by priority (higher values execute as outer middleware)
3. WHEN middleware specifies a busName THEN the Raiser_Generator SHALL generate registration code targeting that named bus

### Requirement 3

**User Story:** As a developer, I want the generator to produce a single initialization function, so that I can wire up all handlers and middleware with one call.

#### Acceptance Criteria

1. WHEN the generator runs THEN the Raiser_Generator SHALL produce a function named `initRaiser` that accepts an `EventBus` parameter
2. WHEN `initRaiser` is called THEN the function SHALL register all discovered handlers with the provided EventBus
3. WHEN `initRaiser` is called THEN the function SHALL register all discovered middleware with the provided EventBus
4. WHEN handlers or middleware specify different busName values THEN the Raiser_Generator SHALL produce separate initialization functions per bus name

### Requirement 4

**User Story:** As a developer, I want the generator to extract the event type from handler generic parameters, so that type-safe registration code is generated.

#### Acceptance Criteria

1. WHEN a handler extends `EventHandler<T>` THEN the Raiser_Generator SHALL extract type T and use it in the generated registration code
2. WHEN a handler has a concrete event type (e.g., `EventHandler<OrderCreatedEvent>`) THEN the Raiser_Generator SHALL generate registration code with that specific type
3. WHEN a handler's event type cannot be resolved THEN the Raiser_Generator SHALL emit a compile-time error indicating the unresolvable type

### Requirement 5

**User Story:** As a developer, I want the generated code to support dependency injection, so that handlers with constructor dependencies can be instantiated properly.

#### Acceptance Criteria

1. WHEN a handler has a default constructor with no parameters THEN the Raiser_Generator SHALL generate direct instantiation code
2. WHEN a handler has constructor parameters THEN the Raiser_Generator SHALL generate a factory function signature that accepts those dependencies
3. WHEN generating factory functions THEN the Raiser_Generator SHALL preserve parameter types and names from the original constructor

### Requirement 6

**User Story:** As a developer, I want clear error messages when annotations are misused, so that I can quickly fix configuration issues.

#### Acceptance Criteria

1. IF `@RaiserHandler` is applied to a non-class element THEN the Raiser_Generator SHALL emit an error stating the annotation is only valid on classes
2. IF `@RaiserHandler` is applied to an abstract class THEN the Raiser_Generator SHALL emit an error stating abstract classes cannot be registered
3. IF a handler class has no accessible constructor THEN the Raiser_Generator SHALL emit an error describing the constructor requirement

### Requirement 7

**User Story:** As a developer, I want the generated code to be readable and debuggable, so that I can understand and troubleshoot the registration process.

#### Acceptance Criteria

1. WHEN generating code THEN the Raiser_Generator SHALL include comments indicating which source file each handler originated from
2. WHEN generating code THEN the Raiser_Generator SHALL format the output according to Dart style guidelines
3. WHEN generating code THEN the Raiser_Generator SHALL include the handler's priority value as a comment for clarity
