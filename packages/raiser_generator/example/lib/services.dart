/// Simple logging service interface.
abstract class Logger {
  void log(String message);
}

/// Console implementation of Logger.
class ConsoleLogger implements Logger {
  @override
  void log(String message) {
    print('[LOG] $message');
  }
}

/// Repository for order persistence.
abstract class OrderRepository {
  Future<void> save(String orderId, double amount);
  Future<double?> getAmount(String orderId);
}

/// In-memory implementation of OrderRepository.
class InMemoryOrderRepository implements OrderRepository {
  final Map<String, double> _orders = {};

  @override
  Future<void> save(String orderId, double amount) async {
    _orders[orderId] = amount;
  }

  @override
  Future<double?> getAmount(String orderId) async {
    return _orders[orderId];
  }
}

/// Service for sending notifications.
abstract class NotificationService {
  Future<void> notify(String message);
}

/// Console implementation of NotificationService.
class ConsoleNotificationService implements NotificationService {
  @override
  Future<void> notify(String message) async {
    print('[NOTIFICATION] $message');
  }
}

/// Payment gateway interface.
abstract class PaymentGateway {
  Future<bool> process(String paymentId);
}

/// Mock implementation of PaymentGateway.
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<bool> process(String paymentId) async {
    print('[PAYMENT] Processing $paymentId');
    return true;
  }
}

/// Authorization service interface.
abstract class AuthService {
  Future<bool> isAuthorized();
}

/// Always-authorized implementation for testing.
class AlwaysAuthorizedService implements AuthService {
  @override
  Future<bool> isAuthorized() async => true;
}

/// Rate limiter interface.
abstract class RateLimiter {
  Future<bool> allowRequest(int maxRequests);
}

/// Simple in-memory rate limiter.
class InMemoryRateLimiter implements RateLimiter {
  int _requestCount = 0;

  @override
  Future<bool> allowRequest(int maxRequests) async {
    _requestCount++;
    return _requestCount <= maxRequests;
  }

  void reset() {
    _requestCount = 0;
  }
}
