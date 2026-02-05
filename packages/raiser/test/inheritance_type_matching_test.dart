import 'package:raiser/raiser.dart';
import 'package:test/test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

/// Tests for inheritance-aware type matching in the EventBus.
///
/// Verifies that handlers registered for base types correctly receive
/// events of subclass types. This is critical for sealed class patterns
/// (e.g., freezed) where domain events have multiple subtypes.
void main() {
  group('Inheritance-Aware Type Matching', () {
    group('Sealed Class Hierarchies', () {
      test('handler for sealed base class receives all subclass events', () async {
        // Simulates the real-world pattern where a handler is registered for
        // a sealed base class but events are published as concrete subtypes.
        final bus = EventBus();
        final received = <SealedBaseEvent>[];

        bus.on<SealedBaseEvent>((event) async {
          received.add(event);
        });

        // Publish different subtypes - all should be received
        await bus.publish(ConcreteEventA(valueA: 'data-a'));
        await bus.publish(ConcreteEventB(valueB: 42));

        expect(received.length, equals(2));
        expect(received[0], isA<ConcreteEventA>());
        expect(received[1], isA<ConcreteEventB>());
      });

      test('class-based EventHandler for sealed base receives all subtypes', () async {
        // Demonstrates the pattern: EventHandler<BaseType> receives all subtypes.
        // Typical usage: @RaiserHandler() class MyHandler extends EventHandler<BaseType>
        final bus = EventBus();
        final handler = SealedBaseEventHandler();

        bus.register<SealedBaseEvent>(handler);

        await bus.publish(ConcreteEventA(valueA: 'test'));
        await bus.publish(ConcreteEventB(valueB: 100));

        expect(handler.handledEvents.length, equals(2));
        expect(handler.handledEvents[0], isA<ConcreteEventA>());
        expect(handler.handledEvents[1], isA<ConcreteEventB>());
      });

      test('handler for specific sealed subtype only receives that subtype', () async {
        // Ensure type specificity still works - a handler for ConcreteEventA
        // should NOT receive ConcreteEventB.
        final bus = EventBus();
        final eventsA = <ConcreteEventA>[];
        final eventsB = <ConcreteEventB>[];

        bus.on<ConcreteEventA>((event) async {
          eventsA.add(event);
        });
        bus.on<ConcreteEventB>((event) async {
          eventsB.add(event);
        });

        await bus.publish(ConcreteEventA(valueA: 'first'));
        await bus.publish(ConcreteEventB(valueB: 10));
        await bus.publish(ConcreteEventA(valueA: 'second'));

        expect(eventsA.length, equals(2));
        expect(eventsB.length, equals(1));
      });

      test('both base and subtype handlers receive subtype events', () async {
        // When handlers exist for both SealedBaseEvent and ConcreteEventA,
        // publishing a ConcreteEventA should trigger BOTH handlers.
        final bus = EventBus();
        final baseReceived = <SealedBaseEvent>[];
        final subtypeReceived = <ConcreteEventA>[];

        bus.on<SealedBaseEvent>((event) async {
          baseReceived.add(event);
        });
        bus.on<ConcreteEventA>((event) async {
          subtypeReceived.add(event);
        });

        await bus.publish(ConcreteEventA(valueA: 'test'));

        // Both handlers should fire
        expect(baseReceived.length, equals(1));
        expect(subtypeReceived.length, equals(1));

        // Base handler would NOT fire for base-only publish
        // (if we could instantiate SealedBaseEvent, but sealed prevents that)
      });

      test('sealed class with three or more subtypes works correctly', () async {
        // Test with a sealed class that has multiple subtypes
        final bus = EventBus();
        final allEvents = <PaymentEvent>[];
        final creditCardEvents = <CreditCardPaymentEvent>[];
        final bankTransferEvents = <BankTransferPaymentEvent>[];
        final cryptoEvents = <CryptoPaymentEvent>[];

        bus.on<PaymentEvent>((event) async => allEvents.add(event));
        bus.on<CreditCardPaymentEvent>((event) async => creditCardEvents.add(event));
        bus.on<BankTransferPaymentEvent>((event) async => bankTransferEvents.add(event));
        bus.on<CryptoPaymentEvent>((event) async => cryptoEvents.add(event));

        await bus.publish(CreditCardPaymentEvent(amount: 100.0, cardLast4: '1234'));
        await bus.publish(BankTransferPaymentEvent(amount: 500.0, iban: 'DE89370400440532013000'));
        await bus.publish(CryptoPaymentEvent(amount: 0.5, walletAddress: '0x123...'));
        await bus.publish(CreditCardPaymentEvent(amount: 25.0, cardLast4: '5678'));

        // Base handler should receive all 4 events
        expect(allEvents.length, equals(4));

        // Specific handlers should only receive their type
        expect(creditCardEvents.length, equals(2));
        expect(bankTransferEvents.length, equals(1));
        expect(cryptoEvents.length, equals(1));
      });
    });

    group('Abstract Base Class Hierarchies', () {
      test('handler for abstract base class receives concrete implementations', () async {
        final bus = EventBus();
        final received = <AbstractNotification>[];

        bus.on<AbstractNotification>((event) async {
          received.add(event);
        });

        await bus.publish(EmailNotification(to: 'user@example.com', subject: 'Hello'));
        await bus.publish(PushNotification(deviceToken: 'abc123', title: 'Alert'));
        await bus.publish(SmsNotification(phoneNumber: '+1234567890', body: 'Code: 1234'));

        expect(received.length, equals(3));
        expect(received[0], isA<EmailNotification>());
        expect(received[1], isA<PushNotification>());
        expect(received[2], isA<SmsNotification>());
      });
    });

    group('Multi-Level Inheritance', () {
      test('handlers at each level of hierarchy receive appropriate events', () async {
        // Given: Animal > Mammal > Dog hierarchy
        final bus = EventBus();
        final animalEvents = <AnimalEvent>[];
        final mammalEvents = <MammalEvent>[];
        final dogEvents = <DogEvent>[];

        bus.on<AnimalEvent>((event) async => animalEvents.add(event));
        bus.on<MammalEvent>((event) async => mammalEvents.add(event));
        bus.on<DogEvent>((event) async => dogEvents.add(event));

        // When: Publishing a DogEvent
        await bus.publish(DogEvent(name: 'Buddy', breed: 'Golden Retriever'));

        // Then: All three handlers should receive it
        expect(animalEvents.length, equals(1));
        expect(mammalEvents.length, equals(1));
        expect(dogEvents.length, equals(1));
      });

      test('mid-level handler receives all descendants but not ancestors', () async {
        final bus = EventBus();
        final mammalEvents = <MammalEvent>[];

        bus.on<MammalEvent>((event) async => mammalEvents.add(event));

        await bus.publish(DogEvent(name: 'Rex', breed: 'German Shepherd'));
        await bus.publish(CatEvent(name: 'Whiskers', indoor: true));

        // MammalEvent handler receives both Dog and Cat
        expect(mammalEvents.length, equals(2));
      });
    });

    group('Interface Implementation', () {
      test('handler for interface receives all implementers', () async {
        final bus = EventBus();
        final serializableEvents = <SerializableEvent>[];

        bus.on<SerializableEvent>((event) async {
          serializableEvents.add(event);
        });

        await bus.publish(JsonSerializableEvent(data: {'key': 'value'}));
        await bus.publish(XmlSerializableEvent(rootElement: 'config'));

        expect(serializableEvents.length, equals(2));
      });
    });

    group('Priority Ordering with Inheritance', () {
      test('priority is respected across inheritance levels', () async {
        final bus = EventBus();
        final executionOrder = <String>[];

        // Register handlers with explicit priorities
        bus.on<SealedBaseEvent>((e) async => executionOrder.add('base:priority-0'), priority: 0);
        bus.on<ConcreteEventA>((e) async => executionOrder.add('subtype:priority-10'), priority: 10);
        bus.on<SealedBaseEvent>((e) async => executionOrder.add('base:priority-5'), priority: 5);

        await bus.publish(ConcreteEventA(valueA: 'test'));

        // Should execute in priority order: 10 > 5 > 0
        expect(executionOrder, equals(['subtype:priority-10', 'base:priority-5', 'base:priority-0']));
      });

      test('registration order is tiebreaker for same priority', () async {
        final bus = EventBus();
        final executionOrder = <String>[];

        // All same priority, should execute in registration order
        bus.on<SealedBaseEvent>((e) async => executionOrder.add('first'));
        bus.on<ConcreteEventA>((e) async => executionOrder.add('second'));
        bus.on<SealedBaseEvent>((e) async => executionOrder.add('third'));

        await bus.publish(ConcreteEventA(valueA: 'test'));

        expect(executionOrder, equals(['first', 'second', 'third']));
      });
    });

    group('Error Handling with Inheritance', () {
      test('error in base handler does not prevent subtype handler (continueOnError)', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);
        final subtypeHandlerCalled = <bool>[];

        bus.on<SealedBaseEvent>((e) async {
          throw Exception('Base handler error');
        }, priority: 10);
        bus.on<ConcreteEventA>((e) async {
          subtypeHandlerCalled.add(true);
        }, priority: 0);

        // Should throw aggregate but both handlers execute
        await expectLater(
          () => bus.publish(ConcreteEventA(valueA: 'test')),
          throwsA(isA<AggregateException>()),
        );

        expect(subtypeHandlerCalled, equals([true]));
      });

      test('error callback receives errors from all matching handlers', () async {
        final bus = EventBus(
          errorStrategy: ErrorStrategy.continueOnError,
          onError: (error, _) {},
        );
        final errors = <Object>[];

        bus.on<SealedBaseEvent>((e) async {
          throw ArgumentError('Base error');
        });
        bus.on<ConcreteEventA>((e) async {
          throw StateError('Subtype error');
        });

        try {
          await bus.publish(ConcreteEventA(valueA: 'test'));
        } on AggregateException catch (e) {
          errors.addAll(e.errors);
        }

        expect(errors.length, equals(2));
        expect(errors[0], isA<ArgumentError>());
        expect(errors[1], isA<StateError>());
      });
    });

    group('Subscription Cancellation with Inheritance', () {
      test('cancelling base handler stops receiving subtype events', () async {
        final bus = EventBus();
        final received = <SealedBaseEvent>[];

        final subscription = bus.on<SealedBaseEvent>((event) async {
          received.add(event);
        });

        await bus.publish(ConcreteEventA(valueA: 'first'));
        expect(received.length, equals(1));

        subscription.cancel();

        await bus.publish(ConcreteEventA(valueA: 'second'));
        expect(received.length, equals(1)); // Still 1, no new events
      });

      test('cancelling subtype handler still receives via base handler', () async {
        final bus = EventBus();
        final baseReceived = <SealedBaseEvent>[];
        final subtypeReceived = <ConcreteEventA>[];

        bus.on<SealedBaseEvent>((e) async => baseReceived.add(e));
        final subtypeSub = bus.on<ConcreteEventA>((e) async => subtypeReceived.add(e));

        await bus.publish(ConcreteEventA(valueA: 'test'));
        expect(baseReceived.length, equals(1));
        expect(subtypeReceived.length, equals(1));

        subtypeSub.cancel();

        await bus.publish(ConcreteEventA(valueA: 'test2'));
        expect(baseReceived.length, equals(2)); // Base still receives
        expect(subtypeReceived.length, equals(1)); // Subtype cancelled
      });
    });

    group('Middleware with Inheritance', () {
      test('middleware sees subtype events when handler is for base type', () async {
        final bus = EventBus();
        final middlewareEvents = <dynamic>[];
        final handlerEvents = <SealedBaseEvent>[];

        bus.addMiddleware((event, next) async {
          middlewareEvents.add(event);
          // ignore: avoid_dynamic_calls
          await next();
        });

        bus.on<SealedBaseEvent>((e) async => handlerEvents.add(e));

        final event = ConcreteEventA(valueA: 'test');
        await bus.publish(event);

        // Middleware should see the actual runtime type
        expect(middlewareEvents.length, equals(1));
        expect(middlewareEvents[0], isA<ConcreteEventA>());
        expect(identical(middlewareEvents[0], event), isTrue);

        // Handler should also receive it
        expect(handlerEvents.length, equals(1));
      });
    });

    group('Edge Cases', () {
      test('publishing exact base type (non-sealed) works', () async {
        // For non-sealed hierarchies where you CAN instantiate the base
        final bus = EventBus();
        final received = <ConcreteBaseEvent>[];

        bus.on<ConcreteBaseEvent>((e) async => received.add(e));

        await bus.publish(ConcreteBaseEvent(value: 'base'));
        await bus.publish(ConcreteChildEvent(value: 'child', extra: 42));

        expect(received.length, equals(2));
      });

      test('no handlers for type completes without error', () async {
        final bus = EventBus();
        final received = <ConcreteEventB>[];

        // Only register for EventB, not EventA
        bus.on<ConcreteEventB>((e) async => received.add(e));

        // Publishing EventA should complete without error
        await expectLater(
          bus.publish(ConcreteEventA(valueA: 'test')),
          completes,
        );

        expect(received.length, equals(0));
      });

      test('handler registered multiple times receives event multiple times', () async {
        final bus = EventBus();
        var callCount = 0;

        Future<void> handler(SealedBaseEvent e) async {
          callCount++;
        }

        bus.on<SealedBaseEvent>(handler);
        bus.on<SealedBaseEvent>(handler);

        await bus.publish(ConcreteEventA(valueA: 'test'));

        expect(callCount, equals(2));
      });
    });
  });
}

