import 'package:flutter/material.dart';
import 'package:split_trip/core/sizer/app_size.dart';

class AppOutlinedButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final double? height;
  final double width;

  const AppOutlinedButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.height,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? AppSize.h(50),
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: AppSize.symmetric(horizontal: 20),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.r(9)),
          ),
        ),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontSize: AppSize.sp(14)),
        ),
      ),
    );
  }
}
