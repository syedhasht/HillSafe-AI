import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/theme_provider.dart';

/// Safety Guidelines Screen
/// Display safety tips with bookmark/save functionality
class SafetyGuidelinesScreen extends StatefulWidget {
  const SafetyGuidelinesScreen({super.key});

  @override
  State<SafetyGuidelinesScreen> createState() => _SafetyGuidelinesScreenState();
}

class _SafetyGuidelinesScreenState extends State<SafetyGuidelinesScreen> {
  final ApiService _apiService = ApiService();
  final Set<String> _savedTipIds = {};
  final Set<String> _savingTipIds = {};
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _showOnlySaved = false;
  bool _isLoadingSavedTips = true;
  bool _animateCardsOnFirstLoad = true;

  final List<Map<String, dynamic>> _safetyTips = [
    {
      'id': 'emergency_kit',
      'title': 'Prepare an Emergency Kit',
      'description': 'Keep essential supplies like water, food, flashlight, first aid kit, and important documents ready.',
      'icon': LucideIcons.package,
      // Kept original color for semantic meaning — tip-category identity
      'color': AppTheme.accentTeal,
    },
    {
      'id': 'evacuation_routes',
      'title': 'Know Evacuation Routes',
      'description': 'Familiarize yourself with safe routes and designated evacuation areas in your locality.',
      'icon': LucideIcons.mapPin,
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'rescue_1122',
      'title': 'Rescue 1122 - Emergency Contact',
      'description': 'Dial 1122 immediately in case of emergency. Save this number in your phone.',
      'icon': LucideIcons.phone,
      'color': const Color(0xFFEF4444),
    },
    {
      'id': 'weather_alerts',
      'title': 'Monitor Weather Alerts',
      'description': 'Stay informed about weather conditions and landslide warnings through official channels.',
      'icon': LucideIcons.cloudRain,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'avoid_steep_slopes',
      'title': 'Avoid Steep Slopes During Rain',
      'description': 'Do not travel or stay near steep slopes during heavy rainfall or if landslide warning is issued.',
      'icon': LucideIcons.alertTriangle,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'warning_signs',
      'title': 'Watch for Warning Signs',
      'description': 'Look for cracks in ground, tilting trees/poles, unusual water flow, or sounds of breaking rocks.',
      'icon': LucideIcons.eye,
      'color': const Color(0xFF06B6D4),
    },
    {
      'id': 'family_plan',
      'title': 'Create a Family Plan',
      'description': 'Establish communication plans and meeting points with family members for emergency situations.',
      'icon': LucideIcons.users,
      'color': const Color(0xFFEC4899),
    },
    {
      'id': 'report_changes',
      'title': 'Report Suspicious Changes',
      'description': 'Immediately report any unusual ground movements or structural damage to authorities.',
      'icon': LucideIcons.flag,
      'color': const Color(0xFFF97316),
    },
  ];

