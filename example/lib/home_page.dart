import 'package:flutter/material.dart';

import 'theme/tweakcn_theme.g.dart';
import 'widgets/chat_card.dart';
import 'widgets/cookie_settings_card.dart';
import 'widgets/create_account_card.dart';
import 'widgets/payments_table.dart';
import 'widgets/stats_card.dart';
import 'widgets/team_members_card.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const HomePage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final colors = context.tweakcnColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.cardForeground,
        elevation: 0,
        title: Text(
          'tweakcn Theme Showcase',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final padding = isWide ? 32.0 : 16.0;

          final cards = <Widget>[
            const StatsCard(),
            const CreateAccountCard(),
            const ChatCard(),
            const TeamMembersCard(),
            const CookieSettingsCard(),
            const PaymentsTable(),
          ];

          if (isWide) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(children: _buildRows(cards)),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(padding),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => cards[i],
          );
        },
      ),
    );
  }

  List<Widget> _buildRows(List<Widget> cards) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (i + 1 < cards.length) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 16),
                Expanded(child: cards[i + 1]),
              ],
            ),
          ),
        );
      } else {
        rows.add(
          Row(
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
      }
      if (i + 2 < cards.length) {
        rows.add(const SizedBox(height: 16));
      }
    }
    return rows;
  }
}
