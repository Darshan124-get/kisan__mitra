import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/main_app_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/role_selection_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language') ?? 'English';
  final languageCode = _getLanguageCode(savedLanguage);
  
  runApp(
    ProviderScope(
      child: MyApp(locale: Locale(languageCode)),
    ),
  );
}

String _getLanguageCode(String languageName) {
  final Map<String, String> languageMap = {
    'English': 'en',
    'हिन्दी (Hindi)': 'hi',
    'मराठी (Marathi)': 'mr',
    'தமிழ் (Tamil)': 'ta',
    'తెలుగు (Telugu)': 'te',
    'ગુજરાતી (Gujarati)': 'gu',
    'ਪੰਜਾਬੀ (Punjabi)': 'pa',
    'ಕನ್ನಡ (Kannada)': 'kn',
  };
  return languageMap[languageName] ?? 'en';
}

class MyApp extends StatelessWidget {
  final Locale locale;

  const MyApp({super.key, required this.locale});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kisan Mitra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Arial',
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('mr'), // Marathi
        Locale('ta'), // Tamil
        Locale('te'), // Telugu
        Locale('gu'), // Gujarati
        Locale('pa'), // Punjabi
        Locale('kn'), // Kannada
      ],
      home: const SplashScreen(),
      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/signup': (context) => const SignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/home': (context) => const MainAppScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}
