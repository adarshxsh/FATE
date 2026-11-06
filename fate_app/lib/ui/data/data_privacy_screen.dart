import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';
import '../theme.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final logs = telemetry.privacyLogs;

    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          FateSliverHeader(
            title: 'Data & Privacy',
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
                    Icons.info_outline_rounded,
                    color: FateColors.primary,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Live view of data stored in your encrypted local vault.',
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: FateColors.bgCard,
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

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info header
                GlassCard(
                  borderGradient: LinearGradient(
                    colors: [
                      FateColors.secondary.withAlpha(60),
                      FateColors.secondary.withAlpha(15),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: FateColors.coolGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Real-Time Telemetry',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: FateColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Live trace of data stored securely on this device',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: FateColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Score Breakdown Card ───
                GlassCard(
                  borderGradient: LinearGradient(
                    colors: [
                      FateColors.primary.withAlpha(60),
                      FateColors.primary.withAlpha(15),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: FateColors.heroGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Score Breakdown',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: FateColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FateColors.scoreColor(
                                telemetry.focusScore,
                              ).withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'CAS: ${telemetry.focusScore.toStringAsFixed(1)}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: FateColors.scoreColor(
                                  telemetry.focusScore,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildScoreRow(
                        'Spatial (S_loc)',
                        telemetry.sLoc,
                        Icons.location_on_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildScoreRow(
                        'Social (S_soc)',
                        telemetry.sSoc,
                        Icons.people_rounded,
                      ),
                      const SizedBox(height: 8),
                      _buildScoreRow(
                        'Digital (S_dig)',
                        telemetry.sDig,
                        Icons.phone_android_rounded,
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withAlpha(10), height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatChip(
                            '${telemetry.appUsageStats.length}',
                            'Apps tracked',
                            Icons.apps_rounded,
                          ),
                          _buildStatChip(
                            '${telemetry.notificationLog.length}',
                            'Notifications',
                            Icons.notifications_rounded,
                          ),
                          _buildStatChip(
                            '${telemetry.nearbyPeers}',
                            'Peers',
                            Icons.bluetooth_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Community sharing controls ───
                _CommunityPrivacyCard(telemetry: telemetry),
                const SizedBox(height: 20),

                SectionHeader(
                  title: 'Secure Vault Log',
                  badge: '${logs.length} entries',
                  icon: Icons.terminal_rounded,
                ),
              ]),
            ),
          ),

          // Log entries
          if (logs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: FateColors.secondary.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_tethering_rounded,
                        size: 36,
                        color: FateColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Listening for events...',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: FateColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Keep the app open to track events',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: FateColors.textMuted,
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 14,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6, right: 10),
                            decoration: BoxDecoration(
                              color: FateColors.secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: FateColors.secondary.withAlpha(80),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              logs[index],
                              style: GoogleFonts.jetBrainsMono(
                                color: FateColors.secondary,
                                fontSize: 11,
                                height: 1.5,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: logs.length),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: FateColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: FateColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value.toStringAsFixed(2),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: value > 0
                ? const Color(0xFF4ADE80)
                : value < 0
                ? const Color(0xFFF87171)
                : FateColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: FateColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: FateColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 10, color: FateColors.textMuted),
        ),
      ],
    );
  }
}

/// What leaves the phone, and the switches that control it.
class _CommunityPrivacyCard extends StatelessWidget {
  final TelemetryProvider telemetry;
  const _CommunityPrivacyCard({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    TextStyle small(Color c) => GoogleFonts.outfit(fontSize: 11, color: c);
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community Sharing',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: FateColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Raw logs never leave this device. When on, only your CAS and '
            'sub-scores, plus "near peer X for N min", are sent so peers can '
            'see each other\'s focus and the campus view can be computed.',
            style: small(FateColors.textSecondary),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: telemetry.communityEnabled,
            onChanged: telemetry.setCommunityEnabled,
            title: Text(
              'Share scores with campus',
              style: GoogleFonts.outfit(fontSize: 13),
            ),
            subtitle: Text(
              telemetry.communityEnabled
                  ? (telemetry.communityOnline
                        ? 'Connected'
                        : 'Offline, will retry')
                  : 'Off: social contagion uses no peer data',
              style: small(FateColors.textMuted),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: telemetry.shareZone,
            onChanged: telemetry.communityEnabled
                ? telemetry.setShareZone
                : null,
            title: Text(
              'Include current zone',
              style: GoogleFonts.outfit(fontSize: 13),
            ),
            subtitle: Text(
              'Zone name only (e.g. LHC), never GPS. Zones with <3 people are hidden.',
              style: small(FateColors.textMuted),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Erase my data from server'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF87171),
              ),
              onPressed: () async {
                final ok = await telemetry.deleteCommunityData();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Server data erased. Sharing turned off.'
                          : 'Could not reach server. Try again when online.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
