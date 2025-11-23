import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class Responsive {
  final BuildContext context;
  
  Responsive(this.context);
  
  /// Get screen width
  double get width => MediaQuery.of(context).size.width;
  
  /// Get screen height
  double get height => MediaQuery.of(context).size.height;
  
  /// Get screen orientation
  Orientation get orientation => MediaQuery.of(context).orientation;
  
  /// Check if device is mobile (width < 600)
  bool get isMobile => width < 600;
  
  /// Check if device is tablet (600 <= width < 1024)
  bool get isTablet => width >= 600 && width < 1024;
  
  /// Check if device is desktop (width >= 1024)
  bool get isDesktop => width >= 1024;
  
  /// Check if device is small mobile (width < 360)
  bool get isSmallMobile => width < 360;
  
  /// Get responsive padding based on screen size
  EdgeInsets get padding {
    if (isSmallMobile) {
      return const EdgeInsets.all(16.0);
    } else if (isMobile) {
      return const EdgeInsets.all(20.0);
    } else if (isTablet) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }
  
  /// Get responsive horizontal padding
  double get horizontalPadding {
    if (isSmallMobile) {
      return 16.0;
    } else if (isMobile) {
      return 20.0;
    } else if (isTablet) {
      return 32.0;
    } else {
      return 48.0;
    }
  }
  
  /// Get responsive vertical padding
  double get verticalPadding {
    if (isSmallMobile) {
      return 16.0;
    } else if (isMobile) {
      return 20.0;
    } else if (isTablet) {
      return 24.0;
    } else {
      return 32.0;
    }
  }
  
  /// Get responsive font size multiplier
  double get fontSizeMultiplier {
    if (isSmallMobile) {
      return 0.9;
    } else if (isMobile) {
      return 1.0;
    } else if (isTablet) {
      return 1.1;
    } else {
      return 1.2;
    }
  }
  
  /// Get responsive icon size
  double iconSize(double baseSize) {
    if (isSmallMobile) {
      return baseSize * 0.85;
    } else if (isMobile) {
      return baseSize;
    } else if (isTablet) {
      return baseSize * 1.15;
    } else {
      return baseSize * 1.3;
    }
  }
  
  /// Get responsive spacing
  double spacing(double baseSpacing) {
    if (isSmallMobile) {
      return baseSpacing * 0.75;
    } else if (isMobile) {
      return baseSpacing;
    } else if (isTablet) {
      return baseSpacing * 1.25;
    } else {
      return baseSpacing * 1.5;
    }
  }
  
  /// Get responsive width (clamped between min and max)
  double responsiveWidth({
    double? min,
    double? max,
    double? percent,
  }) {
    double calculatedWidth = width;
    
    if (percent != null) {
      calculatedWidth = width * percent;
    }
    
    if (min != null && calculatedWidth < min) {
      return min;
    }
    
    if (max != null && calculatedWidth > max) {
      return max;
    }
    
    return calculatedWidth;
  }
  
  /// Get responsive grid cross axis count
  int getGridCrossAxisCount({
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isMobile) {
      return mobile;
    } else if (isTablet) {
      return tablet;
    } else {
      return desktop;
    }
  }
  
  /// Get responsive container width
  double getContainerWidth({
    double mobilePercent = 1.0,
    double tabletPercent = 0.9,
    double desktopPercent = 0.8,
    double? maxWidth,
  }) {
    double percent;
    if (isMobile) {
      percent = mobilePercent;
    } else if (isTablet) {
      percent = tabletPercent;
    } else {
      percent = desktopPercent;
    }
    
    double calculatedWidth = width * percent;
    
    if (maxWidth != null && calculatedWidth > maxWidth) {
      return maxWidth;
    }
    
    return calculatedWidth;
  }
}

/// Extension to easily access Responsive from BuildContext
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

