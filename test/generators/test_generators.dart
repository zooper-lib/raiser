/// Custom Glados generators for property-based testing of the Raiser event system.
///
/// This file contains generators for:
/// - Random event instances with varying metadata
/// - Lists of handlers with random priorities
/// - Random error-throwing handlers
/// - Random subscription sequences (register/cancel)
library;

import 'package:glados/glados.dart';

// Generators will be added as components are implemented.
// Each generator will be documented with its purpose and usage.

/// Generator for non-empty strings suitable for event IDs and aggregate IDs.
extension NonEmptyStringGenerator on Any {
  /// Generates non-empty strings for use as identifiers.
  Any<String> get nonEmptyString => any.string.where((s) => s.isNotEmpty);
}

/// Generator for optional aggregate IDs (nullable strings).
extension OptionalAggregateIdGenerator on Any {
  /// Generates optional aggregate IDs - either null or a non-empty string.
  Any<String?> get optionalAggregateId => any.choose([
        any.always(null),
        any.nonEmptyString,
      ]);
}

/// Generator for priority values (typically -100 to 100 range).
extension PriorityGenerator on Any {
  /// Generates priority values in a reasonable range.
  Any<int> get priority => any.intInRange(-100, 100);
}

/// Generator for positive counts (for list sizes, etc.).
extension PositiveCountGenerator on Any {
  /// Generates small positive integers for collection sizes.
  Any<int> get smallPositiveInt => any.intInRange(1, 20);
}

/// Generator for event names (non-empty strings).
extension EventNameGenerator on Any {
  /// Generates event names for testing.
  Any<String> get eventName => any.nonEmptyString;
}
