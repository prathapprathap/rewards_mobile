import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';

class SettingsProvider with ChangeNotifier {
  static const _cacheKey = 'cached_app_settings_json';

  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    // 1. Instant hydrate from cache so the UI never waits on the network.
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached);
        if (decoded is Map) {
          _settings = Map<String, dynamic>.from(decoded);
          if (_settings['primary_color'] != null) {
            AppColors.updateColors(_settings['primary_color'].toString());
          }
          _isLoading = false;
          notifyListeners();
        }
      }
    } catch (_) {}

    // 2. Refresh from server in the background; emit again when it lands.
    try {
      final api = ApiService();
      final fresh = await api.getAppSettings();
      _settings = fresh;

      if (_settings.containsKey('primary_color')) {
        final colorHex = _settings['primary_color'].toString();
        AppColors.updateColors(colorHex);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_primary_color', colorHex);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(_settings));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  String getString(String key, String defaultValue) {
    return _settings[key]?.toString() ?? defaultValue;
  }

  double getDouble(String key, double defaultValue) {
    return double.tryParse(_settings[key]?.toString() ?? '') ?? defaultValue;
  }

  String get currencySymbol => getString('currency_symbol', '₹');
}
