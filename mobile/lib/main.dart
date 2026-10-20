import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // T22: Firebase.initializeApp() + App Check before runApp.
  runApp(const ProviderScope(child: CricitApp()));
}
