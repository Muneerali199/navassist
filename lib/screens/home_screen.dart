import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/sensor_radar.dart';
import '../widgets/sos_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/brand_logo.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSystemActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Center(child: NavAssistLogo(size: 32)),
        ),
        title: Text('NavAssist',
            style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.8)],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                )),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.glassPanel,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, size: 24),
              onPressed: () {
                // Open settings
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cyberpunk / Neural-Network Background Gradients
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.15),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentPurple.withOpacity(0.15),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Top System Status Layer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(
                        isActive: isSystemActive,
                        activeText: "System Active",
                        inactiveText: "System Offline",
                        activeColor: AppTheme.safeGreen,
                      ),
                      _buildMiniStatus(Icons.bluetooth_connected, "Hardware",
                          AppTheme.primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Open Advanced Map Navigation Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map_rounded, size: 28),
                    label: const Text("Open Surroundings Map"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      foregroundColor: Colors.white,
                      shadowColor: AppTheme.accentPurple.withOpacity(0.6),
                      elevation: 10,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MapScreen()));
                    },
                  ),
                  const SizedBox(height: 24),

                  // Glassmorphism AI Camera Status Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.glassPanel,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue.withOpacity(0.2),
                                    AppTheme.accentPurple.withOpacity(0.1)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.5)),
                              ),
                              child: const Icon(Icons.remove_red_eye_outlined,
                                  color: AppTheme.primaryBlue, size: 36),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Neural Engine",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontSize: 22)),
                                  const SizedBox(height: 6),
                                  Text("YOLOv8 Nano • Vision Clear",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.safeGreen,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Sensor Fusion Radar
                  const Expanded(
                    child: Center(
                      child: SensorRadar(),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Emergency Safety Layer
                  const EmergencySosButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatus(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.glassPanel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
