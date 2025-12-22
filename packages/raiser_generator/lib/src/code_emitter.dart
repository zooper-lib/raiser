import 'models/handler_info.dart';
import 'models/middleware_info.dart';

/// Utility class for generating well-formatted Dart registration code.
///
/// This class is responsible for emitting the `initRaiser` function and
/// related registration code for handlers and middleware discovered by
/// the Raiser generators.
///
/// Requirements: 3.1, 3.2, 3.3, 5.2, 5.3, 7.1, 7.2, 7.3
class CodeEmitter {
  /// Groups handlers by their bus name.
  ///
  /// Returns a map where keys are bus names (null for default bus)
  /// and values are lists of handlers for that bus.
  ///
  /// Requirements: 2.3, 3.4
  Map<String?, List<HandlerInfo>> groupHandlersByBus(List<HandlerInfo> handlers) {
    final grouped = <String?, List<HandlerInfo>>{};
    for (final handler in handlers) {
      grouped.putIfAbsent(handler.busName, () => []).add(handler);
    }
    return grouped;
  }

  /// Groups middleware by their bus name.
  ///
  /// Returns a map where keys are bus names (null for default bus)
  /// and values are lists of middleware for that bus.
  ///
  /// Requirements: 2.3, 3.4
  Map<String?, List<MiddlewareInfo>> groupMiddlewareByBus(List<MiddlewareInfo> middleware) {
    final grouped = <String?, List<MiddlewareInfo>>{};
    for (final m in middleware) {
      grouped.putIfAbsent(m.busName, () => []).add(m);
    }
    return grouped;
  }

