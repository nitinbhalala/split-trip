package app.rudara.splittrip.ads

import android.content.Context
import android.view.LayoutInflater
import app.rudara.splittrip.R
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Builds the compact [NativeAdView] for `factoryId: 'listTile'`
 * (icon + headline + body + CTA), matching `res/layout/list_tile_native_ad.xml`.
 * Registered in MainActivity via `GoogleMobileAdsPlugin.registerNativeAdFactory`; the
 * corresponding Dart side is `NativeAdWidget` in lib/services/ads/native_ad_widget.dart.
 */
class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.list_tile_native_ad, null) as NativeAdView

        val headlineView = adView.findViewById<android.widget.TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<android.widget.TextView>(R.id.ad_body)
        val iconView = adView.findViewById<android.widget.ImageView>(R.id.ad_app_icon)
        val ctaView = adView.findViewById<android.widget.Button>(R.id.ad_call_to_action)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        if (nativeAd.body.isNullOrEmpty()) {
            bodyView.visibility = android.view.View.INVISIBLE
        } else {
            bodyView.visibility = android.view.View.VISIBLE
            bodyView.text = nativeAd.body
        }
        adView.bodyView = bodyView

        if (nativeAd.icon == null) {
            iconView.visibility = android.view.View.GONE
        } else {
            iconView.visibility = android.view.View.VISIBLE
            iconView.setImageDrawable(nativeAd.icon?.drawable)
        }
        adView.iconView = iconView

        if (nativeAd.callToAction.isNullOrEmpty()) {
            ctaView.visibility = android.view.View.INVISIBLE
        } else {
            ctaView.visibility = android.view.View.VISIBLE
            ctaView.text = nativeAd.callToAction
        }
        adView.callToActionView = ctaView

        NativeAdColors.apply(
            NativeAdColors.isDark(customOptions),
            headlineView,
            bodyView,
            ctaView,
            context.resources.displayMetrics.density,
        )

        adView.setNativeAd(nativeAd)
        return adView
    }
}
