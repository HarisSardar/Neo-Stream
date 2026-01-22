import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/settings/settings_provider.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/account_switcher_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/watch_progress_service.dart';
import '../../../data/services/platform_service.dart';
import '../../../core/services/file_sharing_service.dart';
import './about_easter_egg_screen.dart';

class EnhancedSettingsScreen extends ConsumerStatefulWidget {
  const EnhancedSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends ConsumerState<EnhancedSettingsScreen> {
  int _imageCacheSize = 0;
  int _totalCacheSize = 0;
  int _progressCount = 0;
  bool _loadingStats = true;
  
  // TV Navigation
  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _settingsFocusNodes = [];
  int _currentFocusIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider).loadSettings();
      _loadCacheStats();
    });
    
    // Créer les focus nodes pour les paramètres TV
    for (int i = 0; i < 15; i++) {
      final node = FocusNode(debugLabel: 'setting_$i');
      node.addListener(() => _onSettingFocusChanged(i, node));
      _settingsFocusNodes.add(node);
    }
  }

  void _onSettingFocusChanged(int index, FocusNode node) {
    if (node.hasFocus && mounted) {
      setState(() => _currentFocusIndex = index);
      _scrollToFocusedSetting(index);
      HapticFeedback.selectionClick();
    }
  }

  void _scrollToFocusedSetting(int index) {
    if (!_scrollController.hasClients) return;
    
    final targetOffset = index * 70.0;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentOffset = _scrollController.offset;
    final maxOffset = _scrollController.position.maxScrollExtent;
    
    final idealOffset = (targetOffset - viewportHeight / 3).clamp(0.0, maxOffset);
    
    if ((idealOffset - currentOffset).abs() > 50) {
      _scrollController.animateTo(
        idealOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final node in _settingsFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCacheStats() async {
    setState(() => _loadingStats = true);
    
    try {
      // Calculer la taille du cache d'images
      final tempDir = await getTemporaryDirectory();
      _imageCacheSize = await _calculateDirectorySize(tempDir);
      
      // Calculer le nombre de progressions
      final prefs = await SharedPreferences.getInstance();
      final progressKeys = prefs.getKeys().where((key) => key.contains('watch_progress')).length;
      _progressCount = progressKeys;
      
      _totalCacheSize = _imageCacheSize;
    } catch (e) {
      debugPrint('Erreur calcul cache: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur calcul taille: $e');
    }
    return totalSize;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(settingsProvider);
    
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: Center(child: NeonLoadingIndicator()),
      );
    }

    Widget content = Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(provider),
          SliverToBoxAdapter(
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  _buildStorageStatsSection(),
                  _buildVideoPlaybackSection(provider),
                  _buildInterfaceSection(provider),
                  _buildDataManagementSection(),
                  _buildAdvancedSection(provider),
                  _buildAboutSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    
    // TV Navigation wrapper
    if (PlatformService.isTVMode) {
      content = Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          
          // Scroll avec flèches
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _scrollController.animateTo(
              (_scrollController.offset - 100).clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
            return KeyEventResult.ignored; // Laisser le focus changer aussi
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _scrollController.animateTo(
              (_scrollController.offset + 100).clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
            return KeyEventResult.ignored;
          }
          
          return KeyEventResult.ignored;
        },
        child: content,
      );
    }
    
    return content;
  }

  Widget _buildAppBar(SettingsProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.backgroundPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Paramètres',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.accentNeon, AppTheme.accentSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.backgroundPrimary.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (provider.hasUnsavedChanges)
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.accentNeon),
            onPressed: () => _saveSettings(provider),
            tooltip: 'Sauvegarder',
          ),
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: AccountSwitcherButton(isCompact: true),
        ),
      ],
    );
  }

  // ========== SECTION STOCKAGE & STATISTIQUES ==========
  Widget _buildStorageStatsSection() {
    return _buildSection(
      'Stockage & Statistiques',
      Icons.analytics_outlined,
      [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentNeon.withOpacity(0.3)),
          ),
          child: _loadingStats
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStatRow('Cache total', _formatBytes(_totalCacheSize), Icons.storage),
                    const Divider(color: AppTheme.textSecondary, height: 24),
                    _buildStatRow('Cache images', _formatBytes(_imageCacheSize), Icons.image),
                    const Divider(color: AppTheme.textSecondary, height: 24),
                    _buildStatRow('Progressions enregistrées', '$_progressCount', Icons.history),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentNeon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.accentNeon,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ========== SECTION LECTURE VIDÉO ==========
  Widget _buildVideoPlaybackSection(SettingsProvider provider) {
    return _buildSection(
      'Lecture vidéo',
      Icons.play_circle_outline,
      [
        _buildSwitchTile(
          'Lecture automatique',
          'Démarre automatiquement la lecture des vidéos',
          provider.autoPlay,
          (value) {
            provider.setAutoPlay(value);
            _autoSave(provider);
          },
        ),
        _buildSwitchTile(
          'Accélération matérielle',
          'Utilise le GPU pour décoder les vidéos (recommandé)',
          provider.enableHardwareAcceleration,
          (value) {
            provider.setEnableHardwareAcceleration(value);
            _autoSave(provider);
          },
        ),
      ],
    );
  }

  // ========== SECTION INTERFACE ==========
  Widget _buildInterfaceSection(SettingsProvider provider) {
    return _buildSection(
      'Interface',
      Icons.palette_outlined,
      [
        _buildSwitchTile(
          'Animations',
          'Active les animations et transitions',
          provider.enableAnimations,
          (value) {
            provider.setEnableAnimations(value);
            _autoSave(provider);
          },
        ),
      ],
    );
  }

  // ========== SECTION GESTION DES DONNÉES ==========
  Widget _buildDataManagementSection() {
    return _buildSection(
      'Gestion des données',
      Icons.data_usage,
      [
        _buildActionTile(
          'Vider le cache',
          'Libère ${_formatBytes(_totalCacheSize)} d\'espace',
          Icons.cleaning_services,
          _totalCacheSize > 0 ? () => _clearCache() : null,
        ),
        _buildActionTile(
          'Exporter la progression',
          'Sauvegarde vos progressions de visionnage ($_progressCount)',
          Icons.upload_file,
          _progressCount > 0 ? () => _exportWatchProgress() : null,
        ),
        _buildActionTile(
          'Importer la progression',
          'Restaure vos progressions de visionnage',
          Icons.download,
          () => _importWatchProgress(),
        ),
        _buildActionTile(
          'Exporter les paramètres',
          'Sauvegarde tous vos paramètres',
          Icons.settings_backup_restore,
          () => _exportSettings(),
        ),
        _buildActionTile(
          'Importer les paramètres',
          'Restaure vos paramètres',
          Icons.settings_backup_restore,
          () => _importSettings(),
        ),
      ],
    );
  }

  // ========== SECTION AVANCÉ ==========
  Widget _buildAdvancedSection(SettingsProvider provider) {
    return _buildSection(
      'Avancé',
      Icons.settings_outlined,
      [
        _buildSliderTile(
          'Timeout des requêtes',
          'Délai d\'attente maximum pour les requêtes réseau',
          provider.requestTimeout.toDouble(),
          10,
          60,
          '${provider.requestTimeout}s',
          (value) {
            provider.setRequestTimeout(value.toInt());
            _autoSave(provider);
          },
        ),
        _buildActionTile(
          'Réinitialiser les paramètres',
          'Restaure les paramètres par défaut',
          Icons.restore,
          () => _showResetDialog(),
          color: AppTheme.warningColor,
        ),
      ],
    );
  }

  // ========== SECTION À PROPOS ==========
  Widget _buildAboutSection() {
    return _buildSection(
      'À propos',
      Icons.info_outline,
      [
        _buildActionTile(
          'Version',
          'NEO Stream v1.0.0',
          Icons.app_registration,
          () => _showEasterEgg(),
        ),
        _buildActionTile(
          'Licences',
          'Licences des bibliothèques utilisées',
          Icons.description,
          () => showLicensePage(context: context),
        ),
        _buildActionTile(
          'Effacer toutes les données',
          'Supprime tous les paramètres, favoris et progressions',
          Icons.delete_forever,
          () => _showClearAllDataDialog(),
          color: AppTheme.errorColor,
        ),
      ],
    );
  }

  // ========== WIDGETS HELPERS ==========
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accentNeon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.accentNeon,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    if (!PlatformService.isTVMode) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
          subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentNeon,
        ),
      );
    }
    
    // Version TV avec focus navigable
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            onChanged(!value);
            HapticFeedback.lightImpact();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isFocused ? AppTheme.accentNeon.withOpacity(0.15) : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: isFocused 
                  ? Border.all(color: AppTheme.accentNeon, width: 2)
                  : null,
            ),
            child: ListTile(
              title: Text(title, style: TextStyle(
                color: isFocused ? AppTheme.accentNeon : AppTheme.textPrimary,
                fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
              )),
              subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              trailing: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.accentNeon,
              ),
              onTap: () {
                onChanged(!value);
                HapticFeedback.lightImpact();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    String displayValue,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    activeColor: AppTheme.accentNeon,
                    inactiveColor: AppTheme.textSecondary,
                    onChanged: onChanged,
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.centerRight,
                  child: Text(
                    displayValue,
                    style: const TextStyle(
                      color: AppTheme.accentNeon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap, {
    Color? color,
  }) {
    if (!PlatformService.isTVMode || onTap == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: onTap == null ? Border.all(color: AppTheme.textSecondary.withOpacity(0.3)) : null,
        ),
        child: ListTile(
          leading: Icon(icon, color: onTap == null ? AppTheme.textSecondary : (color ?? AppTheme.accentNeon)),
          title: Text(
            title,
            style: TextStyle(color: onTap == null ? AppTheme.textSecondary : (color ?? AppTheme.textPrimary)),
          ),
          subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary) : null,
          onTap: onTap,
          enabled: onTap != null,
        ),
      );
    }

    // Version TV avec focus navigable
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            onTap();
            HapticFeedback.lightImpact();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isFocused ? (color ?? AppTheme.accentNeon).withOpacity(0.15) : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: isFocused 
                    ? Border.all(color: color ?? AppTheme.accentNeon, width: 2)
                    : null,
              ),
              child: ListTile(
                leading: Icon(icon, color: isFocused ? Colors.white : (color ?? AppTheme.accentNeon)),
                title: Text(
                  title,
                  style: TextStyle(
                    color: isFocused ? Colors.white : (color ?? AppTheme.textPrimary),
                    fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Icon(
                  Icons.chevron_right, 
                  color: isFocused ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accentNeon),
        title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ),
    );
  }

  // ========== ACTIONS ==========
  void _autoSave(SettingsProvider provider) async {
    await provider.saveSettings();
  }

  void _saveSettings(SettingsProvider provider) async {
    final success = await provider.saveSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Paramètres sauvegardés' : 'Erreur de sauvegarde'),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Vider le cache', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Êtes-vous sûr de vouloir vider le cache (${_formatBytes(_totalCacheSize)}) ?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentNeon),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          await tempDir.create();
        }
        
        await _loadCacheStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache vidé avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportWatchProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.contains('watch_progress'));
      
      final Map<String, dynamic> exportData = {};
      for (var key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          exportData[key] = value;
        }
      }
      
      final jsonString = jsonEncode({
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'progress_count': exportData.length,
        'data': exportData,
      });
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/neostream_progress_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'NEO Stream - Progression de visionnage',
        text: 'Export de $_progressCount progressions',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progression exportée avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _importWatchProgress() async {
    try {
      final result = await FileSharingService.importSettings();
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun fichier sélectionné'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }
      
      final data = result['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Format invalide');
      }
      
      final prefs = await SharedPreferences.getInstance();
      int imported = 0;
      for (var entry in data.entries) {
        await prefs.setString(entry.key, entry.value.toString());
        imported++;
      }
      
      await _loadCacheStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$imported progressions importées'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'import: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _exportSettings() async {
    final provider = ref.read(settingsProvider);
    final jsonString = await provider.exportSettings();
    
    if (jsonString != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/neostream_settings_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonString);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'NEO Stream - Paramètres',
          text: 'Export des paramètres de l\'application',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paramètres exportés avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _importSettings() async {
    final provider = ref.read(settingsProvider);
    final importedSettings = await FileSharingService.importSettings();
    
    if (importedSettings != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Importer les paramètres', style: TextStyle(color: AppTheme.textPrimary)),
          content: const Text(
            'Cela remplacera tous vos paramètres actuels. Voulez-vous continuer ?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentNeon),
              child: const Text('Importer'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await provider.importSettingsFromMap(importedSettings);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Paramètres importés' : 'Erreur lors de l\'import'),
              backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Réinitialiser les paramètres', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Tous les paramètres seront remis à leurs valeurs par défaut. Cette action est irréversible.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = ref.read(settingsProvider);
      final success = await provider.resetSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Paramètres réinitialisés' : 'Erreur'),
            backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showClearAllDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Effacer toutes les données',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: const Text(
          'Cette action supprimera:\n• Tous vos paramètres\n• Tous vos favoris\n• Toutes vos progressions de visionnage\n• Le cache\n\nCette action est irréversible.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Supprimer toutes les SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        // Vider le cache
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          await tempDir.create();
        }
        
        await _loadCacheStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toutes les données ont été effacées'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Recharger les paramètres par défaut
          final provider = ref.read(settingsProvider);
          await provider.loadSettings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showEasterEgg() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AboutEasterEggScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}
