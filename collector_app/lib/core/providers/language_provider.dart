import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  static LanguageProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<LanguageProvider>(context, listen: listen);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLocale = prefs.getString('language_code') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale == languageCode) return;
    
    _currentLocale = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    notifyListeners();
  }

  void toggleLanguage() {
    if (_currentLocale == 'en') {
      setLanguage('ceb');
    } else {
      setLanguage('en');
    }
  }

  bool get isBisaya => _currentLocale == 'ceb';
}
