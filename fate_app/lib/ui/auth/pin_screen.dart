import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';
import '../theme.dart';

enum PinMode { setup, verify }

/// PIN screen — used both for initial PIN setup (onboarding) and
/// subsequent session unlocking. All storage is hardware-backed
/// (FlutterSecureStorage → Android Keystore).
class PinScreen extends StatefulWidget {
  final PinMode mode;
  const PinScreen({super.key, required this.mode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _pin = [];
  List<String>? _firstPin; // Used in setup mode for confirmation
  bool _isConfirming = false;
  bool _isError = false;
  bool _isLoading = false;

  late final AnimationController _shakeCtrl;

  static const int _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin.add(digit);
      _isError = false;
    });
    if (_pin.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _handleComplete() async {
    final telemetry = context.read<TelemetryProvider>();

    if (widget.mode == PinMode.setup) {
      if (!_isConfirming) {
        // Store first PIN entry, ask to confirm
        setState(() {
          _firstPin = List.from(_pin);
          _pin.clear();
          _isConfirming = true;
        });
      } else {
        // Confirm step
        if (_listEquals(_pin, _firstPin!)) {
          setState(() => _isLoading = true);
          await telemetry.setPin(_pin.join());
          // App's Consumer will redirect to MainScreen automatically
        } else {
          _triggerError();
        }
      }
    } else {
      // Verify mode
      setState(() => _isLoading = true);
      final ok = await telemetry.verifyPin(_pin.join());
      if (!ok && mounted) {
        _triggerError();
      }
      // On success, Consumer in app.dart redirects automatically
    }
  }

  void _triggerError() {
    setState(() {
      _isError = true;
      _pin.clear();
      _isConfirming = false;
      _firstPin = null;
      _isLoading = false;
    });
    _shakeCtrl.forward(from: 0);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String get _title {
    if (widget.mode == PinMode.setup) {
      return _isConfirming ? 'Confirm your PIN' : 'Set a Security PIN';
    }
    return 'Enter your PIN';
  }

  String get _subtitle {
    if (widget.mode == PinMode.setup) {
      return _isConfirming
          ? 'Re-enter to confirm'
          : 'Protects your encrypted data vault';
    }
    return 'Unlock your FATE vault';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: Stack(
        children: [
          // Glow background
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    FateColors.primary.withAlpha(30),
                    FateColors.primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: FateColors.heroGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: FateColors.primary.withAlpha(60),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  _title,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isError ? '❌ Incorrect — try again' : _subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: _isError
                        ? const Color(0xFFF87171)
                        : FateColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // PIN dots
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    final offset = _isError
                        ? 8.0 *
                              (_shakeCtrl.value < 0.5
                                  ? _shakeCtrl.value * 2
                                  : (1 - _shakeCtrl.value) * 2)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(offset * 6 * (_shakeCtrl.value - 0.5), 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (i) {
                      final filled = i < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: filled ? 18 : 14,
                        height: filled ? 18 : 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? (_isError
                                    ? const Color(0xFFF87171)
                                    : FateColors.primary)
                              : Colors.white.withAlpha(20),
                          border: Border.all(
                            color: filled
                                ? Colors.transparent
                                : Colors.white.withAlpha(40),
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const Spacer(),

                // Numpad
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: CircularProgressIndicator(),
                  )
                else
                  _buildNumpad(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _numRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _numRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _numRow(['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip PIN (only in setup mode)
              if (widget.mode == PinMode.setup)
                _PadKey(
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: FateColors.textMuted,
                    ),
                  ),
                  onTap: () async {
                    // No PIN, just create identity and proceed
                    await context.read<TelemetryProvider>().initialize();
                  },
                )
              else
                const _PadKey(child: SizedBox.shrink(), onTap: null),

              _PadKey(
                child: Text(
                  '0',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                onTap: () => _onDigit('0'),
              ),

              _PadKey(
                child: const Icon(
                  Icons.backspace_outlined,
                  color: FateColors.textSecondary,
                  size: 22,
                ),
                onTap: _onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (d) => _PadKey(
              child: Text(
                d,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              onTap: () => _onDigit(d),
            ),
          )
          .toList(),
    );
  }
}

class _PadKey extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PadKey({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap != null
                ? Colors.white.withAlpha(8)
                : Colors.transparent,
          ),
          child: child,
        ),
      ),
    );
  }
}
