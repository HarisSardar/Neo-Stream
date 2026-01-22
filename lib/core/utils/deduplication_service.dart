import 'package:flutter/foundation.dart';
import '../../data/models/movie.dart';
import '../../data/models/series.dart';
import '../../data/models/series_compact.dart';

/// Service de déduplication pour supprimer les doublons dans les listes
class DeduplicationService {
  /// Déduplique une liste de films
  /// 
  /// Critères de détection de doublon:
  /// 1. Même ID (priorité absolue)
  /// 2. Même titre ET même année
  /// 3. Même URL
  static List<Movie> deduplicateMovies(List<Movie> movies, {bool logDuplicates = true}) {
    if (movies.isEmpty) return movies;
    
    final Map<String, Movie> uniqueMovies = {};
    final List<String> duplicates = [];
    int duplicateCount = 0;
    
    for (final movie in movies) {
      // Créer une clé unique basée sur plusieurs critères
      String key;
      
      if (movie.id != null && (movie.id?.isNotEmpty ?? false)) {
        // Priorité 1: ID unique
        key = 'id_${movie.id}';
      } else if (movie.title != null && movie.year != null) {
        // Priorité 2: Titre + Année
        key = 'title_${movie.title}_${movie.year}';
      } else if (movie.url?.isNotEmpty ?? false) {
        // Priorité 3: URL
        key = 'url_${movie.url}';
      } else {
        // Fallback: Titre seul (moins fiable)
        key = 'title_${movie.title}';
      }
      
      if (uniqueMovies.containsKey(key)) {
        // Doublon détecté
        duplicateCount++;
        duplicates.add('${movie.title} (${movie.year ?? "N/A"})');
        
        // Garder celui avec le plus d'informations
        final existing = uniqueMovies[key]!;
        if (_hasMoreInfo(movie, existing)) {
          uniqueMovies[key] = movie;
        }
      } else {
        uniqueMovies[key] = movie;
      }
    }
    
    if (logDuplicates && duplicateCount > 0) {
      debugPrint('🎬 Films: $duplicateCount doublons supprimés');
      debugPrint('🎬 Liste des doublons: ${duplicates.take(10).join(", ")}${duplicates.length > 10 ? "..." : ""}');
      debugPrint('🎬 Films uniques: ${uniqueMovies.length}/${movies.length}');
    }
    
    return uniqueMovies.values.toList();
  }
  
  /// Déduplique une liste de séries
  /// 
  /// IMPORTANT: Pour les séries, plusieurs entrées avec le même titre 
  /// PEUVENT être légitimes si ce sont des saisons différentes
  /// 
  /// Critères de doublon RÉEL:
  /// 1. Même ID + Même saison
  /// 2. Même titre + Même année + Même saison
  /// 3. Même URL (doublon exact)
  static List<Series> deduplicateSeries(List<Series> series, {bool logDuplicates = true}) {
    if (series.isEmpty) return series;
    
    final Map<String, Series> uniqueSeries = {};
    final List<String> duplicates = [];
    int duplicateCount = 0;
    int differentSeasons = 0;
    
    for (final s in series) {
      // Créer une clé unique qui prend en compte les saisons
      String key;
      
      // Récupérer le numéro de saison (peut être null ou vide)
      final seasonInfo = _getSeasonInfo(s);
      
      if (s.id != null && (s.id?.isNotEmpty ?? false)) {
        // ID + Saison (si disponible)
        key = 'id_${s.id}_season_${seasonInfo}';
      } else if (s.title != null && s.year != null) {
        // Titre + Année + Saison
        key = 'title_${s.title}_${s.year}_season_$seasonInfo';
      } else if (s.url?.isNotEmpty ?? false) {
        // URL (doublon exact)
        key = 'url_${s.url}';
      } else {
        // Fallback: Titre + Saison
        key = 'title_${s.title}_season_${seasonInfo}';
      }
      
      if (uniqueSeries.containsKey(key)) {
        // Doublon détecté
        duplicateCount++;
        duplicates.add('${s.title} ${seasonInfo.isNotEmpty ? "(Saison $seasonInfo)" : ""}');
        
        // Garder celui avec le plus d'informations
        final existing = uniqueSeries[key]!;
        if (_hasMoreInfoSeries(s, existing)) {
          uniqueSeries[key] = s;
        }
      } else {
        // Vérifier si c'est une saison différente de la même série
        final similarKey = s.id != null 
            ? 'id_${s.id}_season_'
            : 'title_${s.title}_${s.year}_season_';
        
        final hasDifferentSeason = uniqueSeries.keys.any((k) => k.startsWith(similarKey) && k != key);
        if (hasDifferentSeason) {
          differentSeasons++;
        }
        
        uniqueSeries[key] = s;
      }
    }
    
    if (logDuplicates && (duplicateCount > 0 || differentSeasons > 0)) {
      debugPrint('📺 Séries: $duplicateCount doublons supprimés');
      if (duplicates.isNotEmpty) {
        debugPrint('📺 Liste des doublons: ${duplicates.take(10).join(", ")}${duplicates.length > 10 ? "..." : ""}');
      }
      debugPrint('📺 Saisons différentes détectées: $differentSeasons (normal)');
      debugPrint('📺 Séries uniques: ${uniqueSeries.length}/${series.length}');
    }
    
    return uniqueSeries.values.toList();
  }
  
