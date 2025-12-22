# Raiser Generator

Code generator for the [Raiser](https://pub.dev/packages/raiser) domain event library. Automatically discovers and registers event handlers and middleware annotated with `@RaiserHandler` and `@RaiserMiddleware`.

## Features

- **Automatic discovery** — Finds all annotated handlers and middleware in your codebase
- **Dependency injection support** — Generated factories accept constructor parameters
- **Priority configuration** — Respects priority settings from annotations
- **Type-safe registration** — Generates strongly-typed registration functions

## Installation

```yaml
dependencies:
  raiser: ^1.0.0
  raiser_annotation: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.0
  raiser_generator: ^1.0.0
```

## Quick Start

### 1. Create Event Handlers

```dart
// lib/handlers/welcome_email_handler.dart
import 'package:raiser/raiser.dart';
import 'package:raiser_annotation/raiser_annotation.dart';

@RaiserHandler()
class WelcomeEmailHandler implements EventHandler<UserCreated> {
  final EmailService _emailService;

  WelcomeEmailHandler(this._emailService);

  @override
  Future<void> handle(UserCreated event) async {
    await _emailService.sendWelcome(event.email);
  }
}

@RaiserHandler(priority: 10)
class CreateUserProfileHandler implements EventHandler<UserCreated> {
  final UserRepository _userRepository;

  CreateUserProfileHandler(this._userRepository);

  @override
  Future<void> handle(UserCreated event) async {
    await _userRepository.createProfile(event.userId);
  }
}
```

### 2. Create Middleware (Optional)

```dart
// lib/middleware/logging_middleware.dart
import 'package:raiser/raiser.dart';
import 'package:raiser_annotation/raiser_annotation.dart';

@RaiserMiddleware(priority: 100)
class LoggingMiddleware {
  final Logger _logger;

  LoggingMiddleware(this._logger);

  Future<void> call(DomainEvent event, Future<void> Function() next) async {
    _logger.info('Event: ${event.runtimeType}');
    await next();
  }
}
```

### 3. Configure Build

Create or update `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      raiser_generator:raiserBuilder:
        enabled: true
        generate_for:
          - lib/**
        options:
          handlers_output: lib/handlers.g.dart
          middleware_output: lib/middleware.g.dart
```

### 4. Run the Generator

```bash
dart run build_runner build
```

Or for development with watch mode:

```bash
dart run build_runner watch
```

### 5. Use Generated Code

```dart
// lib/main.dart
import 'package:raiser/raiser.dart';
import 'handlers.g.dart';
import 'middleware.g.dart';

void main() async {
  final bus = EventBus();
  
  // Create your dependencies
  final emailService = EmailService();
  final userRepository = UserRepository();
  final logger = Logger();

  // Register all handlers using generated function
  registerHandlers(
    bus,
    welcomeEmailHandlerFactory: () => WelcomeEmailHandler(emailService),
    createUserProfileHandlerFactory: () => CreateUserProfileHandler(userRepository),
  );

  // Register all middleware using generated function
  registerMiddleware(
    bus,
    loggingMiddlewareFactory: () => LoggingMiddleware(logger),
  );

  // Now use the bus
  await bus.publish(UserCreated(userId: '123', email: 'alice@example.com'));
}
```

## Configuration Options

Configure in `build.yaml`:

| Option | Default | Description |
|--------|---------|-------------|
| `handlers_output` | `lib/handlers.g.dart` | Output path for handler registration |
| `middleware_output` | `lib/middleware.g.dart` | Output path for middleware registration |

## Generated Code

### Handler Registration

The generator creates a `registerHandlers` function:

```dart
void registerHandlers(
  EventBus bus, {
  required WelcomeEmailHandler Function() welcomeEmailHandlerFactory,
  required CreateUserProfileHandler Function() createUserProfileHandlerFactory,
}) {
  bus.register<UserCreated>(welcomeEmailHandlerFactory(), priority: 0);
  bus.register<UserCreated>(createUserProfileHandlerFactory(), priority: 10);
}
```

### Middleware Registration

The generator creates a `registerMiddleware` function:

```dart
void registerMiddleware(
  EventBus bus, {
  required LoggingMiddleware Function() loggingMiddlewareFactory,
}) {
  final loggingMiddleware = loggingMiddlewareFactory();
  bus.addMiddleware(loggingMiddleware.call, priority: 100);
}
```

## How It Works

The generator uses a two-phase build process:

1. **Collection Phase** — Scans all Dart files for `@RaiserHandler` and `@RaiserMiddleware` annotations, extracts metadata (event types, priorities, constructor parameters)

2. **Aggregation Phase** — Combines all discovered handlers and middleware into single registration files

This approach ensures all handlers across your entire codebase are discovered, even across multiple files and directories.

## Requirements

- Dart SDK >= 3.7.0
- Handlers must implement `EventHandler<T>` where `T` extends `DomainEvent`
- Middleware must have a `call` method with signature `Future<void> Function(DomainEvent, Future<void> Function())`

## Related Packages

| Package | Description |
|---------|-------------|
| [raiser](https://pub.dev/packages/raiser) | Core event bus library |
| [raiser_annotation](https://pub.dev/packages/raiser_annotation) | Annotations for handler/middleware marking |

## License

MIT License
