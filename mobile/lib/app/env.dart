/// Build-time configuration. Pass with:
/// flutter run --dart-define=FLAVOR=dev --dart-define=API_BASE_URL=http://10.0.2.2:8787  (api: npm run dev)
class Env {
  const Env._();

  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8787', // Android emulator → host machine
  );

  static bool get isProd => flavor == 'prod';
}
