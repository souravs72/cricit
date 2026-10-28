# CRICIT mobile (Flutter)

```bash
flutter pub get
flutter analyze && flutter test
flutter run --flavor dev --dart-define=FLAVOR=dev --dart-define=API_BASE_URL=http://10.0.2.2:8000
flutter run -d chrome --dart-define=FLAVOR=dev
```

Flavors: `dev` (`app.cricit.dev`), `staging` (`app.cricit.staging`), `prod` (`app.cricit`).
Firebase config per flavor is git-ignored (`google-services.json`, `GoogleService-Info.plist`).

## Release signing

Do not commit the keystore. On the machine that ships to Play, create `android/key.properties` (git-ignored):

```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

`android/app/upload-keystore.jks` is git-ignored. Generate once with `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
