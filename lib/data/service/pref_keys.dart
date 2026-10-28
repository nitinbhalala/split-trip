class PrefKeys {
  PrefKeys._();
  static const isFirstTime = "is_first_time";
  static const lastUpdateCheck = "last_update_check";

  static const userFirstName = "user_first_name";
  static const userLastName = "user_last_name";
  static const userEmail = "user_email";
  static const userPhone = "user_phone";
  static const userProfileImagePath = "user_profile_image_path";
  static const useDummyData = "use_dummy_data";
  static const categoryBudgets = "category_budgets";
  static const savingTarget = "saving_target";
  static const expectedIncome = "expected_income";
  static const themeMode = "theme_mode";
  static const currencyCode = "currency_code";

  // Install report (AppInstallService).
  static const installId = "install_id";
  static const appInstallCalled = "app_install_called";

  // Daily Auto Backup (off by default, turned on with a rewarded ad).
  static const dailyAutoBackupEnabled = "daily_auto_backup_enabled";
  // Opens counted for the one-time "turn on Daily Auto Backup?" popup.
  static const dailyAutoBackupSuggestOpens = "daily_auto_backup_suggest_opens";
  static const dailyAutoBackupSuggested = "daily_auto_backup_suggested";

  // Ad counters (AppOpenAdService): cold starts and returns from recents.
  static const appLaunchCount = "app_launch_count";
  static const recentsReturnCount = "recents_return_count";
}
