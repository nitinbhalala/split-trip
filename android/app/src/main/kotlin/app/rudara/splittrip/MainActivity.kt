package app.rudara.splittrip

import app.rudara.splittrip.ads.AdvancedNativeAdFactory
import app.rudara.splittrip.ads.ListTileNativeAdFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

// class MainActivity : FlutterActivity()
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Native ad factories consumed by NativeAdWidget (lib/services/ads/native_ad_widget.dart)
        // via its `factoryId` param — keys here must match the strings passed there.
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            ListTileNativeAdFactory(this),
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "advanced",
            AdvancedNativeAdFactory(this),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "advanced")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
