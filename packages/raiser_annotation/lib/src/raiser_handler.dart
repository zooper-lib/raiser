/// Marks a class as a Raiser event handler for code generation.
///
/// The generator will auto-discover classes with this annotation
/// and generate registration code.
///
/// ```dart
/// @RaiserHandler()
/// class OrderCreatedHandler extends EventHandler<OrderCreatedEvent> {
///   @override
///   Future<void> handle(OrderCreatedEvent event) async {
///     // handle logic
///   }
/// }
/// ```
class RaiserHandler {
  /// Optional priority for handler execution order.
  /// Higher values execute first.
  final int priority;

  /// Optional bus name for named bus registration.
  final String? busName;

  const RaiserHandler({
    this.priority = 0,
    this.busName,
  });
}
