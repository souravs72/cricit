import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stable anonymous id for POST /v1/events (T26). Stored on-device only.
class DeviceId {
  static const key = 'device_id';
  static final pattern = RegExp(r'^[A-Za-z0-9._:-]{8,100}$');

  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(key);
    if (existing != null && pattern.hasMatch(existing)) return existing;
    final id =
        'cricit-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 30)}';
    await prefs.setString(key, id);
    return id;
  }
}
