import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design_system/design_tokens.dart';
import '../design_system/theme/extensions.dart';
import 'color_tokens.dart';

class AppTheme {
  static ThemeData light() => lightTheme;
  static ThemeData dark() => darkTheme;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColorTokens.lightPrimary,
      onPrimary: AppColorTokens.lightOnPrimary,
      primaryContainer: AppColorTokens.lightPrimaryContainer,
      onPrimaryContainer: AppColorTokens.lightOnPrimaryContainer,
      secondary: AppColorTokens.lightSecondary,
      onSecondary: AppColorTokens.lightOnSecondary,
      secondaryContainer: AppColorTokens.lightSecondaryContainer,
      onSecondaryContainer: AppColorTokens.lightOnSecondaryContainer,
      tertiary: AppColorTokens.lightTertiary,
      onTertiary: AppColorTokens.lightOnTertiary,
      tertiaryContainer: AppColorTokens.lightTertiaryContainer,
      onTertiaryContainer: AppColorTokens.lightOnTertiaryContainer,
      error: AppColorTokens.lightError,
      onError: AppColorTokens.lightOnError,
      errorContainer: AppColorTokens.lightErrorContainer,
      onErrorContainer: AppColorTokens.lightOnErrorContainer,
      surface: AppColorTokens.lightSurface,
      onSurface: AppColorTokens.lightOnSurface,
      surfaceContainerHighest: AppColorTokens.lightSurfaceVariant,
      onSurfaceVariant: AppColorTokens.lightOnSurfaceVariant,
      outline: AppColorTokens.lightOutline,
      outlineVariant: AppColorTokens.lightOutlineVariant,
      shadow: AppColorTokens.lightShadow,
      scrim: AppColorTokens.lightScrim,
      inverseSurface: AppColorTokens.lightInverseSurface,
      onInverseSurface: AppColorTokens.lightOnInverseSurface,
      inversePrimary: AppColorTokens.lightInversePrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorTokens.lightSurface,
      extensions: [AppTokens.light()],
      
