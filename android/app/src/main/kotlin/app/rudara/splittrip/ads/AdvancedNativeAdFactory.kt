package app.rudara.splittrip.ads

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import app.rudara.splittrip.R
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/**
 * Builds the larger [NativeAdView] for `factoryId: 'advanced'` (media + headline +
 * rating + body + CTA), matching `res/layout/advanced_native_ad.xml`. Registered in
 * MainActivity alongside [ListTileNativeAdFactory].
 */
class AdvancedNativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        // val adView = LayoutInflater.from(context)
        //     .inflate(R.layout.advanced_native_ad, null) as NativeAdView
        // v2: MediaView never under 120dp (AdMob validator) — see the layout.
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.advanced_native_ad_v2, null) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        val starsView = adView.findViewById<RatingBar>(R.id.ad_stars)

        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView

        adView.mediaView = mediaView
        nativeAd.mediaContent?.let { mediaView.mediaContent = it }

        if (nativeAd.body.isNullOrEmpty()) {
            // bodyView.visibility = View.INVISIBLE
            // GONE: the media gets the space instead of an empty gap.
            bodyView.visibility = View.GONE
        } else {
            bodyView.visibility = View.VISIBLE
            bodyView.text = nativeAd.body
        }
        adView.bodyView = bodyView

        if (nativeAd.icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.visibility = View.VISIBLE
            iconView.setImageDrawable(nativeAd.icon?.drawable)
        }
        adView.iconView = iconView

        if (nativeAd.callToAction.isNullOrEmpty()) {
            ctaView.visibility = View.INVISIBLE
        } else {
            ctaView.visibility = View.VISIBLE
            ctaView.text = nativeAd.callToAction
        }
        adView.callToActionView = ctaView

        val rating = nativeAd.starRating
        if (rating == null) {
            starsView.visibility = View.INVISIBLE
        } else {
            starsView.visibility = View.VISIBLE
            starsView.rating = rating.toFloat()
        }
        adView.starRatingView = starsView

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
