import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';
import '../theme.dart';
import 'pin_screen.dart';

/// First-launch onboarding — creates local UUID identity, sets display name,
/// then optionally sets a security PIN. No network calls, no Google auth.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _createIdentityAndContinue() async {
    final telemetry = context.read<TelemetryProvider>();
    setState(() => _isLoading = true);

    await telemetry.createLocalIdentity(
      displayName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      // Go to PIN setup screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PinScreen(mode: PinMode.setup),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: Stack(
        children: [
          // Background glow orbs
          Positioned(
            top: -140,
            left: -80,
            child: _glowOrb(FateColors.primary, 320),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _glowOrb(FateColors.accent, 260),
          ),

          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  // Page indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => _dot(i == _currentPage)),
                    ),
                  ),

                  // Pages
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: [
                        _WelcomePage(onNext: _nextPage),
                        _PrivacyPage(onNext: _nextPage),
                        _NamePage(
                          controller: _nameController,
                          isLoading: _isLoading,
                          onStart: _createIdentityAndContinue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withAlpha(35), color.withAlpha(0)],
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? FateColors.primary : FateColors.textMuted,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 1 — WELCOME
// ═══════════════════════════════════════════════════════════════
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: FateColors.heroGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: FateColors.primary.withAlpha(80),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 36),

          Text(
            'FATE',
            style: GoogleFonts.outfit(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Focus Attention Tracking Engine',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: FateColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              gradient: FateColors.heroGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 52),

          Text(
            'Your attention, measured.\nYour progress, private.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: FateColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 52),

          _PrimaryButton(label: 'Get Started', onTap: onNext),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 2 — PRIVACY
// ═══════════════════════════════════════════════════════════════
class _PrivacyPage extends StatelessWidget {
  final VoidCallback onNext;
  const _PrivacyPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: FateColors.coolGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Text(
                'Your Data, Your Device',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          ...[
            ('📍', 'Location', 'Tracks campus zones — stored encrypted on device'),
            ('📱', 'App Usage', 'Monitors app switching — never leaves your phone'),
            ('🔔', 'Notifications', 'Measures focus disruptions — zero content stored'),
            ('📡', 'Bluetooth', 'Detects nearby focus peers — local P2P only'),
            ('🔐', 'Encryption', 'AES-256 SQLCipher — hardware-backed key storage'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: FateColors.textPrimary,
                          ),
                        ),
                        Text(
                          item.$3,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: FateColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          _PrimaryButton(label: 'I Understand', onTap: onNext),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 3 — NAME + CREATE IDENTITY
// ═══════════════════════════════════════════════════════════════
class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onStart;

  const _NamePage({
    required this.controller,
    required this.isLoading,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should we\ncall you?',
            style: GoogleFonts.outfit(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Optional — displayed only on this device',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: FateColors.textMuted,
            ),
          ),
          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(
              color: FateColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: FateColors.primary.withAlpha(40),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'e.g. Adarsh',
                hintStyle: GoogleFonts.outfit(color: FateColors.textMuted),
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: FateColors.textMuted,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: FateColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A unique encrypted identity will be created on this device. No account or internet needed.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: FateColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _PrimaryButton(
                    label: 'Create Identity & Set PIN',
                    onTap: onStart,
                    icon: Icons.fingerprint_rounded,
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED BUTTON
// ═══════════════════════════════════════════════════════════════
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _PrimaryButton({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: FateColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FateColors.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
