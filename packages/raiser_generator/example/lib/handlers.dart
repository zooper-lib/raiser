/// Example handlers demonstrating various @RaiserHandler configurations.
///
/// This file contains handlers with different configurations:
/// - Basic handler with default settings
/// - Handler with priority
/// - Handler with named bus
/// - Handler with dependency injection
/// - Multiple handlers for the same event type

import 'package:raiser/raiser.dart';
import 'package:raiser_annotation/raiser_annotation.dart';

import 'events.dart';
import 'services.dart';

// ============================================================================
// BASIC HANDLERS (default configuration)
// ============================================================================

/// Basic handler with default priority (0) and default bus.
///
/// Demonstrates the simplest @RaiserHandler usage.
@RaiserHandler()
class UserCreatedHandler extends EventHandler<UserCreatedEvent> {
  @override
  Future<void> handle(UserCreatedEvent event) async {
    print('User created: ${event.userId} (${event.email})');
  }
}

/// Another handler for the same event type.
///
/// Demonstrates that multiple handlers can handle the same event.
@RaiserHandler()
class UserWelcomeEmailHandler extends EventHandler<UserCreatedEvent> {
  @override
  Future<void> handle(UserCreatedEvent event) async {
    print('Sending welcome email to ${event.email}');
  }
}

// ============================================================================
// HANDLERS WITH PRIORITY
// ============================================================================

/// High priority handler that executes before others.
///
/// Demonstrates priority configuration.
@RaiserHandler(priority: 100)
class HighPriorityOrderHandler extends EventHandler<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    print('HIGH PRIORITY: Processing order ${event.orderId}');
  }
}

/// Normal priority handler.
@RaiserHandler(priority: 0)
class NormalPriorityOrderHandler extends EventHandler<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    print('NORMAL: Processing order ${event.orderId}');
  }
}

/// Low priority handler that executes after others.
@RaiserHandler(priority: -10)
class LowPriorityOrderHandler extends EventHandler<OrderPlacedEvent> {
  @override
  Future<void> handle(OrderPlacedEvent event) async {
    print('LOW PRIORITY: Processing order ${event.orderId}');
  }
}

// ============================================================================
// HANDLERS WITH NAMED BUS
// ============================================================================

/// Handler registered to the 'payments' bus.
///
/// Demonstrates named bus configuration.
@RaiserHandler(busName: 'payments')
class PaymentHandler extends EventHandler<PaymentProcessedEvent> {
  @override
  Future<void> handle(PaymentProcessedEvent event) async {
    print(
      'Payment ${event.paymentId}: ${event.success ? 'SUCCESS' : 'FAILED'}',
    );
  }
}

/// Another handler for the 'payments' bus with priority.
@RaiserHandler(busName: 'payments', priority: 50)
class PaymentAuditHandler extends EventHandler<PaymentProcessedEvent> {
  @override
  Future<void> handle(PaymentProcessedEvent event) async {
    print('AUDIT: Payment ${event.paymentId} logged');
  }
}

/// Handler registered to the 'inventory' bus.
@RaiserHandler(busName: 'inventory')
class InventoryHandler extends EventHandler<InventoryUpdatedEvent> {
  @override
  Future<void> handle(InventoryUpdatedEvent event) async {
    print('Inventory updated: ${event.productId} = ${event.quantity}');
  }
}

// ============================================================================
// HANDLERS WITH DEPENDENCY INJECTION
// ============================================================================

/// Handler that requires a Logger dependency.
///
/// Demonstrates dependency injection with a single parameter.
@RaiserHandler(priority: 10)
class LoggingUserHandler extends EventHandler<UserCreatedEvent> {
  final Logger logger;

  LoggingUserHandler(this.logger);

  @override
  Future<void> handle(UserCreatedEvent event) async {
    logger.log('User created: ${event.userId}');
  }
}

/// Handler that requires multiple dependencies.
///
/// Demonstrates dependency injection with multiple parameters.
@RaiserHandler()
class OrderProcessingHandler extends EventHandler<OrderPlacedEvent> {
  final OrderRepository repository;
  final NotificationService notifications;

  OrderProcessingHandler(this.repository, this.notifications);

  @override
  Future<void> handle(OrderPlacedEvent event) async {
    await repository.save(event.orderId, event.amount);
    await notifications.notify('Order ${event.orderId} placed');
  }
}

/// Handler with named parameters and default values.
///
/// Demonstrates complex constructor patterns.
@RaiserHandler(busName: 'payments')
class ConfigurablePaymentHandler extends EventHandler<PaymentProcessedEvent> {
  final PaymentGateway gateway;
  final int retryCount;
  final bool enableLogging;

  ConfigurablePaymentHandler(
    this.gateway, {
    this.retryCount = 3,
    this.enableLogging = true,
  });

  @override
  Future<void> handle(PaymentProcessedEvent event) async {
    if (enableLogging) {
      print('Processing payment with $retryCount retries');
    }
    await gateway.process(event.paymentId);
  }
}
