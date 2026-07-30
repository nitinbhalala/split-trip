import 'package:flutter/material.dart';

class AppAutoSizeText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  final double maxFontSize;
  final double minFontSize;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final TextStyle? style;
  final Alignment? alignment;

  const AppAutoSizeText({
    super.key,
    required this.text,
    this.color,
    this.fontWeight,
    this.maxFontSize = 18,
    this.minFontSize = 10,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.style,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    Alignment resolvedAlignment = alignment ?? Alignment.centerLeft;
    if (alignment == null) {
      switch (textAlign) {
        case TextAlign.center:
          resolvedAlignment = Alignment.center;
          break;
        case TextAlign.right:
        case TextAlign.end:
          resolvedAlignment = Alignment.centerRight;
          break;
        default:
          resolvedAlignment = Alignment.centerLeft;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: resolvedAlignment,
            child: Text(
              text,
              maxLines: maxLines,
              overflow: overflow,
              textAlign: textAlign,
              style:
                  style ??
                  TextStyle(
                    color: color,
                    fontFamily: "Inter",
                    fontWeight: fontWeight,
                    fontSize: maxFontSize,
                  ),
            ),
          ),
        );
      },
    );
  }
}
