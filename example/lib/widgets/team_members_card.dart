import 'package:flutter/material.dart';

import '../theme/tweakcn_theme.g.dart';

class TeamMembersCard extends StatelessWidget {
  const TeamMembersCard({super.key});

  static const _members = [
    _Member('Sofia Davis', 's.davis@example.com', 'Owner', 'SD'),
    _Member('Jackson Lee', 'j.lee@example.com', 'Member', 'JL'),
    _Member('Isabella Nguyen', 'i.nguyen@example.com', 'Member', 'IN'),
  ];

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
            'Team Members',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.cardForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Invite your team members to collaborate.',
            style: TextStyle(fontSize: 14, color: colors.mutedForeground),
          ),
          const SizedBox(height: 20),
          ...List.generate(_members.length, (i) {
            final m = _members[i];
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.muted,
                    child: Text(
                      m.initials,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.foreground,
                          ),
                        ),
                        Text(
                          m.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      borderRadius: BorderRadius.circular(radius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.role,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.secondaryForeground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: colors.secondaryForeground,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Member {
  final String name;
  final String email;
  final String role;
  final String initials;

  const _Member(this.name, this.email, this.role, this.initials);
}
