import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<String?> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent;
      } else if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // Create fingerprint from multiple properties
        final fingerprint = '${androidInfo.model}_${androidInfo.device}_${androidInfo.brand}_${androidInfo.id}';
        return fingerprint.hashCode.toString();
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      print('Error getting device ID: $e');
    }
    return null;
  }

  Future<void> login(String googleId, String email, String? name, String? photoUrl, {String? referralCode}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final deviceId = await _getDeviceId();
      _user = await _apiService.loginWithGoogle(
        googleId: googleId,
        email: email,
        name: name,
        profilePic: photoUrl,
        deviceId: deviceId,
        referralCode: referralCode,
      );
      
      // Save user ID to shared prefs for auto-login
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setInt('userId', _user!.id);
      }
      
    } catch (e) {
      print('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUser() async {
     _isLoading = true;
     notifyListeners();
     try {
       final prefs = await SharedPreferences.getInstance();
       final userId = prefs.getInt('userId');
       if (userId != null) {
         _user = await _apiService.getUserProfile(userId);
       }
     } catch (e) {
       print('Load user error: $e');
     } finally {
       _isLoading = false;
       notifyListeners();
     }
  }

  Future<void> refreshUser() async {
     try {
       if (_user != null) {
         final updatedUser = await _apiService.getUserProfile(_user!.id);
         _user = updatedUser;
         notifyListeners();
       }
     } catch (e) {
       print('Refresh user error: $e');
     }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }
}
