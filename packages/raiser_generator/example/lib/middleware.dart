/// Example middleware demonstrating various @RaiserMiddleware configurations.
///
/// This file contains middleware with different configurations:
/// - Basic middleware with default settings
/// - Middleware with priority
/// - Middleware with named bus
/// - Middleware with dependency injection
///
/// Requirements: 2.1, 2.2, 2.3

import 'package:raiser_annotation/raiser_annotation.dart';

import 'services.dart';

// ============================================================================
// BASIC MIDDLEWARE (default configuration)
// ============================================================================

/// Basic logging middleware with default priority.
///
/// Demonstrates the simplest @RaiserMiddleware usage.
@RaiserMiddleware()
class LoggingMiddleware {
  Future<void> call(dynamic event, Future<void> Function() next) async {
    print('Event received: ${event.runtimeType}');
    await next();
    print('Event processed: ${event.runtimeType}');
  }
}

// ============================================================================
// MIDDLEWARE WITH PRIORITY
// ============================================================================

/// High priority middleware that wraps all others.
///
/// Executes first (outer middleware).
/// Requirements: 2.2
@RaiserMiddleware(priority: 100)
class TimingMiddleware {
  Future<void> call(dynamic event, Future<void> Function() next) async {
    final stopwatch = Stopwatch()..start();
    await next();
    stopwatch.stop();
    print('Event processing took ${stopwatch.elapsedMilliseconds}ms');
  }
}

/// Medium priority middleware.
@RaiserMiddleware(priority: 50)
class ValidationMiddleware {
  Future<void> call(dynamic event, Future<void> Function() next) async {
    print('Validating event...');
    await next();
  }
}

/// Low priority middleware that executes closest to handlers.
@RaiserMiddleware(priority: -10)
class MetricsMiddleware {
  Future<void> call(dynamic event, Future<void> Function() next) async {
    print('Recording metrics...');
    await next();
  }
}

// ============================================================================
// MIDDLEWARE WITH NAMED BUS
// ============================================================================

/// Middleware registered to the 'payments' bus.
///
/// Demonstrates named bus configuration for middleware.
/// Requirements: 2.3
@RaiserMiddleware(busName: 'payments')
class PaymentSecurityMiddleware {
  Future<void> call(dynamic event, Future<void> Function() next) async {
    print('Verifying payment security...');
    await next();
  }
}

/// Another middleware for the 'payments' bus with priority.
@RaiserMiddleware(busName: 'payments', priority: 90)
class PaymentLoggingMiddleware {
  Future<void> call(dynamic event, Future<void> Function() next) async {
    print('Payment event: ${event.runtimeType}');
    await next();
  }
}

/// Middleware registered to the 'inventory' bus.
@RaiserMiddleware(busName: 'inventory')
class InventoryAuditMiddleware {
  Future<void> call(dynamic event, Future<void> Function() next) async {
    print('Auditing inventory change...');
    await next();
  }
}

// ============================================================================
// MIDDLEWARE WITH DEPENDENCY INJECTION
// ============================================================================

/// Middleware that requires a Logger dependency.
///
/// Demonstrates dependency injection with a single parameter.
/// Requirements: 5.2, 5.3
@RaiserMiddleware(priority: 80)
class StructuredLoggingMiddleware {
  final Logger logger;

  StructuredLoggingMiddleware(this.logger);

  Future<void> call(dynamic event, Future<void> Function() next) async {
    logger.log('Event started: ${event.runtimeType}');
    try {
      await next();
      logger.log('Event completed: ${event.runtimeType}');
    } catch (e) {
      logger.log('Event failed: ${event.runtimeType} - $e');
      rethrow;
    }
  }
}

/// Middleware that requires multiple dependencies.
///
/// Demonstrates dependency injection with multiple parameters.
@RaiserMiddleware()
class AuthorizationMiddleware {
  final AuthService authService;
  final Logger logger;

  AuthorizationMiddleware(this.authService, this.logger);

  Future<void> call(dynamic event, Future<void> Function() next) async {
    if (await authService.isAuthorized()) {
      logger.log('Authorization passed');
      await next();
    } else {
      logger.log('Authorization failed');
      throw UnauthorizedException('Not authorized to process event');
    }
  }
}

/// Middleware with named parameters.
@RaiserMiddleware(busName: 'payments', priority: 95)
class RateLimitingMiddleware {
  final RateLimiter rateLimiter;
  final int maxRequests;

  RateLimitingMiddleware(
    this.rateLimiter, {
    this.maxRequests = 100,
  });

  Future<void> call(dynamic event, Future<void> Function() next) async {
    if (await rateLimiter.allowRequest(maxRequests)) {
      await next();
    } else {
      throw RateLimitExceededException('Rate limit exceeded');
    }
  }
}

/// Exception thrown when authorization fails.
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception thrown when rate limit is exceeded.
class RateLimitExceededException implements Exception {
  final String message;
  RateLimitExceededException(this.message);

  @override
  String toString() => 'RateLimitExceededException: $message';
}
