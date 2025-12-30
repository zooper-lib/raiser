/// Marks a class as a Raiser middleware for code generation.
///
/// The generator will auto-discover classes with this annotation
/// and generate registration code.
///
/// ```dart
/// @RaiserMiddleware()
/// class LoggingMiddleware implements Middleware {
///   @override
///   Future<void> call(event, next) async {
///     print('Event: $event');
///     await next();
///   }
/// }
/// ```
class RaiserMiddleware {
  /// Optional priority for middleware execution order.
  /// Higher values execute first (outer middleware).
  final int priority;

  /// Optional bus name for named bus registration.
  final String? busName;

  const RaiserMiddleware({
    this.priority = 0,
    this.busName,
  });
}
