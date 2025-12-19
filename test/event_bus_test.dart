import 'package:raiser/raiser.dart';
import 'package:test/test.dart';

/// Simple event class for testing (not extending DomainEvent).
class SimpleEvent {
  final String message;
  SimpleEvent(this.message);
}

/// Another event type for testing type routing.
class OtherEvent {
  final int value;
  OtherEvent(this.value);
}

/// Class-based handler for testing register() method.
class TestHandler implements EventHandler<SimpleEvent> {
  final List<String> receivedMessages = [];

  @override
  Future<void> handle(SimpleEvent event) async {
    receivedMessages.add(event.message);
  }
}

void main() {
  group('EventBus', () {
    // **Feature: core-event-system, Property 7: Registration Style Equivalence**
    // **Validates: Requirements 4.1, 4.2**
    test('Property 7: register() and on() produce equivalent invocation behavior', () async {
      final testMessages = ['hello', 'world', 'test123', 'special !@#'];

      for (final message in testMessages) {
        // Test with class-based handler
        final classBasedBus = EventBus();
        final classHandler = TestHandler();
        classBasedBus.register<SimpleEvent>(classHandler);
        await classBasedBus.publish(SimpleEvent(message));

        // Test with function-based handler
        final functionBasedBus = EventBus();
        final functionResults = <String>[];
        functionBasedBus.on<SimpleEvent>((event) async {
          functionResults.add(event.message);
        });
        await functionBasedBus.publish(SimpleEvent(message));

        // Both should receive the same message
        expect(classHandler.receivedMessages, equals([message]));
        expect(functionResults, equals([message]));
      }
    });

    // **Feature: core-event-system, Property 4: Handler Registration and Invocation**
    // **Validates: Requirements 3.1, 3.2, 3.5, 3.7**
    test('Property 4: all registered handlers are invoked exactly once', () async {
      final bus = EventBus();
      final invocations = <int>[];

      // Register multiple handlers
      bus.on<SimpleEvent>((event) async {
        invocations.add(1);
      });
      bus.on<SimpleEvent>((event) async {
        invocations.add(2);
      });
      bus.on<SimpleEvent>((event) async {
        invocations.add(3);
      });

      await bus.publish(SimpleEvent('test'));

      // All handlers should be invoked exactly once
      expect(invocations, containsAll([1, 2, 3]));
      expect(invocations.length, equals(3));
    });

    test('Property 4: register returns a valid subscription', () async {
      final bus = EventBus();
      final handler = TestHandler();

      final subscription = bus.register<SimpleEvent>(handler);

      expect(subscription, isNotNull);
      expect(subscription.isCancelled, isFalse);
    });

    test('Property 4: no handlers registered completes without error', () async {
      final bus = EventBus();

      // Should complete without error even with no handlers
      await expectLater(bus.publish(SimpleEvent('test')), completes);
    });

    // **Feature: core-event-system, Property 6: Async Handler Completion**
    // **Validates: Requirements 3.3**
    test('Property 6: publish awaits all async handler completions', () async {
      final bus = EventBus();
      var handler1Completed = false;
      var handler2Completed = false;

      bus.on<SimpleEvent>((event) async {
        await Future.delayed(Duration(milliseconds: 50));
        handler1Completed = true;
      });

      bus.on<SimpleEvent>((event) async {
        await Future.delayed(Duration(milliseconds: 30));
        handler2Completed = true;
      });

      await bus.publish(SimpleEvent('test'));

      // Both handlers should have completed by the time publish returns
      expect(handler1Completed, isTrue);
      expect(handler2Completed, isTrue);
    });

    // **Feature: core-event-system, Property 8: Custom Event Type Routing**
    // **Validates: Requirements 5.1, 5.2**
    test('Property 8: handlers only receive events of their registered type', () async {
      final bus = EventBus();
      final simpleEvents = <String>[];
      final otherEvents = <int>[];

      bus.on<SimpleEvent>((event) async {
        simpleEvents.add(event.message);
      });

      bus.on<OtherEvent>((event) async {
        otherEvents.add(event.value);
      });

      await bus.publish(SimpleEvent('hello'));
      await bus.publish(OtherEvent(42));
      await bus.publish(SimpleEvent('world'));

      // Each handler should only receive its own event type
      expect(simpleEvents, equals(['hello', 'world']));
      expect(otherEvents, equals([42]));
    });

    test('Property 8: custom event types not extending DomainEvent are routed correctly', () async {
      final bus = EventBus();
      final received = <String>[];

      bus.on<SimpleEvent>((event) async {
        received.add(event.message);
      });

      await bus.publish(SimpleEvent('custom-event'));

      expect(received, equals(['custom-event']));
    });
  });
}
