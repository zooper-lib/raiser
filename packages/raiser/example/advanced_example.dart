// Raiser Advanced Examples
//
// Demonstrates advanced patterns and real-world use cases:
// - Event sourcing patterns
// - Saga/Process manager pattern
// - Event replay and projection
// - Multi-bus architecture
// - Testing patterns

import 'package:raiser/raiser.dart';

// ============================================================================
// DOMAIN EVENTS FOR E-COMMERCE SCENARIO
// ============================================================================

class CartItemAdded extends RaiserEvent {
  final String productId;
  final int quantity;
  final double price;

  CartItemAdded({
    required this.productId,
    required this.quantity,
    required this.price,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'productId': productId,
    'quantity': quantity,
    'price': price,
  };
}

class CartItemRemoved extends RaiserEvent {
  final String productId;

  CartItemRemoved({required this.productId, super.aggregateId});

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'productId': productId,
  };
}

class CheckoutStarted extends RaiserEvent {
  final double totalAmount;

  CheckoutStarted({required this.totalAmount, super.aggregateId});

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'totalAmount': totalAmount,
  };
}

class PaymentReceived extends RaiserEvent {
  final String transactionId;
  final double amount;

  PaymentReceived({
    required this.transactionId,
    required this.amount,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'transactionId': transactionId,
    'amount': amount,
  };
}

class OrderShipped extends RaiserEvent {
  final String trackingNumber;

  OrderShipped({required this.trackingNumber, super.aggregateId});

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'trackingNumber': trackingNumber,
  };
}

// ============================================================================
// EVENT STORE - Simple in-memory implementation
// ============================================================================

class EventStore {
  final List<RaiserEvent> _events = [];
  final EventBus _bus;

  EventStore(this._bus);

  /// Append and publish an event
  Future<void> append(RaiserEvent event) async {
    _events.add(event);
    await _bus.publish(event);
  }

  /// Get all events for an aggregate
  List<RaiserEvent> getEventsForAggregate(String aggregateId) {
    return _events.where((e) => e.aggregateId == aggregateId).toList();
  }

  /// Get all events of a specific type
  List<T> getEventsByType<T extends RaiserEvent>() {
    return _events.whereType<T>().toList();
  }

  /// Replay events to rebuild state
  Future<void> replay(EventBus targetBus) async {
    for (final event in _events) {
      await _publishTyped(targetBus, event);
    }
  }

  Future<void> _publishTyped(EventBus bus, RaiserEvent event) async {
    switch (event) {
      case CartItemAdded e:
        await bus.publish(e);
      case CartItemRemoved e:
        await bus.publish(e);
      case CheckoutStarted e:
        await bus.publish(e);
      case PaymentReceived e:
        await bus.publish(e);
      case OrderShipped e:
        await bus.publish(e);
    }
  }
}

// ============================================================================
// READ MODEL / PROJECTION
// ============================================================================

/// Cart projection built from events
class CartProjection implements EventHandler<CartItemAdded> {
  final Map<String, Map<String, CartItem>> _carts = {};

  Map<String, CartItem> getCart(String cartId) => _carts[cartId] ?? {};

  double getTotal(String cartId) {
    final cart = getCart(cartId);
    return cart.values.fold(0.0, (sum, item) => sum + item.total);
  }

  @override
  Future<void> handle(CartItemAdded event) async {
    final cartId = event.aggregateId ?? 'default';
    _carts.putIfAbsent(cartId, () => {});

    final existing = _carts[cartId]![event.productId];
    if (existing != null) {
      _carts[cartId]![event.productId] = CartItem(
        productId: event.productId,
        quantity: existing.quantity + event.quantity,
        price: event.price,
      );
    } else {
      _carts[cartId]![event.productId] = CartItem(
        productId: event.productId,
        quantity: event.quantity,
        price: event.price,
      );
    }
  }

