import 'package:flutter/material.dart';

import '../theme/tweakcn_theme.g.dart';
import 'shared.dart';

class CreateAccountCard extends StatelessWidget {
  const CreateAccountCard({super.key});

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
            'Create an account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.cardForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your email below to create your account',
            style: TextStyle(fontSize: 14, color: colors.mutedForeground),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedActionButton(
                  icon: Icons.g_mobiledata,
                  label: 'Google',
                  colors: colors,
                  radius: radius,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedActionButton(
                  icon: Icons.apple,
                  label: 'Apple',
                  colors: colors,
                  radius: radius,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: colors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(fontSize: 11, color: colors.mutedForeground),
                ),
              ),
              Expanded(child: Divider(color: colors.border)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.cardForeground,
            ),
          ),
          const SizedBox(height: 6),
          ThemedTextField(
            hintText: 'm@example.com',
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 16),
          Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.cardForeground,
            ),
          ),
          const SizedBox(height: 6),
          ThemedTextField(
            hintText: '',
            obscureText: true,
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Create account',
              colors: colors,
              radius: radius,
            ),
          ),
        ],
      ),
    );
  }
}
