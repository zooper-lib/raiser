import 'package:raiser/raiser.dart';
import 'package:test/test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

/// Simple event for middleware testing.
final class TestEvent implements RaiserEvent {
  TestEvent(
    this.message, {
    EventId? eventId,
    DateTime? occurredOn,
    Map<String, Object?> metadata = const {},
  }) : id = eventId ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata);

  final String message;

  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;

  Map<String, dynamic> toMetadataMap() => {'message': message};
}

/// Another event type for testing type-specific behavior.
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

/// Simple logging middleware for testing.
class LoggingMiddleware {
  final List<String> logs = [];

  Future<void> call(dynamic event, Future<void> Function() next) async {
    logs.add('before:${event.runtimeType}');
    await next();
    logs.add('after:${event.runtimeType}');
  }
}

/// Middleware that tracks execution order.
class OrderTrackingMiddleware {
  final String id;
  final List<String> executionLog;

  OrderTrackingMiddleware(this.id, this.executionLog);

  Future<void> call(dynamic event, Future<void> Function() next) async {
    executionLog.add('$id:before');
    await next();
    executionLog.add('$id:after');
  }
}

/// Middleware that can short-circuit the pipeline.
class ShortCircuitMiddleware {
  final bool shouldShortCircuit;
  bool wasInvoked = false;

  ShortCircuitMiddleware({this.shouldShortCircuit = true});

  Future<void> call(dynamic event, Future<void> Function() next) async {
    wasInvoked = true;
    if (!shouldShortCircuit) {
      await next();
    }
    // If shouldShortCircuit is true, we don't call next()
  }
}

/// Middleware that throws an error.
class ErrorMiddleware {
  final String errorMessage;

  ErrorMiddleware(this.errorMessage);

  Future<void> call(dynamic event, Future<void> Function() next) async {
    throw Exception(errorMessage);
  }
}

/// Middleware that modifies a shared state.
class StateModifyingMiddleware {
  final Map<String, dynamic> state;
  final String key;
  final dynamic value;

  StateModifyingMiddleware(this.state, this.key, this.value);

  Future<void> call(dynamic event, Future<void> Function() next) async {
    state[key] = value;
    await next();
  }
}

/// Handler that tracks received events.
class TrackingHandler implements EventHandler<TestEvent> {
  final List<String> received = [];

  @override
  Future<void> handle(TestEvent event) async {
    received.add(event.message);
  }
}

