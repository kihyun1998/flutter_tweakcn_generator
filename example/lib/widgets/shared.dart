import 'package:flutter/material.dart';

import '../theme/tweakcn_theme.g.dart';

class ThemedTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const ThemedTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    required this.colors,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        obscureText: obscureText,
        style: TextStyle(fontSize: 14, color: colors.foreground),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, color: colors.mutedForeground),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          filled: false,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius.md),
            borderSide: BorderSide(color: colors.input),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius.md),
            borderSide: BorderSide(color: colors.ring, width: 2),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.colors,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(radius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius.md),
        onTap: () {},
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.primaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class OutlinedActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const OutlinedActionButton({
    super.key,
    this.icon,
    required this.label,
    required this.colors,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.secondary,
      borderRadius: BorderRadius.circular(radius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius.md),
        onTap: () {},
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: colors.secondaryForeground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.secondaryForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
