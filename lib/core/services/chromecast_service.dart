import 'package:flutter/foundation.dart';

/// Stub service - Chromecast désactivé pour compatibilité Freebox Mini v2 (Android 7.1)
/// Le plugin flutter_chrome_cast nécessite des SDKs plus récents
class ChromecastService {
  static final ChromecastService _instance = ChromecastService._internal();
  factory ChromecastService() => _instance;
  ChromecastService._internal();

  bool _isConnected = false;
  String? _deviceName;

  /// Initialise le service Chromecast (stub)
  Future<void> initialize() async {
    debugPrint('🎬 Chromecast: Désactivé (incompatible avec Android 7.1)');
  }

  /// Vérifie si un appareil est connecté
  bool get isConnected => _isConnected;

  /// Nom de l'appareil connecté
  String? get deviceName => _deviceName;

  /// Cast une vidéo (stub - ne fait rien)
  Future<void> castVideo({
    required String videoUrl,
    required String title,
    String? subtitle,
    String? imageUrl,
    Map<String, String>? headers,
  }) async {
    debugPrint('🎬 Chromecast: Cast non disponible sur cette version Android');
  }

  Future<void> togglePlayPause() async {}
  Future<void> pause() async {}
  Future<void> play() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  Duration getPosition() => Duration.zero;
  Duration? getDuration() => null;
  
  Future<void> disconnect() async {
    _isConnected = false;
    _deviceName = null;
  }

  void dispose() {
    _isConnected = false;
    _deviceName = null;
  }
}
