// import 'package:flutter/material.dart';

// class AppImageLoader extends StatelessWidget {
//   final double size;
//   final double strokeWidth;
//   final Color? color;
//   final Widget? placeholder;

//   const AppImageLoader({
//     super.key,
//     this.size = 40,
//     this.strokeWidth = 2,
//     this.color,
//     this.placeholder,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final double innerSize = size - strokeWidth * 2 - 6;
//     final primaryColor = color ?? Theme.of(context).primaryColor;

//     return Center(
//       child: SizedBox(
//         width: size,
//         height: size,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             SizedBox(
//               width: size,
//               height: size,
//               child: CircularProgressIndicator(
//                 strokeWidth: strokeWidth,
//                 color: primaryColor,
//               ),
//             ),
//             ClipOval(
//               child: Container(
//                 width: innerSize,
//                 height: innerSize,
//                 color: Theme.of(context).scaffoldBackgroundColor,
//                 child: _buildImage(innerSize, primaryColor),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImage(double size, Color primaryColor) {
//     return Image.asset(
//       AppAssets.applogo,
//       width: size,
//       height: size,
//       fit: BoxFit.fitHeight,
//       errorBuilder: (_, __, ___) {
//         return _buildPlaceholder(size, primaryColor);
//       },
//     );
//   }

//   Widget _buildPlaceholder(double size, Color primaryColor) {
//     if (placeholder != null) return placeholder!;

//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(color: primaryColor),
//       child: Icon(
//         Icons.person,
//         color: Colors.white.withValues(alpha: 0.9),
//         size: size * 0.45,
//       ),
//     );
//   }
// }
