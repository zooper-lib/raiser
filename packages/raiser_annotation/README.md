# Raiser Annotation

Annotations for the [Raiser](https://pub.dev/packages/raiser) domain event library code generator.

## Overview

This package provides the annotations used by `raiser_generator` to automatically discover and register event handlers and middleware in your application.

## Installation

```yaml
dependencies:
  raiser: ^1.0.0
  raiser_annotation: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.0
  raiser_generator: ^1.0.0
```

## Annotations

### @RaiserHandler

Marks a class as an event handler for code generation:

```dart
import 'package:raiser/raiser.dart';
import 'package:raiser_annotation/raiser_annotation.dart';

@RaiserHandler()
class SendWelcomeEmailHandler implements EventHandler<UserCreated> {
  final EmailService _emailService;

  SendWelcomeEmailHandler(this._emailService);

  @override
  Future<void> handle(UserCreated event) async {
    await _emailService.sendWelcome(event.email);
  }
}
```

**Options:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `priority` | `int` | `0` | Handler execution priority (higher runs first) |

```dart
@RaiserHandler(priority: 100)  // Runs before handlers with lower priority
class HighPriorityHandler implements EventHandler<MyEvent> {
  // ...
}
```

### @RaiserMiddleware

Marks a class as middleware for code generation:

```dart
import 'package:raiser/raiser.dart';
import 'package:raiser_annotation/raiser_annotation.dart';

@RaiserMiddleware()
class LoggingMiddleware {
  final Logger _logger;

  LoggingMiddleware(this._logger);

  Future<void> call(DomainEvent event, Future<void> Function() next) async {
    _logger.info('Processing ${event.runtimeType}');
    await next();
    _logger.info('Completed ${event.runtimeType}');
  }
}
```

**Options:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `priority` | `int` | `0` | Middleware execution priority (higher priority wraps lower) |

```dart
@RaiserMiddleware(priority: 1000)  // Outermost middleware layer
class TimingMiddleware {
  // ...
}
```

## Usage with Generator

After annotating your classes, run the code generator:

```bash
dart run build_runner build
```

This generates registration functions that you use to configure your event bus. See [raiser_generator](https://pub.dev/packages/raiser_generator) for complete setup instructions.

## Related Packages

| Package | Description |
|---------|-------------|
| [raiser](https://pub.dev/packages/raiser) | Core event bus library |
| [raiser_generator](https://pub.dev/packages/raiser_generator) | Code generator for automatic handler discovery |

## License

MIT License
