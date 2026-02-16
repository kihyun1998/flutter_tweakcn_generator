import 'package:flutter/material.dart';

import '../theme/tweakcn_theme.g.dart';
import 'shared.dart';

class CookieSettingsCard extends StatefulWidget {
  const CookieSettingsCard({super.key});

  @override
  State<CookieSettingsCard> createState() => _CookieSettingsCardState();
}

class _CookieSettingsCardState extends State<CookieSettingsCard> {
  bool _strictlyNecessary = true;
  bool _functional = false;
  bool _performance = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final shadows = context.tweakcnShadows;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(radius.lg),
        border: Border.all(color: colors.border),
        boxShadow: shadows.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cookie Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.cardForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your cookie settings here.',
            style: TextStyle(fontSize: 14, color: colors.mutedForeground),
          ),
          const SizedBox(height: 20),
          _CookieRow(
            title: 'Strictly Necessary',
            description:
                'These cookies are essential for the website to function.',
            value: _strictlyNecessary,
            onChanged: (v) => setState(() => _strictlyNecessary = v),
            colors: colors,
          ),
          Divider(color: colors.border, height: 32),
          _CookieRow(
            title: 'Functional Cookies',
            description:
                'These cookies allow the website to provide personalized features.',
            value: _functional,
            onChanged: (v) => setState(() => _functional = v),
            colors: colors,
          ),
          Divider(color: colors.border, height: 32),
          _CookieRow(
            title: 'Performance Cookies',
            description:
                'These cookies help improve the website\'s performance.',
            value: _performance,
            onChanged: (v) => setState(() => _performance = v),
            colors: colors,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedActionButton(
              label: 'Save preferences',
              colors: colors,
              radius: radius,
            ),
          ),
        ],
      ),
    );
  }
}

class _CookieRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TweakcnColors colors;

  const _CookieRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: colors.mutedForeground),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: colors.primaryForeground,
          activeTrackColor: colors.primary,
          inactiveThumbColor: colors.background,
          inactiveTrackColor: colors.input,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ],
    );
  }
}
