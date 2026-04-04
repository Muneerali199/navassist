import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../services/alert_service.dart';

class CaretakerDashboardScreen extends StatefulWidget {
  const CaretakerDashboardScreen({super.key});

  @override
  State<CaretakerDashboardScreen> createState() =>
      _CaretakerDashboardScreenState();
}

class _CaretakerDashboardScreenState extends State<CaretakerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    AlertService().addListener(_onAlertsChanged);
  }

  @override
  void dispose() {
    AlertService().removeListener(_onAlertsChanged);
    super.dispose();
  }

  void _onAlertsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = AlertService().activeAlerts;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Caretaker Dashboard',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "User Status",
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard("Hardware Battery", "85%",
                        Icons.battery_charging_full, AppTheme.safeGreen)),
                const SizedBox(width: 15),
                Expanded(
                    child: _buildMetricCard("Connection", "Online", Icons.wifi,
                        AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 15),
            _buildMetricCard("Current Location", "Main Street, NY",
                Icons.location_on, Colors.purpleAccent,
                isFullWidth: true),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Alerts & Obstacles",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    AlertService().clearAlerts();
                  },
                  child: const Text("Clear All",
                      style: TextStyle(color: AppTheme.primaryBlue)),
                )
              ],
            ),
            const SizedBox(height: 15),
            if (alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: Text("No active alerts",
                        style: TextStyle(color: Colors.white54))),
              )
            else
              ...alerts.map((alert) {
                Color alertColor;
                switch (alert["type"]) {
                  case "danger":
                    alertColor = AppTheme.dangerRed;
                    break;
                  case "warning":
                    alertColor = AppTheme.warningYellow;
                    break;
                  case "info":
                  default:
                    alertColor = AppTheme.primaryBlue;
                }
                return _buildAlertTile(
                    alert["message"]!, alert["time"]!, alertColor);
              }),
            const SizedBox(height: 30),
            const Text(
              "Live Map View",
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 60, color: Colors.white38),
                    SizedBox(height: 10),
                    Text("Map Stream Active",
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color,
      {bool isFullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(String message, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: BorderSide(color: color.withValues(alpha: 0.3)),
          right: BorderSide(color: color.withValues(alpha: 0.3)),
          bottom: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 16))),
          Text(time,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
