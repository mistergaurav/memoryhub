import 'package:flutter/material.dart';

class MemoryHubColors {
  static const Color primary = Color(0xFF4F46E5);
  
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue700 = Color(0xFF1D4ED8);
  
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  
  static const Color pink500 = Color(0xFFEC4899);
  static const Color pink400 = Color(0xFFF472B6);
  static const Color pink600 = Color(0xFFDB2777);
  
  static const Color purple500 = Color(0xFF8B5CF6);
  static const Color purple400 = Color(0xFFA78BFA);
  static const Color purple600 = Color(0xFF7C3AED);
  static const Color purple700 = Color(0xFF6D28D9);
  
  static const Color cyan300 = Color(0xFF67E8F9);
  static const Color cyan500 = Color(0xFF06B6D4);
  static const Color cyan400 = Color(0xFF22D3EE);
  static const Color cyan600 = Color(0xFF0891B2);
  static const Color cyan700 = Color(0xFF0E7490);
  
  static const Color yellow50 = Color(0xFFFEFCE8);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color yellow500 = Color(0xFFEAB308);
  
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
  
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red400 = Color(0xFFF87171);
  static const Color red600 = Color(0xFFDC2626);
  
  static const Color green500 = Color(0xFF10B981);
  static const Color green400 = Color(0xFF34D399);
  static const Color green600 = Color(0xFF059669);
  
  static const Color teal300 = Color(0xFF5EEAD4);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal600 = Color(0xFF0D9488);
  
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
}

class MemoryHubSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double xxxxl = 64.0;
}

class MemoryHubBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  
  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get xxlRadius => BorderRadius.circular(xxl);
  static BorderRadius get fullRadius => BorderRadius.circular(999);
}

class MemoryHubElevation {
  static const double none = 0.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
}

class MemoryHubTypography {
  static const String fontFamily = 'Inter';
  
  static const double display1 = 48.0;
  static const double display2 = 40.0;
  static const double h1 = 32.0;
  static const double h2 = 24.0;
  static const double h3 = 20.0;
  static const double h4 = 18.0;
  static const double h5 = 16.0;
  static const double h6 = 14.0;
  
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  
  static const double caption = 12.0;
  static const double overline = 10.0;
  
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

class MemoryHubGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.indigo500, MemoryHubColors.purple500],
  );
  
  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.pink500, MemoryHubColors.purple500],
  );
  
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.cyan500, MemoryHubColors.teal500],
  );
  
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.green500, MemoryHubColors.teal500],
  );
  
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.amber500, MemoryHubColors.amber600],
  );
  
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.red500, MemoryHubColors.red600],
  );
  
  static const LinearGradient familyHub = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      MemoryHubColors.purple700,
      MemoryHubColors.pink500,
      MemoryHubColors.cyan500,
    ],
  );
  
  static const LinearGradient albums = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.purple600, MemoryHubColors.purple400],
  );
  
  static const LinearGradient calendar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.cyan500, MemoryHubColors.cyan400],
  );
  
  static const LinearGradient milestones = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.amber500, MemoryHubColors.amber400],
  );
  
  static const LinearGradient recipes = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MemoryHubColors.red500, MemoryHubColors.red400],
  );
}

class MemoryHubAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}

class DesignTokens {
  static const Color primaryColor = MemoryHubColors.primary;
}
