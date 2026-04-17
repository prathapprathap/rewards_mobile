import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../constants/colors.dart';

class SettingsProvider with ChangeNotifier {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  Map<String, dynamic> get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    try {
      final api = ApiService();
      _settings = await api.getAppSettings();

      // Update dynamic colors if present
      if (_settings.containsKey('primary_color')) {
        final colorHex = _settings['primary_color'].toString();
        AppColors.updateColors(colorHex);

        // Cache for next launch
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_primary_color', colorHex);
      }

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
}
