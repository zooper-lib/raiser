import 'package:raiser/raiser.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

/// Event fired when a user is created.
final class UserCreatedEvent implements RaiserEvent {
  UserCreatedEvent({
    required this.userId,
    required this.email,
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final String userId;
  final String email;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

/// Event fired when an order is placed.
final class OrderPlacedEvent implements RaiserEvent {
  OrderPlacedEvent({
    required this.orderId,
    required this.amount,
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final String orderId;
  final double amount;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

/// Event fired when a payment is processed.
final class PaymentProcessedEvent implements RaiserEvent {
  PaymentProcessedEvent({
    required this.paymentId,
    required this.success,
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final String paymentId;
  final bool success;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

/// Event fired when inventory is updated.
final class InventoryUpdatedEvent implements RaiserEvent {
  InventoryUpdatedEvent({
    required this.productId,
    required this.quantity,
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final String productId;
  final int quantity;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}
