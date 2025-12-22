import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:raiser_annotation/raiser_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'code_emitter.dart';
import 'handler_generator.dart';
import 'middleware_generator.dart';
import 'models/handler_info.dart';
import 'models/middleware_info.dart';

/// A builder that aggregates all handlers and middleware from a library
/// and generates a unified initRaiser function.
///
/// This builder processes all @RaiserHandler and @RaiserMiddleware annotations
/// in a single library and combines them into one cohesive output.
///
/// Requirements: 3.1, 3.2, 3.3
class RaiserAggregatingGenerator extends Generator {
  final _handlerChecker = const TypeChecker.fromRuntime(RaiserHandler);
  final _middlewareChecker = const TypeChecker.fromRuntime(RaiserMiddleware);
  final _handlerGenerator = RaiserHandlerGenerator();
  final _middlewareGenerator = RaiserMiddlewareGenerator();
  final _codeEmitter = CodeEmitter();

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final handlers = <HandlerInfo>[];
    final middleware = <MiddlewareInfo>[];
    final errors = <String>[];

    // Collect all handlers
    for (final annotatedElement in library.annotatedWith(_handlerChecker)) {
      try {
        final info = _extractHandlerInfo(
          annotatedElement.element,
          annotatedElement.annotation,
          buildStep,
        );
        if (info != null) {
          handlers.add(info);
        }
      } on InvalidGenerationSourceError catch (e) {
        errors.add('// Error: ${e.message}');
      }
    }

    // Collect all middleware
    for (final annotatedElement in library.annotatedWith(_middlewareChecker)) {
      try {
        final info = _extractMiddlewareInfo(
          annotatedElement.element,
          annotatedElement.annotation,
          buildStep,
        );
        if (info != null) {
          middleware.add(info);
        }
      } on InvalidGenerationSourceError catch (e) {
        errors.add('// Error: ${e.message}');
      }
    }

    // If no handlers or middleware found, return null (no output)
    if (handlers.isEmpty && middleware.isEmpty && errors.isEmpty) {
      return null;
    }

    // Generate the aggregated output
    final buffer = StringBuffer();

    // Add any errors as comments
    if (errors.isNotEmpty) {
      for (final error in errors) {
        buffer.writeln(error);
      }
      buffer.writeln();
    }

    // Generate all init functions (grouped by bus name)
    if (handlers.isNotEmpty || middleware.isNotEmpty) {
      buffer.write(_codeEmitter.emitAllInitFunctions(handlers, middleware));
    }

    return buffer.toString();
  }

  /// Extracts HandlerInfo from an annotated element.
  HandlerInfo? _extractHandlerInfo(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Delegate to the handler generator's extraction logic
    // We need to replicate the validation and extraction here
    return _handlerGenerator.extractHandlerInfo(
      element,
      annotation,
      buildStep,
    );
  }

  /// Extracts MiddlewareInfo from an annotated element.
  MiddlewareInfo? _extractMiddlewareInfo(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Delegate to the middleware generator's extraction logic
    return _middlewareGenerator.extractMiddlewareInfo(
      element,
      annotation,
      buildStep,
    );
  }
}
