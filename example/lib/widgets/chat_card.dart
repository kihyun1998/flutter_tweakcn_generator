import 'package:flutter/material.dart';

import '../theme/tweakcn_theme.g.dart';
import 'shared.dart';

class ChatCard extends StatelessWidget {
  const ChatCard({super.key});

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
          _ChatBubble(
            text: 'Hi! How can I help you today?',
            isMe: false,
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 10),
          _ChatBubble(
            text: 'I need help with my account settings.',
            isMe: true,
            colors: colors,
            radius: radius,
          ),
          const SizedBox(height: 10),
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
                child: ThemedTextField(
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