  List<Map<String, dynamic>> get _filteredTips {
    if (_showOnlySaved) {
      return _safetyTips
          .where((tip) => _savedTipIds.contains(tip['id'] as String))
          .toList();
    }
    return _safetyTips;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedTips();
    _loadEmergencyContacts();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _animateCardsOnFirstLoad = false);
      }
    });
  }

  Future<void> _loadSavedTips() async {
    final savedTips = await _apiService.fetchSavedSafetyTips();
    if (!mounted) return;

    setState(() {
      _savedTipIds
        ..clear()
        ..addAll(savedTips
            .map((tip) => tip['tip_id']?.toString())
            .whereType<String>());
      _isLoadingSavedTips = false;
    });
  }

  Future<void> _loadEmergencyContacts() async {
    final contacts = await _apiService.fetchEmergencyContacts();
    if (!mounted) return;

    setState(() {
      _emergencyContacts = contacts.isEmpty ? _fallbackEmergencyContacts : contacts;
    });
  }

  Future<void> _toggleSave(Map<String, dynamic> tip) async {
    final tipId = tip['id'] as String;
    if (_savingTipIds.contains(tipId)) return;

    setState(() => _savingTipIds.add(tipId));

    final wasSaved = _savedTipIds.contains(tipId);
    final success = wasSaved
        ? await _apiService.removeSavedSafetyTip(tipId)
        : await _apiService.saveSafetyTip(
            tipId: tipId,
            title: tip['title'] as String,
            description: tip['description'] as String,
          );

    if (!mounted) return;

    setState(() {
      _savingTipIds.remove(tipId);
      if (success) {
        if (wasSaved) {
          _savedTipIds.remove(tipId);
        } else {
          _savedTipIds.add(tipId);
        }
      }
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LanguageProvider>().tr('Could not update saved tip. Please try again.')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _fallbackEmergencyContacts => const [
        {
          'name': 'Rescue 1122',
          'number': '1122',
          'description': 'Emergency Rescue Services',
          'icon': 'ambulance',
        },
        {
          'name': 'Police',
          'number': '15',
          'description': 'Police Emergency',
          'icon': 'shield',
        },
        {
          'name': 'Fire Brigade',
          'number': '16',
          'description': 'Fire Emergency',
          'icon': 'flame',
        },
      ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      // Light warm-white scaffold background
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        // White AppBar with dark text/icons
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          langProvider.safetyGuidelines,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          // Filter Button — teal accent
          IconButton(
            icon: Icon(
              _showOnlySaved ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
              color: AppTheme.accentTeal,
            ),
            onPressed: () {
              setState(() => _showOnlySaved = !_showOnlySaved);
            },
            tooltip: _showOnlySaved
                ? langProvider.allTips
                : langProvider.savedTips,
          ),
        ],
      ),
      body: _isLoadingSavedTips
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentTeal),
            )
          : _filteredTips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bookmark,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    'No saved tips yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showOnlySaved = false);
                    },
                    icon: const Icon(LucideIcons.list),
                    label: Text(langProvider.tr('View All Tips')),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              children: _filteredTips.asMap().entries.map((entry) {
                final index = entry.key;
                final tip = entry.value;
                final tipId = tip['id'] as String;
                final isSaved = _savedTipIds.contains(tipId);
                final isSaving = _savingTipIds.contains(tipId);
                
                final card = _buildTipCard(
                  context,
                  tip['title'] as String,
                  tip['description'] as String,
                  tip['icon'] as IconData,
                  tip['color'] as Color,
                  isSaved,
                  isSaving,
                  () => _toggleSave(tip),
                  index,
                );

                if (!_animateCardsOnFirstLoad) return card;

                return card
                  .animate()
                  .fadeIn(
                    duration: 400.ms,
                    delay: (index * 100).ms,
                  )
                  .slideX(begin: 0.2, end: 0);
              }).toList(),
            ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    bool isSaved,
    bool isSaving,
    VoidCallback onToggleSave,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        // White surface card
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon — colored container with teal-aware light bg
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.watch<LanguageProvider>().tr(title),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      context.watch<LanguageProvider>().tr(description),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bookmark Button — uses accentTeal when saved
              IconButton(
                icon: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentTeal,
                        ),
                      )
                    : Icon(
                        isSaved
                            ? LucideIcons.bookmarkMinus
                            : LucideIcons.bookmark,
                        color: isSaved ? AppTheme.accentTeal : AppTheme.textSecondary,
                      ),
                onPressed: isSaving ? null : onToggleSave,
                tooltip: isSaved
                    ? context.read<LanguageProvider>().tr('Remove from saved')
                    : context.read<LanguageProvider>().tr('Save tip'),
              ),
            ],
          ),
          
          // Learn More Button (for special tips)
          if (title.contains('1122'))
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
              child: TextButton.icon(
                onPressed: () => _showEmergencyContacts(context),
                icon: const Icon(LucideIcons.info, size: 16),
                label: Text(context.watch<LanguageProvider>().tr('View All Emergency Contacts')),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final contacts = _emergencyContacts.isEmpty
            ? _fallbackEmergencyContacts
            : _emergencyContacts;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              // White surface bottom sheet
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.phoneCall,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.watch<LanguageProvider>().tr('Emergency Contacts'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: context.read<LanguageProvider>().tr('Close'),
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...contacts.expand((contact) {
                    return [
                      _EmergencyContact(
                        name: context.read<LanguageProvider>().tr(contact['name']?.toString() ?? 'Emergency'),
                        number: contact['number']?.toString() ?? '',
                        description:
                            context.read<LanguageProvider>().tr(contact['description']?.toString() ?? ''),
                        icon: _contactIcon(contact['icon']?.toString()),
                      ),
                      const SizedBox(height: 10),
                    ];
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _contactIcon(String? iconName) {
    switch (iconName) {
      case 'ambulance':
        return LucideIcons.ambulance;
      case 'shield':
        return LucideIcons.shield;
      case 'flame':
        return LucideIcons.flame;
      default:
        return LucideIcons.phoneCall;
    }
  }
}

class _EmergencyContact extends StatelessWidget {
  final String name;
  final String number;
  final String description;
  final IconData icon;

  const _EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Light background for contact items
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.watch<LanguageProvider>().tr(name),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  context.watch<LanguageProvider>().tr(description),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
