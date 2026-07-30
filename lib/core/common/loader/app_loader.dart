import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;
  final bool fullScreen;

  const AppLoader({
    super.key,
    this.size = 36,
    this.color,
    this.message,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final loader = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!fullScreen) {
      return Center(child: loader);
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.2),
      child: Center(child: loader),
    );
  }
}
