import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ───────────────────────────────────────────────────
// Minimal: neutral surfaces, one accent, semantic score colours.
// The gradient names are kept so existing call sites compile, but each is
// a flat single tone. Colour now carries meaning (score state) instead of
// decoration.
class FateColors {
  static const Color primary = Color(0xFF8B8CFF);
  static const Color primaryLight = Color(0xFFB4B5FF);
  static const Color accent = Color(0xFFFF7A7A);
  static const Color secondary = Color(0xFF4FD1B5);

  // Surfaces
  static const Color bgDeep = Color(0xFF0E0F13);
  static const Color bgCard = Color(0xFF17181D);
  static const Color bgCardLight = Color(0xFF1D1E24);
  static const Color bgElevated = Color(0xFF22232A);
  static const Color divider = Color(0xFF26272E);

  static const LinearGradient _flat = LinearGradient(
    colors: [bgElevated, bgElevated],
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [primary, primary],
  );
  static const LinearGradient warmGradient = _flat;
  static const LinearGradient coolGradient = _flat;
  static const LinearGradient purpleGradient = _flat;
  static const LinearGradient subtleGradient = _flat;

  static Color scoreColor(double score) {
    if (score >= 70) return const Color(0xFF4ADE80);
    if (score >= 40) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  static String scoreLabel(double score) {
    if (score >= 70) return 'Focused';
    if (score >= 40) return 'Steady';
    return 'Scattered';
  }

  // Text
  static const Color textPrimary = Color(0xFFF2F2F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
}

// ─── Reusable Widgets ──────────────────────────────────────────

/// Flat surface card. (Name kept for call-site compatibility.)
///
/// It used to be a frosted-glass BackdropFilter. Every one of those forces
/// an offscreen saveLayer + blur of everything behind it, so a scrolling
/// list of them janked on mid-range Android. `borderGradient` is accepted
/// and ignored.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final LinearGradient? borderGradient;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderGradient,
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius > 16 ? 16 : borderRadius);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: FateColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: FateColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Icon in the accent colour. (Was a gradient shader mask.)
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final LinearGradient gradient;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 28,
    this.gradient = FateColors.heroGradient,
  });

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: FateColors.textSecondary);
}

/// Section header with optional trailing badge
class SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final IconData? icon;

  const SectionHeader({super.key, required this.title, this.badge, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: FateColors.textMuted,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: FateColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge!,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: FateColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated shimmer line effect for loading states
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, required this.width, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Status dot indicator
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool pulsing;

  const StatusDot({
    super.key,
    required this.color,
    this.size = 8,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    if (!pulsing) return dot;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: dot,
    );
  }
}

/// Shared page header: pinned with a solid background, so content never
/// scrolls under the title. The title collapses from 26 to 20 pt on scroll.
/// Leaves room for the back button when the page was pushed.
class FateSliverHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  const FateSliverHeader({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return SliverAppBar(
      pinned: true,
      expandedHeight: 96,
      backgroundColor: FateColors.bgDeep,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(
          start: canPop ? 56 : 20,
          bottom: 14,
        ),
        expandedTitleScale: 1.3,
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FateColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
