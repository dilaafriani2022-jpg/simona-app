import 'package:flutter/material.dart';

/// Utility class untuk responsive design
class Responsive {
  /// Mendapatkan breakpoint ukuran layar
  static const double mobileSmall = 320;
  static const double mobileMedium = 480;
  static const double mobileLarge = 600;
  static const double tablet = 768;
  static const double desktop = 1024;

  /// Cek jenis device
  static bool isMobileSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMedium;

  static bool isMobileMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMedium &&
      MediaQuery.of(context).size.width < mobileLarge;

  static bool isMobileLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLarge &&
      MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  /// Mendapatkan ukuran font responsif
  static double fontSize(BuildContext context,
      {required double base,
      double? mobile,
      double? tablet,
      double? desktop}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Responsive.desktop) return desktop ?? base;
    if (width >= Responsive.tablet) return tablet ?? base;
    if (width >= Responsive.mobileLarge) return mobile ?? base;
    return base * 0.95;
  }

  /// Mendapatkan padding responsif
  static EdgeInsets padding(
    BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) return EdgeInsets.all(_responsiveValue(context, all));
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? _responsiveValue(context, horizontal) : 0,
      vertical: vertical != null ? _responsiveValue(context, vertical) : 0,
    );
  }

  /// Mendapatkan nilai responsif berdasarkan ukuran layar
  static double _responsiveValue(BuildContext context, double baseValue) {
    if (isMobileSmall(context)) return baseValue * 0.85;
    if (isMobileMedium(context)) return baseValue * 0.90;
    if (isMobileLarge(context)) return baseValue;
    if (isTablet(context)) return baseValue * 1.1;
    return baseValue * 1.2;
  }

  /// Mendapatkan width responsif (untuk card, container, dll)
  static double width(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth;
  }

  /// Mendapatkan max width untuk card/container
  static double maxCardWidth(BuildContext context) {
    if (isDesktop(context)) return 500;
    if (isTablet(context)) return 450;
    if (isMobileLarge(context)) return double.infinity;
    return double.infinity;
  }

  /// Mendapatkan jumlah kolom untuk grid
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    if (isMobileLarge(context)) return 2;
    return 2;
  }

  /// Mendapatkan jumlah kolom untuk quick menu
  static int menuColumns(BuildContext context) {
    if (isDesktop(context)) return 6;
    if (isTablet(context)) return 5;
    if (isMobileLarge(context)) return 4;
    if (isMobileMedium(context)) return 4;
    return 3;
  }

  /// Mendapatkan tinggi button responsif
  static double buttonHeight(BuildContext context) {
    if (isMobileSmall(context)) return 44;
    return 52;
  }

  /// Mendapatkan ukuran icon responsif
  static double iconSize(BuildContext context, {required double base}) {
    if (isMobileSmall(context)) return base * 0.85;
    if (isTablet(context)) return base * 1.2;
    return base;
  }

  /// Widget wrapper untuk memberikan padding responsif
  static Widget responsivePadding(
    BuildContext context, {
    required Widget child,
    double horizontal = 20,
    double vertical = 16,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _responsiveValue(context, horizontal),
        vertical: _responsiveValue(context, vertical),
      ),
      child: child,
    );
  }

  /// Mendapatkan aspect ratio untuk grid card
  static double gridAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 1.5;
    if (isTablet(context)) return 1.4;
    if (isMobileLarge(context)) return 1.3;
    return 1.2;
  }

  /// Mendapatkan spacing responsif
  static double spacing(BuildContext context, {required double base}) {
    return _responsiveValue(context, base);
  }

  /// Cek apakah layar dalam mode landscape
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  /// Mendapatkan height dari app bar responsif
  static double appBarHeight(BuildContext context) {
    return isMobileSmall(context) ? 56 : 64;
  }

  /// Mendapatkan cross axis count untuk GridView yang dinamis
  static int responsiveGridCount(
    BuildContext context, {
    int defaultCount = 2,
    int? mobileCount,
    int? tabletCount,
  }) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return tabletCount ?? 3;
    if (isMobileLarge(context)) return defaultCount;
    if (isMobileMedium(context)) return mobileCount ?? 2;
    return 1;
  }
}

/// Extension untuk context - memudahkan akses responsive values
extension ResponsiveContext on BuildContext {
  bool get isSmall => Responsive.isMobileSmall(this);
  bool get isMedium => Responsive.isMobileMedium(this);
  bool get isLarge => Responsive.isMobileLarge(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isLandscape => Responsive.isLandscape(this);

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double fontSize({
    required double base,
    double? mobile,
    double? tablet,
    double? desktop,
  }) =>
      Responsive.fontSize(
        this,
        base: base,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );

  int get gridColumns => Responsive.gridColumns(this);
  int get menuColumns => Responsive.menuColumns(this);
  double get buttonHeight => Responsive.buttonHeight(this);
  double get spacing => Responsive.spacing(this, base: 16);
  EdgeInsets get responsivePadding => EdgeInsets.symmetric(
    horizontal: Responsive._responsiveValue(this, 20),
    vertical: Responsive._responsiveValue(this, 16),
  );
}

