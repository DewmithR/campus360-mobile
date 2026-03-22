import 'package:flutter/material.dart';

// NSBM Campus 360 – Colour Palette
class AppColors {
  // Primary brand
  static const primary = Color(0xFF006837); // NSBM Forest Green
  static const primaryDark = Color(0xFF004D27); // Deeper green for contrast
  static const primaryLight = Color(0xFF338A5E); // Lighter green for hover/tint

  // Secondary / accent
  static const secondary = Color(0xFF8DC63F); // Vibrant Leaf Green
  static const accent = Color(0xFFF9A825); // NSBM Amber Gold
  static const accentLight = Color(0xFFFFF3CD); // Soft gold tint for badges

  // Status colours
  static const success = Color(0xFF2E7D32); // Deep success green
  static const alert = Color(0xFFD32F2F); // Status Red
  static const warning = Color(0xFFF57C00); // Amber warning
  static const info = Color(0xFF0277BD); // Info blue

  // Neutrals
  static const neutralDark= Color(0xFF1A1A2E); // Rich near-black
  static const neutralMid  = Color(0xFF4A4A68); // Muted body text
  static const neutralLight = Color(0xFFF4F6F9); // Soft ice background
  static const neutralBorder = Color(0xFFE0E4EB); // Subtle divider/border

  // Surface
  static const surface = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFFFFFFF);

  // Gradient helpers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFFCA28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFF4F6F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Typography
class AppTextStyles {
  static const heading1 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.neutralDark,
    letterSpacing: -0.5,
  );

  static const heading2 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralDark,
    letterSpacing: -0.2,
  );

  static const heading3 = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralMid,
  );

  static const body = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    color: AppColors.neutralDark,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    color: AppColors.neutralMid,
    height: 1.4,
  );

  static const button = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const caption = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 11,
    color: AppColors.neutralMid,
    letterSpacing: 0.3,
  );

  static const label = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralMid,
    letterSpacing: 0.8,
  );
}

// Spacing & Radius
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

// Shadows
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 20,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];
}

// ThemeData
final ThemeData campus360Theme = ThemeData(
  useMaterial3: true,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.neutralLight,
  fontFamily: 'Roboto',

  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFB7DFC8),
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFDDF0B8),
    onSecondaryContainer: Color(0xFF2D4A00),
    tertiary: AppColors.accent,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.accentLight,
    onTertiaryContainer: Color(0xFF4A3000),
    error: AppColors.alert,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.neutralDark,
    surfaceContainerHighest: AppColors.neutralLight,
    outline: AppColors.neutralBorder,
    outlineVariant: Color(0xFFEEF0F4),
    shadow: Color(0x1F000000),
  ),

  // Text Theme
  textTheme: const TextTheme(
    displayLarge: AppTextStyles.heading1,
    displayMedium: AppTextStyles.heading1,
    headlineMedium: AppTextStyles.heading1,
    headlineSmall: AppTextStyles.heading2,
    titleLarge: AppTextStyles.heading2,
    titleMedium: AppTextStyles.heading3,
    titleSmall: AppTextStyles.heading3,
    bodyLarge: AppTextStyles.body,
    bodyMedium: AppTextStyles.body,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.button,
    labelSmall: AppTextStyles.caption,
  ),

  // AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 2,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.2,
    ),
    iconTheme: IconThemeData(color: Colors.white, size: 22),
  ),

  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.neutralBorder,
      disabledForegroundColor: AppColors.neutralMid,
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: AppTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      minimumSize: const Size(64, 48),
    ),
  ),

  // Outlined Button
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      minimumSize: const Size(64, 48),
    ),
  ),

  // Text Button
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    ),
  ),

  // Card
  cardTheme: CardThemeData(
    color: AppColors.surfaceCard,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      side: const BorderSide(color: AppColors.neutralBorder, width: 0.8),
    ),
    margin: EdgeInsets.zero,
  ),

  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.neutralBorder, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.neutralBorder, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.alert, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.alert, width: 1.8),
    ),
    labelStyle: AppTextStyles.bodySmall,
    hintStyle: AppTextStyles.bodySmall,
    errorStyle: AppTextStyles.caption.copyWith(color: AppColors.alert),
    prefixIconColor: AppColors.neutralMid,
    suffixIconColor: AppColors.neutralMid,
  ),

  // Bottom Navigation Bar
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.neutralMid,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 11,
    ),
  ),

  // Chip
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.neutralLight,
    selectedColor: AppColors.primaryLight,
    labelStyle: AppTextStyles.bodySmall,
    side: const BorderSide(color: AppColors.neutralBorder),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  ),

  // Divider
  dividerTheme: const DividerThemeData(
    color: AppColors.neutralBorder,
    thickness: 1,
    space: 1,
  ),

  // SnackBar
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.neutralDark,
    contentTextStyle: AppTextStyles.bodySmall.copyWith(color: Colors.white),
    actionTextColor: AppColors.accent,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    elevation: 4,
  ),

  // Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    titleTextStyle: AppTextStyles.heading2,
    contentTextStyle: AppTextStyles.body,
  ),

  // Progress Indicator
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.neutralBorder,
    circularTrackColor: AppColors.neutralBorder,
  ),

  // List Tile
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    tileColor: Colors.transparent,
    iconColor: AppColors.primary,
    titleTextStyle: AppTextStyles.body,
    subtitleTextStyle: AppTextStyles.bodySmall,
  ),
);