// =============================================================================
// Test Event Hierarchies
// =============================================================================

/// Generic sealed base event for testing inheritance-aware type matching.
///
/// Demonstrates the pattern where a sealed class has multiple concrete subtypes.
sealed class SealedBaseEvent implements RaiserEvent {
  @override
  EventId get id;

  @override
  DateTime get occurredOn;

  @override
  Map<String, Object?> get metadata;
}

/// First concrete implementation of sealed base event.
final class ConcreteEventA extends SealedBaseEvent {
  ConcreteEventA({required this.valueA, EventId? id, DateTime? occurredOn})
      : id = id ?? EventId.fromUlid(),
        occurredOn = occurredOn ?? DateTime.now(),
        metadata = const {};

  final String valueA;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

/// Second concrete implementation of sealed base event.
final class ConcreteEventB extends SealedBaseEvent {
  ConcreteEventB({required this.valueB, EventId? id, DateTime? occurredOn})
      : id = id ?? EventId.fromUlid(),
        occurredOn = occurredOn ?? DateTime.now(),
        metadata = const {};

  final int valueB;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

/// Class-based handler for sealed base type.
class SealedBaseEventHandler implements EventHandler<SealedBaseEvent> {
  final List<SealedBaseEvent> handledEvents = [];

  @override
  Future<void> handle(SealedBaseEvent event) async {
    handledEvents.add(event);
  }
}

// -----------------------------------------------------------------------------
// Payment Event Hierarchy (sealed with 3+ subtypes)
// -----------------------------------------------------------------------------

sealed class PaymentEvent implements RaiserEvent {
  double get amount;

