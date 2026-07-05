import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// نظام ترجمة خفيف يدعم فقط عربي/إنجليزي (مدموجين بالتطبيق بدون تحميل)
class AppLocalizations {
  static Map<String, String> _ar = {};
  static Map<String, String> _en = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final arData = await rootBundle.loadString('assets/core/translations/ar.json');
    final enData = await rootBundle.loadString('assets/core/translations/en.json');
    _ar = Map<String, String>.from(json.decode(arData));
    _en = Map<String, String>.from(json.decode(enData));
    _loaded = true;
  }

  /// ترجمة مفتاح حسب لغة الاستخدام الحالية
  static String t(String key, String langCode) {
    final map = langCode == 'ar' ? _ar : _en;
    return map[key] ?? key;
  }
}
