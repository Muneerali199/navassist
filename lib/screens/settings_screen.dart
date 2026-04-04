import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../theme/app_theme.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
        });
      }
    });
  }

  void _startScan() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        // Bluetooth not supported
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bluetooth not supported by this device')),
          );
        }
        return;
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint("Scan Error: $e");
    }
  }

  void _stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.backgroundBlack,
      ),
      backgroundColor: AppTheme.backgroundBlack,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Localization
          _buildSectionHeader('Localization / Voice Settings'),
          const SizedBox(height: 10),
          Card(
            color: AppTheme.glassPanel,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Voice Language",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  DropdownButton<String>(
                    dropdownColor: AppTheme.surfaceDark,
                    value: PreferencesService().currentLanguage,
                    items: PreferencesService()
                        .availableLanguages
                        .entries
                        .map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value,
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          PreferencesService().setLanguage(newValue);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Language updated to ${PreferencesService().availableLanguages[newValue]}')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Hardware Connection Section
          _buildSectionHeader('Hardware Connection (ESP32)'),
          const SizedBox(height: 10),
          Card(
            color: AppTheme.glassPanel,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Connect NavAssist to an external hardware device (like an ESP32 micro-controller) via Bluetooth to receive sensor data or trigger haptic feedback.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.bluetooth_searching),
                      label: Text(_isScanning
                          ? "Scanning..."
                          : "Scan for ESP32 / Bluetooth Devices"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isScanning ? _stopScan : _startScan,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_scanResults.isNotEmpty)
                    const Text("Devices Found:",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._scanResults.map((r) => _buildDeviceTile(r)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
          // Additional Settings could go here
          _buildSectionHeader('App Preferences'),
          const SizedBox(height: 10),
          Card(
            color: AppTheme.glassPanel,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Voice Assistant Auto-Start",
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      "Automatically start listening on map load",
                      style: TextStyle(color: Colors.white54)),
                  value: false,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (bool value) {},
                ),
                SwitchListTile(
                  title: const Text("High Contrast Mode",
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text("Enhance UI elements for low vision",
                      style: TextStyle(color: Colors.white54)),
                  value: true,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (bool value) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryBlue,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDeviceTile(ScanResult result) {
    return ListTile(
      leading: const Icon(Icons.bluetooth, color: AppTheme.primaryBlue),
      title: Text(
          result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Unknown Device",
          style: const TextStyle(color: Colors.white)),
      subtitle: Text(result.device.remoteId.toString(),
          style: const TextStyle(color: Colors.white54)),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentPurple,
          foregroundColor: Colors.white,
        ),
        child: const Text("Connect"),
        onPressed: () {
          // Implement connection logic here
          // result.device.connect();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Attempting to connect to ${result.device.platformName}')),
          );
        },
      ),
    );
  }
}
