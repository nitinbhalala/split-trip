import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppRichText extends StatelessWidget {
  final List<AppTextSpan> spans;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const AppRichText({
    super.key,
    required this.spans,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(
        children: spans
            .map(
              (e) => TextSpan(
                text: e.text,
                style: e.style,
                recognizer: e.onTap != null
                    ? (TapGestureRecognizer()..onTap = e.onTap)
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}

class AppTextSpan {
  final String text;
  final TextStyle? style;
  final VoidCallback? onTap;

  const AppTextSpan({
    required this.text,
    this.style,
    this.onTap,
  });
}