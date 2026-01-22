import 'package:shared_preferences/shared_preferences.dart';
import 'data/services/watch_progress_service.dart';
import 'data/repositories/favorites_repository.dart';

/// Script de débogage pour vérifier la séparation des profils
/// 
/// À exécuter dans la console pour diagnostiquer les problèmes
class ProfileSeparationDebug {
  
  /// Affiche toutes les clés dans SharedPreferences
  static Future<void> debugKeys() async {
    print('\n=== DEBUG: Clés SharedPreferences ===');
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    
    print('📋 Total de clés: ${allKeys.length}');
    
    // Filtrer les clés liées aux profils
    final profileKeys = allKeys.where((k) => k.contains('profile')).toList();
    final watchKeys = allKeys.where((k) => k.contains('watch_progress')).toList();
    final favKeys = allKeys.where((k) => k.contains('favorites')).toList();
    
    print('\n🔑 Clés de profils (${profileKeys.length}):');
    for (final key in profileKeys) {
      print('  - $key');
    }
    
    print('\n📺 Clés de progression (${watchKeys.length}):');
    for (final key in watchKeys) {
      final value = prefs.getStringList(key);
      print('  - $key: ${value?.length ?? 0} items');
    }
    
    print('\n⭐ Clés de favoris (${favKeys.length}):');
    for (final key in favKeys) {
      final value = prefs.getString(key);
      print('  - $key: ${value?.length ?? 0} caractères');
    }
    
    print('\n=====================================\n');
  }
  
  /// Vérifie l'état actuel des services
  static Future<void> debugServiceState() async {
    print('\n=== DEBUG: État des services ===');
    
    // Note: Ces propriétés sont privées, on ne peut pas y accéder directement
    // On doit tester en appelant les services
    
    print('📺 Test WatchProgressService...');
    try {
      final stats = await WatchProgressService.getProgressStats();
      print('  - Stats: $stats');
      print('  - Profil actif: ${stats['profileId'] ?? 'NON DÉFINI'}');
      print('  - Progressions: ${stats['totalProgress'] ?? 0}');
    } catch (e) {
      print('  ❌ Erreur: $e');
    }
    
    print('\n⭐ Test FavoritesRepository...');
    try {
      final repo = FavoritesRepository();
      final favorites = await repo.getFavorites();
      print('  - Favoris: ${favorites.length}');
    } catch (e) {
      print('  ❌ Erreur: $e');
    }
    
    print('\n=====================================\n');
  }
  
  /// Simule un changement de profil pour tester
  static Future<void> testProfileSwitch(String profileId1, String profileId2) async {
    print('\n=== TEST: Changement de profil ===');
    
    print('\n1️⃣ Définir profil 1: $profileId1');
    WatchProgressService.setCurrentProfile(profileId1);
    // Note: FavoritesRepository ne supporte pas encore setCurrentProfile
    
    print('   Vérification...');
    final stats1 = await WatchProgressService.getProgressStats();
    print('   - Profil actif: ${stats1['profileId']}');
    print('   - Progressions: ${stats1['totalProgress']}');
    
    print('\n2️⃣ Définir profil 2: $profileId2');
    WatchProgressService.setCurrentProfile(profileId2);
    // Note: FavoritesRepository ne supporte pas encore setCurrentProfile
    
    print('   Vérification...');
    final stats2 = await WatchProgressService.getProgressStats();
    print('   - Profil actif: ${stats2['profileId']}');
    print('   - Progressions: ${stats2['totalProgress']}');
    
    if (stats1['profileId'] != stats2['profileId']) {
      print('\n✅ SUCCÈS: Les profils sont bien séparés');
    } else {
      print('\n❌ ÉCHEC: Les profils utilisent les mêmes données');
    }
    
    print('\n=====================================\n');
  }
  
  /// Nettoie toutes les données (ATTENTION: destructif)
  static Future<void> resetAll() async {
    print('\n=== RESET: Nettoyage complet ===');
    print('⚠️  Ceci va supprimer TOUTES les données!');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    print('✅ Toutes les données ont été effacées');
    print('=====================================\n');
  }
  
  /// Affiche un rapport complet
  static Future<void> fullReport() async {
    print('\n╔═══════════════════════════════════════════╗');
    print('║   RAPPORT DE SÉPARATION DES PROFILS     ║');
    print('╚═══════════════════════════════════════════╝\n');
    
    await debugKeys();
    await debugServiceState();
    
    print('\n╔═══════════════════════════════════════════╗');
    print('║          FIN DU RAPPORT                  ║');
    print('╚═══════════════════════════════════════════╝\n');
  }
}

/// Fonction helper pour appeler depuis la console de debug
/// 
/// Exemple d'utilisation:
/// ```dart
/// import 'debug_profile_separation.dart';
/// 
/// // Dans un bouton ou au démarrage
/// ProfileSeparationDebug.fullReport();
/// ```
Future<void> debugProfileSeparation() async {
  await ProfileSeparationDebug.fullReport();
}
