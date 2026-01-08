# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-01-08

### Changed

- Migrated generator implementation away from deprecated analyzer element APIs to remove deprecation warnings.

## [2.0.0] - 2026-01-08

### Changed

- **BREAKING**: Renamed `DomainEvent` to `RaiserEvent` to avoid naming conflicts with other packages

## [1.0.0] - 2024-12-19

### Added

- **EventBus** — Central dispatcher for publishing and routing domain events
- **DomainEvent** — Base class with automatic ID generation, timestamps, and optional aggregate ID
- **EventHandler<T>** — Type-safe interface for class-based event handlers
- **Subscription** — Handle for cancelling handler registrations
- **Priority-based ordering** — Higher priority handlers execute first
- **Error handling strategies**
  - `ErrorStrategy.stop` — Halt on first error (default)
  - `ErrorStrategy.continueOnError` — Collect errors, throw `AggregateException`
  - `ErrorStrategy.swallow` — Silent failures with optional callback
- **AggregateException** — Collects multiple handler errors when using `continueOnError`
- Comprehensive examples demonstrating basic and advanced usage patterns
