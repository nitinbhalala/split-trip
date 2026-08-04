import 'package:split_trip/core/common/helper/currency_input_formatter.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';

class CustomTextField extends StatefulWidget {
  final String title;
  final TextStyle? titleStyle;
  final String? rightIcon;
  final bool? isPass;
  final bool isSuffix;
  final bool? isFocus;
  final InputBorder? allBorder;
  final String? hint;
  final bool readOnly;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final bool? isDOllar;
  final TextInputType? keyBoardType;
  final void Function(String)? onFieldSubmitted;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final int? minLines;
  final int? maxLines;
  final Widget? prefixIcon;
  final AutovalidateMode? autovalidateMode;
  final TextEditingController? controller;
  final Color? focusBorderColor;
  final Color? disbleBorderColor;
  //add
  final Color? fillColor;
  final bool fill;
  final double borderRadius;
  final bool removeBorder;
  final EdgeInsets? contentPadding;
  final bool isDense;
  final TextStyle? textStyle;
  final TextStyle? hintTextStyle;
  final TextAlign? textAlign;
  final bool isMoney;
  final double? dollarFontSize;
  final TextStyle? dollarStyle;
  const CustomTextField({
    required this.title,
    super.key,
    this.rightIcon,
    this.allBorder,
    this.isPass = false,
    this.isSuffix = false,
    this.hint,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.focusNode,
    this.inputFormatters,
    this.isDOllar = false,
    this.isFocus = false,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.keyBoardType,
    this.suffixIcon,
    this.controller,
    this.minLines,
    this.maxLines,
    this.prefixIcon,
    this.autovalidateMode,
    this.fillColor,
    this.borderRadius = 12,
    this.removeBorder = false,
    this.isDense = false,
    this.titleStyle,
    this.contentPadding,
    this.focusBorderColor,
    this.textStyle,
    this.textAlign,
    this.disbleBorderColor,
    this.hintTextStyle,
    this.fill = false,
    this.isMoney = false,
    this.dollarFontSize,
    this.dollarStyle,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final TextEditingController _controller;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _obscureText = widget.isPass ?? false;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  double _getLeftPadding(String symbol, double symbolFontSize) {
    if (symbol.length <= 1) return symbolFontSize + 4.0;
    if (symbol.length == 2) return (symbolFontSize * 1.5) + 4.0;
    if (symbol.length == 3) return (symbolFontSize * 2.2) + 4.0;
    return (symbolFontSize * 2.8) + 4.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != '')
          Padding(
            padding: AppSize.only(left: 3, bottom: 3.0),
            child: Text(
              widget.title,
              style:
                  widget.titleStyle ?? Theme.of(context).textTheme.labelMedium,
            ),
          ),
        Obx(() {
          final String symbol = Get.isRegistered<CurrencyController>()
              ? Get.find<CurrencyController>().selectedCurrency.value.symbol
              : '\$';

          final double symbolFontSize =
              widget.dollarFontSize ??
              (widget.dollarStyle?.fontSize ??
                  (widget.textStyle?.fontSize ??
                      (widget.isDense ? AppSize.sp(14) : AppSize.sp(16))));

          final double leftPadding = widget.isDOllar == true
              ? _getLeftPadding(symbol, symbolFontSize)
              : 8.0;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              TextFormField(
                key: widget.key,
                autovalidateMode:
                    widget.autovalidateMode ??
                    AutovalidateMode.onUserInteraction,
                minLines: widget.minLines ?? 1,
                maxLines: widget.maxLines ?? 1,

                autofocus: widget.isFocus ?? false,
                textCapitalization: widget.isPass == true
                    ? TextCapitalization.none
                    : TextCapitalization.sentences,
                onChanged: widget.onChanged ?? (val) {},
                cursorColor: Theme.of(context).primaryColor,
                maxLength: widget.maxLength,

                validator:
                    widget.validator ??
                    (value) {
                      return null;
                    },
                style:
                    widget.textStyle ?? Theme.of(context).textTheme.titleSmall,

                textAlign: widget.textAlign ?? TextAlign.justify,
                onFieldSubmitted: widget.onFieldSubmitted,

                keyboardType: widget.isMoney
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : widget.keyBoardType,
                onTap: widget.onTap,
                focusNode: widget.focusNode,
                inputFormatters: [
                  if (widget.inputFormatters != null)
                    ...widget.inputFormatters!,
                  if (widget.isMoney) CurrencyInputFormatter(),
                ],
                controller: _controller,
                readOnly: widget.readOnly,
                enableInteractiveSelection: !(widget.readOnly),
                showCursor: !(widget.readOnly),
                obscureText: widget.isPass == true ? _obscureText : false,
                decoration: InputDecoration(
                  isDense: widget.isDense,
                  counter: SizedBox(),
                  contentPadding:
                      widget.contentPadding ??
                      AppSize.only(
                        left: leftPadding,
                        top: 13,
                        bottom: 13,
                        right: 8,
                      ),
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: _buildSuffixIcon(),
                  filled: widget.fill,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.15),

                  hintText: widget.hint ?? widget.title,
                  hintStyle:
                      widget.hintTextStyle ??
                      Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: AppColors.lightHint,
                      ),
                  border: widget.removeBorder
                      ? InputBorder.none
                      : widget.allBorder,
                  enabledBorder: widget.removeBorder
                      ? InputBorder.none
                      : (widget.allBorder ??
                            OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                widget.borderRadius,
                              ),
                              borderSide: BorderSide(
                                color: widget.readOnly
                                    ? (widget.disbleBorderColor ??
                                          Theme.of(context)
                                              .inputDecorationTheme
                                              .disabledBorder
                                              ?.borderSide
                                              .color ??
                                          Theme.of(context).disabledColor)
                                    : (widget.disbleBorderColor ??
                                          Theme.of(context)
                                              .inputDecorationTheme
                                              .enabledBorder
                                              ?.borderSide
                                              .color ??
                                          Theme.of(context).dividerColor),
                              ),
                            )),
                  focusedBorder: widget.removeBorder
                      ? InputBorder.none
                      : (widget.allBorder != null
                            ? (widget.allBorder is UnderlineInputBorder
                                  ? UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            widget.focusBorderColor ??
                                            Theme.of(context).primaryColor,
                                        width: 2,
                                      ),
                                    )
                                  : widget.allBorder)
                            : OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  widget.borderRadius,
                                ),
                                borderSide: BorderSide(
                                  color: widget.readOnly
                                      ? (widget.disbleBorderColor ??
                                            Theme.of(context)
                                                .inputDecorationTheme
                                                .disabledBorder
                                                ?.borderSide
                                                .color ??
                                            Theme.of(context).disabledColor)
                                      : (widget.focusBorderColor ??
                                            Theme.of(context)
                                                .inputDecorationTheme
                                                .focusedBorder
                                                ?.borderSide
                                                .color ??
                                            Theme.of(context).primaryColor),
                                ),
                              )),
                ),
              ),
              widget.isDOllar == false
                  ? const SizedBox(height: 0, width: 0)
                  : Padding(
                      padding: AppSize.only(left: 0.0),
                      child: Text(
                        symbol,
                        style:
                            widget.dollarStyle ??
                            Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontSize: symbolFontSize,
                            ),
                      ),
                    ),
            ],
          );
        }),
      ],
    );
  }

  /// 🔥 SAFE SUFFIX ICON HANDLER (NO BREAK)
  Widget? _buildSuffixIcon() {
    // Password + custom suffix icon
    if (widget.isPass == true && widget.suffixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.suffixIcon!,
          IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ],
      );
    }

    // Only password field
    if (widget.isPass == true) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          // size: AppSize.scale(20),
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    // Only custom suffix icon
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    return null;
  }
}
