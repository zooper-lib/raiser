import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:raiser_annotation/raiser_annotation.dart';
import 'package:source_gen/source_gen.dart';

/// Generator that discovers @RaiserHandler annotated classes
/// and generates registration code.
class RaiserHandlerGenerator extends GeneratorForAnnotation<RaiserHandler> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@RaiserHandler can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final priority = annotation.read('priority').intValue;
    final busName = annotation.peek('busName')?.stringValue;

    // TODO: Implement full generation logic
    // This is a placeholder that will be expanded
    return '''
// Handler registration for $className
// Priority: $priority
// Bus: ${busName ?? 'default'}
''';
  }
}
