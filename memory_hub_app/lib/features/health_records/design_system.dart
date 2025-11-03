import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HealthRecordsDesignSystem {
  static const deepCobalt = Color(0xFF1A3A6F);
  static const tealAccent = Color(0xFF2AB3A6);
  static const warmHighlight = Color(0xFFF4B860);
  static const softGray = Color(0xFFF5F7FA);
  static const charcoal = Color(0xFF1E293B);
  
  static const successGreen = Color(0xFF10B981);
  static const warningOrange = Color(0xFFF59E0B);
  static const errorRed = Color(0xFFEF4444);
  static const infoBlue = Color(0xFF3B82F6);
  static const purpleAccent = Color(0xFF8B5CF6);
  
  static const backgroundColor = Color(0xFFFAFBFC);
  static const surfaceColor = Colors.white;
  static const dividerColor = Color(0xFFE5E7EB);
  
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: textPrimary,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      letterSpacing: -0.3,
      height: 1.3,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      letterSpacing: -0.1,
      height: 1.4,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.4,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.5,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.5,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: textSecondary,
      height: 1.5,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textPrimary,
      height: 1.6,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.6,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textTertiary,
      height: 1.5,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      letterSpacing: 0.3,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: textSecondary,
      letterSpacing: 0.5,
    ),
  );

  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;
  static const spacing32 = 32.0;
  static const spacing40 = 40.0;
  static const spacing48 = 48.0;

  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 16.0;
  static const radiusXLarge = 20.0;
  static const radiusXXLarge = 24.0;

  static const shadowSmall = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const shadowMedium = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const shadowLarge = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const shadowXLarge = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static BoxShadow coloredShadow(Color color, {double opacity = 0.25}) {
    return BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );
  }

  static Color getRecordTypeColor(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'medical':
        return deepCobalt;
      case 'dental':
        return tealAccent;
      case 'vaccination':
        return successGreen;
      case 'lab_result':
        return purpleAccent;
      case 'prescription':
      case 'medication':
        return warningOrange;
      case 'allergy':
        return errorRed;
      case 'appointment':
        return infoBlue;
      case 'condition':
        return const Color(0xFFEC4899);
      case 'procedure':
        return const Color(0xFF06B6D4);
      default:
        return textSecondary;
    }
  }

  static IconData getRecordTypeIcon(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'medical':
        return Icons.medical_services_rounded;
      case 'dental':
        return Icons.sentiment_satisfied_rounded;
      case 'vaccination':
        return Icons.vaccines_rounded;
      case 'lab_result':
        return Icons.science_rounded;
      case 'prescription':
      case 'medication':
        return Icons.medication_rounded;
      case 'allergy':
        return Icons.warning_amber_rounded;
      case 'appointment':
        return Icons.event_rounded;
      case 'condition':
        return Icons.favorite_rounded;
      case 'procedure':
        return Icons.healing_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  static String formatRecordType(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'medical':
        return 'Medical';
      case 'dental':
        return 'Dental';
      case 'vaccination':
        return 'Vaccination';
      case 'lab_result':
        return 'Lab Result';
      case 'prescription':
        return 'Prescription';
      case 'medication':
        return 'Medication';
      case 'allergy':
        return 'Allergy';
      case 'appointment':
        return 'Appointment';
      case 'condition':
        return 'Condition';
      case 'procedure':
        return 'Procedure';
      default:
        return recordType;
    }
  }

  static Color getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return errorRed;
      case 'high':
        return warningOrange;
      case 'moderate':
      case 'medium':
        return warmHighlight;
      case 'low':
        return successGreen;
      default:
        return textSecondary;
    }
  }

  static Color getSubjectTypeColor(String subjectType) {
    switch (subjectType.toLowerCase()) {
      case 'self':
        return tealAccent;
      case 'family':
        return purpleAccent;
      case 'friend':
        return infoBlue;
      default:
        return textSecondary;
    }
  }

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  static const Curve animationCurve = Curves.easeOutCubic;
  static const Curve animationCurveSpring = Curves.easeInOutBack;
}
