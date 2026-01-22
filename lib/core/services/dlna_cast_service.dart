import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stub DLNA device class for compatibility when media_cast_dlna is disabled
class DlnaDevice {
  final String friendlyName;
  final String deviceType;
  final DlnaUdn udn;
  final DlnaModelDetails modelDetails;
  
  DlnaDevice({
    required this.friendlyName,
    required this.deviceType,
    required this.udn,
    required this.modelDetails,
  });
}

class DlnaUdn {
  final String value;
  DlnaUdn({required this.value});
}

class DlnaModelDetails {
  final String modelName;
  DlnaModelDetails({required this.modelName});
}

/// Stub service - DLNA désactivé pour compatibilité Freebox Mini v2 (Android 7.1)
/// Le plugin media_cast_dlna nécessite Android 8.0+ (SDK 26)
class DlnaCastService {
  static final DlnaCastService _instance = DlnaCastService._internal();
  factory DlnaCastService() => _instance;
  DlnaCastService._internal();

  List<DlnaDevice> _devices = [];
  DlnaDevice? _connectedDevice;
  bool _isPlaying = false;

  List<DlnaDevice> get devices => _devices;
  DlnaDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  bool get isPlaying => _isPlaying;
  String? get deviceName => _connectedDevice?.friendlyName;

  /// Initialise le service DLNA (stub - ne fait rien)
  Future<void> initialize() async {
    debugPrint('📺 DLNA: Désactivé (incompatible avec Android 7.1)');
  }

  /// Recherche des appareils DLNA (stub - retourne liste vide)
  Future<List<DlnaDevice>> discoverDevices({int timeoutSeconds = 5}) async {
    debugPrint('📺 DLNA: Découverte désactivée (SDK minimum requis: 26)');
    return [];
  }

  /// Arrête la recherche d'appareils (stub)
  Future<void> stopDiscovery() async {}

  /// Se connecte à un appareil DLNA (stub)
  Future<bool> connectToDevice(DlnaDevice device) async {
    return false;
  }

  /// Cast une vidéo (stub)
  Future<bool> castVideo({
    required String videoUrl,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) async {
    debugPrint('📺 DLNA: Cast non disponible sur cette version Android');
    return false;
  }

  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  Future<Duration> getPosition() async => Duration.zero;
  Future<void> setVolume(int volume) async {}
  Future<int> getVolume() async => 0;
  Future<void> disconnect() async {
    _connectedDevice = null;
    _isPlaying = false;
  }
  Future<void> dispose() async {}
}
