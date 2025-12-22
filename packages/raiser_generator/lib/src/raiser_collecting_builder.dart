import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:raiser_annotation/raiser_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'handler_generator.dart';
import 'middleware_generator.dart';
import 'models/handler_info.dart';
import 'models/middleware_info.dart';

/// A builder that collects handler and middleware metadata from individual
/// Dart files and writes them to intermediate JSON files.
///
/// This is the first phase of a two-phase build:
/// 1. CollectingBuilder: Scans each .dart file, extracts metadata, writes .raiser.json
/// 2. AggregatingBuilder: Reads all .raiser.json files, generates single raiser.g.dart
class RaiserCollectingBuilder implements Builder {
  final _handlerChecker = const TypeChecker.fromRuntime(RaiserHandler);
  final _middlewareChecker = const TypeChecker.fromRuntime(RaiserMiddleware);
  final _handlerGenerator = RaiserHandlerGenerator();
  final _middlewareGenerator = RaiserMiddlewareGenerator();

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.raiser.json'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // Skip generated files and part files
    if (buildStep.inputId.path.endsWith('.g.dart') || buildStep.inputId.path.endsWith('.raiser.json')) {
      return;
    }

    // Only process files in lib/
    if (!buildStep.inputId.path.startsWith('lib/')) {
      return;
    }

    final library = await buildStep.resolver.libraryFor(buildStep.inputId, allowSyntaxErrors: true);

    final libraryReader = LibraryReader(library);
    final handlers = <Map<String, dynamic>>[];
    final middleware = <Map<String, dynamic>>[];

    // Collect all handlers
    for (final annotatedElement in libraryReader.annotatedWith(_handlerChecker)) {
      try {
        final info = _handlerGenerator.extractHandlerInfo(annotatedElement.element, annotatedElement.annotation, buildStep);
        handlers.add(info.toJson());
      } on InvalidGenerationSourceError {
        // Skip invalid elements, errors will be reported by validation
      }
    }

    // Collect all middleware
    for (final annotatedElement in libraryReader.annotatedWith(_middlewareChecker)) {
      try {
        final info = _middlewareGenerator.extractMiddlewareInfo(annotatedElement.element, annotatedElement.annotation, buildStep);
        middleware.add(info.toJson());
      } on InvalidGenerationSourceError {
        // Skip invalid elements, errors will be reported by validation
      }
    }

    // Only write output if we found something
    if (handlers.isNotEmpty || middleware.isNotEmpty) {
      // Collect imports from the source file - only event type imports are needed
      // We need imports that define the event types used in handlers
      final sourceImports = <String>[];
      for (final importedLibrary in library.importedLibraries) {
        final source = importedLibrary.source.uri.toString();
        // Only include imports that likely contain event definitions
        // Skip dart:, raiser packages, and service-like files
        if (!source.startsWith('dart:') &&
            !source.startsWith('package:raiser_annotation') &&
            !source.startsWith('package:raiser/') &&
            !source.contains('service')) {
          // Convert package URI to relative path if same package
          if (source.startsWith('package:${buildStep.inputId.package}/')) {
            final relativePath = source.replaceFirst('package:${buildStep.inputId.package}/', 'lib/');
            sourceImports.add(relativePath);
          } else if (source.startsWith('package:')) {
            // Keep package imports as-is
            sourceImports.add(source);
          }
        }
      }

      final output = {'sourceFile': buildStep.inputId.path, 'sourceImports': sourceImports, 'handlers': handlers, 'middleware': middleware};

      final outputId = buildStep.inputId.changeExtension('.raiser.json');
      await buildStep.writeAsString(outputId, jsonEncode(output));
    }
  }
}

