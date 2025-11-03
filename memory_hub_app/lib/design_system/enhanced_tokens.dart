import 'package:flutter/material.dart';

class EnhancedColors {
  static const Color midnightIndigo = Color(0xFF1E1B4B);
  static const Color velvetRose = Color(0xFFE91E63);
  static const Color auroraTeal = Color(0xFF06B6D4);
  static const Color goldenDawn = Color(0xFFF59E0B);
  static const Color cloudGray = Color(0xFFF3F4F6);
  static const Color evergreen = Color(0xFF059669);
  static const Color coralBloom = Color(0xFFF87171);
  static const Color softSand = Color(0xFFFEF3C7);
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
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

class EnhancedSpacing {
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;
  static const double space80 = 80.0;
}

class EnhancedElevation {
  static const double none = 0.0;
  static const double soft = 2.0;
  static const double medium = 4.0;
  static const double raised = 8.0;
  static const double floating = 12.0;
  static const double modal = 16.0;
}

class EnhancedTypography {
  static const String fontFamily = 'Inter';
  
  static const double display1 = 48.0;
  static const double display2 = 40.0;
  static const double h1 = 32.0;
  static const double h2 = 28.0;
  static const double h3 = 24.0;
  static const double h4 = 20.0;
  static const double h5 = 18.0;
  static const double h6 = 16.0;
  static const double body = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  
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

class EnhancedAnimations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration smooth = Duration(milliseconds: 300);
  static const Duration moderate = Duration(milliseconds: 500);
  static const Duration leisurely = Duration(milliseconds: 700);
  
  static const Curve easeInOutCubic = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.easeIn;
}

class EnhancedMicroInteractions {
  static const double scaleFrom = 0.95;
  static const double scaleTo = 1.0;
  static const double fadeFrom = 0.0;
  static const double fadeTo = 1.0;
  static const double slideOffset = 20.0;
}

class EnhancedGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [EnhancedColors.midnightIndigo, EnhancedColors.velvetRose],
  );
  
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [EnhancedColors.auroraTeal, EnhancedColors.evergreen],
  );
  
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [EnhancedColors.evergreen, EnhancedColors.auroraTeal],
  );
  
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [EnhancedColors.goldenDawn, Color(0xFFFBBF24)],
  );
  
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [EnhancedColors.coralBloom, Color(0xFFEF4444)],
  );
  
  static const LinearGradient familyHub = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      EnhancedColors.midnightIndigo,
      EnhancedColors.velvetRose,
      EnhancedColors.auroraTeal,
    ],
  );
}

class EnhancedBorderRadius {
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
