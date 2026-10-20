# CRICIT mobile (Flutter)

This folder holds the Dart code only. Generate the platform folders once (T21):

```bash
flutter create . --org app.cricit --project-name cricit --platforms android,ios
flutter pub get
flutter analyze && flutter test
flutter run --dart-define=FLAVOR=dev --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

`flutter create .` keeps existing files in `lib/` and `test/`; it only adds `android/`, `ios/` and tooling.
