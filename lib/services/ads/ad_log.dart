import 'package:flutter/foundation.dart';

/// Prints an Ad failure log in RED so it's instantly spottable in the console.
void logAdError(String message) {
  debugPrint('\x1B[31m$message\x1B[0m');
}

/// One-line native/banner cache + slot log, filterable by `[Ads]`:
/// `[Ads] banner | CACHE_HIT | profile_banner | ...`.
///
/// Events: LOAD_START, LOADED, LOAD_FAILED, REFRESH_FAILED, CACHE_HIT,
/// WAIT_LOADING, SKIP_COOLDOWN, CACHE_REUSE, IMPRESSION, INVALIDATED, SHOW,
/// COLLAPSE, FALLBACK, SLOT_RELEASE, KEPT_UNSHOWN, CACHE_FIRST,
/// PRELOAD_SKIPPED, REFRESHED.
void logAd(String format, String event, String placementId, [String? detail]) {
  final line =
      '[Ads] $format | $event | $placementId${detail == null ? '' : ' | $detail'}';
  if (event == 'LOAD_FAILED') {
    logAdError(line);
  } else {
    debugPrint(line);
  }
}
