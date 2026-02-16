import 'package:flutter/material.dart';

import '../theme/tweakcn_theme.g.dart';

class PaymentsTable extends StatelessWidget {
  const PaymentsTable({super.key});

  static const _payments = [
    _Payment(true, 'Success', 'ken99@example.com', 316.0),
    _Payment(false, 'Success', 'abe45@example.com', 242.0),
    _Payment(false, 'Pending', 'monserrat44@example.com', 837.0),
    _Payment(true, 'Failed', 'silas22@example.com', 874.0),
    _Payment(false, 'Success', 'carmella@example.com', 721.0),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;
    final radius = context.tweakcnRadius;
    final shadows = context.tweakcnShadows;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(radius.lg),
        border: Border.all(color: colors.border),
        boxShadow: shadows.shadowLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.cardForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your payments and view transaction history.',
                  style: TextStyle(fontSize: 14, color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: colors.muted,
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Icon(
                    Icons.check_box_outline_blank,
                    size: 18,
                    color: colors.mutedForeground,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table rows
          ...List.generate(_payments.length, (i) {
            final p = _payments[i];
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Icon(
                      p.selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color:
                          p.selected ? colors.primary : colors.mutedForeground,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _StatusBadge(
                      status: p.status,
                      colors: colors,
                      radius: radius,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      p.email,
                      style: TextStyle(fontSize: 14, color: colors.foreground),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '\$${p.amount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.foreground,
                      ),
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

class _Payment {
  final bool selected;
  final String status;
  final String email;
  final double amount;

  const _Payment(this.selected, this.status, this.email, this.amount);
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const _StatusBadge({
    required this.status,
    required this.colors,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Success':
        bg = colors.chart2.withValues(alpha: 0.15);
        fg = colors.chart2;
        break;
      case 'Failed':
        bg = colors.destructive.withValues(alpha: 0.15);
        fg = colors.destructive;
        break;
      case 'Pending':
        bg = colors.accent;
        fg = colors.accentForeground;
        break;
      default:
        bg = colors.muted;
        fg = colors.mutedForeground;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius.xl),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}
