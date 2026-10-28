/// Live AdMob ad unit IDs for **iOS**. Used only when
/// `AdUnitIds.testAds = false`. An empty ID means that ad never loads.
///
/// The AdMob App ID (`ca-app-pub-xxx~yyy`) goes in ios/Runner/Info.plist
/// (`GADApplicationIdentifier`), not here.
///
/// TODO: fill in Split Trip's iOS ad unit IDs from AdMob.
class IosAdUnitId {
  IosAdUnitId._();

  // ─── Open ads ───────────────────────────────────────────────────
  static const String appOpen = '';

  // Rewarded removed (not used).
  // // ─── Rewarded ──────────────────────────────────────────────────
  // static const String dailyAutoBackupRewarded = '';

  // ─── Interstitial list: every interstitial (startup, back, ✕/✓, delete,
  // theme, backup) takes the next ID in sequence.
  static const List<String> interstitialIds = [];

  // ─── Dynamic lists (every screen except the main screen) ──────
  // Each new banner / native request takes the next ID (round-robin).
  static const List<String> bannerIds = [];
  static const List<String> nativeIds = [];

  // ─── Fixed IDs ──────────────────────────────────────────────────
  static const String mainBottomBanner = '';
  static const String exitDialogNative = '';
  // Fallback for the exit sheet native.
  static const String exitDialogBanner = '';
}