/// A builder that aggregates all collected metadata and generates a single
/// raiser.g.dart file with all registrations.
///
/// This is the second phase of a two-phase build.
class RaiserAggregatingBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    r'lib/$lib$': ['lib/raiser.g.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // Find all .raiser.json files
    final jsonFiles = Glob('lib/**.raiser.json');
    final handlers = <HandlerInfo>[];
    final middleware = <MiddlewareInfo>[];
    final imports = <String>{};

    await for (final input in buildStep.findAssets(jsonFiles)) {
      final content = await buildStep.readAsString(input);
      final data = jsonDecode(content) as Map<String, dynamic>;

      final sourceFile = data['sourceFile'] as String;

      // Add import for the source file
      imports.add(sourceFile);

      // Add imports from the source file (for event types, etc.)
      final sourceImports = data['sourceImports'] as List<dynamic>?;
      if (sourceImports != null) {
        for (final imp in sourceImports) {
          imports.add(imp as String);
        }
      }

      // Parse handlers
      final handlerList = data['handlers'] as List<dynamic>;
      for (final h in handlerList) {
        handlers.add(HandlerInfo.fromJson(h as Map<String, dynamic>));
      }

      // Parse middleware
      final middlewareList = data['middleware'] as List<dynamic>;
      for (final m in middlewareList) {
        middleware.add(MiddlewareInfo.fromJson(m as Map<String, dynamic>));
      }
    }

    // Only generate output if we have content
    if (handlers.isEmpty && middleware.isEmpty) {
      return;
    }

    final buffer = StringBuffer();

    // Header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
    buffer.writeln("// ignore_for_file: type=lint");
    buffer.writeln();

    // Imports
    buffer.writeln("import 'package:raiser/raiser.dart';");
    buffer.writeln();

    // Sort imports for consistency
    final sortedImports = imports.toList()..sort();
    for (final import in sortedImports) {
      // Convert lib/foo.dart to package import path relative
      final relativePath = import.replaceFirst('lib/', '');
      buffer.writeln("import '$relativePath';");
    }
    buffer.writeln();

    // Generate init functions
    buffer.write(_emitAllInitFunctions(handlers, middleware));

    final outputId = AssetId(buildStep.inputId.package, 'lib/raiser.g.dart');
    await buildStep.writeAsString(outputId, buffer.toString());
  }

  String _emitAllInitFunctions(List<HandlerInfo> handlers, List<MiddlewareInfo> middleware) {
    final buffer = StringBuffer();

    // Group by bus name
    final handlersByBus = _groupHandlersByBus(handlers);
    final middlewareByBus = _groupMiddlewareByBus(middleware);

    // Get all unique bus names
    final allBusNames = <String?>{...handlersByBus.keys, ...middlewareByBus.keys};

    // Generate init function for each bus
    for (final busName in allBusNames) {
      final busHandlers = handlersByBus[busName] ?? [];
      final busMiddleware = middlewareByBus[busName] ?? [];

      buffer.write(_emitInitFunction(busName, busHandlers, busMiddleware));
      buffer.writeln();
    }

    return buffer.toString();
  }

  Map<String?, List<HandlerInfo>> _groupHandlersByBus(List<HandlerInfo> handlers) {
    final grouped = <String?, List<HandlerInfo>>{};
    for (final handler in handlers) {
      grouped.putIfAbsent(handler.busName, () => []).add(handler);
    }
    return grouped;
  }

  Map<String?, List<MiddlewareInfo>> _groupMiddlewareByBus(List<MiddlewareInfo> middleware) {
    final grouped = <String?, List<MiddlewareInfo>>{};
    for (final m in middleware) {
      grouped.putIfAbsent(m.busName, () => []).add(m);
    }
    return grouped;
  }

  String _emitInitFunction(String? busName, List<HandlerInfo> handlers, List<MiddlewareInfo> middleware) {
    final buffer = StringBuffer();
    final functionName = busName == null ? 'initRaiser' : 'initRaiser${_capitalize(busName)}Bus';

    // Check if any handlers or middleware require factory functions
    final handlersWithDeps = handlers.where((h) => h.constructor.hasParameters).toList();
    final middlewareWithDeps = middleware.where((m) => m.constructor.hasParameters).toList();
    final hasFactoryDependencies = handlersWithDeps.isNotEmpty || middlewareWithDeps.isNotEmpty;

    // Sort middleware by priority (descending - higher executes first)
    final sortedMiddleware = List<MiddlewareInfo>.from(middleware)..sort((a, b) => b.priority.compareTo(a.priority));

    // Generate the main init function for handlers without dependencies
    buffer.writeln('/// Initializes all Raiser handlers and middleware.');
    if (busName != null) {
      buffer.writeln("/// This function registers components for the '$busName' bus.");
    }
    buffer.writeln('///');
    buffer.writeln('/// Call this function during application startup to wire up');
    buffer.writeln('/// all discovered event handlers and middleware.');
    buffer.writeln('void $functionName(EventBus bus) {');

    // Emit middleware registrations first (they wrap handlers)
    for (final m in sortedMiddleware) {
      if (!m.constructor.hasParameters) {
        buffer.write(_emitMiddlewareRegistration(m));
      }
    }

    // Emit handler registrations
    for (final h in handlers) {
      if (!h.constructor.hasParameters) {
        buffer.write(_emitHandlerRegistration(h));
      }
    }

    buffer.writeln('}');

    // Generate factory variant if there are dependencies
    if (hasFactoryDependencies) {
      buffer.writeln();
      buffer.write(_emitFactoryVariant(busName, handlers, middleware, handlersWithDeps, middlewareWithDeps));
    }

    return buffer.toString();
  }

  String _emitHandlerRegistration(HandlerInfo handler) {
    final buffer = StringBuffer();

    // Add source file comment
    buffer.writeln('  // Handler: ${handler.className} from ${handler.sourceFile}');
    buffer.writeln('  // Priority: ${handler.priority}');

    // Generate registration
    if (handler.priority != 0) {
      buffer.writeln('  bus.register<${handler.eventType}>(${handler.className}(), priority: ${handler.priority});');
    } else {
      buffer.writeln('  bus.register<${handler.eventType}>(${handler.className}());');
    }

    return buffer.toString();
  }

  String _emitMiddlewareRegistration(MiddlewareInfo middleware) {
    final buffer = StringBuffer();

    // Add source file comment
    buffer.writeln('  // Middleware: ${middleware.className} from ${middleware.sourceFile}');
    buffer.writeln('  // Priority: ${middleware.priority}');

    // Generate registration
    if (middleware.priority != 0) {
      buffer.writeln('  bus.addMiddleware(${middleware.className}(), priority: ${middleware.priority});');
    } else {
      buffer.writeln('  bus.addMiddleware(${middleware.className}());');
    }

    return buffer.toString();
  }

  String _emitFactoryVariant(
    String? busName,
    List<HandlerInfo> allHandlers,
    List<MiddlewareInfo> allMiddleware,
    List<HandlerInfo> handlersWithDeps,
    List<MiddlewareInfo> middlewareWithDeps,
  ) {
    final buffer = StringBuffer();
    final functionName = busName == null ? 'initRaiserWithFactories' : 'initRaiser${_capitalize(busName)}BusWithFactories';

    // Generate typedef for each factory
    for (final h in handlersWithDeps) {
      buffer.writeln('typedef ${h.className}Factory = ${h.className} Function();');
    }
    for (final m in middlewareWithDeps) {
      buffer.writeln('typedef ${m.className}Factory = ${m.className} Function();');
    }

    if (handlersWithDeps.isNotEmpty || middlewareWithDeps.isNotEmpty) {
      buffer.writeln();
    }

    buffer.writeln('/// Initializes Raiser with factory functions for dependency injection.');
    if (busName != null) {
      buffer.writeln("/// This function registers components for the '$busName' bus.");
    }
    buffer.writeln('///');
    buffer.writeln('/// Use this variant when handlers or middleware require constructor dependencies.');
    buffer.writeln('void $functionName(');
    buffer.writeln('  EventBus bus, {');

    // Add factory parameters
    for (final h in handlersWithDeps) {
      buffer.writeln('  required ${h.className}Factory create${h.className},');
    }
    for (final m in middlewareWithDeps) {
      buffer.writeln('  required ${m.className}Factory create${m.className},');
    }

    buffer.writeln('}) {');

    // Sort middleware by priority
    final sortedMiddleware = List<MiddlewareInfo>.from(allMiddleware)..sort((a, b) => b.priority.compareTo(a.priority));

    // Emit middleware registrations
    for (final m in sortedMiddleware) {
      buffer.writeln('  // Middleware: ${m.className} from ${m.sourceFile}');
      buffer.writeln('  // Priority: ${m.priority}');

      final instantiation = m.constructor.hasParameters ? 'create${m.className}()' : '${m.className}()';

      if (m.priority != 0) {
        buffer.writeln('  bus.addMiddleware($instantiation, priority: ${m.priority});');
      } else {
        buffer.writeln('  bus.addMiddleware($instantiation);');
      }
    }

    // Emit handler registrations
    for (final h in allHandlers) {
      buffer.writeln('  // Handler: ${h.className} from ${h.sourceFile}');
      buffer.writeln('  // Priority: ${h.priority}');

      final instantiation = h.constructor.hasParameters ? 'create${h.className}()' : '${h.className}()';

      if (h.priority != 0) {
        buffer.writeln('  bus.register<${h.eventType}>($instantiation, priority: ${h.priority});');
      } else {
        buffer.writeln('  bus.register<${h.eventType}>($instantiation);');
      }
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
