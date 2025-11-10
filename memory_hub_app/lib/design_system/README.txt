# Memory Hub Design System

A comprehensive Material 3 design system with tokens, components, and utilities to ensure consistent UI/UX across the app.

## 🎯 Goals

- **No inline styles**: All styling through tokens and components
- **Material 3**: Modern, accessible design
- **Theme support**: Light/dark modes
- **Accessibility**: WCAG AA compliance, 44x44 touch targets
- **Reduced motion**: Respects user preferences

## 📦 Quick Start

```dart
import 'package:memory_hub_app/design_system/design_system.dart';

// Access via context extensions
Widget build(BuildContext context) {
  return Padded.md(
    child: Column(
      children: [
        Text('Title', style: context.text.titleLarge),
        const VGap.md(),
        PrimaryButton(
          onPressed: () {},
          label: 'Continue',
        ),
      ],
    ),
  );
}
```

## 🎨 Design Tokens

### Spacing
```dart
Spacing.xxs  // 4px
Spacing.xs   // 8px
Spacing.sm   // 12px
Spacing.md   // 16px (base)
Spacing.lg   // 24px
Spacing.xl   // 32px
Spacing.xxl  // 48px
Spacing.xxxl // 64px
```

### Radius
```dart
Radii.xs    // 4px
Radii.sm    // 8px
Radii.md    // 12px
Radii.lg    // 16px
Radii.xl    // 20px
Radii.pill  // 999px
```

### Durations
```dart
Durations.fast   // 120ms
Durations.base   // 200ms
Durations.slow   // 300ms
Durations.slower // 450ms
```

### Breakpoints
```dart
Breakpoints.sm  // 600px
Breakpoints.md  // 904px
Breakpoints.lg  // 1232px
Breakpoints.xl  // 1232px+
```

## 🧩 Components

### Buttons
```dart
PrimaryButton(onPressed: () {}, label: 'Save')
SecondaryButton(onPressed: () {}, label: 'Cancel')
TonalButton(onPressed: () {}, label: 'Edit')
DangerButton(onPressed: () {}, label: 'Delete')
IconButtonX(onPressed: () {}, icon: Icons.add, tooltip: 'Add')
```

### Inputs
```dart
TextFieldX(
  label: 'Email',
  hint: 'Enter your email',
  keyboardType: TextInputType.emailAddress,
)
```

### Layout
```dart
// Gaps
const VGap.md()  // Vertical gap
const HGap.lg()  // Horizontal gap

// Padding
Padded.md(child: ...)
ScreenPadding(responsive: true, child: ...)

// Sections
Section(
  title: Text('Profile'),
  child: ...,
)

CardSection(
  title: Text('Settings'),
  child: ...,
)
```

### Feedback
```dart
// Snackbars
AppSnackbar.success(context, 'Saved!');
AppSnackbar.error(context, 'Failed');
AppSnackbar.info(context, 'Info message');

// Dialogs
final confirmed = await AppDialog.confirm(
  context,
  title: 'Delete Item?',
  message: 'This action cannot be undone.',
);

await AppDialog.error(
  context,
  title: 'Error',
  message: 'Something went wrong',
);
```

## 🎭 Animations

### Motion Utilities
```dart
// Respect reduced motion
Duration duration = Motion.base(context);
bool shouldAnimate = !Motion.reducedMotion(context);

// Use standard curves
curve: Motion.standard
curve: Motion.emphasized
```

### Transitions
```dart
Navigator.push(context, fadeRoute(NextScreen()));
Navigator.push(context, slideRoute(NextScreen()));
Navigator.push(context, scaleRoute(NextScreen()));
```

### Animated Visibility
```dart
AnimatedVisibilityX(
  visible: isVisible,
  child: ...,
)
```

## 🎨 Theme & Context Extensions

### Access Theme
```dart
context.theme      // ThemeData
context.colors     // ColorScheme
context.text       // TextTheme
context.tokens     // AppTokens (custom)
```

### Responsive Helpers
```dart
context.isSm       // Is small screen
context.isMd       // Is medium screen
context.isLg       // Is large screen
context.isXl       // Is extra large screen
context.responsivePadding()  // Get responsive padding
```

## ♿ Accessibility

All components have:
- Minimum 44x44 touch targets
- Proper semantic labels
- Focus indicators
- Screen reader support
- Reduced motion support

```dart
// Manual touch target wrapper
MinTouchTarget(child: ...)

// Focus highlight
focusHighlight(context, child, focusNode)

// Semantic wrapper
withSemantics(
  label: 'Profile picture',
  hint: 'Tap to change',
  child: ...,
)
```

## 📐 Migration Guide

### Before (avoid)
```dart
Padding(
  padding: const EdgeInsets.all(16),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'Hello',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
  ),
)
```

### After (use design system)
```dart
Padded.md(
  child: AppCard(
    child: Text('Hello', style: context.text.titleMedium),
  ),
)
```

## ✅ Code Quality Rules

1. **No inline styles**: Use tokens and components
2. **No magic numbers**: All values from design tokens
3. **No hardcoded colors**: Use theme colors
4. **No raw EdgeInsets**: Use Padded or spacing tokens
5. **No raw SizedBox**: Use Gap widgets
6. **Prefer const**: Use const constructors where possible

## 🧪 Testing

Widget tests ensure:
- Components render correctly
- Touch targets meet minimum size
- Semantic labels present
- Reduced motion works
- Themes build without errors

Run tests:
```bash
flutter test
```

## 📚 Resources

- [Material 3 Design](https://m3.material.io/)
- [Flutter Accessibility](https://docs.flutter.dev/development/accessibility-and-localization/accessibility)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