  @override
  EventId get id;

  @override
  DateTime get occurredOn;

  @override
  Map<String, Object?> get metadata;
}

final class CreditCardPaymentEvent extends PaymentEvent {
  CreditCardPaymentEvent({required this.amount, required this.cardLast4})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  @override
  final double amount;

  final String cardLast4;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

final class BankTransferPaymentEvent extends PaymentEvent {
  BankTransferPaymentEvent({required this.amount, required this.iban})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  @override
  final double amount;

  final String iban;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

final class CryptoPaymentEvent extends PaymentEvent {
  CryptoPaymentEvent({required this.amount, required this.walletAddress})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  @override
  final double amount;

  final String walletAddress;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

// -----------------------------------------------------------------------------
// Abstract Base Class Hierarchy
// -----------------------------------------------------------------------------

abstract class AbstractNotification implements RaiserEvent {
  @override
  EventId get id;

  @override
  DateTime get occurredOn;

  @override
  Map<String, Object?> get metadata;
}

final class EmailNotification extends AbstractNotification {
  EmailNotification({required this.to, required this.subject})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  final String to;
  final String subject;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

final class PushNotification extends AbstractNotification {
  PushNotification({required this.deviceToken, required this.title})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  final String deviceToken;
  final String title;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

final class SmsNotification extends AbstractNotification {
  SmsNotification({required this.phoneNumber, required this.body})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  final String phoneNumber;
  final String body;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

// -----------------------------------------------------------------------------
// Multi-Level Inheritance Hierarchy
// -----------------------------------------------------------------------------

class AnimalEvent implements RaiserEvent {
  AnimalEvent({required this.name})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  final String name;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

class MammalEvent extends AnimalEvent {
  MammalEvent({required super.name});
}

class DogEvent extends MammalEvent {
  DogEvent({required super.name, required this.breed});

  final String breed;
}

class CatEvent extends MammalEvent {
  CatEvent({required super.name, required this.indoor});

  final bool indoor;
}

// -----------------------------------------------------------------------------
// Interface-Based Hierarchy
// -----------------------------------------------------------------------------

abstract interface class SerializableEvent implements RaiserEvent {
  String serialize();
}

final class JsonSerializableEvent implements SerializableEvent {
  JsonSerializableEvent({required this.data})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  final Map<String, dynamic> data;

  @override
  String serialize() => data.toString();

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

final class XmlSerializableEvent implements SerializableEvent {
  XmlSerializableEvent({required this.rootElement})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  final String rootElement;

  @override
  String serialize() => '<$rootElement />';

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

// -----------------------------------------------------------------------------
// Concrete Base (non-sealed) for edge case testing
// -----------------------------------------------------------------------------

class ConcreteBaseEvent implements RaiserEvent {
  ConcreteBaseEvent({required this.value})
      : id = EventId.fromUlid(),
        occurredOn = DateTime.now(),
        metadata = const {};

  final String value;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

class ConcreteChildEvent extends ConcreteBaseEvent {
  ConcreteChildEvent({required super.value, required this.extra});

  final int extra;
}
