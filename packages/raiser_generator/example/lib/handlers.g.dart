// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handlers.dart';

// **************************************************************************
// RaiserAggregatingGenerator
// **************************************************************************

/// Initializes all Raiser handlers and middleware.
///
/// Call this function during application startup to wire up
/// all discovered event handlers and middleware.
void initRaiser(EventBus bus) {
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

/// Initializes Raiser with factory functions for dependency injection.
///
/// Use this variant when handlers or middleware require constructor dependencies.
void initRaiserWithFactories(
  EventBus bus, {
  required LoggingUserHandlerFactory createLoggingUserHandler,
  required OrderProcessingHandlerFactory createOrderProcessingHandler,
}) {
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
  // Handler: PaymentHandler from lib/handlers.dart
  // Priority: 0
  bus.register<PaymentProcessedEvent>(PaymentHandler());
  // Handler: PaymentAuditHandler from lib/handlers.dart
  // Priority: 50
  bus.register<PaymentProcessedEvent>(PaymentAuditHandler(), priority: 50);
}

typedef ConfigurablePaymentHandlerFactory =
    ConfigurablePaymentHandler Function();

/// Initializes Raiser with factory functions for dependency injection.
/// This function registers components for the 'payments' bus.
///
/// Use this variant when handlers or middleware require constructor dependencies.
void initRaiserPaymentsBusWithFactories(
  EventBus bus, {
  required ConfigurablePaymentHandlerFactory createConfigurablePaymentHandler,
}) {
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
  // Handler: InventoryHandler from lib/handlers.dart
  // Priority: 0
  bus.register<InventoryUpdatedEvent>(InventoryHandler());
}
