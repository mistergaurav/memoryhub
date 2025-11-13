# Design System Migration Guide

## 🎯 Goal
Replace ALL inline styling with design system tokens from `memory_hub_app/lib/design_system/`

## 📋 Common Inline → Design System Mappings

### Colors

| Inline Color | Design System Token |
|--------------|-------------------|
| `Color(0xFF0E7C86)` | `MemoryHubColors.teal600` |
| `Color(0xFF1FB7C9)` | `MemoryHubColors.cyan500` |
| `Color(0xFFF2FBFC)` | `MemoryHubColors.gray50` |
| `Color(0xFF0B1F32)` | `MemoryHubColors.gray900` |
| `Color(0xFFE63946)` | `MemoryHubColors.red500` |
| `Color(0xFF10B981)` | `MemoryHubColors.green500` |
| `Color(0xFF4F46E5)` | `MemoryHubColors.indigo600` |
| `Color(0xFF6366F1)` | `MemoryHubColors.indigo500` |
| `Color(0xFFEC4899)` | `MemoryHubColors.pink500` |
| `Color(0xFF8B5CF6)` | `MemoryHubColors.purple500` |
| `Color(0xFF06B6D4)` | `MemoryHubColors.cyan500` |
| `Color(0xFFF59E0B)` | `MemoryHubColors.amber500` |
| `Color(0xFF14B8A6)` | `MemoryHubColors.teal500` |
| `Colors.grey.shade200` | `MemoryHubColors.gray200` |
| `Colors.white` | Use theme-aware `context.colors.surface` or keep as `Colors.white` for true white |

### Spacing

| Inline Value | Design System Token |
|--------------|-------------------|
| `4.0` or `EdgeInsets.all(4)` | `MemoryHubSpacing.xs` |
| `8.0` or `EdgeInsets.all(8)` | `MemoryHubSpacing.sm` |
| `12.0` or `EdgeInsets.all(12)` | `MemoryHubSpacing.md` |
| `16.0` or `EdgeInsets.all(16)` | `MemoryHubSpacing.lg` |
| `24.0` or `EdgeInsets.all(24)` | `MemoryHubSpacing.xl` |
| `32.0` or `EdgeInsets.all(32)` | `MemoryHubSpacing.xxl` |
| `48.0` or `EdgeInsets.all(48)` | `MemoryHubSpacing.xxxl` |
| `64.0` or `EdgeInsets.all(64)` | `MemoryHubSpacing.xxxxl` |

### Border Radius

| Inline Value | Design System Token |
|--------------|-------------------|
| `BorderRadius.circular(4)` | `MemoryHubBorderRadius.xsRadius` |
| `BorderRadius.circular(8)` | `MemoryHubBorderRadius.smRadius` |
| `BorderRadius.circular(12)` | `MemoryHubBorderRadius.mdRadius` |
| `BorderRadius.circular(14)` | `MemoryHubBorderRadius.lgRadius` (use 16) |
| `BorderRadius.circular(16)` | `MemoryHubBorderRadius.lgRadius` |
| `BorderRadius.circular(20)` | `MemoryHubBorderRadius.xlRadius` |
| `BorderRadius.circular(24)` | `MemoryHubBorderRadius.xxlRadius` |
| `BorderRadius.circular(999)` | `MemoryHubBorderRadius.fullRadius` |

### Typography

**Replace:** `GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)`  
**With:** Design system text styles (to be defined if needed) or use consistent values:

| Inline | Design System |
|--------|--------------|
| `fontSize: 48` | `MemoryHubTypography.display1` |
| `fontSize: 40` | `MemoryHubTypography.display2` |
| `fontSize: 32` | `MemoryHubTypography.h1` |
| `fontSize: 24` | `MemoryHubTypography.h2` |
| `fontSize: 20` | `MemoryHubTypography.h3` |
| `fontSize: 18` | `MemoryHubTypography.h4` |
| `fontSize: 16` | `MemoryHubTypography.h5` or `bodyLarge` |
| `fontSize: 14` | `MemoryHubTypography.h6` or `bodyMedium` |
| `fontSize: 12` | `MemoryHubTypography.bodySmall` or `caption` |
| `FontWeight.w400` | `MemoryHubTypography.regular` |
| `FontWeight.w500` | `MemoryHubTypography.medium` |
| `FontWeight.w600` | `MemoryHubTypography.semiBold` |
| `FontWeight.w700` | `MemoryHubTypography.bold` |

### Gradients

| Inline Gradient | Design System Token |
|-----------------|-------------------|
| `LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])` | `MemoryHubGradients.primary` |
| `LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)])` | `MemoryHubGradients.secondary` |
| `LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)])` | `MemoryHubGradients.accent` |
| `LinearGradient(colors: [Color(0xFF10B981), Color(0xFF14B8A6)])` | `MemoryHubGradients.success` |
| `LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])` | `MemoryHubGradients.warning` |
| `LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])` | `MemoryHubGradients.error` |

### Animations

| Inline Duration | Design System Token |
|-----------------|-------------------|
| `Duration(milliseconds: 150)` | `MemoryHubAnimations.fast` |
| `Duration(milliseconds: 300)` | `MemoryHubAnimations.normal` |
| `Duration(milliseconds: 400-500)` | `MemoryHubAnimations.slow` |
| `Duration(milliseconds: 800)` | `MemoryHubAnimations.verySlow` |

## 🔧 Refactoring Steps

1. **Add import:**
   ```dart
   import 'package:memory_hub_app/design_system/design_tokens.dart';
   ```

2. **Replace colors:**
   - Find: `static const Color _primaryTeal = Color(0xFF0E7C86);`
   - Replace with: Use `MemoryHubColors.teal600` directly

3. **Replace spacing:**
   - Find: `const EdgeInsets.all(16)`
   - Replace: `EdgeInsets.all(MemoryHubSpacing.lg)`

4. **Replace border radius:**
   - Find: `BorderRadius.circular(14)`
   - Replace: `MemoryHubBorderRadius.lgRadius`

5. **Replace typography:**
   - Find: `GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)`
   - Replace: `GoogleFonts.inter(fontSize: MemoryHubTypography.bodyMedium, fontWeight: MemoryHubTypography.medium)`

## ⚠️ Special Cases

### Health Records Feature
The `features/health_records/design_system.dart` file should be **removed** and all its color definitions should use the main design system instead.

### Remove Local Constants
Any widget defining local color constants like:
```dart
static const Color _primaryTeal = Color(0xFF0E7C86);
```
Should be removed and replaced with direct design system references.

## ✅ Validation

After each file refactoring:
1. No `Color(0x...)` definitions (except in design_system folder)
2. No hardcoded spacing values
3. No inline `BorderRadius.circular()` with magic numbers
4. All `GoogleFonts` calls use design system typography constants
5. Visual appearance remains identical
