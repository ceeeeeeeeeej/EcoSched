import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Tailwind CSS-inspired utility classes for Flutter
class Tailwind {
  // Spacing utilities (px, py, p, m, mx, my, etc.)
  static const EdgeInsets p0 = EdgeInsets.zero;
  static const EdgeInsets p1 = EdgeInsets.all(4);
  static const EdgeInsets p2 = EdgeInsets.all(8);
  static const EdgeInsets p3 = EdgeInsets.all(12);
  static const EdgeInsets p4 = EdgeInsets.all(16);
  static const EdgeInsets p5 = EdgeInsets.all(20);
  static const EdgeInsets p6 = EdgeInsets.all(24);
  static const EdgeInsets p8 = EdgeInsets.all(32);
  static const EdgeInsets p10 = EdgeInsets.all(40);
  static const EdgeInsets p12 = EdgeInsets.all(48);
  static const EdgeInsets p16 = EdgeInsets.all(64);
  static const EdgeInsets p20 = EdgeInsets.all(80);
  static const EdgeInsets p24 = EdgeInsets.all(96);

  // Padding horizontal
  static const EdgeInsets px1 = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets px2 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets px3 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets px4 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets px5 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets px6 = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets px8 = EdgeInsets.symmetric(horizontal: 32);

  // Padding vertical
  static const EdgeInsets py1 = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets py2 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets py3 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets py4 = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets py5 = EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets py6 = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets py8 = EdgeInsets.symmetric(vertical: 32);

  // Margin
  static const EdgeInsets m0 = EdgeInsets.zero;
  static const EdgeInsets m1 = EdgeInsets.all(4);
  static const EdgeInsets m2 = EdgeInsets.all(8);
  static const EdgeInsets m3 = EdgeInsets.all(12);
  static const EdgeInsets m4 = EdgeInsets.all(16);
  static const EdgeInsets m5 = EdgeInsets.all(20);
  static const EdgeInsets m6 = EdgeInsets.all(24);
  static const EdgeInsets m8 = EdgeInsets.all(32);

  // Margin horizontal
  static const EdgeInsets mx1 = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets mx2 = EdgeInsets.symmetric(horizontal: 8);
  static const EdgeInsets mx3 = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets mx4 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets mx5 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets mx6 = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets mx8 = EdgeInsets.symmetric(horizontal: 32);

  // Margin vertical
  static const EdgeInsets my1 = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets my2 = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets my3 = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets my4 = EdgeInsets.symmetric(vertical: 16);
  static const EdgeInsets my5 = EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets my6 = EdgeInsets.symmetric(vertical: 24);
  static const EdgeInsets my8 = EdgeInsets.symmetric(vertical: 32);

  // Gap utilities
  static const double gap1 = 4;
  static const double gap2 = 8;
  static const double gap3 = 12;
  static const double gap4 = 16;
  static const double gap5 = 20;
  static const double gap6 = 24;
  static const double gap8 = 32;

  // Width utilities
  static const double wFull = double.infinity;
  static const double wHalf = 0.5;
  static const double wThird = 1/3;
  static const double wTwoThirds = 2/3;
  static const double wQuarter = 0.25;
  static const double wThreeQuarters = 0.75;

  // Height utilities
  static const double hFull = double.infinity;
  static const double hHalf = 0.5;
  static const double hThird = 1/3;
  static const double hTwoThirds = 2/3;
  static const double hQuarter = 0.25;
  static const double hThreeQuarters = 0.75;

