import google_mobile_ads
import GoogleMobileAds
import UIKit

/// Builds the larger `NativeAdView` for `factoryId: 'advanced'`
/// (icon + headline + rating + media + body + CTA), built programmatically.
/// Registered in AppDelegate alongside `ListTileNativeAdFactory`.
class AdvancedNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView()

    let iconView = UIImageView()
    iconView.contentMode = .scaleAspectFill
    iconView.clipsToBounds = true
    iconView.translatesAutoresizingMaskIntoConstraints = false

    let headlineLabel = UILabel()
    headlineLabel.font = .boldSystemFont(ofSize: 15)
    headlineLabel.numberOfLines = 1
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false

    let starsLabel = UILabel()
    starsLabel.font = .systemFont(ofSize: 11)
    starsLabel.textColor = .systemYellow
    starsLabel.translatesAutoresizingMaskIntoConstraints = false

    let headlineStack = UIStackView(arrangedSubviews: [headlineLabel, starsLabel])
    headlineStack.axis = .vertical
    headlineStack.spacing = 2
    headlineStack.alignment = .leading
    headlineStack.translatesAutoresizingMaskIntoConstraints = false

    let attributionLabel = UILabel()
    attributionLabel.text = "Ad"
    attributionLabel.font = .boldSystemFont(ofSize: 9)
    attributionLabel.textColor = .white
    attributionLabel.backgroundColor = UIColor(red: 1.0, green: 0.596, blue: 0.0, alpha: 1.0)
    attributionLabel.textAlignment = .center
    attributionLabel.layer.cornerRadius = 2
    attributionLabel.clipsToBounds = true
    attributionLabel.translatesAutoresizingMaskIntoConstraints = false

    let mediaView = MediaView()
    mediaView.translatesAutoresizingMaskIntoConstraints = false

    let bodyLabel = UILabel()
    bodyLabel.font = .systemFont(ofSize: 13)
    bodyLabel.numberOfLines = 2
    bodyLabel.textColor = .darkGray
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false

    let ctaButton = UIButton(type: .system)
    ctaButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
    ctaButton.setTitleColor(.white, for: .normal)
    ctaButton.backgroundColor = UIColor(red: 0.13, green: 0.46, blue: 0.98, alpha: 1.0)
    ctaButton.layer.cornerRadius = 8
    ctaButton.translatesAutoresizingMaskIntoConstraints = false
    ctaButton.isUserInteractionEnabled = false

    let topRow = UIStackView(arrangedSubviews: [iconView, headlineStack, attributionLabel])
    topRow.axis = .horizontal
    topRow.alignment = .center
    topRow.spacing = 8
    topRow.translatesAutoresizingMaskIntoConstraints = false

    let rootStack = UIStackView(arrangedSubviews: [topRow, mediaView, bodyLabel, ctaButton])
    rootStack.axis = .vertical
    rootStack.spacing = 8
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    adView.addSubview(rootStack)
    NSLayoutConstraint.activate([
      rootStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      rootStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      rootStack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 8),
      rootStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -8),

      iconView.widthAnchor.constraint(equalToConstant: 40),
      iconView.heightAnchor.constraint(equalToConstant: 40),
      ctaButton.heightAnchor.constraint(equalToConstant: 40),
      // AdMob minimum 120x120 for the MediaView; it takes the rest of the
      // fixed 300pt slot (kAdvancedNativeAdHeight).
      mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
      topRow.heightAnchor.constraint(equalToConstant: 40),
    ])
    mediaView.setContentHuggingPriority(.defaultLow, for: .vertical)
    mediaView.setContentCompressionResistancePriority(.required, for: .vertical)
    bodyLabel.setContentHuggingPriority(.required, for: .vertical)

    headlineLabel.text = nativeAd.headline
    adView.headlineView = headlineLabel

    adView.mediaView = mediaView
    mediaView.mediaContent = nativeAd.mediaContent

    if let body = nativeAd.body, !body.isEmpty {
      bodyLabel.text = body
      bodyLabel.isHidden = false
    } else {
      bodyLabel.isHidden = true
    }
    adView.bodyView = bodyLabel

    if let icon = nativeAd.icon?.image {
      iconView.image = icon
      iconView.isHidden = false
    } else {
      iconView.isHidden = true
    }
    adView.iconView = iconView

    if let cta = nativeAd.callToAction, !cta.isEmpty {
      ctaButton.setTitle(cta, for: .normal)
      ctaButton.isHidden = false
    } else {
      ctaButton.isHidden = true
    }
    adView.callToActionView = ctaButton

    if let rating = nativeAd.starRating?.doubleValue {
      starsLabel.text = String(format: "★ %.1f", rating)
      starsLabel.isHidden = false
    } else {
      starsLabel.isHidden = true
    }
    adView.starRatingView = starsLabel

    NativeAdColors.apply(
      isDark: NativeAdColors.isDark(customOptions),
      headline: headlineLabel,
      body: bodyLabel,
      cta: ctaButton
    )

    adView.nativeAd = nativeAd
    return adView
  }
}

/// Text / CTA colors for the native ad views, following the app theme passed
/// from Flutter as `customOptions["isDark"]` (NativeAdWidget) — not the iOS
/// system appearance, which can differ from the app's theme.
enum NativeAdColors {
  /// AppColors.primary (0xFF10B981).
  static let primary = UIColor(red: 0x10 / 255, green: 0xB9 / 255, blue: 0x81 / 255, alpha: 1)

  static func isDark(_ customOptions: [AnyHashable: Any]?) -> Bool {
    customOptions?["isDark"] as? Bool ?? false
  }

  static func apply(isDark: Bool, headline: UILabel, body: UILabel, cta: UIButton) {
    headline.textColor = isDark ? .white : UIColor(red: 0x1C / 255, green: 0x1B / 255, blue: 0x1F / 255, alpha: 1)
    body.textColor = isDark
      ? UIColor(red: 0xCA / 255, green: 0xC4 / 255, blue: 0xD0 / 255, alpha: 1)
      : UIColor(red: 0x49 / 255, green: 0x45 / 255, blue: 0x4F / 255, alpha: 1)
    cta.backgroundColor = primary
    cta.setTitleColor(.white, for: .normal)
  }
}
