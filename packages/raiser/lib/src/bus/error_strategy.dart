/// Defines how the EventBus handles handler exceptions.
enum ErrorStrategy {
  /// Stop propagation on first error, rethrow immediately.
  ///
  /// When a handler throws an exception, no subsequent handlers
  /// will be invoked and the exception propagates to the caller.
  stop,

  /// Continue invoking all handlers, collect errors, throw aggregate at end.
  ///
  /// All handlers execute regardless of failures. After all handlers
  /// complete, an [AggregateException] is thrown containing all errors.
  continueOnError,

  /// Log errors via callback but don't throw, continue processing.
  ///
  /// All handlers execute regardless of failures. Errors are passed
  /// to the error callback (if configured) but no exception is thrown.
  swallow,
}

/// Exception that collects multiple errors from handler failures.
///
/// Thrown when using [ErrorStrategy.continueOnError] and one or more
/// handlers fail during event publication.
class AggregateException implements Exception {
  /// List of errors that occurred during handler execution.
  final List<Object> errors;

  /// Stack traces corresponding to each error.
  final List<StackTrace> stackTraces;

  /// Creates an AggregateException with the given errors and stack traces.
  AggregateException(this.errors, this.stackTraces);

  @override
  String toString() =>
      'AggregateException: ${errors.length} error${errors.length == 1 ? '' : 's'} occurred';
}
