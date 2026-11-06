import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../logic/score_history_service.dart';
import 'theme.dart';

/// Shows server-pushed analysis notifications/insights.
class NotificationLogScreen extends StatelessWidget {
  const NotificationLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ScoreHistoryService>();
    final notifications = history.serverNotifications;

    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          FateSliverHeader(
            title: 'Notifications',
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: FateColors.bgCard.withAlpha(200),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(10)),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: FateColors.primary,
                  ),
                  tooltip: 'Fetch Now',
                  onPressed: () {
                    history.fetchAndStore();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fetching fresh analysis...',
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: FateColors.bgCard,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          if (notifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: FateColors.primary.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        size: 40,
                        color: FateColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No insights yet',
                      style: GoogleFonts.outfit(
                        color: FateColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Local analysis arrives every 5 minutes',
                      style: GoogleFonts.outfit(
                        color: FateColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildInsightCard(context, notifications[index]),
                  ),
                  childCount: notifications.length,
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, Map<String, dynamic> n) {
    final type = n['type'] ?? 'info';
    final title = n['title'] ?? '';
    final body = n['body'] ?? '';
    final timeStr = n['time'] ?? '';
    final cas = n['cas'];

    // Parse time
    String displayTime = '';
    try {
      final dt = DateTime.parse(timeStr);
      displayTime =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    // Type styling
    Color typeColor;
    IconData typeIcon;
    LinearGradient iconGradient;
    switch (type) {
      case 'success':
        typeColor = const Color(0xFF4ADE80);
        typeIcon = Icons.check_circle_rounded;
        iconGradient = FateColors.coolGradient;
        break;
      case 'warning':
        typeColor = const Color(0xFFFFAB40);
        typeIcon = Icons.warning_rounded;
        iconGradient = FateColors.warmGradient;
        break;
      default:
        typeColor = FateColors.primary;
        typeIcon = Icons.info_rounded;
        iconGradient = FateColors.heroGradient;
    }

    return GlassCard(
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [typeColor.withAlpha(60), typeColor.withAlpha(10)],
      ),
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: typeColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: FateColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (cas != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: FateColors.bgElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CAS: ${(cas as num).toStringAsFixed(0)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: FateColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    if (displayTime.isNotEmpty)
                      Text(
                        displayTime,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: FateColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
