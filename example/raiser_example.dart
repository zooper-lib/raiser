/// Raiser Package Examples
///
/// This file demonstrates all features of the Raiser event bus library,
/// from basic usage to advanced patterns.

import 'package:raiser/raiser.dart';

// ============================================================================
// DOMAIN EVENTS
// ============================================================================

/// Basic domain event for user creation
class UserCreated extends DomainEvent {
  final String userId;
  final String email;

  UserCreated({required this.userId, required this.email, super.aggregateId});

  @override
  Map<String, dynamic> toMetadataMap() => {
        ...super.toMetadataMap(),
        'userId': userId,
        'email': email,
      };
}

/// Event for order placement with aggregate ID
class OrderPlaced extends DomainEvent {
  final String orderId;
  final double amount;
  final List<String> items;

  OrderPlaced({
    required this.orderId,
    required this.amount,
    required this.items,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
        ...super.toMetadataMap(),
        'orderId': orderId,
        'amount': amount,
        'items': items,
      };
}

/// Event for payment processing
class PaymentProcessed extends DomainEvent {
  final String paymentId;
  final String orderId;
  final bool success;

  PaymentProcessed({
    required this.paymentId,
    required this.orderId,
    required this.success,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
        ...super.toMetadataMap(),
        'paymentId': paymentId,
        'orderId': orderId,
        'success': success,
      };
}

// ============================================================================
// CLASS-BASED HANDLERS
// ============================================================================

/// Handler that sends welcome emails
class WelcomeEmailHandler implements EventHandler<UserCreated> {
  @override
  Future<void> handle(UserCreated event) async {
    print('  📧 Sending welcome email to ${event.email}');
    await Future.delayed(Duration(milliseconds: 50)); // Simulate async work
  }
}

/// Handler that logs user creation for analytics
class UserAnalyticsHandler implements EventHandler<UserCreated> {
  @override
  Future<void> handle(UserCreated event) async {
    print('  📊 Logging analytics for user ${event.userId}');
  }
}

/// Handler for inventory management
class InventoryHandler implements EventHandler<OrderPlaced> {
  @override
  Future<void> handle(OrderPlaced event) async {
    print('  📦 Reserving inventory for ${event.items.length} items');
  }
}

// ============================================================================
// EXAMPLES
// ============================================================================

void main() async {
  print('=' * 60);
  print('RAISER EVENT BUS - EXAMPLES');
  print('=' * 60);

  await basicExample();
  await classBasedHandlerExample();
  await priorityExample();
  await subscriptionExample();
  await errorHandlingExamples();
  await aggregateIdExample();
  await metadataExample();

  print('\n✅ All examples completed!');
}


/// Basic usage with function handlers
Future<void> basicExample() async {
  print('\n--- BASIC EXAMPLE ---');

  final bus = EventBus();

  // Register a simple function handler
  bus.on<UserCreated>((event) async {
    print('  👤 User created: ${event.userId} (${event.email})');
  });

  // Publish an event
  await bus.publish(UserCreated(
    userId: 'user-001',
    email: 'alice@example.com',
  ));
}

/// Using class-based handlers for better organization
Future<void> classBasedHandlerExample() async {
  print('\n--- CLASS-BASED HANDLERS ---');

  final bus = EventBus();

  // Register class-based handlers
  bus.register<UserCreated>(WelcomeEmailHandler());
  bus.register<UserCreated>(UserAnalyticsHandler());
  bus.register<OrderPlaced>(InventoryHandler());

  // Publish events
  await bus.publish(UserCreated(
    userId: 'user-002',
    email: 'bob@example.com',
  ));

  await bus.publish(OrderPlaced(
    orderId: 'order-001',
    amount: 99.99,
    items: ['Widget A', 'Widget B'],
    aggregateId: 'user-002',
  ));
}

/// Handler priority demonstration
Future<void> priorityExample() async {
  print('\n--- PRIORITY ORDERING ---');

  final bus = EventBus();
  final executionOrder = <String>[];

  // Register handlers with different priorities
  bus.on<UserCreated>((event) async {
    executionOrder.add('Normal (0)');
    print('  ⚡ Normal priority handler');
  }, priority: 0);

  bus.on<UserCreated>((event) async {
    executionOrder.add('High (10)');
    print('  🔥 High priority handler');
  }, priority: 10);

  bus.on<UserCreated>((event) async {
    executionOrder.add('Low (-5)');
    print('  🐢 Low priority handler');
  }, priority: -5);

  bus.on<UserCreated>((event) async {
    executionOrder.add('Critical (100)');
    print('  🚨 Critical priority handler');
  }, priority: 100);

  await bus.publish(UserCreated(userId: 'test', email: 'test@example.com'));

  print('  Execution order: ${executionOrder.join(' → ')}');
}

/// Subscription management and cancellation
Future<void> subscriptionExample() async {
  print('\n--- SUBSCRIPTION MANAGEMENT ---');

  final bus = EventBus();
  var callCount = 0;

  // Register and get subscription
  final subscription = bus.on<UserCreated>((event) async {
    callCount++;
    print('  📬 Handler called (count: $callCount)');
  });

  print('  Subscription active: ${!subscription.isCancelled}');

  // First publish - handler is active
  await bus.publish(UserCreated(userId: '1', email: 'a@test.com'));

  // Cancel subscription
  subscription.cancel();
  print('  Subscription cancelled: ${subscription.isCancelled}');

  // Second publish - handler won't be called
  await bus.publish(UserCreated(userId: '2', email: 'b@test.com'));

  print('  Total calls: $callCount (should be 1)');
}


/// Error handling strategies demonstration
Future<void> errorHandlingExamples() async {
  print('\n--- ERROR HANDLING STRATEGIES ---');

  await errorStrategyStop();
  await errorStrategyContinue();
  await errorStrategySwallow();
}

/// ErrorStrategy.stop - Halts on first error
Future<void> errorStrategyStop() async {
  print('\n  [ErrorStrategy.stop]');

  final bus = EventBus(errorStrategy: ErrorStrategy.stop);

  bus.on<PaymentProcessed>((event) async {
    print('    Handler 1: Processing...');
    throw Exception('Payment gateway timeout');
  });

  bus.on<PaymentProcessed>((event) async {
    print('    Handler 2: This should NOT run');
  });

  try {
    await bus.publish(PaymentProcessed(
      paymentId: 'pay-001',
      orderId: 'order-001',
      success: false,
    ));
  } catch (e) {
    print('    ❌ Caught: $e');
  }
}

/// ErrorStrategy.continueOnError - Collects all errors
Future<void> errorStrategyContinue() async {
  print('\n  [ErrorStrategy.continueOnError]');

  final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);