void main() {
  group('EventBus Middleware', () {
    group('Basic Middleware Registration', () {
      test('addMiddleware accepts class-based middleware', () {
        final bus = EventBus();
        final middleware = LoggingMiddleware();

        final subscription = bus.addMiddleware(middleware);

        expect(subscription, isNotNull);
        expect(subscription.isCancelled, isFalse);
      });

      test('addMiddleware accepts function-based middleware', () {
        final bus = EventBus();
        final logs = <String>[];

        final subscription = bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          logs.add('before');
          await next();
          logs.add('after');
        });

        expect(subscription, isNotNull);
        expect(subscription.isCancelled, isFalse);
      });

      test('middleware subscription can be cancelled', () {
        final bus = EventBus();
        final middleware = LoggingMiddleware();

        final subscription = bus.addMiddleware(middleware);
        subscription.cancel();

        expect(subscription.isCancelled, isTrue);
      });

      test('cancelled middleware is not invoked', () async {
        final bus = EventBus();
        final middleware = LoggingMiddleware();
        final handler = TrackingHandler();

        final subscription = bus.addMiddleware(middleware);
        bus.register<TestEvent>(handler);

        subscription.cancel();
        await bus.publish(TestEvent('test'));

        expect(middleware.logs, isEmpty);
        expect(handler.received, equals(['test']));
      });
    });

    group('Middleware Execution', () {
      test('middleware wraps handler execution', () async {
        final bus = EventBus();
        final middleware = LoggingMiddleware();
        final handler = TrackingHandler();

        bus.addMiddleware(middleware);
        bus.register<TestEvent>(handler);

        await bus.publish(TestEvent('hello'));

        expect(middleware.logs, equals(['before:TestEvent', 'after:TestEvent']));
        expect(handler.received, equals(['hello']));
      });

      test('middleware is invoked even with no handlers', () async {
        final bus = EventBus();
        final middleware = LoggingMiddleware();

        bus.addMiddleware(middleware);
        await bus.publish(TestEvent('hello'));

        expect(middleware.logs, equals(['before:TestEvent', 'after:TestEvent']));
      });

      test('multiple middleware form a pipeline', () async {
        final bus = EventBus();
        final executionLog = <String>[];

        bus.addMiddleware(OrderTrackingMiddleware('A', executionLog));
        bus.addMiddleware(OrderTrackingMiddleware('B', executionLog));
        bus.addMiddleware(OrderTrackingMiddleware('C', executionLog));

        bus.on<TestEvent>((event) async {
          executionLog.add('handler');
        });

        await bus.publish(TestEvent('test'));

        // Default priority is 0, so execution order depends on registration order
        // All middleware should wrap the handler
        expect(executionLog, contains('handler'));
        expect(executionLog.where((e) => e.contains('before')).length, equals(3));
        expect(executionLog.where((e) => e.contains('after')).length, equals(3));
      });

      test('function middleware works correctly', () async {
        final bus = EventBus();
        final logs = <String>[];

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          logs.add('before');
          await next();
          logs.add('after');
        });

        bus.on<TestEvent>((event) async {
          logs.add('handler');
        });

        await bus.publish(TestEvent('test'));

        expect(logs, equals(['before', 'handler', 'after']));
      });
    });

    group('Middleware Priority', () {
      test('higher priority middleware executes first (outer layer)', () async {
        final bus = EventBus();
        final executionLog = <String>[];

        bus.addMiddleware(OrderTrackingMiddleware('low', executionLog), priority: -10);
        bus.addMiddleware(OrderTrackingMiddleware('high', executionLog), priority: 100);
        bus.addMiddleware(OrderTrackingMiddleware('mid', executionLog), priority: 50);

        bus.on<TestEvent>((event) async {
          executionLog.add('handler');
        });

        await bus.publish(TestEvent('test'));

        // High priority should be outermost (first before, last after)
        expect(executionLog[0], equals('high:before'));
        expect(executionLog[1], equals('mid:before'));
        expect(executionLog[2], equals('low:before'));
        expect(executionLog[3], equals('handler'));
        expect(executionLog[4], equals('low:after'));
        expect(executionLog[5], equals('mid:after'));
        expect(executionLog[6], equals('high:after'));
      });

      test('same priority middleware ordered by registration', () async {
        final bus = EventBus();
        final executionLog = <String>[];

        bus.addMiddleware(OrderTrackingMiddleware('first', executionLog), priority: 0);
        bus.addMiddleware(OrderTrackingMiddleware('second', executionLog), priority: 0);
        bus.addMiddleware(OrderTrackingMiddleware('third', executionLog), priority: 0);

        bus.on<TestEvent>((event) async {
          executionLog.add('handler');
        });

        await bus.publish(TestEvent('test'));

        // Same priority, so first registered should be outermost
        expect(executionLog[0], equals('first:before'));
        expect(executionLog[1], equals('second:before'));
        expect(executionLog[2], equals('third:before'));
        expect(executionLog[3], equals('handler'));
      });

      test('negative priority middleware is valid', () async {
        final bus = EventBus();
        final executionLog = <String>[];

        bus.addMiddleware(OrderTrackingMiddleware('negative', executionLog), priority: -50);
        bus.addMiddleware(OrderTrackingMiddleware('zero', executionLog), priority: 0);

        bus.on<TestEvent>((event) async {
          executionLog.add('handler');
        });

        await bus.publish(TestEvent('test'));

        expect(executionLog[0], equals('zero:before'));
        expect(executionLog[1], equals('negative:before'));
      });
    });

    group('Middleware Short-Circuiting', () {
      test('middleware can prevent handler execution', () async {
        final bus = EventBus();
        final shortCircuit = ShortCircuitMiddleware(shouldShortCircuit: true);
        final handler = TrackingHandler();

        bus.addMiddleware(shortCircuit);
        bus.register<TestEvent>(handler);

        await bus.publish(TestEvent('test'));

        expect(shortCircuit.wasInvoked, isTrue);
        expect(handler.received, isEmpty);
      });

      test('middleware can allow handler execution', () async {
        final bus = EventBus();
        final passthrough = ShortCircuitMiddleware(shouldShortCircuit: false);
        final handler = TrackingHandler();

        bus.addMiddleware(passthrough);
        bus.register<TestEvent>(handler);

        await bus.publish(TestEvent('test'));

        expect(passthrough.wasInvoked, isTrue);
        expect(handler.received, equals(['test']));
      });

      test('short-circuit prevents subsequent middleware', () async {
        final bus = EventBus();
        final executionLog = <String>[];

        bus.addMiddleware(OrderTrackingMiddleware('outer', executionLog), priority: 100);
        bus.addMiddleware(ShortCircuitMiddleware(shouldShortCircuit: true), priority: 50);
        bus.addMiddleware(OrderTrackingMiddleware('inner', executionLog), priority: 0);

        bus.on<TestEvent>((event) async {
          executionLog.add('handler');
        });

        await bus.publish(TestEvent('test'));

        // Only outer middleware before should run
        expect(executionLog, equals(['outer:before', 'outer:after']));
      });
    });

    group('Middleware Error Handling', () {
      test('middleware error propagates with stop strategy', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.stop);
        bus.addMiddleware(ErrorMiddleware('middleware error'));

        expect(() => bus.publish(TestEvent('test')), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('middleware error'))));
      });

      test('middleware error propagates even with swallow strategy', () async {
        // Middleware errors are not subject to error strategy - they always propagate
        // This is because middleware wraps the entire handler execution
        final bus = EventBus(errorStrategy: ErrorStrategy.swallow);
        bus.addMiddleware(ErrorMiddleware('middleware error'));

        expect(() => bus.publish(TestEvent('test')), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('middleware error'))));
      });

      test('handler errors are caught by error strategy', () async {
        Object? capturedError;
        final bus = EventBus(
          errorStrategy: ErrorStrategy.swallow,
          onError: (error, stackTrace) {
            capturedError = error;
          },
        );

        // Middleware that passes through
        final logs = <String>[];
        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          logs.add('before');
          await next();
          logs.add('after');
        });

        // Handler that throws
        bus.on<TestEvent>((event) async {
          throw Exception('handler error');
        });

        await bus.publish(TestEvent('test'));

        // Handler error should be swallowed and callback invoked
        expect(capturedError, isNotNull);
        expect(capturedError.toString(), contains('handler error'));
        // Middleware should still complete
        expect(logs, equals(['before', 'after']));
      });
    });

    group('Middleware with Multiple Event Types', () {
      test('middleware receives all event types', () async {
        final bus = EventBus();
        final receivedTypes = <Type>[];

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          receivedTypes.add(event.runtimeType);
          await next();
        });

        bus.on<TestEvent>((event) async {});
        bus.on<OtherEvent>((event) async {});

        await bus.publish(TestEvent('test'));
        await bus.publish(OtherEvent(42));

        expect(receivedTypes, equals([TestEvent, OtherEvent]));
      });

      test('middleware can filter by event type', () async {
        final bus = EventBus();
        final processedEvents = <String>[];

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          if (event is TestEvent) {
            processedEvents.add('processed:${event.message}');
          }
          await next();
        });

        bus.on<TestEvent>((event) async {});
        bus.on<OtherEvent>((event) async {});

        await bus.publish(TestEvent('hello'));
        await bus.publish(OtherEvent(42));
        await bus.publish(TestEvent('world'));

        expect(processedEvents, equals(['processed:hello', 'processed:world']));
      });
    });

    group('Middleware State Management', () {
      test('middleware can modify shared state', () async {
        final bus = EventBus();
        final state = <String, dynamic>{};

        bus.addMiddleware(StateModifyingMiddleware(state, 'step1', 'done'), priority: 100);
        bus.addMiddleware(StateModifyingMiddleware(state, 'step2', 'done'), priority: 50);

        bus.on<TestEvent>((event) async {
          state['handler'] = 'executed';
        });

        await bus.publish(TestEvent('test'));

        expect(state, equals({'step1': 'done', 'step2': 'done', 'handler': 'executed'}));
      });

      test('middleware state changes are visible to inner middleware', () async {
        final bus = EventBus();
        final state = <String, dynamic>{};
        var step2SawStep1 = false;

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          state['step1'] = true;
          await next();
        }, priority: 100);

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          step2SawStep1 = state['step1'] == true;
          await next();
        }, priority: 50);

        bus.on<TestEvent>((event) async {});
        await bus.publish(TestEvent('test'));

        expect(step2SawStep1, isTrue);
      });
    });

    group('Middleware and Handler Interaction', () {
      test('middleware sees all handlers executed', () async {
        final bus = EventBus();
        var handlerCount = 0;
        var middlewareCount = 0;

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          middlewareCount++;
          await next();
        });

        bus.on<TestEvent>((event) async {
          handlerCount++;
        });
        bus.on<TestEvent>((event) async {
          handlerCount++;
        });
        bus.on<TestEvent>((event) async {
          handlerCount++;
        });

        await bus.publish(TestEvent('test'));

        expect(middlewareCount, equals(1)); // Middleware runs once per publish
        expect(handlerCount, equals(3)); // All handlers run
      });

      test('middleware can measure handler execution time', () async {
        final bus = EventBus();
        Duration? executionTime;

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          final stopwatch = Stopwatch()..start();
          await next();
          stopwatch.stop();
          executionTime = stopwatch.elapsed;
        });

        bus.on<TestEvent>((event) async {
          await Future.delayed(const Duration(milliseconds: 50));
        });

        await bus.publish(TestEvent('test'));

        expect(executionTime, isNotNull);
        expect(executionTime!.inMilliseconds, greaterThanOrEqualTo(50));
      });
    });

    group('Middleware Edge Cases', () {
      test('empty middleware pipeline works correctly', () async {
        final bus = EventBus();
        final handler = TrackingHandler();

        bus.register<TestEvent>(handler);
        await bus.publish(TestEvent('test'));

        expect(handler.received, equals(['test']));
      });

      test('middleware with no handlers completes', () async {
        final bus = EventBus();
        final logs = <String>[];

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          logs.add('before');
          await next();
          logs.add('after');
        });

        await bus.publish(TestEvent('test'));

        expect(logs, equals(['before', 'after']));
      });

      test('multiple publishes with same middleware', () async {
        final bus = EventBus();
        final middleware = LoggingMiddleware();

        bus.addMiddleware(middleware);
        bus.on<TestEvent>((event) async {});

        await bus.publish(TestEvent('first'));
        await bus.publish(TestEvent('second'));
        await bus.publish(TestEvent('third'));

        expect(middleware.logs.length, equals(6)); // 2 logs per publish
      });

      test('concurrent publishes with middleware', () async {
        final bus = EventBus();
        final invocations = <String>[];

        bus.addMiddleware((RaiserEvent event, Future<void> Function() next) async {
          invocations.add('start:${(event as TestEvent).message}');
          await next();
          invocations.add('end:${(event).message}');
        });

        bus.on<TestEvent>((event) async {
          await Future.delayed(const Duration(milliseconds: 10));
        });

        await Future.wait([bus.publish(TestEvent('A')), bus.publish(TestEvent('B')), bus.publish(TestEvent('C'))]);

        // All events should have start and end
        expect(invocations.where((s) => s.startsWith('start:')).length, equals(3));
        expect(invocations.where((s) => s.startsWith('end:')).length, equals(3));
      });
    });
  });
}
