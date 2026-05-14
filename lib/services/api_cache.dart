import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight cache for API responses.
/// - In-memory layer for instant access during a session
/// - SharedPreferences layer for instant cold-start
/// - TTL-based staleness so stale data still renders, then refreshes
class ApiCache {
  ApiCache._();
  static final ApiCache instance = ApiCache._();

  final Map<String, _Entry> _mem = {};

  /// Returns cached value if present (even if stale), otherwise null.
  /// Does NOT trigger a network fetch — that's the caller's job.
  Future<String?> read(String key) async {
    final m = _mem[key];
    if (m != null) return m.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('apicache:$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final entry = _Entry(decoded['v'] as String, decoded['t'] as int);
      _mem[key] = entry;
      return entry.value;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isFresh(String key, Duration ttl) async {
    final m = _mem[key];
    int? ts = m?.savedAt;
    if (ts == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('apicache:$key');
        if (raw == null) return false;
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        ts = decoded['t'] as int;
      } catch (_) {
        return false;
      }
    }
    final ageMs = DateTime.now().millisecondsSinceEpoch - ts;
    return ageMs < ttl.inMilliseconds;
  }

  Future<void> write(String key, String value) async {
    final entry = _Entry(value, DateTime.now().millisecondsSinceEpoch);
    _mem[key] = entry;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'apicache:$key',
        jsonEncode({'v': entry.value, 't': entry.savedAt}),
      );
    } catch (_) {}
  }

  void invalidate(String key) {
    _mem.remove(key);
    SharedPreferences.getInstance().then((p) => p.remove('apicache:$key'));
  }
}

class _Entry {
  final String value;
  final int savedAt;
  _Entry(this.value, this.savedAt);
}

/// Helper: returns parsed JSON via cache-first, network-refresh pattern.
/// Calls [onValue] each time a value is available — possibly twice:
/// once from cache, once after the network refresh.
Future<void> cachedJson({
  required String key,
  required Duration ttl,
  required Future<String> Function() fetch,
  required void Function(dynamic json) onValue,
}) async {
  final cache = ApiCache.instance;

  final cached = await cache.read(key);
  if (cached != null) {
    try {
      onValue(jsonDecode(cached));
    } catch (_) {}
  }

  // Stale-while-revalidate: always refresh in the background so admin-side
  // changes propagate without waiting for TTL expiry or a re-login.
  try {
    final body = await fetch();
    await cache.write(key, body);
    onValue(jsonDecode(body));
  } catch (_) {
    // Network failed — caller already saw cached value (if any).
  }
}