  void handleRemoval(CartItemRemoved event) {
    final cartId = event.aggregateId ?? 'default';
    _carts[cartId]?.remove(event.productId);
  }
}

class CartItem {
  final String productId;
  final int quantity;
  final double price;

  CartItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

// ============================================================================
// SAGA / PROCESS MANAGER
// ============================================================================

/// Order fulfillment saga coordinating multiple steps
class OrderFulfillmentSaga {
  final EventBus _bus;
  final Map<String, OrderState> _orderStates = {};

  OrderFulfillmentSaga(this._bus) {
    _bus.on<CheckoutStarted>(_onCheckoutStarted);
    _bus.on<PaymentReceived>(_onPaymentReceived);
    _bus.on<OrderShipped>(_onOrderShipped);
  }

  Future<void> _onCheckoutStarted(CheckoutStarted event) async {
    final orderId = event.aggregateId ?? event.id;
    _orderStates[orderId] = OrderState(
      orderId: orderId,
      status: 'awaiting_payment',
      amount: event.totalAmount,
    );
    print('  📋 Saga: Order $orderId awaiting payment');
  }

  Future<void> _onPaymentReceived(PaymentReceived event) async {
    final orderId = event.aggregateId;
    if (orderId != null && _orderStates.containsKey(orderId)) {
      _orderStates[orderId] = _orderStates[orderId]!.copyWith(
        status: 'paid',
        transactionId: event.transactionId,
      );
      print('  📋 Saga: Order $orderId paid, ready for shipping');
    }
  }

  Future<void> _onOrderShipped(OrderShipped event) async {
    final orderId = event.aggregateId;
    if (orderId != null && _orderStates.containsKey(orderId)) {
      _orderStates[orderId] = _orderStates[orderId]!.copyWith(
        status: 'shipped',
        trackingNumber: event.trackingNumber,
      );
      print('  📋 Saga: Order $orderId shipped!');
    }
  }

  OrderState? getOrderState(String orderId) => _orderStates[orderId];
}

class OrderState {
  final String orderId;
  final String status;
  final double amount;
  final String? transactionId;
  final String? trackingNumber;

  OrderState({
    required this.orderId,
    required this.status,
    required this.amount,
    this.transactionId,
    this.trackingNumber,
  });

  OrderState copyWith({
    String? status,
    String? transactionId,
    String? trackingNumber,
  }) {
    return OrderState(
      orderId: orderId,
      status: status ?? this.status,
      amount: amount,
      transactionId: transactionId ?? this.transactionId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }
}

// ============================================================================
// MULTI-BUS ARCHITECTURE
// ============================================================================

/// Demonstrates separate buses for different concerns
class MultiBusArchitecture {
  /// Main domain event bus
  final EventBus domainBus;

  /// Integration events for external systems
  final EventBus integrationBus;

  /// Internal notifications (logging, metrics)
  final EventBus notificationBus;

  MultiBusArchitecture()
    : domainBus = EventBus(errorStrategy: ErrorStrategy.stop),
      integrationBus = EventBus(errorStrategy: ErrorStrategy.continueOnError),
      notificationBus = EventBus(errorStrategy: ErrorStrategy.swallow);

