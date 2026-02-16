# Using with Riverpod

Guide for integrating `flutter_tweakcn_generator` with [Riverpod](https://riverpod.dev).

## Overview

- **Theme switching** (light/dark) → Riverpod (`ref`)
- **Accessing colors, radius, shadows** → Flutter's `BuildContext`

## Setup

### 1. Theme Mode Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
```

### 2. MaterialApp

```dart
import 'theme/tweakcn_theme.g.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      theme: TweakcnTheme.light,
      darkTheme: TweakcnTheme.dark,
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
```

### 3. Toggle Theme

```dart
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return IconButton(
      icon: Icon(
        themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () {
        ref.read(themeModeProvider.notifier).state =
            themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}
```

### 4. Access Theme Tokens

Use `context` (not `ref`) to access colors, radius, and shadows:

```dart
class MyCard extends StatelessWidget {
  const MyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final shadows = context.tweakcnShadows;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(radius.lg),
        border: Border.all(color: colors.border),
        boxShadow: shadows.shadowMd,
      ),
      child: Text(
        'Hello',
        style: TextStyle(color: colors.cardForeground),
      ),
    );
  }
}
```

## Persisting Theme Preference

To save the user's theme preference across app restarts, use `shared_preferences`:

```dart
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('theme_mode');
    if (value != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}
```

Usage:

```dart
// Toggle
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
```

## FAQ

**Q: Do I need to use `ref` to access colors?**
No. Colors, radius, and shadows are accessed via `context.tweakcnColors`, `context.tweakcnRadius`, `context.tweakcnShadows`. These use Flutter's built-in `Theme.of(context)` mechanism, which is independent of Riverpod.

**Q: Can I use `ConsumerWidget` or `StatelessWidget` for themed widgets?**
Either works. If the widget only needs theme tokens (no `ref`), a plain `StatelessWidget` is fine. Use `ConsumerWidget` only when you also need Riverpod state.
