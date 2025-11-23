import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Color Palette - Inspired by nature and sustainability
  
  // Primary Colors
  static const Color primary = Color(0xFF1DB954); // Vibrant eco-green
  static const Color primaryDark = Color(0xFF178A3F);
  static const Color primaryLight = Color(0xFF6FCF97);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF2D9CDB); // Calming blue
  static const Color secondaryDark = Color(0xFF1E6F9F);
  static const Color secondaryLight = Color(0xFF7FC4E9);
  
  // Accent Colors
  static const Color accent = Color(0xFFFFC107); // Sunny yellow
  static const Color accentDark = Color(0xFFFFA000);
  static const Color accentLight = Color(0xFFFFD54F);
  
  // Status Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF2994A);
  static const Color error = Color(0xFFEB5757);
  static const Color info = Color(0xFF2F80ED);
  
  // Waste Management Colors
  static const Color recycling = Color(0xFF2196F3);
  static const Color composting = Color(0xFF8D6E63);
  static const Color organic = Color(0xFF4CAF50);
  static const Color hazardous = Color(0xFFF44336);
  static const Color landfill = Color(0xFF9E9E9E);
  static const Color ewaste = Color(0xFF9C27B0);
  
  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color neutral900 = Color(0xFF0B1116);
  static const Color neutral800 = Color(0xFF1C252D);
  static const Color neutral700 = Color(0xFF27323C);
  static const Color neutral600 = Color(0xFF4A5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFFAFAFA);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4F4F4F);
  static const Color textTertiary = Color(0xFF828282);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Legacy/backwards-compatible aliases
  static const Color primaryGreen = primary;
  static const Color primaryGreenDark = primaryDark;
  static const Color primaryGreenLight = primaryLight;
  static const Color lightGreen = primaryLight;
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = accent;
  static const Color recyclingBlue = recycling;
  static const Color recyclingBlueLight = Color(0xFF56CCF2);
  static const Color compostingBrown = composting;
  static const Color compostingBrownLight = Color(0xFFBCAAA4);
  static const Color landfillGray = landfill;
  static const Color hazardousRed = hazardous;
  static const Color organicGreen = organic;
  static const Color savingsGreen = success;
  static const Color efficiencyBlue = secondary;
  static const Color valueGold = accent;
  static const Color profitGreen = primary;
  static const Color costRed = error;
  static const Color backgroundLight = background;
  static const Color backgroundSecondary = Color(0xFF0F1720);
  static const Color backgroundTertiary = Color(0xFF0C111A);
  static const Color surfaceElevated = surface;
  static const Color surfaceOverlay = Color(0xFFF0F4F8);
  static const Color textDark = textPrimary;
  static const Color textLight = textSecondary;
  static const Color textMuted = textTertiary;
  static const Color cardWhite = surface;
  static const Color backgroundGrey = background;
  
  // Gradients
  static const List<Color> primaryGradient = [primary, Color(0xFF1DB954), Color(0xFF27AE60)];
  static const List<Color> secondaryGradient = [secondary, Color(0xFF2D9CDB), Color(0xFF56CCF2)];
  static const List<Color> successGradient = [success, Color(0xFF6FCF97)];
  static const List<Color> warningGradient = [warning, Color(0xFFF2C94C)];
  static const List<Color> errorGradient = [error, Color(0xFFEB5757)];
  static const List<Color> savingsGradient = [savingsGreen, Color(0xFF34D399)];
  static const List<Color> efficiencyGradient = [efficiencyBlue, Color(0xFF60A5FA)];
  static const List<Color> valueGradient = [valueGold, Color(0xFFFBBF24)];
  static const List<Color> profitGradient = [profitGreen, Color(0xFF22C55E)];
  static const List<Color> costGradient = [costRed, Color(0xFFEF4444)];
  
  // Waste Type Gradients
  static const List<Color> recyclingGradient = [recycling, Color(0xFF56CCF2)];
  static const List<Color> compostingGradient = [composting, Color(0xFFBCAAA4)];
  static const List<Color> organicGradient = [organic, Color(0xFF81C784)];
  static const List<Color> hazardousGradient = [hazardous, Color(0xFFFF8A80)];
  static const List<Color> landfillGradient = [landfill, Color(0xFFE0E0E0)];
  static const List<Color> ewasteGradient = [ewaste, Color(0xFFCE93D8)];
  
  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: 2,
    ),
  ];

  // Icon maps with modern eco-friendly icons
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

  // Typography
  static const String fontFamily = 'Poppins';
  static const String fontFamilyMono = 'RobotoMono';
  
  // Text styles
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: textPrimary,
  );
  
  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static TextStyle get displaySmall => GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static TextStyle get headlineLarge => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get titleMedium => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get titleSmall => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  
  static TextStyle get labelLarge => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get labelMedium => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static TextStyle get labelSmall => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.5,
  );

  // Spacing (4pt grid system)
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
  
  // Standard padding
  static const EdgeInsets paddingSmall = EdgeInsets.all(spacing2);
  static const EdgeInsets paddingMedium = EdgeInsets.all(spacing4);
  static const EdgeInsets paddingLarge = EdgeInsets.all(spacing6);
  
  // Horizontal padding
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: spacing2);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: spacing4);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: spacing6);
  
  // Vertical padding
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: spacing2);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: spacing4);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: spacing6);

  // Border radius
  static const double radiusNone = 0.0;
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radius2XL = 20.0;
  static const double radius3XL = 24.0;
  static const double radiusFull = 1000.0; // For circular shapes
  
  // Border radius helpers
  static BorderRadius borderRadiusXS = BorderRadius.circular(radiusXS);
  static BorderRadius borderRadiusS = BorderRadius.circular(radiusS);
  static BorderRadius borderRadiusM = BorderRadius.circular(radiusM);
  static BorderRadius borderRadiusL = BorderRadius.circular(radiusL);
  static BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static BorderRadius borderRadius2XL = BorderRadius.circular(radius2XL);
  static BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // Elevation shadows
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
  
  // Custom shadows for depth
  static const List<BoxShadow> shadowFloating = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: 2,
    ),
  ];
  
  // Inner shadows for depth
  static const List<BoxShadow> shadowInsetSmall = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  // Convenience lookup maps (unchanged semantics)
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

  // Semantic colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Theme data
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
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: background,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusM,
            side: BorderSide(color: border, width: 1),
          ),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: surface,
          foregroundColor: textPrimary,
          titleTextStyle: titleLarge.copyWith(fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: textPrimary, size: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textInverse,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: spacing4, vertical: spacing3),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusM),
            textStyle: labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: spacing4, vertical: spacing3),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusM),
            textStyle: labelLarge,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: spacing2, vertical: spacing1),
            textStyle: labelLarge,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: spacing4, vertical: spacing3),
          border: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: error, width: 2),
          ),
          labelStyle: bodyMedium.copyWith(color: textTertiary),
          hintStyle: bodyMedium.copyWith(color: textTertiary),
          errorStyle: bodySmall.copyWith(color: error),
        ),
        dividerTheme: DividerThemeData(
          color: divider,
          thickness: 1,
          space: 1,
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
          surface: neutral800,
          error: error,
          onPrimary: textInverse,
          onSecondary: textInverse,
          onSurface: textInverse,
          onError: textInverse,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: neutral900,
        cardTheme: CardThemeData(
          elevation: 0,
          color: neutral800,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadiusM,
            side: BorderSide(color: Colors.white12, width: 1),
          ),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: textInverse,
          titleTextStyle: titleLarge.copyWith(color: textInverse, fontWeight: FontWeight.w700),
          iconTheme: const IconThemeData(color: textInverse, size: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryLight,
            foregroundColor: textInverse,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: spacing4, vertical: spacing3),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusM),
            textStyle: labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textInverse,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: Colors.white24, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: spacing4, vertical: spacing3),
            shape: RoundedRectangleBorder(borderRadius: borderRadiusM),
            textStyle: labelLarge.copyWith(color: textInverse),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: spacing2, vertical: spacing1),
            textStyle: labelLarge.copyWith(color: primaryLight),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: neutral800,
          contentPadding: const EdgeInsets.symmetric(horizontal: spacing4, vertical: spacing3),
          border: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: const BorderSide(color: Colors.white24, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: const BorderSide(color: Colors.white24, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadiusM,
            borderSide: BorderSide(color: error, width: 2),
          ),
          labelStyle: bodyMedium.copyWith(color: textInverse.withOpacity(0.7)),
          hintStyle: bodyMedium.copyWith(color: textInverse.withOpacity(0.6)),
          errorStyle: bodySmall.copyWith(color: error),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white10,
          thickness: 1,
          space: 1,
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
          bodySmall: bodySmall.copyWith(color: textInverse.withOpacity(0.8)),
          labelLarge: labelLarge.copyWith(color: textInverse),
          labelMedium: labelMedium.copyWith(color: textInverse),
          labelSmall: labelSmall.copyWith(color: textInverse.withOpacity(0.8)),
        ),
      );

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
    if (['collected', 'completed', 'success'].contains(lower)) return successGreen;
    if (['pending', 'scheduled'].contains(lower)) return warningYellow;
    if (['cancelled', 'failed'].contains(lower)) return errorRed;
    if (['in_progress', 'processing'].contains(lower)) return infoBlue;
    return neutral500;
  }

  static Color getEconomicStatusColor(String status) {
    final lower = status.toLowerCase();
    if (['profitable', 'savings', 'positive'].contains(lower)) return profitGreen;
    if (['break_even', 'neutral'].contains(lower)) return neutral500;
    if (['loss', 'negative', 'cost'].contains(lower)) return costRed;
    if (['efficient', 'optimized'].contains(lower)) return efficiencyBlue;
    return neutral500;
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

}
