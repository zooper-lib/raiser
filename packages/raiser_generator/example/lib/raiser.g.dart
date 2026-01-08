// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

import 'package:raiser/raiser.dart';

import 'events.dart';
import 'handlers.dart';
import 'middleware.dart';

/// Initializes all Raiser handlers and middleware.
///
/// Call this function during application startup to wire up
/// all discovered event handlers and middleware.
void initRaiser(EventBus bus) {
  // Middleware: TimingMiddleware from lib/middleware.dart
  // Priority: 100
  bus.addMiddleware(TimingMiddleware(), priority: 100);
  // Middleware: ValidationMiddleware from lib/middleware.dart
  // Priority: 50
  bus.addMiddleware(ValidationMiddleware(), priority: 50);
  // Middleware: LoggingMiddleware from lib/middleware.dart
  // Priority: 0
  bus.addMiddleware(LoggingMiddleware());
  // Middleware: MetricsMiddleware from lib/middleware.dart
  // Priority: -10
  bus.addMiddleware(MetricsMiddleware(), priority: -10);
  // Handler: UserCreatedHandler from lib/handlers.dart
  // Priority: 0
  bus.register<UserCreatedEvent>(UserCreatedHandler());
  // Handler: UserWelcomeEmailHandler from lib/handlers.dart
  // Priority: 0
  bus.register<UserCreatedEvent>(UserWelcomeEmailHandler());
  // Handler: HighPriorityOrderHandler from lib/handlers.dart
  // Priority: 100
  bus.register<OrderPlacedEvent>(HighPriorityOrderHandler(), priority: 100);
  // Handler: NormalPriorityOrderHandler from lib/handlers.dart
  // Priority: 0
  bus.register<OrderPlacedEvent>(NormalPriorityOrderHandler());
  // Handler: LowPriorityOrderHandler from lib/handlers.dart
  // Priority: -10
  bus.register<OrderPlacedEvent>(LowPriorityOrderHandler(), priority: -10);
}

typedef LoggingUserHandlerFactory = LoggingUserHandler Function();
typedef OrderProcessingHandlerFactory = OrderProcessingHandler Function();
typedef StructuredLoggingMiddlewareFactory =
    StructuredLoggingMiddleware Function();
typedef AuthorizationMiddlewareFactory = AuthorizationMiddleware Function();

/// Initializes Raiser with factory functions for dependency injection.
///
/// Use this variant when handlers or middleware require constructor dependencies.
void initRaiserWithFactories(
  EventBus bus, {
  required LoggingUserHandlerFactory createLoggingUserHandler,
  required OrderProcessingHandlerFactory createOrderProcessingHandler,
  required StructuredLoggingMiddlewareFactory createStructuredLoggingMiddleware,
  required AuthorizationMiddlewareFactory createAuthorizationMiddleware,
}) {
  // Middleware: TimingMiddleware from lib/middleware.dart
  // Priority: 100
  bus.addMiddleware(TimingMiddleware(), priority: 100);
  // Middleware: StructuredLoggingMiddleware from lib/middleware.dart
  // Priority: 80
  bus.addMiddleware(createStructuredLoggingMiddleware(), priority: 80);
  // Middleware: ValidationMiddleware from lib/middleware.dart
  // Priority: 50
  bus.addMiddleware(ValidationMiddleware(), priority: 50);
  // Middleware: LoggingMiddleware from lib/middleware.dart
  // Priority: 0
  bus.addMiddleware(LoggingMiddleware());
  // Middleware: AuthorizationMiddleware from lib/middleware.dart
  // Priority: 0
  bus.addMiddleware(createAuthorizationMiddleware());
  // Middleware: MetricsMiddleware from lib/middleware.dart
  // Priority: -10
  bus.addMiddleware(MetricsMiddleware(), priority: -10);
  // Handler: UserCreatedHandler from lib/handlers.dart
  // Priority: 0
  bus.register<UserCreatedEvent>(UserCreatedHandler());
  // Handler: UserWelcomeEmailHandler from lib/handlers.dart
  // Priority: 0
  bus.register<UserCreatedEvent>(UserWelcomeEmailHandler());
  // Handler: HighPriorityOrderHandler from lib/handlers.dart
  // Priority: 100
  bus.register<OrderPlacedEvent>(HighPriorityOrderHandler(), priority: 100);
  // Handler: NormalPriorityOrderHandler from lib/handlers.dart
  // Priority: 0
  bus.register<OrderPlacedEvent>(NormalPriorityOrderHandler());
  // Handler: LowPriorityOrderHandler from lib/handlers.dart
  // Priority: -10
  bus.register<OrderPlacedEvent>(LowPriorityOrderHandler(), priority: -10);
  // Handler: LoggingUserHandler from lib/handlers.dart
  // Priority: 10
  bus.register<UserCreatedEvent>(createLoggingUserHandler(), priority: 10);
  // Handler: OrderProcessingHandler from lib/handlers.dart
  // Priority: 0
  bus.register<OrderPlacedEvent>(createOrderProcessingHandler());
}