      textTheme: _buildTextTheme(Brightness.light),
      
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: MemoryHubElevation.none,
        scrolledUnderElevation: MemoryHubElevation.none,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColorTokens.lightOnSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.h3,
          fontWeight: MemoryHubTypography.bold,
          color: AppColorTokens.lightOnSurface,
        ),
        iconTheme: IconThemeData(
          color: AppColorTokens.lightOnSurface,
          size: 24,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: MemoryHubElevation.sm,
        shadowColor: AppColorTokens.lightShadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.xlRadius,
        ),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: MemoryHubElevation.none,
          padding: const EdgeInsets.symmetric(
            vertical: MemoryHubSpacing.lg,
            horizontal: MemoryHubSpacing.xxl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MemoryHubBorderRadius.lgRadius,
          ),
          backgroundColor: AppColorTokens.lightPrimary,
          foregroundColor: AppColorTokens.lightOnPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: MemoryHubTypography.bodyLarge,
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: MemoryHubSpacing.lg,
            horizontal: MemoryHubSpacing.xxl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MemoryHubBorderRadius.lgRadius,
          ),
          side: BorderSide(
            color: AppColorTokens.lightPrimary,
            width: 2,
          ),
          foregroundColor: AppColorTokens.lightPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: MemoryHubTypography.bodyLarge,
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: MemoryHubSpacing.md,
            horizontal: MemoryHubSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MemoryHubBorderRadius.mdRadius,
          ),
          foregroundColor: AppColorTokens.lightPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: MemoryHubTypography.bodyMedium,
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorTokens.lightSecondary,
        foregroundColor: AppColorTokens.lightOnSecondary,
        elevation: MemoryHubElevation.md,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(color: AppColorTokens.lightOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(color: AppColorTokens.lightOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(
            width: 2,
            color: AppColorTokens.lightPrimary,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(color: AppColorTokens.lightError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(
            width: 2,
            color: AppColorTokens.lightError,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MemoryHubSpacing.xl,
          vertical: MemoryHubSpacing.lg,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColorTokens.lightOnSurfaceVariant,
          fontSize: MemoryHubTypography.bodyMedium,
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: MemoryHubColors.gray100,
        labelStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.bodySmall,
          fontWeight: MemoryHubTypography.medium,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: MemoryHubSpacing.md,
          vertical: MemoryHubSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.mdRadius,
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: MemoryHubColors.gray100,
        thickness: 1,
        space: 1,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColorTokens.lightPrimary,
        unselectedItemColor: AppColorTokens.lightOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: MemoryHubElevation.lg,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.caption,
          fontWeight: MemoryHubTypography.semiBold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.caption,
          fontWeight: MemoryHubTypography.medium,
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorTokens.lightInverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: AppColorTokens.lightOnInverseSurface,
          fontSize: MemoryHubTypography.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.mdRadius,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: MemoryHubElevation.xxl,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.xxlRadius,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.h3,
          fontWeight: MemoryHubTypography.bold,
          color: AppColorTokens.lightOnSurface,
        ),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColorTokens.lightPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorTokens.darkPrimary,
      onPrimary: AppColorTokens.darkOnPrimary,
      primaryContainer: AppColorTokens.darkPrimaryContainer,
      onPrimaryContainer: AppColorTokens.darkOnPrimaryContainer,
      secondary: AppColorTokens.darkSecondary,
      onSecondary: AppColorTokens.darkOnSecondary,
      secondaryContainer: AppColorTokens.darkSecondaryContainer,
      onSecondaryContainer: AppColorTokens.darkOnSecondaryContainer,
      tertiary: AppColorTokens.darkTertiary,
      onTertiary: AppColorTokens.darkOnTertiary,
      tertiaryContainer: AppColorTokens.darkTertiaryContainer,
      onTertiaryContainer: AppColorTokens.darkOnTertiaryContainer,
      error: AppColorTokens.darkError,
      onError: AppColorTokens.darkOnError,
      errorContainer: AppColorTokens.darkErrorContainer,
      onErrorContainer: AppColorTokens.darkOnErrorContainer,
      surface: AppColorTokens.darkSurface,
      onSurface: AppColorTokens.darkOnSurface,
      surfaceContainerHighest: AppColorTokens.darkSurfaceVariant,
      onSurfaceVariant: AppColorTokens.darkOnSurfaceVariant,
      outline: AppColorTokens.darkOutline,
      outlineVariant: AppColorTokens.darkOutlineVariant,
      shadow: AppColorTokens.darkShadow,
      scrim: AppColorTokens.darkScrim,
      inverseSurface: AppColorTokens.darkInverseSurface,
      onInverseSurface: AppColorTokens.darkOnInverseSurface,
      inversePrimary: AppColorTokens.darkInversePrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColorTokens.darkSurface,
      extensions: [AppTokens.dark()],
      
      textTheme: _buildTextTheme(Brightness.dark),
      
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: MemoryHubElevation.none,
        scrolledUnderElevation: MemoryHubElevation.none,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColorTokens.darkOnSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.h3,
          fontWeight: MemoryHubTypography.bold,
          color: AppColorTokens.darkOnSurface,
        ),
        iconTheme: IconThemeData(
          color: AppColorTokens.darkOnSurface,
          size: 24,
        ),
      ),
      
      cardTheme: CardThemeData(
        elevation: MemoryHubElevation.sm,
        shadowColor: AppColorTokens.darkShadow.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.xlRadius,
        ),
        color: AppColorTokens.darkSurfaceVariant,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: MemoryHubElevation.none,
          padding: const EdgeInsets.symmetric(
            vertical: MemoryHubSpacing.lg,
            horizontal: MemoryHubSpacing.xxl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MemoryHubBorderRadius.lgRadius,
          ),
          backgroundColor: AppColorTokens.darkPrimary,
          foregroundColor: AppColorTokens.darkOnPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: MemoryHubTypography.bodyLarge,
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: MemoryHubSpacing.lg,
            horizontal: MemoryHubSpacing.xxl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MemoryHubBorderRadius.lgRadius,
          ),
          side: BorderSide(
            color: AppColorTokens.darkPrimary,
            width: 2,
          ),
          foregroundColor: AppColorTokens.darkPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: MemoryHubTypography.bodyLarge,
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: MemoryHubSpacing.md,
            horizontal: MemoryHubSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: MemoryHubBorderRadius.mdRadius,
          ),
          foregroundColor: AppColorTokens.darkPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: MemoryHubTypography.bodyMedium,
            fontWeight: MemoryHubTypography.semiBold,
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorTokens.darkSecondary,
        foregroundColor: AppColorTokens.darkOnSecondary,
        elevation: MemoryHubElevation.md,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorTokens.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(color: AppColorTokens.darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(color: AppColorTokens.darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(
            width: 2,
            color: AppColorTokens.darkPrimary,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(color: AppColorTokens.darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: MemoryHubBorderRadius.lgRadius,
          borderSide: BorderSide(
            width: 2,
            color: AppColorTokens.darkError,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MemoryHubSpacing.xl,
          vertical: MemoryHubSpacing.lg,
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColorTokens.darkOnSurfaceVariant,
          fontSize: MemoryHubTypography.bodyMedium,
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: AppColorTokens.darkSurfaceVariant,
        labelStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.bodySmall,
          fontWeight: MemoryHubTypography.medium,
          color: AppColorTokens.darkOnSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: MemoryHubSpacing.md,
          vertical: MemoryHubSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.mdRadius,
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: AppColorTokens.darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorTokens.darkSurfaceVariant,
        selectedItemColor: AppColorTokens.darkPrimary,
        unselectedItemColor: AppColorTokens.darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: MemoryHubElevation.lg,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.caption,
          fontWeight: MemoryHubTypography.semiBold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.caption,
          fontWeight: MemoryHubTypography.medium,
        ),
      ),
      
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorTokens.darkInverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: AppColorTokens.darkOnInverseSurface,
          fontSize: MemoryHubTypography.bodyMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.mdRadius,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorTokens.darkSurfaceVariant,
        elevation: MemoryHubElevation.xxl,
        shape: RoundedRectangleBorder(
          borderRadius: MemoryHubBorderRadius.xxlRadius,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: MemoryHubTypography.h3,
          fontWeight: MemoryHubTypography.bold,
          color: AppColorTokens.darkOnSurface,
        ),
      ),
      
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColorTokens.darkPrimary,
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? MemoryHubColors.gray900
        : Colors.white;
    
    final secondaryColor = brightness == Brightness.light
        ? MemoryHubColors.gray600
        : MemoryHubColors.gray300;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: MemoryHubTypography.display1,
        fontWeight: MemoryHubTypography.bold,
        color: baseColor,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: MemoryHubTypography.display2,
        fontWeight: MemoryHubTypography.bold,
        color: baseColor,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: MemoryHubTypography.h1,
        fontWeight: MemoryHubTypography.bold,
        color: baseColor,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: MemoryHubTypography.h1,
        fontWeight: MemoryHubTypography.bold,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: MemoryHubTypography.h2,
        fontWeight: MemoryHubTypography.bold,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: MemoryHubTypography.h3,
        fontWeight: MemoryHubTypography.semiBold,
        color: baseColor,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: MemoryHubTypography.h3,
        fontWeight: MemoryHubTypography.semiBold,
        color: baseColor,
        height: 1.4,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: MemoryHubTypography.h4,
        fontWeight: MemoryHubTypography.semiBold,
        color: baseColor,
        height: 1.4,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: MemoryHubTypography.h5,
        fontWeight: MemoryHubTypography.medium,
        color: baseColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodyLarge,
        fontWeight: MemoryHubTypography.regular,
        color: baseColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodyMedium,
        fontWeight: MemoryHubTypography.regular,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodySmall,
        fontWeight: MemoryHubTypography.regular,
        color: secondaryColor,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodyMedium,
        fontWeight: MemoryHubTypography.semiBold,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: MemoryHubTypography.bodySmall,
        fontWeight: MemoryHubTypography.medium,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: MemoryHubTypography.caption,
        fontWeight: MemoryHubTypography.medium,
        color: secondaryColor,
      ),
    );
  }
}