  /// Generates all init functions for all buses.
  ///
  /// This method groups handlers and middleware by bus name and generates
  /// separate init functions for each bus.
  ///
  /// Requirements: 2.3, 3.4
  String emitAllInitFunctions(List<HandlerInfo> handlers, List<MiddlewareInfo> middleware) {
    final buffer = StringBuffer();

    // Group by bus name
    final handlersByBus = groupHandlersByBus(handlers);
    final middlewareByBus = groupMiddlewareByBus(middleware);

    // Get all unique bus names
    final allBusNames = <String?>{...handlersByBus.keys, ...middlewareByBus.keys};

    // Generate init function for each bus
    for (final busName in allBusNames) {
      final busHandlers = handlersByBus[busName] ?? [];
      final busMiddleware = middlewareByBus[busName] ?? [];

      buffer.write(emitInitFunction(busName, busHandlers, busMiddleware));
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generates the initRaiser function for a specific bus (or default).
  ///
  /// For the default bus (busName is null), generates `initRaiser`.
  /// For named buses, generates `initRaiser{BusName}Bus`.
  ///
  /// Requirements: 3.1, 3.2, 3.3, 3.4
  String emitInitFunction(String? busName, List<HandlerInfo> handlers, List<MiddlewareInfo> middleware) {
    final buffer = StringBuffer();
    final functionName = _getFunctionName(busName);

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
        buffer.write(emitMiddlewareRegistration(m));
      }
    }

    // Emit handler registrations
    for (final h in handlers) {
      if (!h.constructor.hasParameters) {
        buffer.write(emitHandlerRegistration(h));
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

  /// Generates registration code for a single handler.
  ///
  /// Requirements: 3.2, 7.1, 7.3
  String emitHandlerRegistration(HandlerInfo handler) {
    final buffer = StringBuffer();

    // Add source file comment (Requirement 7.1)
    buffer.writeln('  // Handler: ${handler.className} from ${handler.sourceFile}');

    // Add priority comment (Requirement 7.3)
    buffer.writeln('  // Priority: ${handler.priority}');

    // Generate registration call
    if (handler.priority != 0) {
      buffer.writeln('  bus.register<${handler.eventType}>(${handler.className}(), priority: ${handler.priority});');
    } else {
      buffer.writeln('  bus.register<${handler.eventType}>(${handler.className}());');
    }

    return buffer.toString();
  }

  /// Generates registration code for a single middleware.
  ///
  /// Requirements: 3.3, 7.1, 7.3
  String emitMiddlewareRegistration(MiddlewareInfo middleware) {
    final buffer = StringBuffer();

    // Add source file comment (Requirement 7.1)
    buffer.writeln('  // Middleware: ${middleware.className} from ${middleware.sourceFile}');

    // Add priority comment (Requirement 7.3)
    buffer.writeln('  // Priority: ${middleware.priority}');

    // Generate registration call
    if (middleware.priority != 0) {
      buffer.writeln('  bus.addMiddleware(${middleware.className}(), priority: ${middleware.priority});');
    } else {
      buffer.writeln('  bus.addMiddleware(${middleware.className}());');
    }

    return buffer.toString();
  }

  /// Generates a factory function typedef for handlers with dependencies.
  ///
  /// The factory function takes no parameters - the user is expected to
  /// provide a closure that captures the dependencies.
  ///
  /// Requirements: 5.2, 5.3
  String emitFactoryTypedef(HandlerInfo handler) {
    return 'typedef ${handler.className}Factory = ${handler.className} Function();';
  }

  /// Generates a factory function typedef for middleware with dependencies.
  ///
  /// The factory function takes no parameters - the user is expected to
  /// provide a closure that captures the dependencies.
  ///
  /// Requirements: 5.2, 5.3
  String emitMiddlewareFactoryTypedef(MiddlewareInfo middleware) {
    return 'typedef ${middleware.className}Factory = ${middleware.className} Function();';
  }

  /// Gets the function name based on bus name.
  ///
  /// Requirements: 3.4
  String _getFunctionName(String? busName) {
    if (busName == null) {
      return 'initRaiser';
    }
    // Capitalize first letter of bus name
    final capitalizedBusName = busName[0].toUpperCase() + busName.substring(1);
    return 'initRaiser${capitalizedBusName}Bus';
  }

  /// Generates the factory variant of the init function.
  String _emitFactoryVariant(
    String? busName,
    List<HandlerInfo> allHandlers,
    List<MiddlewareInfo> allMiddleware,
    List<HandlerInfo> handlersWithDeps,
    List<MiddlewareInfo> middlewareWithDeps,
  ) {
    final buffer = StringBuffer();
    final baseFunctionName = _getFunctionName(busName);
    final factoryFunctionName = '${baseFunctionName}WithFactories';

    // Generate typedefs for all handlers and middleware with dependencies
    for (final h in handlersWithDeps) {
      buffer.writeln(emitFactoryTypedef(h));
    }
    for (final m in middlewareWithDeps) {
      buffer.writeln(emitMiddlewareFactoryTypedef(m));
    }

    if (handlersWithDeps.isNotEmpty || middlewareWithDeps.isNotEmpty) {
      buffer.writeln();
    }

    // Generate the factory function
    buffer.writeln('/// Initializes Raiser with factory functions for dependency injection.');
    if (busName != null) {
      buffer.writeln("/// This function registers components for the '$busName' bus.");
    }
    buffer.writeln('///');
    buffer.writeln('/// Use this variant when handlers or middleware require constructor dependencies.');
    buffer.write('void $factoryFunctionName(');
    buffer.writeln();
    buffer.writeln('  EventBus bus, {');

    // Add factory parameters for handlers
    for (final h in handlersWithDeps) {
      buffer.writeln('  required ${h.className}Factory create${h.className},');
    }

    // Add factory parameters for middleware
    for (final m in middlewareWithDeps) {
      buffer.writeln('  required ${m.className}Factory create${m.className},');
    }

    buffer.writeln('}) {');

    // Sort middleware by priority (descending)
    final sortedMiddleware = List<MiddlewareInfo>.from(allMiddleware)..sort((a, b) => b.priority.compareTo(a.priority));

    // Emit middleware registrations
    for (final m in sortedMiddleware) {
      buffer.writeln('  // Middleware: ${m.className} from ${m.sourceFile}');
      buffer.writeln('  // Priority: ${m.priority}');
      if (m.constructor.hasParameters) {
        if (m.priority != 0) {
          buffer.writeln('  bus.addMiddleware(create${m.className}(), priority: ${m.priority});');
        } else {
          buffer.writeln('  bus.addMiddleware(create${m.className}());');
        }
      } else {
        if (m.priority != 0) {
          buffer.writeln('  bus.addMiddleware(${m.className}(), priority: ${m.priority});');
        } else {
          buffer.writeln('  bus.addMiddleware(${m.className}());');
        }
      }
    }

    // Emit handler registrations
    for (final h in allHandlers) {
      buffer.writeln('  // Handler: ${h.className} from ${h.sourceFile}');
      buffer.writeln('  // Priority: ${h.priority}');
      if (h.constructor.hasParameters) {
        if (h.priority != 0) {
          buffer.writeln('  bus.register<${h.eventType}>(create${h.className}(), priority: ${h.priority});');
        } else {
          buffer.writeln('  bus.register<${h.eventType}>(create${h.className}());');
        }
      } else {
        if (h.priority != 0) {
          buffer.writeln('  bus.register<${h.eventType}>(${h.className}(), priority: ${h.priority});');
        } else {
          buffer.writeln('  bus.register<${h.eventType}>(${h.className}());');
        }
      }
    }

    buffer.writeln('}');

    return buffer.toString();
  }
}
