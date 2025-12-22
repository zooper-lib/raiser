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

    // **Feature: core-event-system, Property 5: Subscription Cancellation Stops Delivery**
    test('Property 5: cancelled subscription does not receive subsequent events', () async {
      // Test with multiple different scenarios
      final testCases = [
        ['event1', 'event2', 'event3'],
        ['a', 'b', 'c', 'd', 'e'],
        ['single'],
        ['first', 'second'],
      ];

      for (final messages in testCases) {
        final bus = EventBus();
        final receivedBeforeCancel = <String>[];
        final receivedAfterCancel = <String>[];

        final subscription = bus.on<SimpleEvent>((event) async {
          receivedAfterCancel.add(event.message);
        });

        // Publish first event before cancellation
        if (messages.isNotEmpty) {
          await bus.publish(SimpleEvent(messages.first));
          receivedBeforeCancel.addAll(receivedAfterCancel);
          receivedAfterCancel.clear();
        }

        // Cancel the subscription
        subscription.cancel();

        // Verify subscription is marked as cancelled
        expect(subscription.isCancelled, isTrue);

        // Publish remaining events after cancellation
        for (var i = 1; i < messages.length; i++) {
          await bus.publish(SimpleEvent(messages[i]));
        }

        // Handler should not have received any events after cancellation
        expect(receivedAfterCancel, isEmpty,
            reason: 'Cancelled handler should not receive events');
      }
    });

    test('Property 5: cancellation is idempotent - multiple cancels have no additional effect', () async {
      final bus = EventBus();
      var invocationCount = 0;

      final subscription = bus.on<SimpleEvent>((event) async {
        invocationCount++;
      });

      await bus.publish(SimpleEvent('before'));
      expect(invocationCount, equals(1));

      // Cancel multiple times
      subscription.cancel();
      subscription.cancel();
      subscription.cancel();

      expect(subscription.isCancelled, isTrue);

      await bus.publish(SimpleEvent('after'));
      // Should still be 1, not invoked after cancellation
      expect(invocationCount, equals(1));
    });

    test('Property 5: cancelling one subscription does not affect others', () async {
      final bus = EventBus();
      final handler1Results = <String>[];
      final handler2Results = <String>[];

      final subscription1 = bus.on<SimpleEvent>((event) async {
        handler1Results.add(event.message);
      });

      bus.on<SimpleEvent>((event) async {
        handler2Results.add(event.message);
      });

      await bus.publish(SimpleEvent('first'));

      // Cancel only the first subscription
      subscription1.cancel();

      await bus.publish(SimpleEvent('second'));

      // Handler 1 should only have received 'first'
      expect(handler1Results, equals(['first']));
      // Handler 2 should have received both events
      expect(handler2Results, equals(['first', 'second']));
    });

    // **Feature: core-event-system, Property 9: Priority-Based Handler Ordering**
    test('Property 9: handlers execute in descending priority order', () async {
      // Test with various priority configurations
      final priorityConfigs = [
        [10, 5, 1],      // Descending registration
        [1, 5, 10],      // Ascending registration
        [5, 10, 1],      // Mixed registration
        [100, 50, 75],   // Larger values
        [-5, 0, 5],      // Negative priorities
      ];

      for (final priorities in priorityConfigs) {
        final bus = EventBus();
        final executionOrder = <int>[];

        // Register handlers with different priorities
        for (var i = 0; i < priorities.length; i++) {
          final priority = priorities[i];
          final handlerId = i;
          bus.on<SimpleEvent>((event) async {
            executionOrder.add(handlerId);
          }, priority: priority);
        }

        await bus.publish(SimpleEvent('test'));

        // Build expected order: sort handler indices by their priority (descending)
        final indexedPriorities = List.generate(
          priorities.length,
          (i) => MapEntry(i, priorities[i]),
        );
        indexedPriorities.sort((a, b) => b.value.compareTo(a.value));
        final expectedOrder = indexedPriorities.map((e) => e.key).toList();

        expect(executionOrder, equals(expectedOrder),
            reason: 'Priorities $priorities should execute in descending priority order');
      }
    });

    test('Property 9: equal priority handlers execute in registration order', () async {
      // Test with multiple handlers at same priority
      final testCases = [
        {'count': 3, 'priority': 0},
        {'count': 5, 'priority': 10},
        {'count': 4, 'priority': -5},
      ];

      for (final testCase in testCases) {
        final bus = EventBus();
        final executionOrder = <int>[];
        final count = testCase['count'] as int;
        final priority = testCase['priority'] as int;

        // Register handlers with same priority
        for (var i = 0; i < count; i++) {
          final handlerId = i;
          bus.on<SimpleEvent>((event) async {
            executionOrder.add(handlerId);
          }, priority: priority);
        }

        await bus.publish(SimpleEvent('test'));

        // Expected order is registration order: 0, 1, 2, ...
        final expectedOrder = List.generate(count, (i) => i);

        expect(executionOrder, equals(expectedOrder),
            reason: 'Equal priority handlers should execute in registration order');
      }
    });

    test('Property 9: mixed priorities with some equal values', () async {
      final bus = EventBus();
      final executionOrder = <String>[];

      // Register handlers with mixed priorities (some equal)
      // Priority 10: A, B (registration order)
      // Priority 5: C
      // Priority 10: D (same priority as A, B but registered later)
      bus.on<SimpleEvent>((event) async {
        executionOrder.add('A');
      }, priority: 10);

      bus.on<SimpleEvent>((event) async {
        executionOrder.add('B');
      }, priority: 10);

      bus.on<SimpleEvent>((event) async {
        executionOrder.add('C');
      }, priority: 5);

      bus.on<SimpleEvent>((event) async {
        executionOrder.add('D');
      }, priority: 10);

      await bus.publish(SimpleEvent('test'));

      // Expected: A, B, D (priority 10 in registration order), then C (priority 5)
      expect(executionOrder, equals(['A', 'B', 'D', 'C']));
    });
  });
}
