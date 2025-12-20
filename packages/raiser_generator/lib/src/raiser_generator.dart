import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'handler_generator.dart';

/// Builder factory for raiser_generator.
Builder raiserBuilder(BuilderOptions options) =>
    SharedPartBuilder([RaiserHandlerGenerator()], 'raiser');
