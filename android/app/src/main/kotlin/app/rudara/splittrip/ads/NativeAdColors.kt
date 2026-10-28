package app.rudara.splittrip.ads

import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.widget.Button
import android.widget.TextView

/**
 * Text / CTA colors for the native ad layouts, following the app theme passed
 * from Flutter as `customOptions["isDark"]` (NativeAdWidget). Without this the
 * text takes the Activity's default color and can vanish on the card.
 */
object NativeAdColors {
    private const val PRIMARY = 0xFF10B981.toInt() // AppColors.primary

    fun isDark(customOptions: Map<String, Any>?): Boolean =
        customOptions?.get("isDark") as? Boolean ?: false

    fun apply(
        isDark: Boolean,
        headline: TextView,
        body: TextView,
        cta: Button,
        density: Float,
    ) {
        headline.setTextColor(if (isDark) Color.WHITE else 0xFF1C1B1F.toInt())
        body.setTextColor(if (isDark) 0xFFCAC4D0.toInt() else 0xFF49454F.toInt())

        cta.setTextColor(Color.WHITE)
        cta.backgroundTintList = null
        cta.background = GradientDrawable().apply {
            cornerRadius = 8 * density
            setColor(ColorStateList.valueOf(PRIMARY))
        }
    }
}
