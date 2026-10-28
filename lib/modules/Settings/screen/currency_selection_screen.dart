import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/common/widgets/app_rich_text.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/currecy_icons_model.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/banner_or_native_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CurrencySelectionScreen extends StatelessWidget {
  const CurrencySelectionScreen({super.key});

  String _getCurrencyName(String code) {
    switch (code) {
      case 'INR':
        return "Indian Rupee";
      case 'USD':
        return "United States Dollar";
      case 'EUR':
        return "Euro";
      case 'GBP':
        return "British Pound";
      case 'JPY':
        return "Japanese Yen";
      case 'RUB':
        return "Russian Ruble";
      case 'KRW':
        return "Korean Won";
      case 'TRY':
        return "Turkish Lira";
      case 'THB':
        return "Thai Baht";
      case 'VND':
        return "Vietnamese Dong";
      case 'BDT':
        return "Bangladeshi Taka";
      case 'PHP':
        return "Philippine Peso";
      case 'ILS':
        return "Israeli Shekel";
      case 'NGN':
        return "Nigerian Naira";
      case 'GHS':
        return "Ghanaian Cedi";
      case 'IDR':
        return "Indonesian Rupiah";
      case 'UAH':
        return "Ukrainian Hryvnia";
      case 'SAR':
        return "Saudi Riyal";
      case 'CRC':
        return "Costa Rican Colón";
      case 'PYG':
        return "Paraguayan Guaraní";
      case 'KZT':
        return "Kazakhstani Tenge";
      case 'LAK':
        return "Lao Kip";
      case 'AUD':
        return "Australian Dollar";
      case 'CAD':
        return "Canadian Dollar";
      case 'NZD':
        return "New Zealand Dollar";
      case 'SGD':
        return "Singapore Dollar";
      case 'HKD':
        return "Hong Kong Dollar";
      case 'CHF':
        return "Swiss Franc";
      case 'AED':
        return "United Arab Emirates Dirham";
      case 'QAR':
        return "Qatari Riyal";
      case 'OMR':
        return "Omani Rial";
      case 'KWD':
        return "Kuwaiti Dinar";
      case 'BHD':
        return "Bahraini Dinar";
      case 'PKR':
        return "Pakistani Rupee";
      case 'NPR':
        return "Nepalese Rupee";
      case 'LKR':
        return "Sri Lankan Rupee";
      case 'MYR':
        return "Malaysian Ringgit";
      case 'ZAR':
        return "South African Rand";
      case 'BRL':
        return "Brazilian Real";
      case 'MXN':
        return "Mexican Peso";
      case 'EGP':
        return "Egyptian Pound";
      case 'CLP':
        return "Chilean Peso";
      case 'COP':
        return "Colombian Peso";
      case 'ARS':
        return "Argentine Peso";
      case 'CZK':
        return "Czech Koruna";
      case 'SEK':
        return "Swedish Krona";
      case 'NOK':
        return "Norwegian Krone";
      case 'DKK':
        return "Danish Krone";
      case 'PLN':
        return "Polish Złoty";
      case 'HUF':
        return "Hungarian Forint";
      case 'RON':
        return "Romanian Leu";
      case 'ISK':
        return "Icelandic Króna";
      default:
        return "Global Currency";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyController = Get.find<CurrencyController>();

    return Scaffold(
      appBar: const CommonAppBar(
        title: "Select Currency",
        showBackButton: true,
      ),
      // Banner (native if the banner fails) at the bottom of the screen.
      bottomNavigationBar: BannerOrNativeAdWidget(
        bannerAdUnitId: AdUnitIds.selectCurrencyBanner,
        nativeAdUnitId: AdUnitIds.selectCurrencyNative,
        bannerPlacementId: 'select_currency_banner',
        nativePlacementId: 'select_currency_banner_fallback_native',
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: ListView.builder(
          padding: AppSize.symmetric(vertical: 8, horizontal: 12),
          itemCount: currencyList.length,

          itemBuilder: (context, index) {
            final currency = currencyList[index];
            final name = _getCurrencyName(currency.code);

            return Obx(() {
              final isSelected =
                  currencyController.selectedCurrency.value.code ==
                  currency.code;

              return AppCard(
                padding: EdgeInsets.zero,
                margin: AppSize.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,

                  minVerticalPadding: 1,
                  leading: Container(
                    width: AppSize.w(30),
                    height: AppSize.w(30),
                    padding: AppSize.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.primary
                                : AppColors.primaryDark),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Text(
                          currency.symbol,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: "Iner",
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.warningLight
                                : AppColors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  title: AppRichText(
                    spans: [
                      AppTextSpan(
                        text: currency.code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: AppSize.sp(13),
                        ),
                      ),
                      AppTextSpan(
                        text: " (${currency.symbol})",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: AppSize.sp(12),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: AppSize.sp(10),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: AppSize.sp(25),
                        )
                      : null,
                  onTap: () {
                    currencyController.updateCurrency(currency);
                    Get.back();
                    AppSnackbar.success(
                      message:
                          "Currency updated to ${currency.code} (${currency.symbol}) successfully!",
                    );
                  },
                ),
              );
            });
          },
        ),
      ),
    );
  }
}
