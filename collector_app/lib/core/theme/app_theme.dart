import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Color Palette for EcoSched
/// Centralized Color Palette for EcoSched
class AppPalette {
  // Primary - Emerald/Seafoam (Premium Green)
  static const Color primary = Color(0xFF059669); // Emerald 600
  static const Color primaryDark = Color(0xFF064E3B);
  static const Color primaryLight = Color(0xFF10B981);

  // Secondary - Indigo/Sky (Premium Blue)
  static const Color secondary = Color(0xFF0EA5E9); // Sky 500
  static const Color secondaryDark = Color(0xFF0369A1);
  static const Color secondaryLight = Color(0xFF38BDF8);

  // Accent Colors
  static const Color accent = Color(0xFFF59E0B); // Amber 500
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);

  // Neutral / Greyscale (Slate for modern feel)
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // Waste Management Colors
  static const Color recycling = Color(0xFF0EA5E9);
  static const Color composting = Color(0xFF92400E);
  static const Color organic = Color(0xFF059669);
  static const Color hazardous = Color(0xFFDC2626);
  static const Color landfill = Color(0xFF475569);
  static const Color ewaste = Color(0xFF7C3AED);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF1F5F9); // Slate 50 tint
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceOverlay =
      Color(0xFFF0FDF4); // Mint tint for light surfaces

  // Glassmorphism tokens
  static const double glassBlur = 12.0;
  static const double glassOpacity = 0.15;
}

class AppTheme {
  // Legacy aliases mapped to Palette
  static const Color primary = AppPalette.primary;
  static const Color primaryDark = AppPalette.primaryDark;
  static const Color primaryLight = AppPalette.primaryLight;
  static const Color secondary = AppPalette.secondary;
  static const Color secondaryDark = AppPalette.secondaryDark;
  static const Color secondaryLight = AppPalette.secondaryLight;

  static const Color accent = AppPalette.accent;
  static const Color success = AppPalette.success;
  static const Color warning = AppPalette.warning;
  static const Color error = AppPalette.error;
  static const Color info = AppPalette.info;

  static const Color background = AppPalette.backgroundLight;
  static const Color surface = AppPalette.surfaceLight;
  static const Color surfaceOverlay = AppPalette.surfaceOverlay;
  static const Color border = AppPalette.neutral200;
  static const Color divider = AppPalette.neutral100;

  // Text Colors
  static const Color textPrimary = AppPalette.neutral900;
  static const Color textSecondary = AppPalette.neutral600;
  static const Color textTertiary = AppPalette.neutral400;
  static const Color textInverse = Colors.white;
  static const Color textDisabled = AppPalette.neutral300;

  // Legacy/Compatibility Colors
  static const Color primaryGreen = primary;
  static const Color primaryGreenDark = primaryDark;
  static const Color primaryGreenLight = primaryLight;
  static const Color lightGreen = primaryLight;
  static const Color accentBlue = AppPalette.secondary;
  static const Color accentPurple = AppPalette.ewaste;
  static const Color accentOrange = AppPalette.warning;
  static const Color recyclingBlue = AppPalette.recycling;
  static const Color recyclingBlueLight = Color(0xFF7DD3FC);
  static const Color compostingBrown = AppPalette.composting;
  static const Color compostingBrownLight = Color(0xFFB45309);
  static const Color landfillGray = AppPalette.landfill;
  static const Color hazardousRed = AppPalette.hazardous;
  static const Color organicGreen = AppPalette.organic;
  static const Color warningYellow = warning;
  static const Color errorRed = error;
  static const Color infoBlue = info;
  static const Color successGreen = success;

  // Neutral Aliases
  static const Color neutral50 = AppPalette.neutral50;
  static const Color neutral100 = AppPalette.neutral100;
  static const Color neutral200 = AppPalette.neutral200;
  static const Color neutral300 = AppPalette.neutral300;
  static const Color neutral400 = AppPalette.neutral400;
  static const Color neutral500 = AppPalette.neutral500;
  static const Color neutral600 = AppPalette.neutral600;
  static const Color neutral700 = AppPalette.neutral700;
  static const Color neutral800 = AppPalette.neutral800;
  static const Color neutral900 = AppPalette.neutral900;

  static const Color savingsGreen = success;
  static const Color efficiencyBlue = secondary;
  static const Color valueGold = warning;
  static const Color profitGreen = primary;
  static const Color costRed = error;
  static const Color backgroundLight = background;
  static const Color backgroundSecondary = Color(0xFFF8FAFC);
  static const Color backgroundTertiary = Color(0xFFF1F5F9);
  static const Color surfaceElevated = surface;
  static const Color textDark = textPrimary;
  static const Color textLight = textSecondary;
  static const Color textMuted = textTertiary;
  static const Color cardWhite = surface;
  static const Color backgroundGrey = background;

