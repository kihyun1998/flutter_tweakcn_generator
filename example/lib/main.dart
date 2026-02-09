import 'package:flutter/material.dart';

import 'theme/tweakcn_theme.g.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tweakcn Theme Example',
      theme: TweakcnTheme.light,
      darkTheme: TweakcnTheme.dark,
      themeMode: _themeMode,
      home: HomePage(onToggleTheme: _toggleTheme),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const HomePage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final shadows = context.tweakcnShadows;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        title: const Text('tweakcn Theme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color palette
            Text(
              'Color Palette',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ColorTile('primary', colors.primary, colors),
                _ColorTile('secondary', colors.secondary, colors),
                _ColorTile('accent', colors.accent, colors),
                _ColorTile('muted', colors.muted, colors),
                _ColorTile('destructive', colors.destructive, colors),
              ],
            ),
            const SizedBox(height: 32),

            // Card example
            Text(
              'Card',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(radius.lg),
                border: Border.all(color: colors.border),
                boxShadow: shadows.shadowMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.cardForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This card uses tweakcn theme tokens: card background, '
                    'border color, radius.lg, and shadowMd.',
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Shadow examples
            Text(
              'Shadows',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ShadowTile('sm', shadows.shadowSm, colors, radius),
                _ShadowTile('md', shadows.shadowMd, colors, radius),
                _ShadowTile('lg', shadows.shadowLg, colors, radius),
                _ShadowTile('xl', shadows.shadowXl, colors, radius),
              ],
            ),
            const SizedBox(height: 32),

            // Radius examples
            Text(
              'Radius',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _RadiusTile('sm', radius.sm, colors),
                _RadiusTile('md', radius.md, colors),
                _RadiusTile('lg', radius.lg, colors),
                _RadiusTile('xl', radius.xl, colors),
              ],
            ),
            const SizedBox(height: 32),

            // Chart colors
            Text(
              'Chart Colors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ChartBar(colors.chart1, 0.9),
                const SizedBox(width: 4),
                _ChartBar(colors.chart2, 0.7),
                const SizedBox(width: 4),
                _ChartBar(colors.chart3, 0.5),
                const SizedBox(width: 4),
                _ChartBar(colors.chart4, 0.8),
                const SizedBox(width: 4),
                _ChartBar(colors.chart5, 0.6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  final String label;
  final Color color;
  final TweakcnColors colors;

  const _ColorTile(this.label, this.color, this.colors);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _ShadowTile extends StatelessWidget {
  final String label;
  final List<BoxShadow> shadow;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const _ShadowTile(this.label, this.shadow, this.colors, this.radius);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(radius.md),
        boxShadow: shadow,
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: colors.cardForeground)),
      ),
    );
  }
}

class _RadiusTile extends StatelessWidget {
  final String label;
  final double radiusVal;
  final TweakcnColors colors;

  const _RadiusTile(this.label, this.radiusVal, this.colors);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(radiusVal),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label (${radiusVal.toInt()})',
          style: TextStyle(fontSize: 11, color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _ChartBar extends StatelessWidget {
  final Color color;
  final double heightFactor;

  const _ChartBar(this.color, this.heightFactor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 120 * heightFactor,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}
