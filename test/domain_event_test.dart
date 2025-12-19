import 'package:glados/glados.dart';
import 'package:raiser/raiser.dart';
import 'package:test/test.dart';

import 'generators/test_generators.dart';

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
    // **Validates: Requirements 1.1**
    Glados<int>(any.intInRange(2, 100)).test(
      'Property 1: all event IDs are unique across multiple instances',
      (count) {
        final events = List.generate(count, (_) => TestEvent(name: 'test'));
        final ids = events.map((e) => e.id).toSet();
        expect(ids.length, equals(events.length));
      },
    );

    // **Feature: core-event-system, Property 3: Aggregate ID Preservation**
    // **Validates: Requirements 1.3**
    Glados<String>(any.nonEmptyString).test(
      'Property 3: aggregate ID is preserved exactly as provided',
      (aggregateId) {
        final event = TestEvent(name: 'test', aggregateId: aggregateId);
        expect(event.aggregateId, equals(aggregateId));
      },
    );

    // **Feature: core-event-system, Property 2: Event Metadata Round-Trip**
    // **Validates: Requirements 1.5, 1.6**
    Glados2<String, String?>(any.eventName, any.optionalAggregateId).test(
      'Property 2: serializing and deserializing preserves event metadata',
      (name, aggregateId) {
        final original = TestEvent(name: name, aggregateId: aggregateId);
        final map = original.toMetadataMap();
        final reconstructed = TestEvent.fromMetadataMap(map);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.timestamp, equals(original.timestamp));
        expect(reconstructed.aggregateId, equals(original.aggregateId));
        expect(reconstructed.name, equals(original.name));
      },
    );
  });
}