/// Initializes all Raiser handlers and middleware.
/// This function registers components for the 'payments' bus.
///
/// Call this function during application startup to wire up
/// all discovered event handlers and middleware.
void initRaiserPaymentsBus(EventBus bus) {
  // Middleware: PaymentLoggingMiddleware from lib/middleware.dart
  // Priority: 90
  bus.addMiddleware(PaymentLoggingMiddleware(), priority: 90);
  // Middleware: PaymentSecurityMiddleware from lib/middleware.dart
  // Priority: 0
  bus.addMiddleware(PaymentSecurityMiddleware());
  // Handler: PaymentHandler from lib/handlers.dart
  // Priority: 0
  bus.register<PaymentProcessedEvent>(PaymentHandler());
  // Handler: PaymentAuditHandler from lib/handlers.dart
  // Priority: 50
  bus.register<PaymentProcessedEvent>(PaymentAuditHandler(), priority: 50);
}

typedef ConfigurablePaymentHandlerFactory =
    ConfigurablePaymentHandler Function();
typedef RateLimitingMiddlewareFactory = RateLimitingMiddleware Function();

/// Initializes Raiser with factory functions for dependency injection.
/// This function registers components for the 'payments' bus.
///
/// Use this variant when handlers or middleware require constructor dependencies.
void initRaiserPaymentsBusWithFactories(
  EventBus bus, {
  required ConfigurablePaymentHandlerFactory createConfigurablePaymentHandler,
  required RateLimitingMiddlewareFactory createRateLimitingMiddleware,
}) {
  // Middleware: RateLimitingMiddleware from lib/middleware.dart
  // Priority: 95
  bus.addMiddleware(createRateLimitingMiddleware(), priority: 95);
  // Middleware: PaymentLoggingMiddleware from lib/middleware.dart
  // Priority: 90
  bus.addMiddleware(PaymentLoggingMiddleware(), priority: 90);
  // Middleware: PaymentSecurityMiddleware from lib/middleware.dart
  // Priority: 0
  bus.addMiddleware(PaymentSecurityMiddleware());
  // Handler: PaymentHandler from lib/handlers.dart
  // Priority: 0
  bus.register<PaymentProcessedEvent>(PaymentHandler());
  // Handler: PaymentAuditHandler from lib/handlers.dart
  // Priority: 50
  bus.register<PaymentProcessedEvent>(PaymentAuditHandler(), priority: 50);
  // Handler: ConfigurablePaymentHandler from lib/handlers.dart
  // Priority: 0
  bus.register<PaymentProcessedEvent>(createConfigurablePaymentHandler());
}

/// Initializes all Raiser handlers and middleware.
/// This function registers components for the 'inventory' bus.
///
/// Call this function during application startup to wire up
/// all discovered event handlers and middleware.
void initRaiserInventoryBus(EventBus bus) {
  // Middleware: InventoryAuditMiddleware from lib/middleware.dart
  // Priority: 0
  bus.addMiddleware(InventoryAuditMiddleware());
  // Handler: InventoryHandler from lib/handlers.dart
  // Priority: 0
  bus.register<InventoryUpdatedEvent>(InventoryHandler());
}