  // Gradients
  static const List<Color> primaryGradient = [
    AppPalette.primary,
    AppPalette.primaryDark,
  ];
  static const List<Color> secondaryGradient = [
    AppPalette.secondary,
    AppPalette.secondaryDark,
  ];
  static const List<Color> successGradient = [
    AppPalette.success,
    Color(0xFF34D399)
  ];
  static const List<Color> warningGradient = [
    AppPalette.warning,
    Color(0xFFFBBF24)
  ];
  static const List<Color> errorGradient = [
    AppPalette.error,
    Color(0xFFF87171)
  ];
  static const List<Color> savingsGradient = [savingsGreen, Color(0xFF34D399)];
  static const List<Color> efficiencyGradient = [
    efficiencyBlue,
    Color(0xFF38BDF8)
  ];
  static const List<Color> valueGradient = [valueGold, Color(0xFFFBBF24)];
  static const List<Color> profitGradient = [profitGreen, Color(0xFF10B981)];
  static const List<Color> costGradient = [costRed, Color(0xFFEF4444)];

  // Waste Type Gradients
  static const List<Color> recyclingGradient = [
    AppPalette.recycling,
    Color(0xFF56CCF2)
  ];
  static const List<Color> compostingGradient = [
    AppPalette.composting,
    Color(0xFFBCAAA4)
  ];
  static const List<Color> organicGradient = [
    AppPalette.organic,
    Color(0xFF81C784)
  ];
  static const List<Color> hazardousGradient = [
    AppPalette.hazardous,
    Color(0xFFFF8A80)
  ];
  static const List<Color> landfillGradient = [
    AppPalette.landfill,
    Color(0xFFE0E0E0)
  ];
  static const List<Color> ewasteGradient = [
    AppPalette.ewaste,
    Color(0xFFCE93D8)
  ];

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05059669), // Emerald 600 with very low opacity
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x1A059669),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 2,
    ),
  ];

  // Icon maps
  static const Map<String, IconData> wasteTypeIcons = {
    'recycling': Icons.recycling_rounded,
    'composting': Icons.compost_rounded,
    'organic': Icons.eco_rounded,
    'hazardous': Icons.dangerous_rounded,
    'landfill': Icons.delete_outline_rounded,
    'paper': Icons.article_rounded,
    'plastic': Icons.water_drop_rounded,
    'glass': Icons.wine_bar_rounded,
    'metal': Icons.build_rounded,
    'electronics': Icons.devices_other_rounded,
    'ewaste': Icons.computer_rounded,
  };

  static const Map<String, IconData> economicIcons = {
    'savings': Icons.savings_rounded,
    'efficiency': Icons.electric_bolt_rounded,
    'value': Icons.trending_up_rounded,
    'profit': Icons.attach_money_rounded,
    'cost': Icons.trending_down_rounded,
    'budget': Icons.account_balance_wallet_rounded,
    'revenue': Icons.monetization_on_rounded,
    'expense': Icons.money_off_rounded,
    'investment': Icons.show_chart_rounded,
    'roi': Icons.analytics_rounded,
  };

  // Typography - Refining weights and letter spacing
  static const String fontFamily = 'Inter';
  static const String fontFamilyMono = 'RobotoMono';

  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      );

  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: textPrimary,
      );

  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        letterSpacing: 0.5,
      );

  // Spacing
  static const double spacing0 = 0.0;
  static const double spacing1 = 4.0;
  static const double spacing2 = 8.0;
  static const double spacing3 = 12.0;
  static const double spacing4 = 16.0;
  static const double spacing5 = 20.0;
  static const double spacing6 = 24.0;
  static const double spacing8 = 32.0;
  static const double spacing10 = 40.0;
  static const double spacing12 = 48.0;
  static const double spacing16 = 64.0;

  static const EdgeInsets paddingSmall = EdgeInsets.all(spacing2);
  static const EdgeInsets paddingMedium = EdgeInsets.all(spacing4);
  static const EdgeInsets paddingLarge = EdgeInsets.all(spacing6);

  static const EdgeInsets paddingHorizontalSmall =
      EdgeInsets.symmetric(horizontal: spacing2);
  static const EdgeInsets paddingHorizontalMedium =
      EdgeInsets.symmetric(horizontal: spacing4);
  static const EdgeInsets paddingHorizontalLarge =
      EdgeInsets.symmetric(horizontal: spacing6);

  static const EdgeInsets paddingVerticalSmall =
      EdgeInsets.symmetric(vertical: spacing2);
  static const EdgeInsets paddingVerticalMedium =
      EdgeInsets.symmetric(vertical: spacing4);
  static const EdgeInsets paddingVerticalLarge =
      EdgeInsets.symmetric(vertical: spacing6);

  // Border radius
  static const double radiusNone = 0.0;
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radius2XL = 20.0;
  static const double radius3XL = 24.0;
  static const double radiusFull = 1000.0;

  static BorderRadius borderRadiusXS = BorderRadius.circular(radiusXS);
  static BorderRadius borderRadiusS = BorderRadius.circular(radiusS);
  static BorderRadius borderRadiusM = BorderRadius.circular(radiusM);
  static BorderRadius borderRadiusL = BorderRadius.circular(radiusL);
  static BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static BorderRadius borderRadius2XL = BorderRadius.circular(radius2XL);
  static BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // Elevation
  static const List<BoxShadow> shadowNone = [];

  static const List<BoxShadow> shadowXSmall = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> shadowXLarge = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
  ];

  static const List<BoxShadow> shadowFloating = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowInsetSmall = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  // Colors Maps
  static const Map<String, List<Color>> wasteTypeColors = {
    'recycling': recyclingGradient,
    'composting': compostingGradient,
    'organic': organicGradient,
    'hazardous': hazardousGradient,
    'landfill': landfillGradient,
  };

  static const Map<String, Color> wasteTypePrimaryColors = {
    'recycling': recyclingBlue,
    'composting': compostingBrown,
    'organic': organicGreen,
    'hazardous': hazardousRed,
    'landfill': landfillGray,
  };

  static const Map<String, List<Color>> economicGradients = {
    'savings': savingsGradient,
    'efficiency': efficiencyGradient,
    'value': valueGradient,
    'profit': profitGradient,
    'cost': costGradient,
  };

  static const Map<String, Color> economicPrimaryColors = {
    'savings': savingsGreen,
    'efficiency': efficiencyBlue,
    'value': valueGold,
    'profit': profitGreen,
    'cost': costRed,
  };

  // Helper methods
  static List<Color> getWasteTypeGradient(String type) =>
      wasteTypeColors[type] ?? primaryGradient;

  static Color getWasteTypeColor(String type) =>
      wasteTypePrimaryColors[type] ?? primary;

  static IconData getWasteTypeIcon(String type) =>
      wasteTypeIcons[type] ?? Icons.eco_rounded;

  static List<Color> getEconomicGradient(String type) =>
      economicGradients[type] ?? primaryGradient;

  static Color getEconomicColor(String type) =>
      economicPrimaryColors[type] ?? primaryGreen;

  static IconData getEconomicIcon(String type) =>
      economicIcons[type] ?? Icons.trending_up;

  static Color getWasteStatusColor(String status) {
    final lower = status.toLowerCase();
    if (['collected', 'completed', 'success'].contains(lower)) {
      return successGreen;
    }
    if (['pending', 'scheduled'].contains(lower)) return warningYellow;
    if (['cancelled', 'failed'].contains(lower)) return errorRed;
    if (['in_progress', 'processing'].contains(lower)) return infoBlue;
    return AppPalette.neutral500;
  }

  static Color getEconomicStatusColor(String status) {
    final lower = status.toLowerCase();
    if (['profitable', 'savings', 'positive'].contains(lower)) {
      return profitGreen;
    }
    if (['break_even', 'neutral'].contains(lower)) return AppPalette.neutral500;
    if (['loss', 'negative', 'cost'].contains(lower)) return costRed;
    if (['efficient', 'optimized'].contains(lower)) return efficiencyBlue;
    return AppPalette.neutral500;
  }

  static BoxDecoration getWasteTypeDecoration(String wasteType,
          {bool isGradient = true}) =>
      isGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: getWasteTypeGradient(wasteType),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radiusL),
            )
          : BoxDecoration(
              color: getWasteTypeColor(wasteType),
              borderRadius: BorderRadius.circular(radiusL),
            );

  static const BoxDecoration scaffoldGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFF0FDF4),
        Color(0xFFECFDF5),
        Color(0xFFF0F9FF),
        Color(0xFFE0F2FE),
        Color(0xFFF0FDF4),
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
  );

  static BoxDecoration getEconomicDecoration(String economicType,
          {bool isGradient = true}) =>
      isGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: getEconomicGradient(economicType),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radiusL),
            )
          : BoxDecoration(
              color: getEconomicColor(economicType),
              borderRadius: BorderRadius.circular(radiusL),
            );

  // Theme Data
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: primary,
          primaryContainer: primaryLight,
          secondary: secondary,
          secondaryContainer: secondaryLight,
          surface: surface,
          error: error,
          onPrimary: textInverse,
          onSecondary: textInverse,
          onSurface: textPrimary,
          onError: textInverse,
          outline: border,
          outlineVariant: divider,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: background,
        cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusXL,
            side: BorderSide(color: divider, width: 1.5),
          ),
          shadowColor: const Color(0x08000000),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: surface.withValues(alpha: 0.8),
          foregroundColor: textPrimary,
          titleTextStyle: titleLarge.copyWith(fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: textPrimary, size: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textInverse,
            elevation: 8,
            shadowColor: primary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(
                horizontal: spacing6, vertical: spacing4),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusL),
            textStyle: labelLarge.copyWith(letterSpacing: 0.5),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: primary, width: 1.5),
            padding: const EdgeInsets.symmetric(
                horizontal: spacing6, vertical: spacing4),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusL),
            textStyle: labelLarge.copyWith(letterSpacing: 0.5),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(
                horizontal: spacing4, vertical: spacing2),
            textStyle: labelLarge,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: neutral50,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: spacing5, vertical: spacing4),
          border: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: error, width: 2),
          ),
          labelStyle: bodyMedium.copyWith(color: textSecondary),
          hintStyle: bodyMedium.copyWith(color: textTertiary),
          errorStyle: bodySmall.copyWith(color: error),
          prefixIconColor: textSecondary,
          suffixIconColor: textSecondary,
        ),
        dividerTheme: DividerThemeData(
          color: divider,
          thickness: 1,
          space: spacing4,
        ),
        textTheme: TextTheme(
          displayLarge: displayLarge,
          displayMedium: displayMedium,
          displaySmall: displaySmall,
          headlineLarge: headlineLarge,
          headlineMedium: headlineMedium,
          headlineSmall: headlineSmall,
          titleLarge: titleLarge,
          titleMedium: titleMedium,
          titleSmall: titleSmall,
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
          labelLarge: labelLarge,
          labelMedium: labelMedium,
          labelSmall: labelSmall,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: primaryLight,
          primaryContainer: primaryDark,
          secondary: secondaryLight,
          secondaryContainer: secondaryDark,
          surface: AppPalette.neutral800,
          error: error,
          onPrimary: textInverse,
          onSecondary: textInverse,
          onSurface: textInverse,
          onError: textInverse,
          outline: AppPalette.neutral700,
          outlineVariant: AppPalette.neutral700,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppPalette.neutral900,
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppPalette.neutral800,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusXL,
            side: const BorderSide(color: Colors.white10, width: 1),
          ),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppPalette.neutral900.withValues(alpha: 0.8),
          foregroundColor: textInverse,
          titleTextStyle: titleLarge.copyWith(
              color: textInverse, fontWeight: FontWeight.w700),
          iconTheme: const IconThemeData(color: textInverse, size: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryLight,
            foregroundColor: textInverse,
            elevation: 8,
            shadowColor: primaryLight.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(
                horizontal: spacing6, vertical: spacing4),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusL),
            textStyle: labelLarge.copyWith(letterSpacing: 0.5),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textInverse,
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.white24, width: 1.5),
            padding: const EdgeInsets.symmetric(
                horizontal: spacing6, vertical: spacing4),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusL),
            textStyle:
                labelLarge.copyWith(color: textInverse, letterSpacing: 0.5),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryLight,
            padding: const EdgeInsets.symmetric(
                horizontal: spacing4, vertical: spacing2),
            textStyle: labelLarge.copyWith(color: primaryLight),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.neutral800,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: spacing5, vertical: spacing4),
          border: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: const BorderSide(color: Colors.white10, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: const BorderSide(color: Colors.white10, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadiusL,
            borderSide: BorderSide(color: error, width: 2),
          ),
          labelStyle: bodyMedium.copyWith(color: textInverse.withValues(alpha: 0.7)),
          hintStyle: bodyMedium.copyWith(color: textInverse.withValues(alpha: 0.5)),
          errorStyle: bodySmall.copyWith(color: error),
          prefixIconColor: textInverse.withValues(alpha: 0.6),
          suffixIconColor: textInverse.withValues(alpha: 0.6),
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.white12,
          thickness: 1,
          space: spacing4,
        ),
        textTheme: TextTheme(
          displayLarge: displayLarge.copyWith(color: textInverse),
          displayMedium: displayMedium.copyWith(color: textInverse),
          displaySmall: displaySmall.copyWith(color: textInverse),
          headlineLarge: headlineLarge.copyWith(color: textInverse),
          headlineMedium: headlineMedium.copyWith(color: textInverse),
          headlineSmall: headlineSmall.copyWith(color: textInverse),
          titleLarge: titleLarge.copyWith(color: textInverse),
          titleMedium: titleMedium.copyWith(color: textInverse),
          titleSmall: titleSmall.copyWith(color: textInverse),
          bodyLarge: bodyLarge.copyWith(color: textInverse),
          bodyMedium: bodyMedium.copyWith(color: textInverse),
          bodySmall: bodySmall.copyWith(color: textInverse.withValues(alpha: 0.8)),
          labelLarge: labelLarge.copyWith(color: textInverse),
          labelMedium: labelMedium.copyWith(color: textInverse),
          labelSmall: labelSmall.copyWith(color: textInverse.withValues(alpha: 0.8)),
        ),
      );
}
