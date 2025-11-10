# Widget API Reference for Manual Fixes

## Custom Design System Buttons (USE `label:` parameter)

These widgets accept a **String `label:`** parameter (NOT `child: Text()`):

### PrimaryButton
```dart
PrimaryButton(
  onPressed: () {},
  label: 'Click Me',  // ✅ CORRECT
  leading: Icon(Icons.add),  // Optional
  trailing: Icon(Icons.arrow_forward),  // Optional
  isLoading: false,  // Optional
  fullWidth: false,  // Optional
)
```

### SecondaryButton
```dart
SecondaryButton(
  onPressed: () {},
  label: 'Cancel',  // ✅ CORRECT
  // Same optional parameters as PrimaryButton
)
```

### DangerButton
```dart
DangerButton(
  onPressed: () {},
  label: 'Delete',  // ✅ CORRECT
  // Same optional parameters as PrimaryButton
)
```

### TonalButton
```dart
TonalButton(
  onPressed: () {},
  label: 'Maybe',  // ✅ CORRECT
  // Same optional parameters as PrimaryButton
)
```

---

## Standard Flutter Widgets (USE `child:` parameter)

These widgets accept a **Widget `child:`** parameter (NOT `label:`):

### TextButton, ElevatedButton, OutlinedButton
```dart
TextButton(
  onPressed: () {},
  child: const Text('Click'),  // ✅ CORRECT
)
```

### Card
```dart
Card(
  child: Padding(  // ✅ CORRECT
    padding: const EdgeInsets.all(16),
    child: Text('Content'),
  ),
)
```

### InkWell, GestureDetector
```dart
InkWell(
  onTap: () {},
  child: Container(...),  // ✅ CORRECT
)
```

### Container, Center, Padding
```dart
Container(
  child: Text('Content'),  // ✅ CORRECT
)
```

---

## Special Cases

### FloatingActionButton
```dart
// For icon-only FAB:
FloatingActionButton(
  onPressed: () {},
  child: const Icon(Icons.add),  // ✅ Uses child:
)

// For extended FAB with label:
FloatingActionButton.extended(
  onPressed: () {},
  label: const Text('Create'),  // ✅ Uses label: but as Text widget
  icon: const Icon(Icons.add),
)
```

### IconButton (Flutter standard)
```dart
IconButton(
  onPressed: () {},
  icon: const Icon(Icons.menu),  // ✅ Uses icon:, NOT child: or label:
  tooltip: 'Menu',
)
```

### IconButtonX (Custom design system)
```dart
IconButtonX(
  onPressed: () {},
  icon: Icons.menu,  // ✅ Uses IconData, NOT Widget
  tooltip: 'Menu',
)
```

### PopupMenuButton
```dart
PopupMenuButton(
  itemBuilder: (context) => [...],  // ✅ Uses itemBuilder:, NOT child:
  icon: const Icon(Icons.more_vert),  // Optional icon:
)
```

---

## Spacing Backward Compatibility Shims

These helper methods are available for backward compatibility:

```dart
// Method calls (returns EdgeInsets)
padding: Spacing.edgeInsetsAll(Spacing.lg)
padding: Spacing.edgeInsetsFromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.sm)
padding: Spacing.edgeInsetsSymmetric(horizontal: Spacing.md, vertical: Spacing.sm)
padding: Spacing.edgeInsetsOnly(left: Spacing.md, top: Spacing.sm)

// Static const fields
padding: Spacing.edgeInsetsAll16  // EdgeInsets.all(16)
padding: Spacing.edgeInsetsAll20  // EdgeInsets.all(20)
padding: Spacing.edgeInsetsBottomMd  // EdgeInsets.only(bottom: 16)
```

---

## Quick Decision Tree

**When fixing a widget parameter error:**

1. **Is it PrimaryButton, SecondaryButton, DangerButton, or TonalButton?**
   - YES → Use `label: 'text'` (String, no Text widget)
   - NO → Continue to #2

2. **Is it IconButton or IconButtonX?**
   - YES → Use `icon: Icons.xxx` or `icon: const Icon(Icons.xxx)`
   - NO → Continue to #3

3. **Is it FloatingActionButton.extended?**
   - YES → Use `label: const Text('text')` (Text widget!)
   - NO → Continue to #4

4. **Is it a standard Flutter widget (Card, Container, InkWell, TextButton, etc.)?**
   - YES → Use `child: Widget(...)` (any widget)
   - NO → Check the widget's definition file for its API

---

## Common Mistakes to Avoid

❌ **WRONG:**
```dart
PrimaryButton(
  onPressed: () {},
  child: const Text('Click'),  // Error: PrimaryButton doesn't have 'child'
)
```

✅ **CORRECT:**
```dart
PrimaryButton(
  onPressed: () {},
  label: 'Click',  // String, not Text widget
)
```

❌ **WRONG:**
```dart
TextButton(
  onPressed: () {},
  label: 'Click',  // Error: TextButton doesn't have 'label'
)
```

✅ **CORRECT:**
```dart
TextButton(
  onPressed: () {},
  child: const Text('Click'),  // Text widget
)
```

❌ **WRONG:**
```dart
Card(
  label: 'Content',  // Error: Card doesn't have 'label'
)
```

✅ **CORRECT:**
```dart
Card(
  child: Text('Content'),  // Any widget
)
```