  // Border radius utilities
  static const BorderRadius roundedNone = BorderRadius.zero;
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(2));
  static const BorderRadius rounded = BorderRadius.all(Radius.circular(4));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(6));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(8));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(12));
  static const BorderRadius rounded2Xl = BorderRadius.all(Radius.circular(16));
  static const BorderRadius rounded3Xl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(9999));

  // Shadow utilities
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowXl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  // Text size utilities
  static const TextStyle textXs = TextStyle(fontSize: 12);
  static const TextStyle textSm = TextStyle(fontSize: 14);
  static const TextStyle textBase = TextStyle(fontSize: 16);
  static const TextStyle textLg = TextStyle(fontSize: 18);
  static const TextStyle textXl = TextStyle(fontSize: 20);
  static const TextStyle text2Xl = TextStyle(fontSize: 24);
  static const TextStyle text3Xl = TextStyle(fontSize: 30);
  static const TextStyle text4Xl = TextStyle(fontSize: 36);
  static const TextStyle text5Xl = TextStyle(fontSize: 48);

  // Font weight utilities
  static const TextStyle fontThin = TextStyle(fontWeight: FontWeight.w100);
  static const TextStyle fontExtralight = TextStyle(fontWeight: FontWeight.w200);
  static const TextStyle fontLight = TextStyle(fontWeight: FontWeight.w300);
  static const TextStyle fontNormal = TextStyle(fontWeight: FontWeight.w400);
  static const TextStyle fontMedium = TextStyle(fontWeight: FontWeight.w500);
  static const TextStyle fontSemibold = TextStyle(fontWeight: FontWeight.w600);
  static const TextStyle fontBold = TextStyle(fontWeight: FontWeight.w700);
  static const TextStyle fontExtrabold = TextStyle(fontWeight: FontWeight.w800);
  static const TextStyle fontBlack = TextStyle(fontWeight: FontWeight.w900);

  // Text color utilities
  static TextStyle get textGray50 => TextStyle(color: Colors.grey[50]);
  static TextStyle get textGray100 => TextStyle(color: Colors.grey[100]);
  static TextStyle get textGray200 => TextStyle(color: Colors.grey[200]);
  static TextStyle get textGray300 => TextStyle(color: Colors.grey[300]);
  static TextStyle get textGray400 => TextStyle(color: Colors.grey[400]);
  static TextStyle get textGray500 => TextStyle(color: Colors.grey[500]);
  static TextStyle get textGray600 => TextStyle(color: Colors.grey[600]);
  static TextStyle get textGray700 => TextStyle(color: Colors.grey[700]);
  static TextStyle get textGray800 => TextStyle(color: Colors.grey[800]);
  static TextStyle get textGray900 => TextStyle(color: Colors.grey[900]);

  // Background color utilities
  static Color get bgWhite => Colors.white;
  static Color get bgGray50 => Colors.grey[50]!;
  static Color get bgGray100 => Colors.grey[100]!;
  static Color get bgGray200 => Colors.grey[200]!;
  static Color get bgGray300 => Colors.grey[300]!;
  static Color get bgGray400 => Colors.grey[400]!;
  static Color get bgGray500 => Colors.grey[500]!;
  static Color get bgGray600 => Colors.grey[600]!;
  static Color get bgGray700 => Colors.grey[700]!;
  static Color get bgGray800 => Colors.grey[800]!;
  static Color get bgGray900 => Colors.grey[900]!;

  // Flex utilities
  static const FlexFit flex1 = FlexFit.tight;
  static const FlexFit flexNone = FlexFit.loose;

  // Alignment utilities
  static const Alignment alignStart = Alignment.centerLeft;
  static const Alignment alignCenter = Alignment.center;
  static const Alignment alignEnd = Alignment.centerRight;
  static const Alignment alignStretch = Alignment.center;

  // Opacity utilities
  static const double opacity0 = 0.0;
  static const double opacity25 = 0.25;
  static const double opacity50 = 0.5;
  static const double opacity75 = 0.75;
  static const double opacity100 = 1.0;

  // Z-index utilities (for Stack positioning)
  static const int z0 = 0;
  static const int z10 = 10;
  static const int z20 = 20;
  static const int z30 = 30;
  static const int z40 = 40;
  static const int z50 = 50;

  // Common combinations
  static BoxDecoration get card => BoxDecoration(
    color: Colors.white,
    borderRadius: roundedLg,
    boxShadow: shadowMd,
  );

  static BoxDecoration get cardHover => BoxDecoration(
    color: Colors.white,
    borderRadius: roundedLg,
    boxShadow: shadowLg,
  );

  static const BoxDecoration input = BoxDecoration(
    color: Colors.white,
    borderRadius: roundedLg,
    border: Border.fromBorderSide(BorderSide(color: Colors.grey, width: 1)),
  );

  static const BoxDecoration inputFocused = BoxDecoration(
    color: Colors.white,
    borderRadius: roundedLg,
    border: Border.fromBorderSide(BorderSide(color: AppTheme.primaryGreen, width: 2)),
  );

  // Waste management specific utilities
  static BoxDecoration getWasteCard(String wasteType) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: AppTheme.getWasteTypeGradient(wasteType),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: roundedXl,
      boxShadow: shadowLg,
    );
  }

  static BoxDecoration getEconomicCard(String economicType) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: AppTheme.getEconomicGradient(economicType),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: roundedXl,
      boxShadow: shadowLg,
    );
  }

  // Responsive utilities
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  // Spacing based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) return p4;
    if (isTablet(context)) return p6;
    return p8;
  }

  static double responsiveGap(BuildContext context) {
    if (isMobile(context)) return gap4;
    if (isTablet(context)) return gap6;
    return gap8;
  }
}

