import google_mobile_ads
import GoogleMobileAds
import UIKit

/// Builds the compact `NativeAdView` for `factoryId: 'listTile'`
/// (icon + headline + body + CTA), built programmatically since this target has
/// no .xib. Registered in AppDelegate; the corresponding Dart side is
/// `NativeAdWidget` in lib/services/ads/native_ad_widget.dart.
class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let adView = NativeAdView()

    let iconView = UIImageView()
    iconView.contentMode = .scaleAspectFill
    iconView.clipsToBounds = true
    iconView.translatesAutoresizingMaskIntoConstraints = false

    let attributionLabel = UILabel()
    attributionLabel.text = "Ad"
    attributionLabel.font = .boldSystemFont(ofSize: 9)
    attributionLabel.textColor = .white
    attributionLabel.backgroundColor = UIColor(red: 1.0, green: 0.596, blue: 0.0, alpha: 1.0)
    attributionLabel.textAlignment = .center
    attributionLabel.layer.cornerRadius = 2
    attributionLabel.clipsToBounds = true
    attributionLabel.translatesAutoresizingMaskIntoConstraints = false

    let headlineLabel = UILabel()
    headlineLabel.font = .boldSystemFont(ofSize: 14)
    headlineLabel.numberOfLines = 1
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false

    let bodyLabel = UILabel()
    bodyLabel.font = .systemFont(ofSize: 12)
    bodyLabel.numberOfLines = 1
    bodyLabel.textColor = .darkGray
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false

    let textStack = UIStackView(arrangedSubviews: [attributionLabel, headlineLabel, bodyLabel])
    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.alignment = .leading
    textStack.translatesAutoresizingMaskIntoConstraints = false

    let ctaButton = UIButton(type: .system)
    ctaButton.titleLabel?.font = .boldSystemFont(ofSize: 12)
    ctaButton.setTitleColor(.white, for: .normal)
    ctaButton.backgroundColor = UIColor(red: 0.13, green: 0.46, blue: 0.98, alpha: 1.0)
    ctaButton.layer.cornerRadius = 6
    ctaButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    ctaButton.translatesAutoresizingMaskIntoConstraints = false
    // Interaction is handled by NativeAdView's callToActionView tap forwarding.
    ctaButton.isUserInteractionEnabled = false

    adView.addSubview(iconView)
    adView.addSubview(textStack)
    adView.addSubview(ctaButton)

    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 8),
      iconView.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 48),
      iconView.heightAnchor.constraint(equalToConstant: 48),

      textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
      textStack.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
      textStack.trailingAnchor.constraint(lessThanOrEqualTo: ctaButton.leadingAnchor, constant: -10),

      ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -8),
      ctaButton.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
      ctaButton.heightAnchor.constraint(equalToConstant: 36),
    ])

    headlineLabel.text = nativeAd.headline
    adView.headlineView = headlineLabel

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