  /// Bridge domain events to other buses
  void setupBridges() {
    // Forward payment events to integration bus
    domainBus.on<PaymentReceived>((event) async {
      await integrationBus.publish(event);
    });

    // Forward all events to notification bus for logging
    domainBus.on<PaymentReceived>((event) async {
      await notificationBus.publish(event);
    });
  }
}

// ============================================================================
// MAIN - RUN ALL ADVANCED EXAMPLES
// ============================================================================

void main() async {
  print('=' * 60);
  print('RAISER - ADVANCED EXAMPLES');
  print('=' * 60);

  await eventSourcingExample();
  await sagaExample();
  await projectionReplayExample();
  await multiBusExample();

  print('\n✅ All advanced examples completed!');
}

/// Event sourcing with event store
Future<void> eventSourcingExample() async {
  print('\n--- EVENT SOURCING PATTERN ---');

  final bus = EventBus();
  final store = EventStore(bus);

  const cartId = 'cart-001';

  // Record events
  await store.append(
    CartItemAdded(
      productId: 'SKU-A',
      quantity: 2,
      price: 29.99,
      aggregateId: cartId,
    ),
  );

  await store.append(
    CartItemAdded(
      productId: 'SKU-B',
      quantity: 1,
      price: 49.99,
      aggregateId: cartId,
    ),
  );

  await store.append(CartItemRemoved(productId: 'SKU-A', aggregateId: cartId));

  // Query event history
  final cartEvents = store.getEventsForAggregate(cartId);
  print('  Events for $cartId: ${cartEvents.length}');
  for (final event in cartEvents) {
    print('    - ${event.runtimeType} at ${event.timestamp}');
  }
}

/// Saga pattern for order fulfillment
Future<void> sagaExample() async {
  print('\n--- SAGA PATTERN ---');

  final bus = EventBus();
  final saga = OrderFulfillmentSaga(bus);

  const orderId = 'order-500';

  // Simulate order flow
  await bus.publish(CheckoutStarted(totalAmount: 199.99, aggregateId: orderId));

  await bus.publish(
    PaymentReceived(
      transactionId: 'txn-12345',
      amount: 199.99,
      aggregateId: orderId,
    ),
  );

  await bus.publish(
    OrderShipped(trackingNumber: 'TRACK-ABC123', aggregateId: orderId),
  );

  // Check final state
  final state = saga.getOrderState(orderId);
  print('  Final order state:');
  print('    Status: ${state?.status}');
  print('    Transaction: ${state?.transactionId}');
  print('    Tracking: ${state?.trackingNumber}');
}

/// Projection rebuild via event replay
Future<void> projectionReplayExample() async {
  print('\n--- PROJECTION REPLAY ---');

  // Original bus and store
  final originalBus = EventBus();
  final store = EventStore(originalBus);
  final originalProjection = CartProjection();

  originalBus.register<CartItemAdded>(originalProjection);

  const cartId = 'cart-replay';

  // Add items
  await store.append(
    CartItemAdded(
      productId: 'ITEM-1',
      quantity: 3,
      price: 10.00,
      aggregateId: cartId,
    ),
  );

  await store.append(
    CartItemAdded(
      productId: 'ITEM-2',
      quantity: 2,
      price: 25.00,
      aggregateId: cartId,
    ),
  );

  print(
    '  Original projection total: \$${originalProjection.getTotal(cartId)}',
  );

  // Create new projection and replay events
  final replayBus = EventBus();
  final rebuiltProjection = CartProjection();
  replayBus.register<CartItemAdded>(rebuiltProjection);

  print('  Replaying ${store.getEventsForAggregate(cartId).length} events...');
  await store.replay(replayBus);

  print('  Rebuilt projection total: \$${rebuiltProjection.getTotal(cartId)}');
}

/// Multi-bus architecture example
Future<void> multiBusExample() async {
  print('\n--- MULTI-BUS ARCHITECTURE ---');

  final arch = MultiBusArchitecture();

  // Setup handlers on different buses
  arch.domainBus.on<PaymentReceived>((event) async {
    print('  💰 Domain: Payment ${event.transactionId} processed');
  });

  arch.integrationBus.on<PaymentReceived>((event) async {
    print('  🔗 Integration: Notifying external payment gateway');
  });

  arch.notificationBus.on<PaymentReceived>((event) async {
    print('  📝 Notification: Logging payment for audit');
  });

  arch.setupBridges();

  // Publish to domain bus - bridges forward to others
  await arch.domainBus.publish(
    PaymentReceived(
      transactionId: 'multi-bus-txn',
      amount: 500.00,
      aggregateId: 'order-multi',
    ),
  );
}
