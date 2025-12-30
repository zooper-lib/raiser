import 'package:build/build.dart';

import 'raiser_collecting_builder.dart';

/// Builder factory for the collecting phase.
///
/// This builder scans individual Dart files and extracts handler/middleware
/// metadata into intermediate .raiser.json files.
Builder raiserCollectingBuilder(BuilderOptions options) => RaiserCollectingBuilder();

/// Builder factory for the aggregating phase.
///
/// This builder reads all .raiser.json files and generates a single
/// raiser.g.dart file with all registrations.
Builder raiserAggregatingBuilder(BuilderOptions options) => RaiserAggregatingBuilder();
