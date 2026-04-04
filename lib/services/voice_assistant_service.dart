import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:developer';
import 'preferences_service.dart';

class VoiceAssistantService {
  static final VoiceAssistantService _instance =
      VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final PreferencesService _prefs = PreferencesService();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _speech.isListening;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final lang = _prefs.currentLanguage;
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      log('TTS Error: $msg');
    });

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) => log('VoiceAssistant Status: $status'),
        onError: (errorNotification) =>
            log('VoiceAssistant Error: $errorNotification'),
      );
      if (_isInitialized) {
        log("Voice Assistant Service initialized. Language: $lang");
      } else {
        log("Voice Assistant init failed (Microphone denied?).");
      }
    } catch (e) {
      log("Error initializing SpeechToText: $e");
    }
  }

  /// Update TTS language when preference changes
  Future<void> updateLanguage() async {
    final lang = _prefs.currentLanguage;
    await _tts.setLanguage(lang);
    log("VoiceAssistant language updated to: $lang");
  }

  /// Speak translated text using a key from PreferencesService
  Future<void> speakTranslated(String key) async {
    final text = _prefs.translate(key);
    await speak(text);
  }

  /// Speak arbitrary text in the current language
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      log("TTS speak error: $e");
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized) {
      await speak(_prefs.translate('listening'));
      // Delay to let TTS finish before mic turns on
      await Future.delayed(const Duration(milliseconds: 2000));

      // Map our language codes to STT locale IDs
      String localeId = _mapLanguageToLocale(_prefs.currentLanguage);

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            String spokenText = result.recognizedWords;
            log("User said: $spokenText");
            onResult(spokenText);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: localeId,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      await speak(_prefs.translate('mic_denied'));
    }
  }

  String _mapLanguageToLocale(String langCode) {
    // Map our ISO locale codes to speech recognition locale IDs
    final Map<String, String> localeMap = {
      'en-IN': 'en_IN',
      'hi-IN': 'hi_IN',
      'es-ES': 'es_ES',
      'fr-FR': 'fr_FR',
      'de-DE': 'de_DE',
      'ja-JP': 'ja_JP',
      'ar-SA': 'ar_SA',
      'ur-PK': 'ur_PK',
      'bn-IN': 'bn_IN',
      'ta-IN': 'ta_IN',
    };
    return localeMap[langCode] ?? 'en_IN';
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
