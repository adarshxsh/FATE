import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';
import '../theme.dart';

class SocialSynergyScreen extends StatelessWidget {
  const SocialSynergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final devices = telemetry.nearbyDevicesMap;
    final distances = telemetry.peerDistances;

    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Social Synergy',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero Card
                GlassCard(
                  borderGradient: FateColors.purpleGradient,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: FateColors.purpleGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.people_alt_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${telemetry.nearbyPeers} Peers Nearby',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                             '${telemetry.localFriends.length} excluded from scoring',
                              style: GoogleFonts.outfit(
                                color: FateColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _CampusPulseCard(telemetry: telemetry),
                const SizedBox(height: 24),

                // Info header
                SectionHeader(
                  title: 'Discovered Users',
                  icon: Icons.bluetooth_searching_rounded,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 14),
                  child: Text(
                    'High-focus peers at 1-2m improve your attention score.',
                    style: GoogleFonts.outfit(
                      color: FateColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Peer List
                if (devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: FateColors.primary.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bluetooth_searching_rounded,
                            size: 36,
                            color: FateColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Scanning for FATE users...',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: FateColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Make sure Bluetooth is enabled',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: FateColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...devices.entries.map((entry) {
                    final endpointId = entry.key;
                    // Friends are keyed by the stable BLE id, not the
                    // per-discovery endpointId, so the choice survives.
                    final bleId = telemetry.bleIdFor(endpointId);
                    final info = telemetry.peerInfo(bleId);
                    final peerName =
                        (info?['display_name'] as String?) ?? entry.value;
                    final peerCas = (info?['cas'] as num?)?.toDouble();
                    final isExcluded = telemetry.isFriend(bleId);
                    final distance = distances[endpointId] ?? 5.0;
                    final isClose = distance < 2.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        borderGradient: isClose
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFFB721FF).withAlpha(80),
                                  const Color(0xFF21D4FD).withAlpha(30),
                                ],
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: isExcluded
                                    ? FateColors.subtleGradient
                                    : FateColors.purpleGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isExcluded
                                    ? Icons.person_off_rounded
                                    : Icons.person_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          peerName,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: FateColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isClose) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: FateColors.purpleGradient,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'CLOSE',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${distance.toStringAsFixed(1)}m · '
                                    '${peerCas != null ? "CAS ${peerCas.toStringAsFixed(0)} · " : (info?['known'] == false ? "Not on FATE · " : "")}'
                                    '${isExcluded ? "Excluded" : "Active"}',
                                    style: GoogleFonts.outfit(
                                      color: isExcluded
                                          ? FateColors.textMuted
                                          : const Color(0xFF00E676),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: !isExcluded,
                              activeThumbColor: const Color(0xFF00E676),
                              activeTrackColor: const Color(
                                0xFF00E676,
                              ).withAlpha(60),
                              inactiveTrackColor: Colors.white.withAlpha(15),
                              inactiveThumbColor: FateColors.textMuted,
                              onChanged: (countThisPeer) {
                                if (countThisPeer) {
                                  telemetry.removeLocalFriend(bleId);
                                } else {
                                  telemetry.addLocalFriend(bleId);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


/// Campus-wide view from the community server.
class _CampusPulseCard extends StatelessWidget {
  final TelemetryProvider telemetry;
  const _CampusPulseCard({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final c = telemetry.campus;
    TextStyle label() =>
        GoogleFonts.outfit(fontSize: 11, color: FateColors.textMuted);
    TextStyle value() => GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: FateColors.textPrimary,
        );

    Widget stat(String v, String l) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(v, style: value()), Text(l, style: label())],
          ),
        );

    if (c == null) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: FateColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                telemetry.communityEnabled
                    ? 'Campus pulse loads once connected to the FATE server.'
                    : 'Community sharing is off (Data tab).',
                style: label(),
              ),
            ),
          ],
        ),
      );
    }

    final eng = (c['engagements'] as Map?) ?? {};
    final zones = (c['zones'] as List?) ?? [];
    final pct = c['my_percentile'];
    return GlassCard(
      borderGradient: FateColors.purpleGradient,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus Pulse · last 24h',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(children: [
            stat('${c['active_members'] ?? 0}', 'active members'),
            stat(c['avg_cas'] != null ? '${c['avg_cas']}' : '–', 'campus avg CAS'),
            stat(pct != null ? 'top ${(100 - (pct as num)).toStringAsFixed(0)}%' : '–', 'your rank'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            stat('${eng['positive'] ?? 0}', 'focus-lifting contacts'),
            stat('${eng['negative'] ?? 0}', 'focus-draining contacts'),
            stat('${eng['my_minutes'] ?? 0}m', 'your peer time'),
          ]),
          if (zones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Focus by zone', style: label()),
            const SizedBox(height: 6),
            ...zones.take(5).map((z) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Expanded(child: Text('${z['zone']}', style: GoogleFonts.outfit(fontSize: 12))),
                    Text('${z['avg_cas']} · ${z['members']} ppl', style: label()),
                  ]),
                )),
          ],
        ],
      ),
    );
  }
}