  /// Déduplique une liste de séries compactes
  static List<SeriesCompact> deduplicateSeriesCompact(List<SeriesCompact> series, {bool logDuplicates = true}) {
    if (series.isEmpty) return series;
    
    final Map<String, SeriesCompact> uniqueSeries = {};
    final List<String> duplicates = [];
    int duplicateCount = 0;
    
    for (final s in series) {
      String key;
      
      if (s.id != null && (s.id?.isNotEmpty ?? false)) {
        key = 'id_${s.id}';
      } else if (s.title != null) {
        key = 'title_${s.title}';
      } else if (s.url.isNotEmpty) {
        key = 'url_${s.url}';
      } else {
        key = 'unknown_${s.hashCode}';
      }
      
      if (uniqueSeries.containsKey(key)) {
        duplicateCount++;
        duplicates.add('${s.title}');
        
        // Garder celui avec le plus d'informations
        final existing = uniqueSeries[key]!;
        if (_hasMoreInfoSeriesCompact(s, existing)) {
          uniqueSeries[key] = s;
        }
      } else {
        uniqueSeries[key] = s;
      }
    }
    
    if (logDuplicates && duplicateCount > 0) {
      debugPrint('📺 Séries compactes: $duplicateCount doublons supprimés');
      debugPrint('📺 Liste des doublons: ${duplicates.take(10).join(", ")}${duplicates.length > 10 ? "..." : ""}');
      debugPrint('📺 Séries uniques: ${uniqueSeries.length}/${series.length}');
    }
    
    return uniqueSeries.values.toList();
  }
  
  /// Récupère l'info de saison d'une série
  static String _getSeasonInfo(Series series) {
    if (series.seasons != null && series.seasons!.isNotEmpty) {
      // Si une seule saison, retourner son numéro
      if (series.seasons!.length == 1) {
        return series.seasons!.first.seasonNumber.toString();
      }
      // Si plusieurs saisons, c'est probablement la série complète
      return 'all';
    }
    
    // Tenter d'extraire du titre (ex: "Série S01")
    final titleLower = series.title?.toLowerCase() ?? '';
    final seasonMatch = RegExp(r's(?:eason)?[\s-]*(\d+)', caseSensitive: false).firstMatch(titleLower);
    if (seasonMatch != null) {
      return seasonMatch.group(1) ?? 'unknown';
    }
    
    return 'unknown';
  }
  
  /// Compare deux films pour déterminer lequel a le plus d'informations
  static bool _hasMoreInfo(Movie a, Movie b) {
    int scoreA = 0;
    int scoreB = 0;
    
    if (a.id != null && a.id!.isNotEmpty) scoreA++;
    if (b.id != null && b.id!.isNotEmpty) scoreB++;
    
    if (a.poster != null && a.poster!.isNotEmpty) scoreA++;
    if (b.poster != null && b.poster!.isNotEmpty) scoreB++;
    
    if (a.synopsis != null && a.synopsis!.isNotEmpty) scoreA++;
    if (b.synopsis != null && b.synopsis!.isNotEmpty) scoreB++;
    
    if (a.watchLinks != null && a.watchLinks!.isNotEmpty) scoreA += 2;
    if (b.watchLinks != null && b.watchLinks!.isNotEmpty) scoreB += 2;
    
    if (a.genres != null && a.genres!.isNotEmpty) scoreA++;
    if (b.genres != null && b.genres!.isNotEmpty) scoreB++;
    
    return scoreA > scoreB;
  }
  
