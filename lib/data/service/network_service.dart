import 'dart:io';

/// Real internet check (not just "Wi-Fi is on"): a DNS lookup that fails or
/// times out means there is no usable internet.
class NetworkService {
  NetworkService._();

  static Future<bool> hasInternet({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool? _lastResult;
  static DateTime? _lastCheckedAt;
  static Future<bool>? _inFlight;

  /// [hasInternet], but one answer is reused for [maxAge] and parallel
  /// callers share one lookup — for ad requests, which often fire together.
  static Future<bool> hasInternetCached({
    Duration maxAge = const Duration(seconds: 5),
  }) {
    final at = _lastCheckedAt;
    final last = _lastResult;
    if (last != null && at != null && DateTime.now().difference(at) < maxAge) {
      return Future.value(last);
    }
    return _inFlight ??= hasInternet(timeout: const Duration(seconds: 3))
        .then((online) {
          _lastResult = online;
          _lastCheckedAt = DateTime.now();
          return online;
        })
        .whenComplete(() => _inFlight = null);
  }
}
