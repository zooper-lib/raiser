import 'package:raiser/raiser.dart';
import 'package:test/test.dart';

/// Simple event class for testing error handling.
class TestEvent {
  final String message;
  TestEvent(this.message);
}

void main() {
  group('Error Handling', () {
    // **Feature: core-event-system, Property 10: Error Strategy Stop Halts Propagation**
    // **Validates: Requirements 7.1**
    group('Property 10: Error Strategy Stop Halts Propagation', () {
      test('stop strategy halts on first error and rethrows', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.stop);
        final executionOrder = <int>[];

        bus.on<TestEvent>((event) async {
          executionOrder.add(1);
        }, priority: 30);

        bus.on<TestEvent>((event) async {
          executionOrder.add(2);
          throw Exception('Handler 2 failed');
        }, priority: 20);

        bus.on<TestEvent>((event) async {
          executionOrder.add(3);
        }, priority: 10);

        await expectLater(
          bus.publish(TestEvent('test')),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Handler 2 failed'),
          )),
        );

        // Handler 1 executed, handler 2 threw, handler 3 should NOT execute
        expect(executionOrder, equals([1, 2]));
      });

      test('stop strategy with multiple handler configurations', () async {
        // Test with different numbers of handlers before the failing one
        final handlerCounts = [1, 2, 3, 5];

        for (final countBefore in handlerCounts) {
          final bus = EventBus(errorStrategy: ErrorStrategy.stop);
          final executionOrder = <int>[];

          // Register handlers before the failing one
          for (var i = 0; i < countBefore; i++) {
            final handlerId = i;
            bus.on<TestEvent>((event) async {
              executionOrder.add(handlerId);
            }, priority: 100 - i);
          }

          // Register the failing handler
          bus.on<TestEvent>((event) async {
            executionOrder.add(-1); // Mark failing handler
            throw Exception('Intentional failure');
          }, priority: 100 - countBefore);

          // Register handlers after the failing one
          for (var i = 0; i < 2; i++) {
            final handlerId = countBefore + 1 + i;
            bus.on<TestEvent>((event) async {
              executionOrder.add(handlerId);
            }, priority: 100 - countBefore - 1 - i);
          }

          await expectLater(
            bus.publish(TestEvent('test')),
            throwsA(isA<Exception>()),
          );

          // Should have executed handlers before failing one, plus the failing one
          final expectedOrder = List.generate(countBefore, (i) => i)..add(-1);
          expect(executionOrder, equals(expectedOrder),
              reason: 'With $countBefore handlers before failure, '
                  'subsequent handlers should not execute');
        }
      });

      test('stop strategy is the default', () async {
        final bus = EventBus(); // No explicit strategy
        expect(bus.errorStrategy, equals(ErrorStrategy.stop));

        final executed = <int>[];
        bus.on<TestEvent>((event) async {
          executed.add(1);
          throw Exception('fail');
        });
        bus.on<TestEvent>((event) async {
          executed.add(2);
        });

        await expectLater(
          bus.publish(TestEvent('test')),
          throwsA(isA<Exception>()),
        );

        expect(executed, equals([1]));
      });
    });

    // **Feature: core-event-system, Property 11: Error Strategy ContinueOnError Collects All Errors**
    // **Validates: Requirements 7.2, 7.5**
    group('Property 11: Error Strategy ContinueOnError Collects All Errors', () {
      test('continueOnError invokes all handlers and collects errors', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);
        final executionOrder = <int>[];

        bus.on<TestEvent>((event) async {
          executionOrder.add(1);
          throw Exception('Handler 1 failed');
        }, priority: 30);

        bus.on<TestEvent>((event) async {
          executionOrder.add(2);
        }, priority: 20);

        bus.on<TestEvent>((event) async {
          executionOrder.add(3);
          throw Exception('Handler 3 failed');
        }, priority: 10);

        bus.on<TestEvent>((event) async {
          executionOrder.add(4);
        }, priority: 5);

        await expectLater(
          bus.publish(TestEvent('test')),
          throwsA(isA<AggregateException>().having(
            (e) => e.errors.length,
            'error count',
            equals(2),
          )),
        );

        // All handlers should have executed
        expect(executionOrder, equals([1, 2, 3, 4]));
      });

      test('continueOnError with varying failure counts', () async {
        // Test with different numbers of failing handlers
        final failureCounts = [1, 2, 3, 4];

        for (final failCount in failureCounts) {
          final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);
          final executionOrder = <int>[];
          const totalHandlers = 5;

          for (var i = 0; i < totalHandlers; i++) {
            final handlerId = i;
            final shouldFail = i < failCount;
            bus.on<TestEvent>((event) async {
              executionOrder.add(handlerId);
              if (shouldFail) {
                throw Exception('Handler $handlerId failed');
              }
            }, priority: totalHandlers - i);
          }

          await expectLater(
            bus.publish(TestEvent('test')),
            throwsA(isA<AggregateException>().having(
              (e) => e.errors.length,
              'error count',
              equals(failCount),
            )),
          );

          // All handlers should have executed regardless of failures
          expect(executionOrder, equals(List.generate(totalHandlers, (i) => i)),
              reason: 'All $totalHandlers handlers should execute with $failCount failures');
        }
      });

      test('AggregateException contains all errors and stack traces', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);

        bus.on<TestEvent>((event) async {
          throw ArgumentError('Error A');
        }, priority: 20);

        bus.on<TestEvent>((event) async {
          throw StateError('Error B');
        }, priority: 10);

        try {
          await bus.publish(TestEvent('test'));
          fail('Should have thrown AggregateException');
        } on AggregateException catch (e) {
          expect(e.errors.length, equals(2));
          expect(e.stackTraces.length, equals(2));
          expect(e.errors[0], isA<ArgumentError>());
          expect(e.errors[1], isA<StateError>());
          expect(e.stackTraces[0], isNotNull);
          expect(e.stackTraces[1], isNotNull);
          expect(e.toString(), contains('2 errors'));
        }
      });

      test('continueOnError does not throw if no errors occur', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.continueOnError);
        final executed = <int>[];

        bus.on<TestEvent>((event) async {
          executed.add(1);
        });
        bus.on<TestEvent>((event) async {
          executed.add(2);
        });

        await expectLater(bus.publish(TestEvent('test')), completes);
        expect(executed, equals([1, 2]));
      });
    });

    // **Feature: core-event-system, Property 12: Error Strategy Swallow Continues Silently**
    // **Validates: Requirements 7.3**
    group('Property 12: Error Strategy Swallow Continues Silently', () {
      test('swallow strategy invokes all handlers without throwing', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.swallow);
        final executionOrder = <int>[];

        bus.on<TestEvent>((event) async {
          executionOrder.add(1);
          throw Exception('Handler 1 failed');
        }, priority: 30);

        bus.on<TestEvent>((event) async {
          executionOrder.add(2);
        }, priority: 20);

        bus.on<TestEvent>((event) async {
          executionOrder.add(3);
          throw Exception('Handler 3 failed');
        }, priority: 10);

        bus.on<TestEvent>((event) async {
          executionOrder.add(4);
        }, priority: 5);

        // Should complete without throwing
        await expectLater(bus.publish(TestEvent('test')), completes);

        // All handlers should have executed
        expect(executionOrder, equals([1, 2, 3, 4]));
      });

      test('swallow strategy with varying failure counts', () async {
        // Test with different numbers of failing handlers
        final failureCounts = [1, 2, 3, 4, 5];

        for (final failCount in failureCounts) {
          final bus = EventBus(errorStrategy: ErrorStrategy.swallow);
          final executionOrder = <int>[];
          const totalHandlers = 5;

          for (var i = 0; i < totalHandlers; i++) {
            final handlerId = i;
            final shouldFail = i < failCount;
            bus.on<TestEvent>((event) async {
              executionOrder.add(handlerId);
              if (shouldFail) {
                throw Exception('Handler $handlerId failed');
              }
            }, priority: totalHandlers - i);
          }

          // Should complete without throwing regardless of failures
          await expectLater(bus.publish(TestEvent('test')), completes);

          // All handlers should have executed regardless of failures
          expect(executionOrder, equals(List.generate(totalHandlers, (i) => i)),
              reason: 'All $totalHandlers handlers should execute with $failCount failures');
        }
      });

      test('swallow strategy with all handlers failing', () async {
        final bus = EventBus(errorStrategy: ErrorStrategy.swallow);
        final executionOrder = <int>[];

        bus.on<TestEvent>((event) async {
          executionOrder.add(1);
          throw Exception('Handler 1 failed');
        });

        bus.on<TestEvent>((event) async {
          executionOrder.add(2);
          throw Exception('Handler 2 failed');
        });

        bus.on<TestEvent>((event) async {
          executionOrder.add(3);
          throw Exception('Handler 3 failed');
        });

        // Should complete without throwing even when all handlers fail
        await expectLater(bus.publish(TestEvent('test')), completes);

        // All handlers should have executed
        expect(executionOrder, equals([1, 2, 3]));
      });
    });

    // **Feature: core-event-system, Property 13: Error Callback Invocation**
    // **Validates: Requirements 7.4**
    group('Property 13: Error Callback Invocation', () {
      test('error callback is invoked for each handler error with stop strategy', () async {
        final callbackErrors = <Object>[];
        final callbackStackTraces = <StackTrace>[];

        final bus = EventBus(
          errorStrategy: ErrorStrategy.stop,
          onError: (error, stackTrace) {
            callbackErrors.add(error);
            callbackStackTraces.add(stackTrace);
          },
        );

        bus.on<TestEvent>((event) async {
          throw ArgumentError('Handler failed');
        });

        await expectLater(
          bus.publish(TestEvent('test')),
          throwsA(isA<ArgumentError>()),
        );

        // Callback should have been invoked once
        expect(callbackErrors.length, equals(1));
        expect(callbackErrors[0], isA<ArgumentError>());
        expect(callbackStackTraces.length, equals(1));
        expect(callbackStackTraces[0], isNotNull);
      });

      test('error callback is invoked for each handler error with continueOnError strategy', () async {
        final callbackErrors = <Object>[];
        final callbackStackTraces = <StackTrace>[];

        final bus = EventBus(
          errorStrategy: ErrorStrategy.continueOnError,
          onError: (error, stackTrace) {
            callbackErrors.add(error);
            callbackStackTraces.add(stackTrace);
          },
        );

        bus.on<TestEvent>((event) async {
          throw ArgumentError('Error 1');
        }, priority: 30);

        bus.on<TestEvent>((event) async {
          // No error
        }, priority: 20);

        bus.on<TestEvent>((event) async {
          throw StateError('Error 2');
        }, priority: 10);

        await expectLater(
          bus.publish(TestEvent('test')),
          throwsA(isA<AggregateException>()),
        );

        // Callback should have been invoked for each error
        expect(callbackErrors.length, equals(2));
        expect(callbackErrors[0], isA<ArgumentError>());
        expect(callbackErrors[1], isA<StateError>());
        expect(callbackStackTraces.length, equals(2));
      });

      test('error callback is invoked for each handler error with swallow strategy', () async {
        final callbackErrors = <Object>[];
        final callbackStackTraces = <StackTrace>[];

        final bus = EventBus(
          errorStrategy: ErrorStrategy.swallow,
          onError: (error, stackTrace) {
            callbackErrors.add(error);
            callbackStackTraces.add(stackTrace);
          },
        );

        bus.on<TestEvent>((event) async {
          throw ArgumentError('Error 1');
        }, priority: 30);

        bus.on<TestEvent>((event) async {
          throw StateError('Error 2');
        }, priority: 20);

        bus.on<TestEvent>((event) async {
          throw FormatException('Error 3');
        }, priority: 10);

        // Should complete without throwing
        await expectLater(bus.publish(TestEvent('test')), completes);

        // Callback should have been invoked for each error
        expect(callbackErrors.length, equals(3));
        expect(callbackErrors[0], isA<ArgumentError>());
        expect(callbackErrors[1], isA<StateError>());
        expect(callbackErrors[2], isA<FormatException>());
        expect(callbackStackTraces.length, equals(3));
      });

      test('error callback receives correct stack traces', () async {
        StackTrace? capturedStackTrace;

        final bus = EventBus(
          errorStrategy: ErrorStrategy.swallow,
          onError: (error, stackTrace) {
            capturedStackTrace = stackTrace;
          },
        );

        bus.on<TestEvent>((event) async {
          throw Exception('Test error');
        });

        await bus.publish(TestEvent('test'));

        expect(capturedStackTrace, isNotNull);
        expect(capturedStackTrace.toString(), contains('error_handling_test.dart'));
      });

      test('no callback invocation when no errors occur', () async {
        var callbackInvoked = false;

        final bus = EventBus(
          errorStrategy: ErrorStrategy.continueOnError,
          onError: (error, stackTrace) {
            callbackInvoked = true;
          },
        );

        bus.on<TestEvent>((event) async {
          // No error
        });

        await bus.publish(TestEvent('test'));

        expect(callbackInvoked, isFalse);
      });

      test('callback invocation with varying error counts', () async {
        final errorCounts = [1, 2, 3, 5];

        for (final errorCount in errorCounts) {
          final callbackErrors = <Object>[];

          final bus = EventBus(
            errorStrategy: ErrorStrategy.swallow,
            onError: (error, stackTrace) {
              callbackErrors.add(error);
            },
          );

          for (var i = 0; i < errorCount; i++) {
            final errorIndex = i;
            bus.on<TestEvent>((event) async {
              throw Exception('Error $errorIndex');
            }, priority: errorCount - i);
          }

          await bus.publish(TestEvent('test'));

          expect(callbackErrors.length, equals(errorCount),
              reason: 'Callback should be invoked $errorCount times');
        }
      });
    });
  });
}
