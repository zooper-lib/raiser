import 'package:raiser/raiser.dart';
import 'package:test/test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

/// Edge case and stress tests for the EventBus.
///
/// These tests verify behavior in unusual or extreme scenarios.
final class TestEvent implements RaiserEvent {
  TestEvent(
    this.value, {
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final String value;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;

  Map<String, dynamic> toMetadataMap() => {'value': value};
}

/// Handler that tracks invocations.
class CountingHandler implements EventHandler<TestEvent> {
  int count = 0;

  @override
  Future<void> handle(TestEvent event) async {
    count++;
  }
}

void main() {
  group('EventBus Edge Cases', () {
    group('Handler Registration Edge Cases', () {
      test('can register same handler instance twice', () async {
        final bus = EventBus();
        final handler = CountingHandler();

        bus.register<TestEvent>(handler);
        bus.register<TestEvent>(handler);

        await bus.publish(TestEvent('test'));

        // Handler invoked twice because registered twice
        expect(handler.count, equals(2));
      });

      test('cancelling one subscription does not affect others', () async {
        final bus = EventBus();
        final handler1 = CountingHandler();
        final handler2 = CountingHandler();

        final sub1 = bus.register<TestEvent>(handler1);
        bus.register<TestEvent>(handler2);

        sub1.cancel();
        await bus.publish(TestEvent('test'));

        expect(handler1.count, equals(0));
        expect(handler2.count, equals(1));
      });

      test('double cancel is safe', () {
        final bus = EventBus();
        final handler = CountingHandler();

        final subscription = bus.register<TestEvent>(handler);

        subscription.cancel();
        subscription.cancel(); // Should not throw

        expect(subscription.isCancelled, isTrue);
      });

      test('registering after cancel uses new subscription', () async {
        final bus = EventBus();
        final handler = CountingHandler();

        final sub1 = bus.register<TestEvent>(handler);
        sub1.cancel();

        bus.register<TestEvent>(handler);
        await bus.publish(TestEvent('test'));

        expect(handler.count, equals(1));
      });
    });

    group('Priority Edge Cases', () {
      test('extreme priority values work correctly', () async {
        final bus = EventBus();
        final order = <int>[];

        bus.on<TestEvent>((e) async => order.add(0), priority: 0);
        bus.on<TestEvent>((e) async => order.add(-2147483648), priority: -2147483648);
        bus.on<TestEvent>((e) async => order.add(2147483647), priority: 2147483647);

        await bus.publish(TestEvent('test'));

        expect(order, equals([2147483647, 0, -2147483648]));
      });

      test('many handlers with same priority maintain order', () async {
        final bus = EventBus();
        final order = <int>[];

        for (var i = 0; i < 100; i++) {
          final index = i;
          bus.on<TestEvent>((e) async => order.add(index), priority: 0);
        }

        await bus.publish(TestEvent('test'));

        // Should maintain registration order
        expect(order, equals(List.generate(100, (i) => i)));
      });
    });

    group('Concurrent Publish Edge Cases', () {
      test('handlers can publish events recursively', () async {
        final bus = EventBus();
        final received = <String>[];
        var depth = 0;

        bus.on<TestEvent>((event) async {
          received.add(event.value);
          if (depth < 3) {
            depth++;
            await bus.publish(TestEvent('nested-$depth'));
          }
        });

        await bus.publish(TestEvent('initial'));

        expect(received, equals(['initial', 'nested-1', 'nested-2', 'nested-3']));
      });

      test('many concurrent publishes complete correctly', () async {
        final bus = EventBus();
        final received = <String>{};

        bus.on<TestEvent>((event) async {
          await Future.delayed(const Duration(milliseconds: 1));
          received.add(event.value);
        });

        await Future.wait(List.generate(100, (i) => bus.publish(TestEvent('event-$i'))));

        expect(received.length, equals(100));
      });
    });

    group('Empty and Null Edge Cases', () {
      test('publish with no handlers is no-op', () async {
        final bus = EventBus();

        // Should complete without error
        await bus.publish(TestEvent('test'));
      });

      test('empty event value works', () async {
        final bus = EventBus();
        String? received;

        bus.on<TestEvent>((event) async {
          received = event.value;
        });

        await bus.publish(TestEvent(''));

        expect(received, equals(''));
      });
    });

    group('Handler Exception Edge Cases', () {
      test('handler throwing synchronously is caught', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.swallow);
        var invoked = false;

        bus.on<TestEvent>((event) {
          invoked = true;
          throw StateError('sync error');
        });

        await bus.publish(TestEvent('test'));

        expect(invoked, isTrue);
      });

      test('handler returning failed future is caught', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.swallow);
        var invoked = false;

        bus.on<TestEvent>((event) {
          invoked = true;
          return Future.error(StateError('async error'));
        });

        await bus.publish(TestEvent('test'));

        expect(invoked, isTrue);
      });

      test('continueOnError collects all errors', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);

        bus.on<TestEvent>((event) async {
          throw Exception('error 1');
        });
        bus.on<TestEvent>((event) async {
          throw Exception('error 2');
        });
        bus.on<TestEvent>((event) async {
          throw Exception('error 3');
        });

        expect(() => bus.publish(TestEvent('test')), throwsA(isA<AggregateException>().having((e) => e.errors.length, 'error count', equals(3))));
      });
    });

    group('Type Safety Edge Cases', () {
      test('unrelated event types do not trigger handler', () async {
        final bus = EventBus();
        var invoked = false;

        bus.on<TestEvent>((event) async {
          invoked = true;
        });

        // Publish a different event type - need to create one
        await bus.publish(OtherEvent(42));

        expect(invoked, isFalse);
      });
    });

    group('Memory and Cleanup Edge Cases', () {
      test('cancelled handlers are removed from internal storage', () async {
        final bus = EventBus();
        final subscriptions = <Subscription>[];

        for (var i = 0; i < 1000; i++) {
          subscriptions.add(bus.on<TestEvent>((e) async {}));
        }

        // Cancel all
        for (final sub in subscriptions) {
          sub.cancel();
        }

        // Publish should be fast with no handlers
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 100; i++) {
          await bus.publish(TestEvent('test'));
        }
        stopwatch.stop();

        // Should complete quickly (< 100ms for 100 publishes)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });

  group('Middleware Edge Cases', () {
    test('adding middleware during publish is safe', () async {
      final bus = EventBus();
      final order = <String>[];

      bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
        order.add('outer:before');
        // Add another middleware during execution
        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          order.add('dynamic:before');
          await next();
          order.add('dynamic:after');
        });
        await next();
        order.add('outer:after');
      });

      bus.on<TestEvent>((e) async => order.add('handler'));

      await bus.publish(TestEvent('first'));
      order.add('---');
      await bus.publish(TestEvent('second'));

      // First publish: only outer middleware
      // Second publish: both middlewares
      expect(order[0], equals('outer:before'));
      expect(order[1], equals('handler'));
      expect(order[2], equals('outer:after'));
      expect(order[3], equals('---'));
      // Second publish has both
      expect(order.sublist(4), contains('dynamic:before'));
    });

    test('removing middleware during publish is safe', () async {
      final bus = EventBus();
      final order = <String>[];
      late Subscription middlewareSub;

      middlewareSub = bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
        order.add('middleware:before');
        middlewareSub.cancel(); // Cancel self
        await next();
        order.add('middleware:after');
      });

      bus.on<TestEvent>((e) async => order.add('handler'));

      await bus.publish(TestEvent('first'));
      order.add('---');
      await bus.publish(TestEvent('second'));

      expect(
        order,
        equals([
          'middleware:before',
          'handler',
          'middleware:after',
          '---',
          'handler', // Second publish has no middleware
        ]),
      );
    });

    test('deeply nested middleware chain works', () async {
      final bus = EventBus();
      final order = <String>[];

      for (var i = 0; i < 50; i++) {
        final index = i;
        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          order.add('m$index:before');
          await next();
          order.add('m$index:after');
        }, priority: 50 - i); // Highest priority first
      }

      bus.on<TestEvent>((e) async => order.add('handler'));

      await bus.publish(TestEvent('test'));

      // 50 befores + handler + 50 afters = 101
      expect(order.length, equals(101));
      expect(order[0], equals('m0:before'));
      expect(order[49], equals('m49:before'));
      expect(order[50], equals('handler'));
      expect(order[51], equals('m49:after'));
      expect(order[100], equals('m0:after'));
    });
  });
}

/// Another event type for type isolation tests.
final class OtherEvent implements RaiserEvent {
  OtherEvent(
    this.value, {
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final int value;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;

  Map<String, dynamic> toMetadataMap() => {'value': value};
}
