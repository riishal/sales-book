// lib/providers/language_provider.dart
import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isMalayalam => _locale.languageCode == 'ml';

  void toggleLanguage() {
    _locale = isMalayalam ? const Locale('en') : const Locale('ml');
    notifyListeners();
  }
}