  bus.on<PaymentProcessed>((event) async {
    print('    Handler 1: Fails');
    throw Exception('Error 1');
  });

  bus.on<PaymentProcessed>((event) async {
    print('    Handler 2: Also fails');
    throw Exception('Error 2');
  });

  bus.on<PaymentProcessed>((event) async {
    print('    Handler 3: Succeeds ✓');
  });

  try {
    await bus.publish(PaymentProcessed(
      paymentId: 'pay-002',
      orderId: 'order-002',
      success: false,
    ));
  } on AggregateException catch (e) {
    print('    ❌ AggregateException: ${e.errors.length} errors collected');
    for (var i = 0; i < e.errors.length; i++) {
      print('       - ${e.errors[i]}');
    }
  }
}

/// ErrorStrategy.swallow - Logs errors but continues
Future<void> errorStrategySwallow() async {
  print('\n  [ErrorStrategy.swallow]');

  final errors = <String>[];

  final bus = EventBus(
    errorStrategy: ErrorStrategy.swallow,
    onError: (error, stackTrace) {
      errors.add(error.toString());
      print('    ⚠️ Error logged: $error');
    },
  );

  bus.on<PaymentProcessed>((event) async {
    throw Exception('Silent failure');
  });

  bus.on<PaymentProcessed>((event) async {
    print('    Handler 2: Runs despite previous error ✓');
  });

  // No exception thrown
  await bus.publish(PaymentProcessed(
    paymentId: 'pay-003',
    orderId: 'order-003',
    success: true,
  ));

  print('    Errors collected via callback: ${errors.length}');
}

/// Using aggregate IDs for DDD patterns
Future<void> aggregateIdExample() async {
  print('\n--- AGGREGATE ID PATTERN ---');

  final bus = EventBus();
  final userEvents = <DomainEvent>[];

  // Track all events for a specific user aggregate
  bus.on<UserCreated>((event) async {
    if (event.aggregateId != null) {
      userEvents.add(event);
    }
    print('  👤 User ${event.userId} created (aggregate: ${event.aggregateId})');
  });

  bus.on<OrderPlaced>((event) async {
    if (event.aggregateId != null) {
      userEvents.add(event);
    }
    print('  🛒 Order ${event.orderId} placed (aggregate: ${event.aggregateId})');
  });

  // Events linked to user aggregate
  const userId = 'user-100';

  await bus.publish(UserCreated(
    userId: userId,
    email: 'customer@shop.com',
    aggregateId: userId,
  ));

  await bus.publish(OrderPlaced(
    orderId: 'order-A',
    amount: 150.00,
    items: ['Product X'],
    aggregateId: userId,
  ));

  await bus.publish(OrderPlaced(
    orderId: 'order-B',
    amount: 75.50,
    items: ['Product Y', 'Product Z'],
    aggregateId: userId,
  ));

  print('  Events for aggregate $userId: ${userEvents.length}');
}

/// Event metadata and serialization
Future<void> metadataExample() async {
  print('\n--- EVENT METADATA ---');

  final event = OrderPlaced(
    orderId: 'order-999',
    amount: 299.99,
    items: ['Premium Widget', 'Deluxe Gadget'],
    aggregateId: 'user-500',
  );

  print('  Event ID: ${event.id}');
  print('  Timestamp: ${event.timestamp}');
  print('  Aggregate ID: ${event.aggregateId}');
  print('  Metadata Map:');

  final metadata = event.toMetadataMap();
  metadata.forEach((key, value) {
    print('    $key: $value');
  });
}
