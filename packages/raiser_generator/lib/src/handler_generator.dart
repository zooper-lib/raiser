import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:raiser_annotation/raiser_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'models/constructor_info.dart';
import 'models/handler_info.dart';
import 'models/parameter_info.dart';

/// Generator that discovers @RaiserHandler annotated classes
/// and generates registration code.
class RaiserHandlerGenerator extends GeneratorForAnnotation<RaiserHandler> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Validate the annotated element
    final classElement = _validateElement(element);

    // Extract annotation values
    final priority = annotation.read('priority').intValue;
    final busName = annotation.peek('busName')?.stringValue;

    // Extract event type from EventHandler<T>
    final eventType = _extractEventType(classElement);

    // Analyze constructor for dependency injection
    final constructorInfo = _analyzeConstructor(classElement);

    // Build HandlerInfo
    final handlerInfo = HandlerInfo(
      className: classElement.name,
      eventType: eventType,
      priority: priority,
      busName: busName,
      sourceFile: buildStep.inputId.path,
      constructor: constructorInfo,
    );

    // Generate registration code
    return _generateRegistrationCode(handlerInfo);
  }

  /// Validates that the annotated element is a valid handler class.
  ///
  /// Requirements: 1.2, 6.1, 6.2, 6.3
  ClassElement _validateElement(Element element) {
    // Check if element is a class (Requirement 6.1)
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@RaiserHandler can only be applied to classes. Found: ${element.kind.displayName}',
        element: element,
      );
    }

    final classElement = element;

    // Check if class is abstract (Requirement 6.2)
    if (classElement.isAbstract) {
      throw InvalidGenerationSourceError(
        "@RaiserHandler cannot be applied to abstract classes. "
        "'${classElement.name}' must be concrete.",
        element: element,
      );
    }

    // Check if class extends EventHandler<T> (Requirement 1.2)
    if (!_extendsEventHandler(classElement)) {
      throw InvalidGenerationSourceError(
        "Class '${classElement.name}' must extend EventHandler<T> to use @RaiserHandler.",
        element: element,
      );
    }

    // Check for accessible constructor (Requirement 6.3)
    if (!_hasAccessibleConstructor(classElement)) {
      throw InvalidGenerationSourceError(
        "Class '${classElement.name}' must have an accessible constructor for registration.",
        element: element,
      );
    }

    return classElement;
  }

  /// Checks if the class extends EventHandler<T>.
  bool _extendsEventHandler(ClassElement classElement) {
    // Check supertype chain for EventHandler
    for (final supertype in classElement.allSupertypes) {
      if (supertype.element.name == 'EventHandler') {
        return true;
      }
    }
    return false;
  }

  /// Checks if the class has an accessible (public) constructor.
  bool _hasAccessibleConstructor(ClassElement classElement) {
    // Look for any public constructor
    for (final constructor in classElement.constructors) {
      if (!constructor.isPrivate && !constructor.isFactory) {
        return true;
      }
    }
    return false;
  }

  /// Extracts the event type T from EventHandler<T>.
  ///
  /// Requirements: 4.1, 4.2, 4.3
  String _extractEventType(ClassElement classElement) {
    // Find EventHandler in the supertype chain
    for (final supertype in classElement.allSupertypes) {
      if (supertype.element.name == 'EventHandler') {
        final typeArgs = supertype.typeArguments;
        if (typeArgs.isNotEmpty) {
          final eventType = typeArgs.first;

          // Check if the type is resolvable (not dynamic or unresolved)
          if (eventType is DynamicType) {
            throw InvalidGenerationSourceError(
              "Cannot resolve event type for '${classElement.name}'. "
              "Ensure the generic type parameter is a concrete type.",
              element: classElement,
            );
          }

          // Get the type name with proper handling
          final typeName = eventType.getDisplayString();

          // Verify it's not a type parameter (unresolved generic)
          if (eventType is TypeParameterType) {
            throw InvalidGenerationSourceError(
              "Cannot resolve event type for '${classElement.name}'. "
              "Ensure the generic type parameter is a concrete type, not a type variable.",
              element: classElement,
            );
          }

          return typeName;
        }
      }
    }

    throw InvalidGenerationSourceError(
      "Cannot resolve event type for '${classElement.name}'. "
      "Ensure the class extends EventHandler<T> with a concrete type.",
      element: classElement,
    );
  }

  /// Analyzes the constructor for dependency injection support.
  ///
  /// Requirements: 5.1, 5.2, 5.3
  ConstructorInfo _analyzeConstructor(ClassElement classElement) {
    // Find the primary constructor (unnamed or first public)
    ConstructorElement? primaryConstructor;

    for (final constructor in classElement.constructors) {
      if (!constructor.isPrivate && !constructor.isFactory) {
        // Prefer unnamed constructor
        if (constructor.name.isEmpty) {
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

    final parameters = primaryConstructor.parameters;

    if (parameters.isEmpty) {
      return const ConstructorInfo.noArgs();
    }

    // Extract parameter information
    final parameterInfos = parameters.map((param) {
      return ParameterInfo(
        name: param.name,
        type: param.type.getDisplayString(),
        isRequired: param.isRequired,
        defaultValue: param.defaultValueCode,
        isNamed: param.isNamed,
      );
    }).toList();

    return ConstructorInfo(
      hasParameters: true,
      parameters: parameterInfos,
    );
  }

  /// Generates the registration code for a handler.
  String _generateRegistrationCode(HandlerInfo info) {
    final buffer = StringBuffer();

    // Add source file comment (Requirement 7.1)
    buffer.writeln('// Handler: ${info.className} from ${info.sourceFile}');

    // Add priority comment (Requirement 7.3)
    buffer.writeln('// Priority: ${info.priority}');

    if (info.busName != null) {
      buffer.writeln('// Bus: ${info.busName}');
    }

    // Generate registration based on constructor type
    if (!info.constructor.hasParameters) {
      // Direct instantiation (Requirement 5.1)
      if (info.priority != 0) {
        buffer.writeln(
          'bus.register<${info.eventType}>(${info.className}(), priority: ${info.priority});',
        );
      } else {
        buffer.writeln(
          'bus.register<${info.eventType}>(${info.className}());',
        );
      }
    } else {
      // Factory function needed - generate placeholder comment
      // Full factory generation will be in CodeEmitter
      buffer.writeln(
        '// Requires factory function for dependency injection',
      );
      buffer.writeln(
        '// Parameters: ${info.constructor.parameters.map((p) => '${p.type} ${p.name}').join(', ')}',
      );
    }

    return buffer.toString();
  }
}
