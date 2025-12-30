import 'package:raiser/raiser.dart';
import 'package:test/test.dart';

/// Simple concrete DomainEvent for testing purposes.
class TestEvent extends DomainEvent {
  final String name;

  TestEvent({
    required this.name,
    super.id,
    super.timestamp,
    super.aggregateId,
  });

  @override
  Map<String, dynamic> toMetadataMap() => {
        ...super.toMetadataMap(),
        'name': name,
      };

  /// Reconstructs a TestEvent from a metadata map.
  static TestEvent fromMetadataMap(Map<String, dynamic> map) {
    return TestEvent(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      aggregateId: map['aggregateId'] as String?,
      name: map['name'] as String,
    );
  }
}

void main() {
  group('DomainEvent', () {
    // **Feature: core-event-system, Property 1: Event ID Uniqueness**
    test('Property 1: all event IDs are unique across multiple instances', () {
      final events = List.generate(100, (_) => TestEvent(name: 'test'));
      final ids = events.map((e) => e.id).toSet();
      expect(ids.length, equals(events.length));
    });

    // **Feature: core-event-system, Property 3: Aggregate ID Preservation**
    test('Property 3: aggregate ID is preserved exactly as provided', () {
      final testIds = ['agg-1', 'agg-123', 'user-abc', 'order-xyz-999'];
      for (final aggregateId in testIds) {
        final event = TestEvent(name: 'test', aggregateId: aggregateId);
        expect(event.aggregateId, equals(aggregateId));
      }
    });

    test('Property 3: null aggregate ID is preserved', () {
      final event = TestEvent(name: 'test');
      expect(event.aggregateId, isNull);
    });

    // **Feature: core-event-system, Property 2: Event Metadata Round-Trip**
    test('Property 2: serializing and deserializing preserves event metadata', () {
      final testCases = [
        TestEvent(name: 'simple'),
        TestEvent(name: 'with-aggregate', aggregateId: 'agg-123'),
        TestEvent(name: 'special chars !@#'),
      ];

      for (final original in testCases) {
        final map = original.toMetadataMap();
        final reconstructed = TestEvent.fromMetadataMap(map);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.timestamp, equals(original.timestamp));
        expect(reconstructed.aggregateId, equals(original.aggregateId));
        expect(reconstructed.name, equals(original.name));
      }
    });

    test('timestamp is automatically set', () {
      final before = DateTime.now();
      final event = TestEvent(name: 'test');
      final after = DateTime.now();

      expect(event.timestamp.isAfter(before.subtract(Duration(seconds: 1))), isTrue);
      expect(event.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });
  });
}
