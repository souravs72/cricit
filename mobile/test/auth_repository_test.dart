import 'package:cricit/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects short or invalid Indian numbers', () async {
    final auth = AuthRepository();
    expect(() => auth.sendOtp('123'), throwsA(isA<AuthException>()));
    expect(() => auth.sendOtp('0123456789'), throwsA(isA<AuthException>()));
    await auth.sendOtp('9876543210');
  });

  test('accepts the non-prod OTP after a valid send', () async {
    final auth = AuthRepository();
    await auth.sendOtp('9876543210');
    await auth.verifyOtp('9876543210', '123456');
  });

  test('wrong OTP is an error', () async {
    final auth = AuthRepository();
    await auth.sendOtp('9876543210');
    expect(
      () => auth.verifyOtp('9876543210', '000000'),
      throwsA(isA<AuthException>()),
    );
  });
}
