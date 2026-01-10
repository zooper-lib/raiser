import 'package:zooper_flutter_core/zooper_flutter_core.dart';

/// A raiser event is a Zooper domain event with an [EventId] identifier.
///
/// This type is intentionally an interface so applications are not forced to
/// extend a specific base class (Dart supports only single inheritance).
abstract interface class RaiserEvent implements ZooperDomainEvent {}
