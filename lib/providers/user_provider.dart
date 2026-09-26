import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Old fingerprint (model+device+brand+build-id). It collides across every
  /// phone of the same model/firmware, but existing accounts have it stored
  /// server-side, so it's still sent to match them (see [_hardwareId]).
  static const _legacyDeviceIdKey = 'device_id_legacy_v1';

  Future<String?> _legacyDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? legacyId = prefs.getString(_legacyDeviceIdKey);
      if (legacyId == null) {
        legacyId = await _computeLegacyFingerprint();
        if (legacyId != null) {
          await prefs.setString(_legacyDeviceIdKey, legacyId);
        }
      }
      return legacyId;
    } catch (e) {
      print('Error getting device ID: $e');
    }
    return null;
  }

  static const _deviceChannel = MethodChannel('com.reward.server/device');

  /// Stable per-phone id that clearing app data or reinstalling can't reset
  /// (Android: ANDROID_ID, iOS: identifierForVendor). The backend uses it to
  /// enforce one account per phone and to tell apart different phones that
  /// share the same [_legacyDeviceIdKey] fingerprint.
  Future<String?> _hardwareId() async {
    try {
      if (kIsWeb) return null;
      if (Platform.isAndroid) {
        final id = await _deviceChannel.invokeMethod<String>('getAndroidId');
        // Known bogus value shared by many old/buggy devices.
        if (id == null || id.isEmpty || id == '9774d56d682e549c') return null;
        return 'a_$id';
      } else if (Platform.isIOS) {
        final id = (await DeviceInfoPlugin().iosInfo).identifierForVendor;
        return id == null ? null : 'i_$id';
      }
    } catch (e) {
      print('Error getting hardware ID: $e');
    }
    return null;
  }

  Future<String?> _computeLegacyFingerprint() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent;
      } else if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final fingerprint = '${androidInfo.model}_${androidInfo.device}_${androidInfo.brand}_${androidInfo.id}';
        return fingerprint.hashCode.toString();
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      print('Error computing legacy device fingerprint: $e');
    }
    return null;
  }

  // Deliberately does NOT set _isLoading: AuthWrapper swaps LoginScreen for
  // the splash while isLoading is true, which disposes LoginScreen and
  // silently drops its error toast when login fails. LoginScreen shows its
  // own spinner instead.
  Future<void> login(String googleId, String email, String? name, String? photoUrl, {String? referralCode}) async {
    try {
      final legacyDeviceId = await _legacyDeviceId();
      final hardwareId = await _hardwareId();
      // Single attempt: the backend uses hardware_id to tell a different phone
      // of the same model apart from this phone, so no retry is needed.
      _user = await _apiService.loginWithGoogle(
        googleId: googleId,
        email: email,
        name: name,
        profilePic: photoUrl,
        deviceId: legacyDeviceId,
        hardwareId: hardwareId,
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
