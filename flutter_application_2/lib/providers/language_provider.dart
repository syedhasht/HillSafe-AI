import 'package:flutter/material.dart';

/// Language Provider for managing app language
class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en'; // 'en' or 'ur'

  String get languageCode => _languageCode;
  bool get isEnglish => _languageCode == 'en';
  bool get isUrdu => _languageCode == 'ur';

  void toggleLanguage() {
    _languageCode = _languageCode == 'en' ? 'ur' : 'en';
    notifyListeners();
  }

  void setLanguage(String code) {
    if (code == 'en' || code == 'ur') {
      _languageCode = code;
      notifyListeners();
    }
  }

  // Translations
  String get appName => isEnglish ? 'HillSafe AI' : 'ہل سیف AI';
  String get welcome => isEnglish ? 'Welcome' : 'خوش آمدید';
  String get settings => isEnglish ? 'Settings' : 'ترتیبات';
  String get about => isEnglish ? 'About' : 'کے بارے میں';
  String get safetyGuidelines => isEnglish ? 'Safety Guidelines' : 'حفاظتی رہنما خطوط';
  String get emergencyContacts => isEnglish ? 'Emergency Contacts' : 'ہنگامی رابطے';
  String get logout => isEnglish ? 'Log Out' : 'لاگ آؤٹ';
  String get darkMode => isEnglish ? 'Dark Mode' : 'ڈارک موڈ';
  String get notifications => isEnglish ? 'Notifications' : 'اطلاعات';
  String get savedTips => isEnglish ? 'Saved Tips' : 'محفوظ شدہ تجاویز';
  String get allTips => isEnglish ? 'All Tips' : 'تمام تجاویز';
}
