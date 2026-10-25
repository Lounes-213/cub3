import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('ar', 'AE');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale_code') ?? 'ar';
    final country = prefs.getString('locale_country') ?? 'AE';
    _locale = Locale(code, country);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!['ar', 'fr', 'en'].contains(locale.languageCode)) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', locale.languageCode);
    await prefs.setString('locale_country', locale.countryCode ?? '');
    notifyListeners();
  }

  String getLanguageLabel(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return '';
    }
  }
}
