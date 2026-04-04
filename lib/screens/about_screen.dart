import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('About NavAssist',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.remove_red_eye,
                  color: AppTheme.primaryBlue, size: 80),
            ),
            const SizedBox(height: 20),
            const Text(
              "Empowering Independence",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "NavAssist is an AI-powered assistive navigation application designed specifically for visually impaired and deafblind individuals. Our core mission is to provide safe, reliable, and real-time environmental awareness, even in complete offline scenarios (dead network zones).",
              style:
                  TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),
            const Text(
              "Core Features",
              style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(Icons.wifi_off, "Offline-First AI",
                "Uses local TFLite models for zero-latency obstacle detection without internet."),
            _buildFeatureTile(Icons.cloud_done, "Cloud AI Enhancement",
                "Automatically switches to highly accurate Cloud AI when an internet connection is available."),
            _buildFeatureTile(Icons.map, "High-Precision Routing",
                "Real-time turn-by-turn navigation with dynamic ETA calculations."),
            _buildFeatureTile(Icons.bluetooth, "Hardware Integration",
                "Connects to ESP32 wearables for haptic feedback and physical warnings."),
            const SizedBox(height: 30),
            const Text(
              "What Our AI Detects",
              style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Our dual-engine AI (Cloud + Edge) is trained to detect a wide variety of everyday obstacles and points of interest to keep you safe:",
              style:
                  TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTag("Persons / Pedestrians"),
                _buildTag("Cars & Vehicles"),
                _buildTag("Bicycles"),
                _buildTag("Traffic Lights"),
                _buildTag("Stairs & Steps"),
                _buildTag("Doors & Entrances"),
                _buildTag("Chairs & Furniture"),
                _buildTag("Poles & Pillars"),
                _buildTag("Potholes (Cloud only)"),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purpleAccent, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
      ),
    );
  }
}
