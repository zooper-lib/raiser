# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## UNRELEASED

### Modified

- **RaiserEvent** — Updated documentation references from `DomainEvent` to `RaiserEvent`

## [1.0.0] - 2024-12-19

### Added

- **@RaiserHandler** annotation for marking event handler classes
  - `priority` parameter for controlling execution order
  - `busName` parameter for routing handlers to named buses
- **@RaiserMiddleware** annotation for marking middleware classes
  - `priority` parameter for controlling middleware order
  - `busName` parameter for routing middleware to named buses
- Support for dependency injection through annotation metadata
- Documentation and examples for all annotations
