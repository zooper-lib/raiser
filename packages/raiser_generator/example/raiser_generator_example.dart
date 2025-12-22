/// Raiser Generator Example
///
/// This example demonstrates the usage of @RaiserHandler and @RaiserMiddleware
/// annotations for automatic handler and middleware discovery.
///
/// To generate the registration code, run:
/// ```bash
/// cd example
/// dart run build_runner build
/// ```
library raiser_generator_example;

import 'package:raiser/raiser.dart';
import 'package:raiser_generator_example/raiser.g.dart';

import 'lib/events.dart';
import 'lib/handlers.dart';
import 'lib/services.dart';

/// Example usage of the generated code.
void main() async {
  print('=== Raiser Generator Example ===\n');

  // Create the event bus
  final bus = EventBus();

  // Initialize all handlers without dependencies (generated function)
  initRaiser(bus);

  print('Handlers registered. Publishing events...\n');

  // Publish a UserCreatedEvent
  print('--- Publishing UserCreatedEvent ---');
  await bus.publish(UserCreatedEvent(
    userId: 'user-001',
    email: 'alice@example.com',
  ));

  print('\n--- Publishing OrderPlacedEvent ---');
  await bus.publish(OrderPlacedEvent(
    orderId: 'order-001',
    amount: 99.99,
  ));

  print('\n=== Example with Dependency Injection ===\n');

  // Create a new bus for the DI example
  final diBus = EventBus();

  // Create concrete dependencies
  final logger = ConsoleLogger();
  final repository = InMemoryOrderRepository();
  final notifications = ConsoleNotificationService();

  // Initialize with factory functions for dependency injection
  // The factory functions capture the dependencies in closures
  initRaiserWithFactories(
    diBus,
    createLoggingUserHandler: () => LoggingUserHandler(logger),
    createOrderProcessingHandler: () =>
        OrderProcessingHandler(repository, notifications),
  );

  print('DI Handlers registered. Publishing events...\n');

  print('--- Publishing UserCreatedEvent (with DI) ---');
  await diBus.publish(UserCreatedEvent(
    userId: 'user-002',
    email: 'bob@example.com',
  ));

  print('\n--- Publishing OrderPlacedEvent (with DI) ---');
  await diBus.publish(OrderPlacedEvent(
    orderId: 'order-002',
    amount: 149.99,
  ));

  print('\n=== Named Bus Example ===\n');

  // Create named buses
  final paymentsBus = EventBus();
  final inventoryBus = EventBus();

  // Initialize handlers for named buses
  initRaiserPaymentsBus(paymentsBus);
  initRaiserInventoryBus(inventoryBus);

  print('Named bus handlers registered. Publishing events...\n');

  print('--- Publishing PaymentProcessedEvent (payments bus) ---');
  await paymentsBus.publish(PaymentProcessedEvent(
    paymentId: 'pay-001',
    success: true,
  ));

  print('\n--- Publishing InventoryUpdatedEvent (inventory bus) ---');
  await inventoryBus.publish(InventoryUpdatedEvent(
    productId: 'prod-001',
    quantity: 50,
  ));

  print('\n=== Example Complete ===');
}
