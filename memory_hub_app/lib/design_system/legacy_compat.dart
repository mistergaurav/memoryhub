/// Legacy compatibility shims
/// These are deprecated and should be migrated to the new design system
import 'package:flutter/material.dart';
import 'tokens/radius_tokens.dart';

/// Deprecated: Use Radii instead
@Deprecated('Use Radii from design_system.dart instead')
class AppRadius {
  AppRadius._();

  static BorderRadius get xs => Radii.xsRadius;
  static BorderRadius get sm => Radii.smRadius;
  static BorderRadius get md => Radii.mdRadius;
  static BorderRadius get lg => Radii.lgRadius;
  static BorderRadius get xl => Radii.xlRadius;
}
