import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
/// Provides breakpoints and responsive values for phone sizes
class ResponsiveUtil {
  static const double phoneWidth = 600;
  static const double tabletWidth = 900;
  static const double desktopWidth = 1200;

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get device pixel ratio
  static double devicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is a phone
  static bool isPhone(BuildContext context) {
    return screenWidth(context) < phoneWidth;
  }

  /// Check if device is a tablet
  static bool isTablet(BuildContext context) {
    double width = screenWidth(context);
    return width >= phoneWidth && width < desktopWidth;
  }

  /// Check if device is a desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= desktopWidth;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    double width = screenWidth(context);
    if (width < phoneWidth) {
      return const EdgeInsets.all(16.0);
    } else if (width < tabletWidth) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive font size
  static double responsiveFontSize(BuildContext context, double baseSize) {
    double width = screenWidth(context);
    double scaleFactor = width / 375.0; // iPhone 6/7/8 width as base
    double scaledSize = baseSize * scaleFactor;
    // Clamp between min and max reasonable sizes
    return scaledSize.clamp(baseSize * 0.8, baseSize * 1.5);
  }

  /// Get responsive height for spacing
  static double responsiveHeight(BuildContext context, double baseHeight) {
    double height = screenHeight(context);
    double scaleFactor = height / 667.0; // iPhone 6/7/8 height as base
    return baseHeight * scaleFactor.clamp(0.8, 1.5);
  }

  /// Get responsive width for spacing
  static double responsiveWidth(BuildContext context, double baseWidth) {
    double width = screenWidth(context);
    double scaleFactor = width / 375.0; // iPhone 6/7/8 width as base
    return baseWidth * scaleFactor.clamp(0.8, 1.5);
  }

  /// Get max width for content (to prevent content from stretching too wide)
  static double maxContentWidth(BuildContext context) {
    double width = screenWidth(context);
    if (isPhone(context)) {
      return width - 32;
    } else if (isTablet(context)) {
      return width - 64;
    } else {
      return 1200;
    }
  }

  /// Get column count for grid layouts
  static int gridCrossAxisCount(BuildContext context) {
    if (isPhone(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get grid child aspect ratio
  static double gridChildAspectRatio(BuildContext context) {
    if (isPhone(context)) {
      return 0.75;
    } else if (isTablet(context)) {
      return 0.8;
    } else {
      return 0.85;
    }
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context) {
    return isPhone(context) ? 48.0 : 56.0;
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context) {
    return isPhone(context) ? 12.0 : 16.0;
  }

  /// Get safe area insets (handles notches, etc)
  static EdgeInsets safeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get view insets (handles keyboard)
  static EdgeInsets viewInsets(BuildContext context) {
    return MediaQuery.of(context).viewInsets;
  }
}

/// Widget to make layouts responsive with different breakpoints
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, bool isPhone, bool isTablet, bool isDesktop) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      ResponsiveUtil.isPhone(context),
      ResponsiveUtil.isTablet(context),
      ResponsiveUtil.isDesktop(context),
    );
  }
}

/// Extension to make accessing responsive values easier
extension ResponsiveExt on BuildContext {
  bool get isPhone => ResponsiveUtil.isPhone(this);
  bool get isTablet => ResponsiveUtil.isTablet(this);
  bool get isDesktop => ResponsiveUtil.isDesktop(this);
  bool get isPortrait => ResponsiveUtil.isPortrait(this);
  bool get isLandscape => ResponsiveUtil.isLandscape(this);
  
  double get screenWidth => ResponsiveUtil.screenWidth(this);
  double get screenHeight => ResponsiveUtil.screenHeight(this);
  double get maxContentWidth => ResponsiveUtil.maxContentWidth(this);
  
  EdgeInsets get responsivePadding => ResponsiveUtil.responsivePadding(this);
  EdgeInsets get safeAreaPadding => ResponsiveUtil.safeAreaPadding(this);
  EdgeInsets get viewInsets => ResponsiveUtil.viewInsets(this);
  
  double fontSize(double baseSize) => ResponsiveUtil.responsiveFontSize(this, baseSize);
  double hPadding(double baseHeight) => ResponsiveUtil.responsiveHeight(this, baseHeight);
  double wPadding(double baseWidth) => ResponsiveUtil.responsiveWidth(this, baseWidth);
  double buttonHeight() => ResponsiveUtil.buttonHeight(this);
  double borderRadius() => ResponsiveUtil.borderRadius(this);
}
