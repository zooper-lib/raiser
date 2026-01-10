import 'package:raiser/raiser.dart';
import 'package:test/test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

void main() {
  group('Public API exports', () {
    test('RaiserEvent is exported and usable', () {
      // Verify RaiserEvent can be implemented via a mixin.
      final event = _TestEvent();
      expect(event.id, isNotEmpty);
      expect(event.occurredOn, isA<DateTime>());
    });

    test('EventBus is exported and usable', () {
      final bus = EventBus();
      expect(bus, isA<EventBus>());
    });

    test('EventHandler is exported and usable', () {
      final handler = _TestHandler();
      expect(handler, isA<EventHandler<_TestEvent>>());
    });

    test('Subscription is exported and usable', () {
      final bus = EventBus();
      final subscription = bus.on<_TestEvent>((event) async {});
      expect(subscription, isA<Subscription>());
      expect(subscription.isCancelled, isFalse);
    });

    test('ErrorStrategy is exported and usable', () {
      expect(ErrorStrategy.stop, isA<ErrorStrategy>());
      expect(ErrorStrategy.continueOnError, isA<ErrorStrategy>());
      expect(ErrorStrategy.swallow, isA<ErrorStrategy>());
    });

    test('AggregateException is exported and usable', () {
      final exception = AggregateException([Exception('test')], [StackTrace.current]);
      expect(exception, isA<AggregateException>());
      expect(exception.errors.length, equals(1));
    });
  });
}

final class _TestEvent implements RaiserEvent {
  _TestEvent({
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

class _TestHandler implements EventHandler<_TestEvent> {
  @override
  Future<void> handle(_TestEvent event) async {}
}
