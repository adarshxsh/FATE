import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({Key? key}) : super(key: key);

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> with TickerProviderStateMixin {
  late AnimationController _radarScanController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _radarScanController = AnimationController(
       vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _radarScanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  _buildRadarSection(),
                  _buildPeersList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.gridLines)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.grid_view, color: AppColors.gridLines, size: 28),
              ClipPath(
                clipper: _TopRightChamferClipper(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.5 + (_pulseController.value * 0.5),
                            child: const Icon(Icons.radar, color: AppColors.secondary, size: 14),
                          );
                        }
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "ZONE: LIBRARY_SILENT",
                        style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("CONTEXT MESH", style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  SizedBox(height: 4),
                  Text("SENSORS: ACTIVE // BLE_SCAN_INTERVAL: 200ms", style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.5)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text("NET_ID", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text("88:A2:X9", style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRadarSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.gridLines)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(
                painter: _GridPainter(color: AppColors.gridLines, spacing: 40),
              ),
            ),
          ),
          
          // Radar Container
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gridLines),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rings
                _buildRing(0.75, BorderStyle.solid), // Not dashed in Flutter easily without CustomPaint, just make thinner or opacity
                _buildRing(0.50, BorderStyle.solid),
                _buildRing(0.25, BorderStyle.solid),
                
                // Crosshairs
                Container(width: 320, height: 1, color: AppColors.gridLines.withOpacity(0.5)),
                Container(height: 320, width: 1, color: AppColors.gridLines.withOpacity(0.5)),

                // Axis Labels
                const Positioned(top: 8, child: Text("0°", style: TextStyle(color: AppColors.gridLines, fontSize: 10))),
                const Positioned(right: 8, child: Text("90°", style: TextStyle(color: AppColors.gridLines, fontSize: 10))),
                const Positioned(bottom: 8, child: Text("180°", style: TextStyle(color: AppColors.gridLines, fontSize: 10))),
                const Positioned(left: 8, child: Text("270°", style: TextStyle(color: AppColors.gridLines, fontSize: 10))),

                // Sweep Animation
                RotationTransition(
                  turns: _radarScanController,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.6),
                        ],
                        stops: const [0.75, 0.95, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Center Anchors
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 10)],
                  ),
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 12 + (_pulseController.value * 24),
                      height: 12 + (_pulseController.value * 24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5 - (_pulseController.value * 0.5))),
                      ),
                    );
                  },
                ),

                // Blips
                _buildBlip(top: 0.4, left: 0.6, size: 8, color: AppColors.primary, label: "IPHONE_13_PRO"),
                _buildBlip(bottom: 0.25, left: 0.3, size: 6, color: AppColors.primary.withOpacity(0.8)),
                _buildBlip(top: 0.15, right: 0.2, size: 4, color: AppColors.primary.withOpacity(0.5)),
                _buildAlertBlip(bottom: 0.1, right: 0.45, size: 8, color: AppColors.alert, label: "UNKNOWN_TAG"),
              ],
            ),
          ),

          // Overlay stats
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: const [
                Icon(Icons.wifi_tethering, color: AppColors.primary, size: 12),
                SizedBox(width: 4),
                Text("RSSI_THRESHOLD: -90dBm", style: TextStyle(color: AppColors.primary, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRing(double scale, BorderStyle style) {
    return FractionallySizedBox(
      widthFactor: scale,
      heightFactor: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gridLines.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildBlip({double? top, double? bottom, double? left, double? right, required double size, required Color color, String? label}) {
    return Align(
      alignment: FractionalOffset(
        left ?? (1.0 - (right ?? 0.5)),
        top ?? (1.0 - (bottom ?? 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: color),
              ),
              child: Text(label, style: TextStyle(color: color, fontSize: 9)),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBlip({double? top, double? bottom, double? left, double? right, required double size, required Color color, required String label}) {
    return Align(
      alignment: FractionalOffset(
        left ?? (1.0 - (right ?? 0.5)),
        top ?? (1.0 - (bottom ?? 0.5)),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.5 + (_pulseController.value * 0.5),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: color),
              ),
              child: Text(label, style: TextStyle(color: color, fontSize: 9)),
            ),
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color, blurRadius: 8)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeersList() {
    return Expanded(
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // List Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("DETECTED SIGNATURES (5)", style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  Row(
                    children: const [
                      Icon(Icons.filter_list, color: AppColors.textMuted, size: 16),
                      SizedBox(width: 8),
                      Icon(Icons.refresh, color: AppColors.textMuted, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            // Table Headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gridLines)),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 5, child: Text("DEVICE ID (MASK)", style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5))),
                  Expanded(flex: 3, child: Text("RSSI (dBm)", textAlign: TextAlign.right, style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5))),
                  Expanded(flex: 4, child: Text("EST. DIST", textAlign: TextAlign.right, style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5))),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 60),
                children: [
                  _buildDataRow(
                    isPriority: true,
                    icon: Icons.smartphone,
                    id: "DE:4A:21:**",
                    rssi: "-42",
                    dist: "1.2m",
                    color: AppColors.primary,
                  ),
                  _buildDataRow(
                    icon: Icons.headphones,
                    id: "77:1B:09:**",
                    rssi: "-68",
                    dist: "4.5m",
                    color: AppColors.secondary,
                  ),
                  _buildDataRow(
                    icon: Icons.watch,
                    id: "A2:99:FF:**",
                    rssi: "-82",
                    dist: "8.0m",
                    color: AppColors.textMuted,
                  ),
                  _buildDataRow(
                    isAlert: true,
                    icon: Icons.warning,
                    id: "UNK_TAG_01",
                    rssi: "-35",
                    dist: "0.5m",
                    color: AppColors.alert,
                  ),
                  _buildDataRow(
                    icon: Icons.laptop_mac,
                    id: "C4:11:00:**",
                    rssi: "-91",
                    dist: "12.4m",
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            // Bottom Footer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.gridLines)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("STATUS: MONITORING", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text("MESH_VER: v2.0.4", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow({
    bool isPriority = false,
    bool isAlert = false,
    required IconData icon,
    required String id,
    required String rssi,
    required String dist,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.alert.withOpacity(0.05) : Colors.transparent,
        border: Border(
           bottom: BorderSide(color: AppColors.gridLines.withOpacity(0.5)),
           left: BorderSide(color: isPriority || isAlert ? color : Colors.transparent, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 8),
                Text(id, style: TextStyle(color: isPriority ? Colors.white : (isAlert ? AppColors.alert : AppColors.textSecondary), fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(rssi, textAlign: TextAlign.right, style: TextStyle(color: color, fontSize: 12, fontWeight: isPriority || isAlert ? FontWeight.bold : FontWeight.normal)),
          ),
          Expanded(
            flex: 4,
            child: Text(dist, textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return ClipPath(
      clipper: _ChamferClipper(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15)],
        ),
        child: const Icon(Icons.add, color: AppColors.background, size: 32),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  
  _GridPainter({required this.color, this.spacing = 20.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopRightChamferClipper extends CustomClipper<Path> {
  final double chamferSize;

  _TopRightChamferClipper({this.chamferSize = 12.0});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - chamferSize, 0);
    path.lineTo(size.width, chamferSize);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ChamferClipper extends CustomClipper<Path> {
  final double chamferSize;

  _ChamferClipper({this.chamferSize = 12.0});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(chamferSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - chamferSize);
    path.lineTo(size.width - chamferSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, chamferSize);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
