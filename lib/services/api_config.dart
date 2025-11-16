import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Production server URL
  static const String _productionUrl = 'https://kisan-mitra-e656.onrender.com/api';
  
  // Development URLs (for local testing)
  static String _getDevelopmentUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }
  
  // Use production URL by default
  // To use local development server, change this to false
  static const bool _useProduction = true;
  
  static String get baseUrl {
    return _useProduction ? _productionUrl : _getDevelopmentUrl();
  }
  
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }
}

