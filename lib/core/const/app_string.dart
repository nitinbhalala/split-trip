import 'dart:io';

class AppString {
  static const String appname = "Split Trip";
  static const String appPackageName = "app.rudara.splittrip";
  static const String serverClientId =
      "582158608949-9diqhcke4927r4vdjfnt74fbj7j3d0le.apps.googleusercontent.com";

  static const String privacyPolicyURl =
      "https://sites.google.com/view/appsplittrip-privacy";

  // share app link
  static const String androidShareAppLink =
      "https://play.google.com/store/apps/details?id=$appPackageName";
  static const String iosShareAppLink =
      "https://apps.apple.com/app/$appPackageName";

  // rate us
  static const String androidRateUsLink =
      "https://play.google.com/store/apps/details?id=$appPackageName";
  static const String iosRateUsLink =
      "https://apps.apple.com/app/$appPackageName?action=write-review";

  static String get shareAppLink =>
      Platform.isIOS ? iosShareAppLink : androidShareAppLink;
  static String get rateUsLink =>
      Platform.isIOS ? iosRateUsLink : androidRateUsLink;
}
