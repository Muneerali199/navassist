import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends ChangeNotifier {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  String _currentLanguage = "en-IN";
  bool _onboardingComplete = false;
  bool _voiceAutoStart = false;
  bool _highContrast = true;

  final Map<String, String> availableLanguages = {
    "en-IN": "English",
    "hi-IN": "हिन्दी (Hindi)",
    "es-ES": "Español (Spanish)",
    "fr-FR": "Français (French)",
    "de-DE": "Deutsch (German)",
    "ja-JP": "日本語 (Japanese)",
    "ar-SA": "العربية (Arabic)",
    "ur-PK": "اردو (Urdu)",
    "bn-IN": "বাংলা (Bengali)",
    "ta-IN": "தமிழ் (Tamil)",
  };

  String get currentLanguage => _currentLanguage;
  bool get onboardingComplete => _onboardingComplete;
  bool get voiceAutoStart => _voiceAutoStart;
  bool get highContrast => _highContrast;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? "en-IN";
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    _voiceAutoStart = prefs.getBool('voice_auto_start') ?? false;
    _highContrast = prefs.getBool('high_contrast') ?? true;
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (availableLanguages.containsKey(langCode)) {
      _currentLanguage = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', langCode);
      notifyListeners();
    }
  }

  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', value);
    notifyListeners();
  }

  Future<void> setVoiceAutoStart(bool value) async {
    _voiceAutoStart = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_auto_start', value);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', value);
    notifyListeners();
  }

  String translate(String key) {
    final translations = {
      "en-IN": {
        "nav_active": "NavAssist Active. Tracking your location.",
        "vision_start": "Starting AI Vision Mode.",
        "obstacle": "Caution. Object detected ahead.",
        "route_found": "Route found. Follow the highlighted path.",
        "dest_not_found": "Destination not found. Please try again.",
        "network_error": "Network error. Switching to offline mode.",
        "turn_left": "Turn left",
        "turn_right": "Turn right",
        "continue_straight": "Continue straight",
        "slight_left": "Keep slightly left",
        "slight_right": "Keep slightly right",
        "u_turn": "Make a U-turn",
        "arrived": "You have arrived at your destination.",
        "in_meters": "in %d meters",
        "recalculating": "Recalculating route.",
        "gps_weak": "GPS signal weak. Using approximate location.",
        "listening": "Listening. Say your destination.",
        "mic_denied": "Microphone permission denied.",
        "danger_stop": "Danger. Immediate obstacle. Stop now.",
        "obstacle_meters": "Obstacle %d meters ahead.",
        "route_cancelled": "Route cancelled. Resuming free navigation.",
        "distance_km": "Distance is %s kilometers.",
        "distance_m": "Distance is %d meters.",
        "eta_min": "Estimated arrival in %d minutes.",
        "eta_sec": "Estimated arrival in %d seconds.",
        "searching": "Searching for %s.",
        "routing_to": "Routing to %s.",
        "offline_mode": "Offline mode active. Using local AI.",
        "camera_unavailable": "Camera not available. Running AI simulation.",
      },
      "hi-IN": {
        "nav_active": "नैव असिस्ट सक्रिय है। आपका स्थान ट्रैक हो रहा है।",
        "vision_start": "AI विजन मोड शुरू हो रहा है।",
        "obstacle": "सावधान। आगे बाधा है।",
        "route_found": "रास्ता मिल गया है। हाइलाइट किए गए पथ का पालन करें।",
        "dest_not_found": "मंजिल नहीं मिली। कृपया दोबारा कोशिश करें।",
        "network_error": "नेटवर्क त्रुटि। ऑफलाइन मोड पर स्विच हो रहा है।",
        "turn_left": "बाएं मुड़ें",
        "turn_right": "दाएं मुड़ें",
        "continue_straight": "सीधे चलते रहें",
        "slight_left": "थोड़ा बाएं रहें",
        "slight_right": "थोड़ा दाएं रहें",
        "u_turn": "यू-टर्न लें",
        "arrived": "आप अपनी मंजिल पर पहुंच गए हैं।",
        "in_meters": "%d मीटर में",
        "recalculating": "रास्ता पुनः गणना हो रहा है।",
        "gps_weak": "GPS सिग्नल कमजोर है। अनुमानित स्थान का उपयोग हो रहा है।",
        "listening": "सुन रहा हूं। अपनी मंजिल बताएं।",
        "mic_denied": "माइक्रोफोन अनुमति अस्वीकृत।",
        "danger_stop": "खतरा। तुरंत बाधा। अभी रुकें।",
        "obstacle_meters": "बाधा %d मीटर आगे।",
        "route_cancelled": "रास्ता रद्द। मुक्त नेविगेशन फिर से शुरू।",
        "distance_km": "दूरी %s किलोमीटर है।",
        "distance_m": "दूरी %d मीटर है।",
        "eta_min": "अनुमानित आगमन %d मिनट में।",
        "eta_sec": "अनुमानित आगमन %d सेकंड में।",
        "searching": "%s खोज रहा है।",
        "routing_to": "%s तक रास्ता बना रहा है।",
        "offline_mode": "ऑफलाइन मोड सक्रिय। स्थानीय AI का उपयोग।",
        "camera_unavailable": "कैमरा उपलब्ध नहीं है। AI सिमुलेशन चल रहा है।",
      },
      "es-ES": {
        "nav_active": "NavAssist activo. Rastreando su ubicación.",
        "vision_start": "Iniciando modo de visión con IA.",
        "obstacle": "Precaución. Objeto detectado adelante.",
        "route_found": "Ruta encontrada. Siga el camino resaltado.",
        "dest_not_found": "Destino no encontrado. Inténtelo de nuevo.",
        "network_error": "Error de red. Cambiando a modo sin conexión.",
        "turn_left": "Gire a la izquierda",
        "turn_right": "Gire a la derecha",
        "continue_straight": "Continúe recto",
        "slight_left": "Manténgase ligeramente a la izquierda",
        "slight_right": "Manténgase ligeramente a la derecha",
        "u_turn": "Haga un cambio de sentido",
        "arrived": "Ha llegado a su destino.",
        "in_meters": "en %d metros",
        "recalculating": "Recalculando ruta.",
        "gps_weak": "Señal GPS débil. Usando ubicación aproximada.",
        "listening": "Escuchando. Diga su destino.",
        "mic_denied": "Permiso de micrófono denegado.",
        "danger_stop": "Peligro. Obstáculo inmediato. Deténgase ahora.",
        "obstacle_meters": "Obstáculo a %d metros adelante.",
        "route_cancelled": "Ruta cancelada. Reanudando navegación libre.",
        "distance_km": "La distancia es de %s kilómetros.",
        "distance_m": "La distancia es de %d metros.",
        "eta_min": "Llegada estimada en %d minutos.",
        "eta_sec": "Llegada estimada en %d segundos.",
        "searching": "Buscando %s.",
        "routing_to": "Trazando ruta a %s.",
        "offline_mode": "Modo sin conexión activo. Usando IA local.",
        "camera_unavailable": "Cámara no disponible. Ejecutando simulación de IA.",
      },
      "fr-FR": {
        "nav_active": "NavAssist actif. Suivi de votre position.",
        "vision_start": "Démarrage du mode Vision IA.",
        "obstacle": "Attention. Objet détecté devant.",
        "route_found": "Itinéraire trouvé. Suivez le chemin en surbrillance.",
        "dest_not_found": "Destination introuvable. Veuillez réessayer.",
        "network_error": "Erreur réseau. Passage en mode hors ligne.",
        "turn_left": "Tournez à gauche",
        "turn_right": "Tournez à droite",
        "continue_straight": "Continuez tout droit",
        "slight_left": "Restez légèrement à gauche",
        "slight_right": "Restez légèrement à droite",
        "u_turn": "Faites demi-tour",
        "arrived": "Vous êtes arrivé à destination.",
        "in_meters": "dans %d mètres",
        "recalculating": "Recalcul de l'itinéraire.",
        "gps_weak": "Signal GPS faible. Position approximative utilisée.",
        "listening": "Écoute en cours. Dites votre destination.",
        "mic_denied": "Permission microphone refusée.",
        "danger_stop": "Danger. Obstacle immédiat. Arrêtez-vous maintenant.",
        "obstacle_meters": "Obstacle à %d mètres devant.",
        "route_cancelled": "Itinéraire annulé. Navigation libre reprise.",
        "distance_km": "Distance de %s kilomètres.",
        "distance_m": "Distance de %d mètres.",
        "eta_min": "Arrivée estimée dans %d minutes.",
        "eta_sec": "Arrivée estimée dans %d secondes.",
        "searching": "Recherche de %s.",
        "routing_to": "Calcul de l'itinéraire vers %s.",
        "offline_mode": "Mode hors ligne actif. IA locale utilisée.",
        "camera_unavailable": "Caméra non disponible. Simulation IA en cours.",
      },
      "de-DE": {
        "nav_active": "NavAssist aktiv. Standort wird verfolgt.",
        "vision_start": "KI-Sichtmodus wird gestartet.",
        "obstacle": "Vorsicht. Objekt voraus erkannt.",
        "route_found": "Route gefunden. Folgen Sie dem markierten Weg.",
        "dest_not_found": "Ziel nicht gefunden. Bitte versuchen Sie es erneut.",
        "network_error": "Netzwerkfehler. Wechsel in den Offline-Modus.",
        "turn_left": "Links abbiegen",
        "turn_right": "Rechts abbiegen",
        "continue_straight": "Geradeaus weiter",
        "slight_left": "Leicht links halten",
        "slight_right": "Leicht rechts halten",
        "u_turn": "Wenden Sie",
        "arrived": "Sie haben Ihr Ziel erreicht.",
        "in_meters": "in %d Metern",
        "recalculating": "Route wird neu berechnet.",
        "gps_weak": "GPS-Signal schwach. Ungefährer Standort wird verwendet.",
        "listening": "Hören zu. Sagen Sie Ihr Ziel.",
        "mic_denied": "Mikrofonberechtigung verweigert.",
        "danger_stop": "Gefahr. Sofortiges Hindernis. Jetzt anhalten.",
        "obstacle_meters": "Hindernis in %d Metern voraus.",
        "route_cancelled": "Route abgebrochen. Freie Navigation fortgesetzt.",
        "distance_km": "Entfernung beträgt %s Kilometer.",
        "distance_m": "Entfernung beträgt %d Meter.",
        "eta_min": "Geschätzte Ankunft in %d Minuten.",
        "eta_sec": "Geschätzte Ankunft in %d Sekunden.",
        "searching": "Suche nach %s.",
        "routing_to": "Route zu %s wird berechnet.",
        "offline_mode": "Offline-Modus aktiv. Lokale KI wird verwendet.",
        "camera_unavailable": "Kamera nicht verfügbar. KI-Simulation läuft.",
      },
      "ja-JP": {
        "nav_active": "ナビアシスト起動中。位置を追跡しています。",
        "vision_start": "AIビジョンモードを開始します。",
        "obstacle": "注意。前方に障害物を検出しました。",
        "route_found": "ルートが見つかりました。ハイライトされた経路に従ってください。",
        "dest_not_found": "目的地が見つかりません。もう一度お試しください。",
        "network_error": "ネットワークエラー。オフラインモードに切り替えます。",
        "turn_left": "左に曲がってください",
        "turn_right": "右に曲がってください",
        "continue_straight": "直進してください",
        "slight_left": "少し左に寄ってください",
        "slight_right": "少し右に寄ってください",
        "u_turn": "Uターンしてください",
        "arrived": "目的地に到着しました。",
        "in_meters": "%dメートル先",
        "recalculating": "ルートを再計算中。",
        "gps_weak": "GPS信号が弱いです。おおよその位置を使用します。",
        "listening": "聞いています。行き先を言ってください。",
        "mic_denied": "マイクの許可が拒否されました。",
        "danger_stop": "危険。直近の障害物。今すぐ止まってください。",
        "obstacle_meters": "障害物が%dメートル先にあります。",
        "route_cancelled": "ルートをキャンセルしました。自由ナビゲーションに戻ります。",
        "distance_km": "距離は%sキロメートルです。",
        "distance_m": "距離は%dメートルです。",
        "eta_min": "到着予定は%d分後です。",
        "eta_sec": "到着予定は%d秒後です。",
        "searching": "%sを検索中。",
        "routing_to": "%sまでのルートを計算中。",
        "offline_mode": "オフラインモード起動。ローカルAIを使用。",
        "camera_unavailable": "カメラが利用できません。AIシミュレーションを実行中。",
      },
      "ar-SA": {
        "nav_active": "ناف أسيست نشط. تتبع موقعك.",
        "vision_start": "بدء وضع الرؤية بالذكاء الاصطناعي.",
        "obstacle": "تنبيه. تم اكتشاف عائق أمامك.",
        "route_found": "تم العثور على المسار. اتبع المسار المحدد.",
        "dest_not_found": "لم يتم العثور على الوجهة. حاول مرة أخرى.",
        "network_error": "خطأ في الشبكة. التبديل إلى وضع عدم الاتصال.",
        "turn_left": "انعطف يساراً",
        "turn_right": "انعطف يميناً",
        "continue_straight": "استمر بالسير مباشرة",
        "arrived": "لقد وصلت إلى وجهتك.",
        "in_meters": "خلال %d متر",
        "recalculating": "إعادة حساب المسار.",
        "listening": "أستمع. قل وجهتك.",
        "danger_stop": "خطر. عائق فوري. توقف الآن.",
        "obstacle_meters": "عائق على بعد %d متر.",
        "route_cancelled": "تم إلغاء المسار.",
        "searching": "جاري البحث عن %s.",
        "routing_to": "حساب المسار إلى %s.",
      },
      "ur-PK": {
        "nav_active": "نیو اسسٹ فعال ہے۔ آپ کا مقام ٹریک ہو رہا ہے۔",
        "vision_start": "AI ویژن موڈ شروع ہو رہا ہے۔",
        "obstacle": "ہوشیار! آگے رکاوٹ ہے۔",
        "route_found": "راستہ مل گیا۔ نشان زد راستے پر چلیں۔",
        "dest_not_found": "منزل نہیں ملی۔ دوبارہ کوشش کریں۔",
        "network_error": "نیٹ ورک خرابی۔ آف لائن موڈ پر سوئچ ہو رہا ہے۔",
        "turn_left": "بائیں مڑیں",
        "turn_right": "دائیں مڑیں",
        "continue_straight": "سیدھے چلتے رہیں",
        "arrived": "آپ اپنی منزل پر پہنچ گئے ہیں۔",
        "in_meters": "%d میٹر میں",
        "recalculating": "راستہ دوبارہ حساب ہو رہا ہے۔",
        "listening": "سن رہا ہوں۔ اپنی منزل بتائیں۔",
        "danger_stop": "خطرہ! فوری رکاوٹ۔ ابھی رکیں!",
        "obstacle_meters": "رکاوٹ %d میٹر آگے۔",
        "route_cancelled": "راستہ منسوخ۔",
        "searching": "%s تلاش کر رہا ہے۔",
        "routing_to": "%s تک راستہ بنا رہا ہے۔",
      },
      "bn-IN": {
        "nav_active": "ন্যাভ অ্যাসিস্ট সক্রিয়। আপনার অবস্থান ট্র্যাক হচ্ছে।",
        "vision_start": "AI ভিশন মোড শুরু হচ্ছে।",
        "obstacle": "সাবধান! সামনে বাধা সনাক্ত হয়েছে।",
        "route_found": "পথ পাওয়া গেছে। হাইলাইট করা পথ অনুসরণ করুন।",
        "dest_not_found": "গন্তব্য পাওয়া যায়নি। আবার চেষ্টা করুন।",
        "network_error": "নেটওয়ার্ক ত্রুটি। অফলাইন মোডে যাচ্ছে।",
        "turn_left": "বাঁদিকে মোড় নিন",
        "turn_right": "ডানদিকে মোড় নিন",
        "continue_straight": "সোজা এগিয়ে যান",
        "arrived": "আপনি আপনার গন্তব্যে পৌঁছেছেন।",
        "in_meters": "%d মিটারের মধ্যে",
        "recalculating": "পথ পুনরায় গণনা হচ্ছে।",
        "listening": "শুনছি। আপনার গন্তব্য বলুন।",
        "danger_stop": "বিপদ! তাৎক্ষণিক বাধা। এখনই থামুন!",
        "obstacle_meters": "%d মিটার সামনে বাধা।",
        "route_cancelled": "পথ বাতিল।",
        "searching": "%s খোঁজা হচ্ছে।",
        "routing_to": "%s পর্যন্ত পথ তৈরি হচ্ছে।",
      },
      "ta-IN": {
        "nav_active": "நேவ் அசிஸ்ட் செயலில் உள்ளது. உங்கள் இருப்பிடம் கண்காணிக்கப்படுகிறது.",
        "vision_start": "AI விஷன் பயன்முறை தொடங்குகிறது.",
        "obstacle": "எச்சரிக்கை! முன்னால் தடை கண்டறியப்பட்டது.",
        "route_found": "வழி கண்டுபிடிக்கப்பட்டது. சிறப்பிக்கப்பட்ட பாதையைப் பின்பற்றுங்கள்.",
        "dest_not_found": "இலக்கு கிடைக்கவில்லை. மீண்டும் முயற்சிக்கவும்.",
        "network_error": "நெட்வொர்க் பிழை. ஆஃப்லைன் பயன்முறைக்கு மாறுகிறது.",
        "turn_left": "இடது பக்கம் திரும்பவும்",
        "turn_right": "வலது பக்கம் திரும்பவும்",
        "continue_straight": "நேராகச் செல்லுங்கள்",
        "arrived": "நீங்கள் உங்கள் இலக்கை அடைந்துவிட்டீர்கள்.",
        "in_meters": "%d மீட்டரில்",
        "recalculating": "வழி மீண்டும் கணக்கிடப்படுகிறது.",
        "listening": "கேட்கிறேன். உங்கள் இலக்கைச் சொல்லுங்கள்.",
        "danger_stop": "ஆபத்து! உடனடி தடை. இப்போதே நிறுத்துங்கள்!",
        "obstacle_meters": "%d மீட்டர் முன்னால் தடை.",
        "route_cancelled": "வழி ரத்து செய்யப்பட்டது.",
        "searching": "%s தேடுகிறது.",
        "routing_to": "%s க்கு வழி கணக்கிடப்படுகிறது.",
      },
    };

    return translations[_currentLanguage]?[key] ??
        translations["en-IN"]?[key] ??
        key;
  }

  /// Format a translation with a single string argument
  String translateWith(String key, String arg) {
    return translate(key).replaceAll('%s', arg);
  }

  /// Format a translation with a single integer argument
  String translateWithInt(String key, int arg) {
    return translate(key).replaceAll('%d', arg.toString());
  }
}
