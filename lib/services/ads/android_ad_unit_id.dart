/// Live AdMob ad unit IDs for **Android**. Used only when
/// `AdUnitIds.testAds = false`. An empty ID means that ad never loads.
///
/// The AdMob App ID (`ca-app-pub-xxx~yyy`) goes in
/// android/app/src/main/AndroidManifest.xml, not here.
///
/// Split Trip (app.rudara.splittrip) — AdMob App ID
/// ca-app-pub-6387171395672190~8326982421.
class AndroidAdUnitId {
  AndroidAdUnitId._();

  // ─── Open ads ───────────────────────────────────────────────────
  // static const String appOpen = '';
  static const String appOpen = 'ca-app-pub-6387171395672190/3419551931';

  // Rewarded removed (not used).
  // // ─── Rewarded ──────────────────────────────────────────────────
  // static const String dailyAutoBackupRewarded = '';

  // ─── Interstitial list: every interstitial (startup, back, ✕/✓, delete,
  // theme, backup) takes the next ID in sequence.
  // static const List<String> interstitialIds = [];
  static const List<String> interstitialIds = [
    'ca-app-pub-6387171395672190/6388496052', // interstitial_1_android
    'ca-app-pub-6387171395672190/7640586711', // interstitial_2_android
  ];

  // ─── Dynamic lists (every screen except the main screen) ──────
  // Each new banner / native request takes the next ID (round-robin).
  // static const List<String> bannerIds = [];
  // static const List<String> nativeIds = [];
  static const List<String> bannerIds = [
    'ca-app-pub-6387171395672190/5648848191', // banner_2_android
    'ca-app-pub-6387171395672190/1709603182', // banner_3_android
    'ca-app-pub-6387171395672190/6770358174', // banner_4_android
    'ca-app-pub-6387171395672190/5457276505', // banner_5_android
    'ca-app-pub-6387171395672190/7891868152', // banner_6_android
  ];
  static const List<String> nativeIds = [
    'ca-app-pub-6387171395672190/1676767410', // native_1_android
    'ca-app-pub-6387171395672190/2832394428', // native_2_android
    'ca-app-pub-6387171395672190/3856208191', // native_3_android
    'ca-app-pub-6387171395672190/4004594031', // native_4_android
    'ca-app-pub-6387171395672190/8916963182', // native_5_android
  ];

  // ─── Fixed IDs ──────────────────────────────────────────────────
  // static const String mainBottomBanner = '';
  // static const String exitDialogNative = '';
  // // Fallback for the exit sheet native.
  // static const String exitDialogBanner = '';
  // banner_1_android
  static const String mainBottomBanner =
      'ca-app-pub-6387171395672190/4977718175';
  // Exit sheet now takes its native / banner from the lists above.
  // // native_1_android
  // static const String exitDialogNative =
  //     'ca-app-pub-6387171395672190/1676767410';
  // // Fallback for the exit sheet native. banner_2_android
  // static const String exitDialogBanner =
  //     'ca-app-pub-6387171395672190/5648848191';
}
