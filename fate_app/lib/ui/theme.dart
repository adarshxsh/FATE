import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Premium Color Palette ─────────────────────────────────────
class FateColors {
  // Core brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color secondary = Color(0xFF00D4AA);

  // Backgrounds
  static const Color bgDeep = Color(0xFF08080F);
  static const Color bgCard = Color(0xFF13131E);
  static const Color bgCardLight = Color(0xFF1A1A2E);
  static const Color bgElevated = Color(0xFF1E1E30);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF3D38A0)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
  );

  static const LinearGradient coolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB721FF), Color(0xFF21D4FD)],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  );

  // Score colors
  static Color scoreColor(double score) {
    if (score >= 70) return const Color(0xFF00E676);
    if (score >= 40) return const Color(0xFFFFAB40);
    return const Color(0xFFFF5252);
  }

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textMuted = Color(0xFF6B6B80);
}

// ─── Reusable Widget Helpers ───────────────────────────────────

/// Glassmorphic frosted card with optional gradient border
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
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FateColors.bgCard.withAlpha(180),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withAlpha(15), width: 1),
          ),
          child: child,
        ),
      ),
    );

    Widget wrapped = borderGradient != null
        ? Container(
            margin: margin ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: borderGradient,
              borderRadius: BorderRadius.circular(borderRadius + 1),
            ),
            padding: const EdgeInsets.all(1.5),
            child: inner,
          )
        : Container(margin: margin ?? EdgeInsets.zero, child: inner);

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: wrapped);
    }
    return wrapped;
  }
}

/// Gradient icon badge (e.g. for metric cards)
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
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Icon(icon, size: size),
    );
  }
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
          if (icon != null) ...[
            GradientIcon(icon: icon!, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: FateColors.textPrimary,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: FateColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FateColors.primaryLight,
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(100),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
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
