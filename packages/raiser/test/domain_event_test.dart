import 'package:raiser/raiser.dart';
import 'package:test/test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

/// Simple concrete RaiserEvent for testing purposes.
class TestEvent implements RaiserEvent {
  @override
  final EventId id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;

  final String name;

  TestEvent({
    required this.name,
    EventId? id,
    DateTime? occurredOn,
    Map<String, Object?>? metadata,
  }) : id = id ?? EventId.fromUlid(),
       occurredOn = occurredOn ?? DateTime.now(),
       metadata = Map<String, Object?>.unmodifiable(metadata ?? const <String, Object?>{});

  Map<String, Object?> toMetadataMap() {
    return <String, Object?>{
      'id': id.value,
      'occurredOn': occurredOn.toIso8601String(),
      'metadata': metadata,
      'name': name,
    };
  }

  /// Reconstructs a TestEvent from a metadata map.
  static TestEvent fromMetadataMap(Map<String, dynamic> map) {
    return TestEvent(
      id: EventId.fromJson(map['id'] as String),
      occurredOn: DateTime.parse(map['occurredOn'] as String),
      metadata: Map<String, Object?>.from(map['metadata'] as Map),
      name: map['name'] as String,
    );
  }
}

void main() {
  group('RaiserEvent', () {
    // **Feature: core-event-system, Property 1: Event ID Uniqueness**
    test('Property 1: all event IDs are unique across multiple instances', () {
      final events = List.generate(100, (_) => TestEvent(name: 'test'));
      final ids = events.map((e) => e.id).toSet();
      expect(ids.length, equals(events.length));
    });

    // **Feature: core-event-system, Property 3: Metadata Preservation**
    test('Property 3: metadata map preserves provided keys and values', () {
      final TestEvent event = TestEvent(name: 'test', metadata: <String, Object?>{'aggregateId': 'agg-123', 'correlationId': 'corr-1'});

      expect(event.metadata['aggregateId'], equals('agg-123'));
      expect(event.metadata['correlationId'], equals('corr-1'));
    });

    // **Feature: core-event-system, Property 2: Event Metadata Round-Trip**
    test('Property 2: serializing and deserializing preserves event metadata', () {
      final testCases = <TestEvent>[
        TestEvent(name: 'simple'),
        TestEvent(name: 'with-aggregate', metadata: <String, Object?>{'aggregateId': 'agg-123'}),
        TestEvent(name: 'special chars !@#'),
      ];

      for (final original in testCases) {
        final Map<String, Object?> map = original.toMetadataMap();
        final TestEvent reconstructed = TestEvent.fromMetadataMap(Map<String, dynamic>.from(map));

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.occurredOn, equals(original.occurredOn));
        expect(reconstructed.name, equals(original.name));
      }
    });

    test('occurredOn is automatically set', () {
      final before = DateTime.now();
      final event = TestEvent(name: 'test');
      final after = DateTime.now();

      expect(event.occurredOn.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(event.occurredOn.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });
}
