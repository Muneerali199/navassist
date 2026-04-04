import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import '../services/vision_ai_service.dart';
import '../theme/app_theme.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  CameraController? _cameraController;
  final VisionAIService _visionAIService = VisionAIService();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  List<Map<String, dynamic>> _detections = [];
  DateTime _lastVoiceTime =
      DateTime.now().subtract(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    _initTTS();
    _initVision();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak("Starting AI Vision Mode.");
  }

  Future<void> _initVision() async {
    await _visionAIService.initialize();

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
        });

        _cameraController!.startImageStream((CameraImage image) {
          if (!_isProcessing) {
            _processFrame(image);
          }
        });
      } else {
        _handleNoCamera();
      }
    } catch (e) {
      debugPrint("Camera error: $e");
      _handleNoCamera();
    }
  }

  void _handleNoCamera() {
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
      _flutterTts.speak("Camera not available. Running AI simulation.");
      _startSimulationLoop();
    }
  }

  void _startSimulationLoop() {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      // Simulate fake detections since camera failed (e.g. on web)
      final fakeDetections = await _visionAIService.runInference(null);

      setState(() {
        _detections = fakeDetections;
        _isProcessing = false;
      });

      _announceDetections(fakeDetections);
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    _isProcessing = true;
    try {
      final results = await _visionAIService.runInference(image);
      if (mounted) {
        setState(() {
          _detections = results;
        });
        _announceDetections(results);
      }
    } catch (e) {
      debugPrint("Inference Error: $e");
    } finally {
      if (mounted) {
        _isProcessing = false;
      }
    }
  }

  void _announceDetections(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return;

    // Only speak every 4 seconds to avoid spamming the user
    if (DateTime.now().difference(_lastVoiceTime).inSeconds > 4) {
      final topResult = results.first;
      String label = topResult['label'];

      _flutterTts.speak("Caution. $label detected ahead.");
      _lastVoiceTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("AI Vision System"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.white54, size: 60),
                  SizedBox(height: 20),
                  Text("Camera Unavailable / Simulating Sensor",
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),

          // AR Bounding Boxes Overlay
          if (_detections.isNotEmpty)
            ..._detections.map((d) {
              // Simulated bounds if real bounds are [0.2, 0.3, 0.8, 0.7]
              final box = d['box'] as List<double>;
              return Positioned(
                top: MediaQuery.of(context).size.height * box[0],
                left: MediaQuery.of(context).size.width * box[1],
                bottom: MediaQuery.of(context).size.height * (1 - box[2]),
                right: MediaQuery.of(context).size.width * (1 - box[3]),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.dangerRed, width: 3),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.dangerRed.withValues(alpha: 0.2),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      color: AppTheme.dangerRed,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text(
                        "${d['label']} ${(d['confidence'] * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

          // HUD Scan Line
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.4, 0.5, 0.6],
                  ),
                ),
              ),
            ),
          ),

          // Status Box
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.glassPanel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _visionAIService.isUsingCloud
                        ? Colors.purpleAccent
                        : AppTheme.primaryBlue.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _visionAIService.isUsingCloud
                            ? Icons.cloud_done
                            : Icons.wifi_off,
                        color: _visionAIService.isUsingCloud
                            ? Colors.purpleAccent
                            : AppTheme.primaryBlue,
                        size: 28,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        _visionAIService.isUsingCloud
                            ? "Cloud AI Active"
                            : "Offline Edge AI Active",
                        style: TextStyle(
                          color: _visionAIService.isUsingCloud
                              ? Colors.purpleAccent
                              : AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          _detections.isNotEmpty
                              ? "Object detected: ${_detections.first['label']}"
                              : "Scanning environment...",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
