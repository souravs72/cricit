import '../../../app/env.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}

/// Phone OTP. Firebase exchange lands in T22; non-prod accepts 123456 so the
/// onboarding chrome can be designed and tested without Google credentials.
class AuthRepository {
  var _attempts = 0;
  DateTime? _lockedUntil;
  String? _pendingPhone;

  void _guardLock() {
    final until = _lockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      throw AuthException('locked');
    }
  }

  Future<void> sendOtp(String phone) async {
    _guardLock();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      throw AuthException('phone');
    }
    _pendingPhone = phone;
  }

  Future<void> verifyOtp(String phone, String code) async {
    _guardLock();
    if (_pendingPhone != phone) {
      throw AuthException('phone');
    }
    if (Env.isProd) {
      throw AuthException('offline');
    }
    if (code != '123456') {
      _attempts += 1;
      if (_attempts >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
        _attempts = 0;
        throw AuthException('locked');
      }
      throw AuthException('otp');
    }
    _attempts = 0;
  }
}
