import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:raiser_annotation/raiser_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'models/constructor_info.dart';
import 'models/middleware_info.dart';
import 'models/parameter_info.dart';

/// Generator that discovers @RaiserMiddleware annotated classes
/// and generates registration code.
class RaiserMiddlewareGenerator extends GeneratorForAnnotation<RaiserMiddleware> {
  @override
  String generateForAnnotatedElement(Element2 element, ConstantReader annotation, BuildStep buildStep) {
    final middlewareInfo = extractMiddlewareInfo(element.firstFragment.element, annotation, buildStep);
    // Generate registration code
    return _generateRegistrationCode(middlewareInfo);
  }

  /// Extracts middleware information from an annotated element.
  ///
  /// This method is used by both the individual generator and the
  /// aggregating builder to extract middleware metadata.
  MiddlewareInfo extractMiddlewareInfo(Element2 element, ConstantReader annotation, BuildStep buildStep) {
    // Validate the annotated element
    final classElement = _validateElement(element);

    // Extract annotation values
    final priority = annotation.read('priority').intValue;
    final busName = annotation.peek('busName')?.stringValue;

    // Analyze constructor for dependency injection
    final constructorInfo = _analyzeConstructor(classElement);

    // Build MiddlewareInfo
    return MiddlewareInfo(
      className: classElement.name3 ?? '',
      priority: priority,
      busName: busName,
      sourceFile: buildStep.inputId.path,
      constructor: constructorInfo,
    );
  }

  /// Validates that the annotated element is a valid middleware class.
  ClassElement2 _validateElement(Element2 element) {
    // Check if element is a class
    if (element is! ClassElement2) {
      throw InvalidGenerationSourceError('@RaiserMiddleware can only be applied to classes. Found: ${element.kind.displayName}');
    }

    final classElement = element;

    // Check if class is abstract
    if (classElement.isAbstract) {
      throw InvalidGenerationSourceError(
        "@RaiserMiddleware cannot be applied to abstract classes. "
        "'${classElement.name3}' must be concrete.",
      );
    }

    // Check for accessible constructor
    if (!_hasAccessibleConstructor(classElement)) {
      throw InvalidGenerationSourceError("Class '${classElement.name3}' must have an accessible constructor for registration.");
    }

    return classElement;
  }

  /// Checks if the class has an accessible (public) constructor.
  bool _hasAccessibleConstructor(ClassElement2 classElement) {
    // Look for any public constructor
    for (final constructor in classElement.constructors2) {
      if (!constructor.isPrivate && !constructor.isFactory) {
        return true;
      }
    }
    return false;
  }

  /// Analyzes the constructor for dependency injection support.
  ConstructorInfo _analyzeConstructor(ClassElement2 classElement) {
    // Find the primary constructor (unnamed or first public)
    ConstructorElement2? primaryConstructor;

    for (final constructor in classElement.constructors2) {
      if (!constructor.isPrivate && !constructor.isFactory) {
        // Prefer unnamed constructor
        if ((constructor.name3 ?? '').isEmpty) {
          primaryConstructor = constructor;
          break;
        }
        // Otherwise use first public constructor
        primaryConstructor ??= constructor;
      }
    }

    if (primaryConstructor == null) {
      return const ConstructorInfo.noArgs();
    }

    final parameters = primaryConstructor.formalParameters;

    if (parameters.isEmpty) {
      return const ConstructorInfo.noArgs();
    }

    // Extract parameter information
    final parameterInfos = parameters.map((param) {
      return ParameterInfo(
        name: param.name3 ?? '',
        type: param.type.getDisplayString(),
        isRequired: param.isRequired,
        defaultValue: param.defaultValueCode,
        isNamed: param.isNamed,
      );
    }).toList();

    return ConstructorInfo(hasParameters: true, parameters: parameterInfos);
  }

  /// Generates the registration code for a middleware.
  String _generateRegistrationCode(MiddlewareInfo info) {
    final buffer = StringBuffer();

    // Add source file comment (Requirement 7.1)
    buffer.writeln('// Middleware: ${info.className} from ${info.sourceFile}');

    // Add priority comment (Requirement 7.3)
    buffer.writeln('// Priority: ${info.priority}');

    if (info.busName != null) {
      buffer.writeln('// Bus: ${info.busName}');
    }

    // Generate registration based on constructor type
    if (!info.constructor.hasParameters) {
      // Direct instantiation (Requirement 5.1)
      if (info.priority != 0) {
        buffer.writeln('bus.addMiddleware(${info.className}(), priority: ${info.priority});');
      } else {
        buffer.writeln('bus.addMiddleware(${info.className}());');
      }
    } else {
      // Factory function needed - generate placeholder comment
      // Full factory generation will be in CodeEmitter
      buffer.writeln('// Requires factory function for dependency injection');
      buffer.writeln('// Parameters: ${info.constructor.parameters.map((p) => '${p.type} ${p.name}').join(', ')}');
    }

    return buffer.toString();
  }
}
