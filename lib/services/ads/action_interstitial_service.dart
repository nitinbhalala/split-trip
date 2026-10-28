import 'package:flutter/material.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/interstitial_ad_helper.dart';
import 'package:split_trip/services/firebase/remote_config_service.dart';

/// Interstitials counted per user action, frequency from Remote Config:
///  - **back** (`splittrip_back`): ← app bar icon, Android back button/gesture,
///    iOS swipe back — only when a screen actually closes. A pop from code
///    (e.g. `Get.back()` after a save) is not a back.
///  - **theme change**: on every change (no Remote Config key). The caller
///    awaits the ad, so the theme is applied only after the ad is closed.
///  (✕ cancel / ✓ save and delete ads removed with their Remote Config keys.)
///
/// Every Nth action shows the ad (`count % N == 0`, N <= 0 = never). If the
/// ad is not loaded at that moment, it is shown on the next action instead
/// of popping up late. Counts live for the app session.
class ActionInterstitialService with WidgetsBindingObserver {
  ActionInterstitialService._();
  static final ActionInterstitialService instance =
      ActionInterstitialService._();

  /// Add to `GetMaterialApp.navigatorObservers` — sees the actual screen pops.
  static final NavigatorObserver navigatorObserver = _BackNavigatorObserver();

  /// Screens whose back is not counted (no back ad).
  static const Set<String> _noBackAdRoutes = {AppRoutes.groupDetail};

  /// A pop this soon after a back intent counts as a back.
  static const Duration _backIntentWindow = Duration(milliseconds: 1500);

  late final _ActionCounter _back = _ActionCounter(
    name: 'back',
    every: () => RemoteConfigService.backAdEvery,
    helper: InterstitialAdHelper(
      adUnitId: AdUnitIds.backInterstitial,
      placement: 'back',
    ),
  );
  // late final _ActionCounter _saveCancel = _ActionCounter(
  //   name: 'save_cancel',
  //   every: () => RemoteConfigService.saveCancelAdEvery,
  //   helper: InterstitialAdHelper(
  //     adUnitId: AdUnitIds.saveCancelInterstitial,
  //     placement: 'save_cancel',
  //   ),
  // );
  // late final _ActionCounter _delete = _ActionCounter(
  //   name: 'delete',
  //   every: () => RemoteConfigService.deleteAdEvery,
  //   helper: InterstitialAdHelper(
  //     adUnitId: AdUnitIds.deleteInterstitial,
  //     placement: 'delete',
  //   ),
  // );
  late final _ActionCounter _themeChange = _ActionCounter(
    name: 'theme_change',
    // every: () => RemoteConfigService.themeChangeAdEvery,
    // Every theme change shows the ad.
    every: () => 1,
    helper: InterstitialAdHelper(
      adUnitId: AdUnitIds.themeChangeInterstitial,
      placement: 'theme_change',
    ),
  );

  bool _initialized = false;
  DateTime? _backIntentAt;
  bool _inUserGesture = false;

  /// Call before `runApp` so the system-back hook runs before the app's own
  /// back handling (observers are asked in the order they were added).
  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  /// Loads every action ad so the first due action can show one — call once
  /// the main screen is reached.
  void preload() {
    if (!AdUnitIds.adsEnabled) return;
    // _back.helper.preload();
    // _saveCancel.helper.preload();
    // _delete.helper.preload();
    // _themeChange.helper.preload();
    for (final c in [
      _back,
      // _saveCancel,
      // _delete,
      _themeChange,
    ]) {
      c.helper.preload(reason: 'main_screen_open');
    }
  }

  /// Screen-open loading: an action's ad loads only when the user opens a
  /// screen where that action can happen AND the next such action is the
  /// ad's turn (or a missed one is pending). Nothing loads in advance
  /// otherwise, and nothing reloads after an ad was shown — no ad request
  /// sits waiting.
  void _prepare(_ActionCounter c) {
    if (!AdUnitIds.adsEnabled) return;
    final every = c.every();
    if (every <= 0) return;
    final nextDue = c.pending || (c.count + 1) % every == 0;
    if (!nextDue) {
      debugPrint(
        '[Ads] [ActionAd] ${c.name} screen open → next is #${c.count + 1}, '
        'not due (every $every): no load',
      );
      return;
    }
    debugPrint(
      '[Ads] [ActionAd] ${c.name} screen open → next #${c.count + 1} is due: load',
    );
    c.helper.preload(reason: 'screen_open_next_is_due');
  }

  // /// Add/Edit Category, Edit Profile opened (✕ / ✓, Cancel / Save).
  // static void prepareSaveCancel() => instance._prepare(instance._saveCancel);
  //
  // /// Dashbord tab, Group Info, Select Category opened (Delete).
  // static void prepareDelete() => instance._prepare(instance._delete);

