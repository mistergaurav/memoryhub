import 'package:flutter/material.dart';

class FamilyColors {
  static const midnightIndigo = Color(0xFF1E1B4B);
  static const velvetRose = Color(0xFFE91E63);
  static const auroraTeal = Color(0xFF06B6D4);
  static const goldenDawn = Color(0xFFF59E0B);
  static const evergreen = Color(0xFF059669);
  static const coralBloom = Color(0xFFF87171);
  static const cloudGray = Color(0xFFF3F4F6);
  static const softSand = Color(0xFFFEF3C7);
  static const pureWhite = Color(0xFFFFFFFF);
  static const deepCharcoal = Color(0xFF1F2937);

  static final familyDashboardGradient = LinearGradient(
    colors: [midnightIndigo, velvetRose, auroraTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final genealogyGradient = LinearGradient(
    colors: [evergreen, auroraTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final albumsGradient = LinearGradient(
    colors: [velvetRose, Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final calendarGradient = LinearGradient(
    colors: [auroraTeal, Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final milestonesGradient = LinearGradient(
    colors: [goldenDawn, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final recipesGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final healthGradient = LinearGradient(
    colors: [evergreen, Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final lettersGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), velvetRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class FamilyAnimations {
  static const instant = Duration(milliseconds: 100);
  static const quick = Duration(milliseconds: 200);
  static const smooth = Duration(milliseconds: 300);
  static const moderate = Duration(milliseconds: 500);
  static const slow = Duration(milliseconds: 800);

  static const easeInOutCubic = Cubic(0.65, 0.05, 0.36, 1);
  static const spring = Curves.easeOutBack;
  static const bounce = Curves.elasticOut;
  static const easeOut = Curves.easeOut;
  static const easeIn = Curves.easeIn;

  static const scaleFrom = 0.95;
  static const scaleTo = 1.0;
  static const slideOffset = Offset(0, 20);
  static const fadeFrom = 0.0;
  static const fadeTo = 1.0;
}

class FamilySpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

class FamilyBorderRadius {
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
}

class FamilyElevation {
  static const double none = 0.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
}

class FamilyIcons {
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData family = Icons.family_restroom_rounded;
  static const IconData albums = Icons.photo_library_rounded;
  static const IconData calendar = Icons.calendar_month_rounded;
  static const IconData milestones = Icons.celebration_rounded;
  static const IconData recipes = Icons.restaurant_menu_rounded;
  static const IconData timeline = Icons.timeline_rounded;
  static const IconData traditions = Icons.auto_stories_rounded;
  static const IconData health = Icons.health_and_safety_rounded;
  static const IconData letters = Icons.mail_rounded;
  static const IconData genealogy = Icons.account_tree_rounded;
  static const IconData person = Icons.person_rounded;
  static const IconData add = Icons.add_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData delete = Icons.delete_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData empty = Icons.inbox_rounded;
}
