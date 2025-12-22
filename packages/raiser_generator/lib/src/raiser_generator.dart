import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'raiser_aggregating_builder.dart';

/// Builder factory for raiser_generator.
///
/// This builder uses an aggregating generator that collects all handlers
/// and middleware from a library and generates a unified initRaiser function.
///
/// Requirements: 1.1, 2.1, 3.1, 3.2, 3.3
Builder raiserBuilder(BuilderOptions options) => SharedPartBuilder(
      [RaiserAggregatingGenerator()],
      'raiser',
    );