  /// Compare deux séries pour déterminer laquelle a le plus d'informations
  static bool _hasMoreInfoSeries(Series a, Series b) {
    int scoreA = 0;
    int scoreB = 0;
    
    if (a.id != null && a.id!.isNotEmpty) scoreA++;
    if (b.id != null && b.id!.isNotEmpty) scoreB++;
    
    if (a.poster != null && a.poster!.isNotEmpty) scoreA++;
    if (b.poster != null && b.poster!.isNotEmpty) scoreB++;
    
    if (a.synopsis != null && a.synopsis!.isNotEmpty) scoreA++;
    if (b.synopsis != null && b.synopsis!.isNotEmpty) scoreB++;
    
    if (a.seasons != null && a.seasons!.isNotEmpty) scoreA += 3;
    if (b.seasons != null && b.seasons!.isNotEmpty) scoreB += 3;
    
    if (a.watchLinks != null && a.watchLinks!.isNotEmpty) scoreA += 2;
    if (b.watchLinks != null && b.watchLinks!.isNotEmpty) scoreB += 2;
    
    if (a.genres != null && a.genres!.isNotEmpty) scoreA++;
    if (b.genres != null && b.genres!.isNotEmpty) scoreB++;
    
    return scoreA > scoreB;
  }
  
  /// Compare deux séries compactes
  static bool _hasMoreInfoSeriesCompact(SeriesCompact a, SeriesCompact b) {
    int scoreA = 0;
    int scoreB = 0;
    
    if (a.id != null && a.id!.isNotEmpty) scoreA++;
    if (b.id != null && b.id!.isNotEmpty) scoreB++;
    
    if (a.poster != null && a.poster!.isNotEmpty) scoreA++;
    if (b.poster != null && b.poster!.isNotEmpty) scoreB++;
    
    if (a.rating != null) scoreA++;
    if (b.rating != null) scoreB++;
    
    return scoreA > scoreB;
  }
  
  /// Analyse et rapporte les doublons sans les supprimer (mode debug)
  static Map<String, dynamic> analyzeMovieDuplicates(List<Movie> movies) {
    final Map<String, List<Movie>> groups = {};
    
    for (final movie in movies) {
      final key = movie.title ?? 'Unknown';
      groups.putIfAbsent(key, () => []).add(movie);
    }
    
    final duplicateGroups = groups.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => {
              'title': entry.key,
              'count': entry.value.length,
              'movies': entry.value.map((m) => {
                    'id': m.id,
                    'year': m.year,
                    'url': m.url,
                  }).toList(),
            })
        .toList();
    
    return {
      'total': movies.length,
      'unique_titles': groups.length,
      'duplicate_groups': duplicateGroups,
      'duplicate_count': duplicateGroups.fold<int>(0, (sum, group) => sum + (group['count'] as int) - 1),
    };
  }
  
  /// Analyse et rapporte les doublons de séries sans les supprimer (mode debug)
  static Map<String, dynamic> analyzeSeriesDuplicates(List<Series> series) {
    final Map<String, List<Series>> groups = {};
    
    for (final s in series) {
      final key = s.title ?? 'Unknown';
      groups.putIfAbsent(key, () => []).add(s);
    }
    
    final duplicateGroups = groups.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => {
              'title': entry.key,
              'count': entry.value.length,
              'series': entry.value.map((s) => {
                    'id': s.id,
                    'url': s.url,
                    'season_info': _getSeasonInfo(s),
                  }).toList(),
            })
        .toList();
    
    return {
      'total': series.length,
      'unique_titles': groups.length,
      'duplicate_groups': duplicateGroups,
      'duplicate_count': duplicateGroups.fold<int>(0, (sum, group) => sum + (group['count'] as int) - 1),
    };
  }
}
