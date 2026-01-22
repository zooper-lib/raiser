# Changelog

All notable changes to this workspace will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this workspace adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This is a lockstep workspace: all packages share the same version and release notes.

## [Unreleased]

### Changed

- Updated dependencies to use latest versions:
  - `zooper_flutter_core: ^2.0.0`
  - `bounded: ^1.0.0`

## [3.0.0] - 2026-01-10

### Changed

- **BREAKING**: `RaiserEvent` is now a pure `abstract interface class` instead of a base class with implementation.
  - **Note: Using `RaiserEvent` is completely optional - `EventBus` works with ANY type.**
  - If you choose to use `RaiserEvent`, you must explicitly implement all three required properties: `id`, `occurredOn`, and `metadata`.
  - No more automatic property initialization - implement the interface explicitly.
  - This change allows events to use composition and multiple interfaces without inheritance constraints.
- `RaiserEvent` now implements `ZooperDomainEvent` from `zooper_flutter_core` package.
- Event IDs in `RaiserEvent` now use `EventId` type (ULID-based) instead of `String`.
  - IDs are generated via `EventId.fromUlid()` for better uniqueness guarantees.
  - Access raw string value via `event.id.value` when needed.
- Renamed `RaiserEvent.timestamp` property to `occurredOn` for clarity and DDD alignment.
- Removed `aggregateId` as a direct property from `RaiserEvent`.
  - Store aggregate identifiers in the `metadata` map instead: `metadata: {'aggregateId': 'user-123'}`.
  - Access via `event.metadata['aggregateId'] as String?`.
- Removed helper mixins and convenience extensions.
- Updated generator dependency constraints to `raiser: ^3.0.0` and `raiser_annotation: ^3.0.0`.

### Important Note

**`EventBus` is fully generic and does not require `RaiserEvent`.** You can publish and subscribe to any type. The `RaiserEvent` interface is purely optional for users who want standardized domain event metadata.

## [2.0.1] - 2026-01-08

### Changed

- Migrated generator implementation away from deprecated analyzer element APIs to remove deprecation warnings.

## [2.0.0] - 2026-01-08

### Changed

- **BREAKING**: Renamed `DomainEvent` to `RaiserEvent` to avoid naming conflicts with other packages.
- Updated documentation references from `DomainEvent` to `RaiserEvent`.
- Updated generator dependency constraints to `raiser: ^2.0.0` and `raiser_annotation: ^2.0.0`.

## [1.0.0] - 2024-12-19

### Added

- **EventBus** — Central dispatcher for publishing and routing domain events.
- **DomainEvent** — Base class with automatic ID generation, timestamps, and optional aggregate ID.
- **EventHandler<T>** — Type-safe interface for class-based event handlers.
- **Subscription** — Handle for cancelling handler registrations.
- **Priority-based ordering** — Higher priority handlers execute first.
- **Error handling strategies**.
- **AggregateException** — Collects multiple handler errors when using `continueOnError`.
- **@RaiserHandler** annotation for marking event handler classes.
- **@RaiserMiddleware** annotation for marking middleware classes.
- Support for dependency injection through annotation metadata.
- **Two-phase builder system** (`raiser_collecting` → `raiser_aggregating`).
- **Automatic handler discovery** and **middleware discovery**.
- Generated registration functions (`initRaiser()`, `initRaiserWithFactories()`, and named bus variants).
- Dependency injection factory parameter generation.
- Priority support and type-safe code generation.
