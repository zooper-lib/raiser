# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## UNRELEASED

### Modified

- **RaiserEvent** — Updated documentation and examples from `DomainEvent` to `RaiserEvent`

## [1.0.0] - 2024-12-19

### Added

- **Two-phase builder system**
  - Phase 1: `raiser_collecting` — Discovers annotated handlers and middleware per file
  - Phase 2: `raiser_aggregating` — Generates consolidated registration code
- **Automatic handler discovery** — Scans codebase for `@RaiserHandler` annotations
- **Automatic middleware discovery** — Scans codebase for `@RaiserMiddleware` annotations
- **Generated registration functions**
  - `initRaiser()` — Registers all handlers without dependencies
  - `initRaiserWithFactories()` — Registers handlers with dependency injection support
  - Named bus functions — `initRaiser{BusName}()` for handlers on specific buses
- **Dependency injection support**
  - Factory parameter generation for handlers with constructor dependencies
  - Preserves constructor parameter names and types
- **Priority support** — Respects priority ordering from annotations
- **Type-safe code generation** — Generates strongly-typed registration code
- **Build configuration** — Excludes generated files (.g.dart, .freezed.dart, .gr.dart, .config.dart)
- Comprehensive examples demonstrating basic and advanced usage patterns
- Full test coverage for all generation scenarios
