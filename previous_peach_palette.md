# Previous Peach/Orange Color Palette

This file contains the original peach/orange color palette code for reverting back if needed.

## Color Values

```dart
// Peach/Orange Palette
static const Color primaryPeach = Color(0xFFF0A07A); // Main peach
static const Color lightPeach = Color(0xFFD17A47);   // Light peach for gradient start
static const Color warmOrange = Color(0xFFB85C2E);   // Warm orange for gradient end
static const Color darkText = Color(0xFF4E342E);     // Dark text
```

---

## Welcome Screen (welcome_screen.dart)

### Color Definitions Section
Replace lines 16-19 with:

```dart
  // --- Define Brand Colors ---
  static const Color primaryPeach = Color(0xFFF0A07A);
  static const Color lightPeach = Color(0xFFD17A47);
  static const Color warmOrange = Color(0xFFB85C2E);
  static const Color darkText = Color(0xFF4E342E);
```

### Background Gradient
Replace the gradient colors with:

```dart
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lightPeach, warmOrange],
              ),
            ),
```

### Sign In Link Color
Replace the "Sign In" text color with:

```dart
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: primaryPeach,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
```

### Button Background Color
Replace the button backgroundColor with:

```dart
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPeach,
          foregroundColor: Colors.white,
```

---

## Splash Screen (splash_screen.dart)

### Color Definitions Section
Replace lines 20-26 with:

```dart
  // Define your brand colors
  static const Color primaryPeach = Color(0xFFF0A07A); // Main peach from logo
  static const Color lightPeach = Color(
    0xFFD17A47,
  ); // Darker peach for gradient start
  static const Color warmOrange = Color(
    0xFFB85C2E,
  ); // Darker orange for gradient end
```

### Background Gradient
Replace the gradient colors with:

```dart
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lightPeach, // Start with a lighter peach
              warmOrange, // End with a warmer orange
            ],
          ),
        ),
```

---

## Quick Revert Instructions

1. Open `lib/screens/shared/welcome_screen.dart`
2. Replace all instances of `primaryGreen` with `primaryPeach`
3. Replace all instances of `lightGreen` with `lightPeach`
4. Replace all instances of `darkGreen` with `warmOrange`

5. Open `lib/screens/splash_screen.dart`
6. Replace all instances of `primaryGreen` with `primaryPeach`
7. Replace all instances of `lightGreen` with `lightPeach`
8. Replace all instances of `darkGreen` with `warmOrange`

9. Hot restart the app (press `R` in terminal)

---

## Color Comparison

| Element | Peach/Orange | Green |
|---------|-------------|-------|
| Primary | `#F0A07A` | `#4CAF50` |
| Light | `#D17A47` | `#66BB6A` |
| Dark | `#B85C2E` | `#388E3C` |
| Text | `#4E342E` | `#1B5E20` |
