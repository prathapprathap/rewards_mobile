import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';

enum AppGateState { ok, maintenance, forceUpdate, optionalUpdate }

/// Polls the backend on app start to decide whether to:
///   • block with a maintenance screen
///   • block with a force-update screen
///   • show a dismissible "update available" banner
class AppGateProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  AppGateState _state = AppGateState.ok;
  String _currentVersion = '0.0.0';
  String _latestVersion = '0.0.0';
  String _minSupportedVersion = '0.0.0';
  String _maintenanceMessage = '';
  String _updateMessage = '';
  String _updateUrl = '';
  bool _optionalDismissed = false;
  bool _loaded = false;

  AppGateState get state => _state;
  String get currentVersion => _currentVersion;
  String get latestVersion => _latestVersion;
  String get minSupportedVersion => _minSupportedVersion;
  String get maintenanceMessage => _maintenanceMessage;
  String get updateMessage => _updateMessage;
  String get updateUrl => _updateUrl;
  bool get loaded => _loaded;
  bool get optionalDismissed => _optionalDismissed;

  Future<void> check() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      _currentVersion = pkg.version;
      final data = await _api.versionCheck(_currentVersion);

      _latestVersion = (data['latest_version'] ?? '').toString();
      _minSupportedVersion = (data['min_supported_version'] ?? '').toString();
      _maintenanceMessage = (data['maintenance_message'] ?? '').toString();
      _updateMessage = (data['update_message'] ?? '').toString();
      _updateUrl = (data['update_url'] ?? '').toString();

      final maintenance = data['maintenance_mode'] == true;
      final forceUpdate = data['update_required'] == true;
      final optionalUpdate = data['update_available'] == true;

      if (maintenance) {
        _state = AppGateState.maintenance;
      } else if (forceUpdate) {
        _state = AppGateState.forceUpdate;
      } else if (optionalUpdate) {
        _state = AppGateState.optionalUpdate;
      } else {
        _state = AppGateState.ok;
      }
    } catch (_) {
      // On network failure, don't block the app — let it through.
      _state = AppGateState.ok;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  void dismissOptional() {
    _optionalDismissed = true;
    notifyListeners();
  }
}