/// Tailwind-inspired widget extensions
extension TailwindWidget on Widget {
  Widget p(double value) => Padding(
    padding: EdgeInsets.all(value),
    child: this,
  );

  Widget px(double value) => Padding(
    padding: EdgeInsets.symmetric(horizontal: value),
    child: this,
  );

  Widget py(double value) => Padding(
    padding: EdgeInsets.symmetric(vertical: value),
    child: this,
  );

  Widget pt(double value) => Padding(
    padding: EdgeInsets.only(top: value),
    child: this,
  );

  Widget pb(double value) => Padding(
    padding: EdgeInsets.only(bottom: value),
    child: this,
  );

  Widget pl(double value) => Padding(
    padding: EdgeInsets.only(left: value),
    child: this,
  );

  Widget pr(double value) => Padding(
    padding: EdgeInsets.only(right: value),
    child: this,
  );

  Widget m(double value) => Container(
    margin: EdgeInsets.all(value),
    child: this,
  );

  Widget mx(double value) => Container(
    margin: EdgeInsets.symmetric(horizontal: value),
    child: this,
  );

  Widget my(double value) => Container(
    margin: EdgeInsets.symmetric(vertical: value),
    child: this,
  );

  Widget mt(double value) => Container(
    margin: EdgeInsets.only(top: value),
    child: this,
  );

  Widget mb(double value) => Container(
    margin: EdgeInsets.only(bottom: value),
    child: this,
  );

  Widget ml(double value) => Container(
    margin: EdgeInsets.only(left: value),
    child: this,
  );

  Widget mr(double value) => Container(
    margin: EdgeInsets.only(right: value),
    child: this,
  );

  Widget bg(Color color) => Container(
    color: color,
    child: this,
  );

  Widget rounded(double radius) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: this,
  );

  Widget shadow(List<BoxShadow> shadows) => Container(
    decoration: BoxDecoration(boxShadow: shadows),
    child: this,
  );

  Widget w(double width) => SizedBox(
    width: width,
    child: this,
  );

  Widget h(double height) => SizedBox(
    height: height,
    child: this,
  );

  Widget wFull() => SizedBox(
    width: double.infinity,
    child: this,
  );

  Widget hFull() => SizedBox(
    height: double.infinity,
    child: this,
  );

  Widget center() => Center(child: this);

  Widget align(Alignment alignment) => Align(
    alignment: alignment,
    child: this,
  );

  Widget opacity(double opacity) => Opacity(
    opacity: opacity,
    child: this,
  );

  Widget flex([int flex = 1]) => Expanded(
    flex: flex,
    child: this,
  );

  Widget flexNone() => Flexible(
    flex: 0,
    child: this,
  );
}