  /// Theme screen opened.
  static void prepareThemeChange() => instance._prepare(instance._themeChange);

  /// ← app bar icon tapped. The pop that follows counts as a back.
  static void markBackIntent() => instance._backIntentAt = DateTime.now();

  // /// ✕ cancel or ✓ save tapped.
  // static void onSaveOrCancel() => instance._register(instance._saveCancel);
  //
  // /// Delete confirmed — await it, then delete. Returns once the ad (if any)
  // /// is closed.
  // static Future<void> onDelete() => instance._register(instance._delete);

  /// A different theme picked — await it, then apply the theme.
  static Future<void> onThemeChange() =>
      instance._register(instance._themeChange);

  /// Android back button / non-predictive gesture. Never consumes the event.
  @override
  Future<bool> didPopRoute() async {
    markBackIntent();
    return false;
  }

  // void _onPagePopped() {
  void _onPagePopped(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final intentAt = _backIntentAt;
    final isUserBack =
        _inUserGesture ||
        (intentAt != null &&
            DateTime.now().difference(intentAt) < _backIntentWindow);
    _backIntentAt = null;
    // if (isUserBack) _register(_back);
    if (!isUserBack) return;
    if (_noBackAdRoutes.contains(route.settings.name)) {
      debugPrint(
        '[Ads] [ActionAd] back from ${route.settings.name} → not counted',
      );
      return;
    }
    _register(_back);
    // Still a screen to go back from: load now if its back is the ad's turn.
    if (previousRoute is PageRoute && !previousRoute.isFirst) _prepare(_back);
  }

  // void _register(_ActionCounter c) {
  /// Counts the action and shows the ad when due. The future completes when
  /// that ad closes (right away if none was shown).
  Future<void> _register(_ActionCounter c) async {
    if (!AdUnitIds.adsEnabled) return;
    // Its ad is on screen right now (a quick second tap) — not a new action.
    if (c.helper.isShowing) {
      debugPrint('[Ads] [ActionAd] ${c.name} → ignored, its ad is on screen');
      return;
    }
    final every = c.every();
    c.count++;
    final due = every > 0 && c.count % every == 0;
    debugPrint(
      '[Ads] [ActionAd] ${c.name} #${c.count} | every $every | '
      'due: $due | pending: ${c.pending}',
    );
    if (every <= 0) {
      c.pending = false;
      return;
    }
    // if (!due && !c.pending) return;
    if (!due && !c.pending) {
      // Not due: keep the ad warm, so it is ready (and not expired) when the
      // due action comes — also retries after an earlier failed load (F).
      // c.helper.preload();
      // c.helper.preload(reason: 'warm_not_due_yet');
      // No background "warm" load — only on screen open (see _prepare).
      return;
    }

    // if (c.helper.showIfReady()) {
    //   c.pending = false;
    //   debugPrint('[Ads] [ActionAd] ${c.name} → SHOW');
    // } else {
    // final shown = c.helper.showIfReadyAndWait();
    // if (c.helper.isShowing) {
    if (c.helper.isReadyToShow) {
      c.pending = false;
      debugPrint('[Ads] [ActionAd] ${c.name} → SHOW');
      // await shown;
      await c.helper.showIfReadyAndWait();
      debugPrint('[Ads] [ActionAd] ${c.name} → CLOSED');
    } else {
      // Not loaded yet — a load was started; show on the next action.
      // c.helper.preload();
      // c.helper.preload(reason: 'due_but_not_ready');
      // No load here — the next screen open loads it (pending = due).
      c.pending = true;
      debugPrint(
        '[Ads] [ActionAd] ${c.name} → NOT_READY, next ${c.name} shows it',
      );
    }
  }
}

class _ActionCounter {
  _ActionCounter({
    required this.name,
    required this.every,
    required this.helper,
  });

  final String name;
  final int Function() every;
  final InterstitialAdHelper helper;
  int count = 0;
  bool pending = false;
}

class _BackNavigatorObserver extends NavigatorObserver {
  ActionInterstitialService get _s => ActionInterstitialService.instance;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Only a closed screen counts — not a dialog or bottom sheet.
    if (route is PageRoute) {
      // _s._onPagePopped();
      _s._onPagePopped(route, previousRoute);
    } else {
      _s._backIntentAt = null;
    }
  }

  // iOS swipe back / Android predictive back gesture.
  /// A screen opened → the back from it may be the ad's turn.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _s._prepare(_s._back);
  }

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) {
    _s._inUserGesture = true;
  }

  @override
  void didStopUserGesture() {
    _s._inUserGesture = false;
  }
}
