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
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
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

          final cards = [
            const _StatsCard(),
            const _CreateAccountCard(),
            const _ChatCard(),
            const _TeamMembersCard(),
            const _CookieSettingsCard(),
            const _PaymentsTable(),
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

// ─────────────────────────────────────────────
// 1. Stats Card (Total Revenue)
// ─────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  const _StatsCard();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Revenue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.cardForeground,
                ),
              ),
              Icon(Icons.attach_money, size: 16, color: colors.mutedForeground),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$45,231.89',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.cardForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+20.1% from last month',
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. Create Account Card (Login Form)
// ─────────────────────────────────────────────

class _CreateAccountCard extends StatelessWidget {
  const _CreateAccountCard();

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
                child: _OutlinedButton(
                  icon: Icons.g_mobiledata,
                  label: 'Google',
                  colors: colors,
                  radius: radius,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlinedButton(
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
          _ThemedTextField(
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
          _ThemedTextField(
            hintText: '',
            obscureText: true,
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
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

// ─────────────────────────────────────────────
// 3. Chat Card (Message UI)
// ─────────────────────────────────────────────

class _ChatCard extends StatelessWidget {
  const _ChatCard();

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
        boxShadow: shadows.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colors.accent,
                child: Text(
                  'S',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.accentForeground,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sofia Davis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.cardForeground,
                    ),
                  ),
                  Text(
                    'Active now',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Received message
          _ChatBubble(
            text: 'Hi! How can I help you today?',
            isMe: false,
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 10),
          // Sent message
          _ChatBubble(
            text: 'I need help with my account settings.',
            isMe: true,
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 10),
          // Received message
          _ChatBubble(
            text: 'Sure! What would you like to change?',
            isMe: false,
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ThemedTextField(
                  hintText: 'Type a message...',
                  colors: colors,
                  radius: radius,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(radius.md),
                ),
                child: Icon(
                  Icons.send,
                  size: 16,
                  color: colors.primaryForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.colors,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? colors.primary : colors.muted,
          borderRadius: BorderRadius.circular(radius.lg),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isMe ? colors.primaryForeground : colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 4. Team Members Card
// ─────────────────────────────────────────────

class _TeamMembersCard extends StatelessWidget {
  const _TeamMembersCard();

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

// ─────────────────────────────────────────────
// 5. Cookie Settings Card
// ─────────────────────────────────────────────

class _CookieSettingsCard extends StatefulWidget {
  const _CookieSettingsCard();

  @override
  State<_CookieSettingsCard> createState() => _CookieSettingsCardState();
}

class _CookieSettingsCardState extends State<_CookieSettingsCard> {
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
            child: _OutlinedButton(
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

// ─────────────────────────────────────────────
// 6. Payments Table
// ─────────────────────────────────────────────

class _PaymentsTable extends StatelessWidget {
  const _PaymentsTable();

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border, width: 1)),
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
                      color: p.selected
                          ? colors.primary
                          : colors.mutedForeground,
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

// ─────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────

class _ThemedTextField extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const _ThemedTextField({
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const _PrimaryButton({
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

class _OutlinedButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final TweakcnColors colors;
  final TweakcnRadius radius;

  const _OutlinedButton({
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
