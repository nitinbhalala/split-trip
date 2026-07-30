import 'package:flutter/widgets.dart';

class AppSize {
  AppSize._();

  // 🔧 Base design size (Figma / XD reference)
  static const double _designWidth = 375;
  static const double _designHeight = 812;

  static late MediaQueryData _media;
  static late Size _screen;
  static late Orientation orientation;

  // Screen width / height
  static late double sw;
  static late double sh;

  // Device types
  static late bool isMobile;
  static late bool isTablet;
  static late bool isDesktop;

  // Internal scales
  static late double _scaleW;
  static late double _scaleH;
  static late double _scale;

  // ----------------------------
  // INIT (CALL ONCE PER SCREEN)
  // ----------------------------
  static void init(BuildContext context) {
    _media = MediaQuery.of(context);
    _screen = _media.size;
    orientation = _media.orientation;

    sw = _screen.width;
    sh = _screen.height;

    // 🔥 Breakpoints
    isMobile = sw < 600;
    isTablet = sw >= 600 && sw < 1024;
    isDesktop = sw >= 1024;

    // 🔥 Clamp scaling (prevents over-scaling)
    _scaleW = _clamp(sw / _designWidth, 0.85, 1.4);
    _scaleH = _clamp(sh / _designHeight, 0.85, 1.4);
    _scale = (_scaleW + _scaleH) / 2;
  }

  // ----------------------------
  // BASIC SIZES
  // ----------------------------

  /// Width
  static double w(double value) => value * _scaleW;

  /// Height
  static double h(double value) => value * _scaleH;

  /// Radius
  static double r(double value) => value * _scale;

  /// Scale (icons / animation)
  static double scale(double value) => value * _scale;

  /// Font size (accessibility safe)
  static double sp(double value) {
    final systemScale = _media.textScaler.scale(1.0);
    return value * _scale * _clamp(systemScale, 0.9, 1.2);
  }

  // ----------------------------
  // PADDING & MARGIN
  // ----------------------------

  static EdgeInsets all(double value) => EdgeInsets.all(w(value));

  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: w(horizontal), vertical: h(vertical));

  static EdgeInsets only({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) => EdgeInsets.only(
    left: w(left),
    right: w(right),
    top: h(top),
    bottom: h(bottom),
  );

  // ----------------------------
  // SPACING (GAPS)
  // ----------------------------
  static SizedBox gapH(double value) => SizedBox(height: h(value));
  static SizedBox gapW(double value) => SizedBox(width: w(value));
  // ----------------------------
  // GRID SYSTEM
  // ----------------------------
  static int gridCount({int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  // ----------------------------
  // CONTENT WIDTH (DESKTOP POLISH)
  // ----------------------------

  static double contentWidth() {
    if (isDesktop) return 1100;
    if (isTablet) return 800;
    return sw;
  }

  // ----------------------------
  // INTERNAL CLAMP
  // ----------------------------

  static double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static EdgeInsetsGeometry?    paddingAll(int i) {
    return null;
  }
  //all spcae mare
  static double minCardWidth() {
  if (sw <= 360) return 95;
  if (sw <= 390) return 105;
  if (sw <= 430) return 115;
  return 125;
}
}
