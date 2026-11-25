/// Build-time configuration. Pass with:
/// flutter run --dart-define=FLAVOR=dev --dart-define=API_BASE_URL=http://10.0.2.2:8000
class Env {
  const Env._();

  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://137.23.51.182',
  );

  static bool get isProd => flavor == 'prod';
}
