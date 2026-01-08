/// Example domain events for testing the Raiser code generator.
///
/// These events are used by the example handlers and middleware
/// to demonstrate various generator configurations.

import 'package:raiser/raiser.dart';

/// Event fired when a user is created.
class UserCreatedEvent extends RaiserEvent {
  final String userId;
  final String email;

  UserCreatedEvent({
    required this.userId,
    required this.email,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'userId': userId,
    'email': email,
  };
}

/// Event fired when an order is placed.
class OrderPlacedEvent extends RaiserEvent {
  final String orderId;
  final double amount;

  OrderPlacedEvent({
    required this.orderId,
    required this.amount,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'orderId': orderId,
    'amount': amount,
  };
}

/// Event fired when a payment is processed.
class PaymentProcessedEvent extends RaiserEvent {
  final String paymentId;
  final bool success;

  PaymentProcessedEvent({
    required this.paymentId,
    required this.success,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'paymentId': paymentId,
    'success': success,
  };
}

/// Event fired when inventory is updated.
class InventoryUpdatedEvent extends RaiserEvent {
  final String productId;
  final int quantity;

  InventoryUpdatedEvent({
    required this.productId,
    required this.quantity,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
    ...super.toMetadataMap(),
    'productId': productId,
    'quantity': quantity,
  };
}
