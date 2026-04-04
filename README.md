# NavAssist 👁️‍🗨️ AI-Powered Assistive Navigation

NavAssist is a cutting-edge, offline-first Flutter application designed to empower visually impaired and deafblind individuals. It combines real-time Computer Vision, Voice-Controlled Routing, and Caretaker Monitoring into a single, high-performance assistive tool.

---

## 🚀 Key Features (All Working)

### ✅ 1. Dual-Engine AI Vision System
- **Hybrid Intelligence:** Automatically switches between **Offline Edge AI** (TFLite MobileNet) for zero-latency detection in dead zones and **Cloud AI** for high-precision obstacle identification when online.
- **Smart Detection:** Identifies pedestrians, vehicles, bicycles, traffic lights, stairs, doors, furniture, and poles.
- **Vocal Alerts:** Real-time Text-to-Speech (TTS) warnings (e.g., "Caution, car detected ahead").
- **AR Bounding Boxes:** Visual detection overlays on the camera feed.

### ✅ 2. Role-Based Dashboards
- **User Dashboard (HomeScreen):** Main control center with large touch targets, SOS button, and quick navigation.
- **Caretaker Dashboard:** Dedicated view for guardians to monitor user location, battery status, connection stability, and real-time alerts.
- **About Section:** Complete information about AI capabilities, features, and detected objects.

### ✅ 3. High-Precision Navigation
- **Turn-by-Turn Guidance:** Hands-free voice instructions using STT/TTS.
- **Dynamic ETA:** Real-time calculation of distance and time remaining based on walking speed.
- **Premium Satellite HUD:** High-contrast neon/dark UI with high-zoom satellite hybrid mapping.
- **GPS Fallback:** Gracefully falls back to MIET Meerut coordinates (28.9734, 77.6836) when GPS is restricted on web.

### ✅ 4. SOS Emergency System
- **Instant Alert Sync:** When user long-presses the SOS button, alert immediately appears on caretaker dashboard.
- **User ID Tracking:** Each alert includes unique user identifier (e.g., User-A1B2).
- **Clear Alerts:** Caretaker can clear alerts after handling them.

### ✅ 5. Multi-Language Support
- **Voice Language Selection:** Dropdown in Settings to choose TTS language (English, Hindi, Spanish, French, German, Japanese).
- **Translation Dictionary:** Core phrases stored for each language (expandable).

### ✅ 6. Hardware Integration (Settings)
- **Bluetooth Scanning:** flutter_blue_plus integration to scan for ESP32 devices.
- **Device Pairing UI:** Ready-to-use connect buttons for wearables.

### ✅ 7. Voice Assistant
- **Speech-to-Text:** Hands-free destination search using `speech_to_text` package.
- **Microphone Permissions:** Handles Android/Web permissions gracefully.

---

## 🛠️ Technical Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter (Android/iOS/Web) |
| AI Models | TensorFlow Lite (MobileNet v2), Cloud Vision API |
| Maps | flutter_map + OSRM + Google Satellite Hybrid |
| State Management | Provider, ChangeNotifier |
| Voice | flutter_tts, speech_to_text |
| Hardware | flutter_blue_plus (ESP32/BLE) |
| Routing | OSRM (Open Source Routing Machine) |

---

## 📱 How to Run

### Web (Simulation Mode)
```bash
flutter run -d web-server --web-port 8080 --web-hostname localhost
```
Access at: **http://localhost:8080**

*Note: On web, GPS may fallback to Meerut. Camera simulation runs if no camera is available.*

### Android (Full Real AI Mode)
```bash
flutter build apk --release
```
Then install the APK on an Android device to use:
- Real TFLite inference on camera
- Actual GPS tracking
- Full BLE scanning

---

## 🔗 MCP + Supabase Integration (For Developers)

To connect OpenCode with your Supabase via MCP:

1. **Set Environment Variables:**
   ```bash
   export SUPABASE_URL='https://your-project.supabase.co'
   export SUPABASE_SERVICE_ROLE_KEY='your_service_role_key'
   ```

2. **Start MCP Server:**
   ```bash
   npx @modelcontextprotocol/server-supabase
   ```

3. **OpenCode Context:** The AI will now have database access to create tables (alerts, user_location, etc.) and sync real-time data.

---

## 🎨 UI Aesthetic

- **Theme:** Premium Dark/Neon
- **Primary Colors:** Cyan Cyber (#00F0FF), Vivid Purple (#BD00FF)
- **Danger:** Neon Pink-Red (#FF0055)
- **Safe:** Matrix Green (#00FF73)

---

## 📂 Project Structure

```
lib/
├── main.dart                    # Entry point
├── screens/
│   ├── role_selection_screen.dart    # User/Caretaker choice
│   ├── home_screen.dart              # User dashboard
│   ├── caretaker_dashboard_screen.dart # Guardian view
│   ├── map_screen.dart               # Navigation + AI Vision
│   ├── vision_screen.dart            # Live camera + AI detection
│   ├── settings_screen.dart          # Bluetooth + Language settings
│   └── about_screen.dart              # Feature info
├── services/
│   ├── vision_ai_service.dart   # Cloud/Offline AI switch
│   ├── voice_assistant_service.dart # STT/TTS
│   ├── alert_service.dart       # SOS syncing
│   └── preferences_service.dart # Language settings
├── widgets/
│   ├── brand_logo.dart
│   ├── sensor_radar.dart
│   ├── status_badge.dart
│   └── sos_button.dart
└── theme/
    └── app_theme.dart
```

---

## 🗺️ Current Roadmap

| Feature | Status |
|---------|--------|
| Hybrid Cloud/Offline AI Vision | ✅ Complete |
| Role-Based Dashboards | ✅ Complete |
| Multi-Language TTS | ✅ Complete |
| Dynamic Navigation ETA | ✅ Complete |
| SOS Alert Sync (CareTaker) | ✅ Complete |
| Bluetooth ESP32 Scan | ✅ Complete |
| Voice Assistant (STT) | ✅ Complete |
| Offline Map Tile Caching | 🔜 Planned |
| Real Haptic Feedback Patterns | 🔜 Planned |

---

## 📄 License

This project is for demonstration and educational purposes.
