import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'settings': 'Settings',
      'basicFeatures': 'Basic Features',
      'enableNotifications': 'Enable Notifications',
      'notificationsSubtitle': 'Receive updates about your crops and market prices',
      'darkMode': 'Dark Mode',
      'darkModeSubtitle': 'Switch between light and dark theme',
      'languageOptions': 'Language Options',
      'logout': 'Logout',
      'logoutConfirmation': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'languageChanged': 'Language changed to {language}. Please restart the app for changes to take effect.',
      'restart': 'Restart',
    },
    'hi': {
      'settings': 'सेटिंग्स',
      'basicFeatures': 'बुनियादी सुविधाएं',
      'enableNotifications': 'सूचनाएं सक्षम करें',
      'notificationsSubtitle': 'अपनी फसलों और बाजार की कीमतों के बारे में अपडेट प्राप्त करें',
      'darkMode': 'डार्क मोड',
      'darkModeSubtitle': 'लाइट और डार्क थीम के बीच स्विच करें',
      'languageOptions': 'भाषा विकल्प',
      'logout': 'लॉग आउट',
      'logoutConfirmation': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'languageChanged': 'भाषा {language} में बदल गई है। परिवर्तन प्रभावी होने के लिए कृपया ऐप को पुनरारंभ करें।',
      'restart': 'पुनरारंभ करें',
    },
    // Add more languages as needed
  };

  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get basicFeatures => _localizedValues[locale.languageCode]!['basicFeatures']!;
  String get enableNotifications => _localizedValues[locale.languageCode]!['enableNotifications']!;
  String get notificationsSubtitle => _localizedValues[locale.languageCode]!['notificationsSubtitle']!;
  String get darkMode => _localizedValues[locale.languageCode]!['darkMode']!;
  String get darkModeSubtitle => _localizedValues[locale.languageCode]!['darkModeSubtitle']!;
  String get languageOptions => _localizedValues[locale.languageCode]!['languageOptions']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get logoutConfirmation => _localizedValues[locale.languageCode]!['logoutConfirmation']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get restart => _localizedValues[locale.languageCode]!['restart']!;

  String languageChanged(String language) {
    return _localizedValues[locale.languageCode]!['languageChanged']!.replaceAll('{language}', language);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr', 'ta', 'te', 'gu', 'pa', 'kn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 