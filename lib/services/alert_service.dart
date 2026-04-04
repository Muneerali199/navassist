import 'package:flutter/material.dart';

class AlertService extends ChangeNotifier {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final List<Map<String, String>> _activeAlerts = [
    {"message": "Route Started to Home", "time": "15 mins ago", "type": "info"},
    {"message": "Obstacle Avoided (Car)", "time": "2 mins ago", "type": "warning"},
  ];

  List<Map<String, String>> get activeAlerts => _activeAlerts;

  void triggerSOS(String userId) {
    _activeAlerts.insert(0, {
      "message": "🚨 EMERGENCY SOS Triggered! (User: $userId)",
      "time": "Just now",
      "type": "danger"
    });
    notifyListeners();
  }

  void clearAlerts() {
    _activeAlerts.clear();
    notifyListeners();
  }
}
