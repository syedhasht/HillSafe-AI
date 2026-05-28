import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/providers/language_provider.dart';

/// Safety Guidelines Screen
/// Display safety tips with bookmark/save functionality
class SafetyGuidelinesScreen extends StatefulWidget {
  const SafetyGuidelinesScreen({super.key});

  @override
  State<SafetyGuidelinesScreen> createState() => _SafetyGuidelinesScreenState();
}

class _SafetyGuidelinesScreenState extends State<SafetyGuidelinesScreen> {
  // Track saved tips by index
  final Set<int> _savedTips = {};
  bool _showOnlySaved = false;

  final List<Map<String, dynamic>> _safetyTips = [
    {
      'title': 'Prepare an Emergency Kit',
      'description': 'Keep essential supplies like water, food, flashlight, first aid kit, and important documents ready.',
      'icon': LucideIcons.package,
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Know Evacuation Routes',
      'description': 'Familiarize yourself with safe routes and designated evacuation areas in your locality.',
      'icon': LucideIcons.mapPin,
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Rescue 1122 - Emergency Contact',
      'description': 'Dial 1122 immediately in case of emergency. Save this number in your phone.',
      'icon': LucideIcons.phone,
      'color': const Color(0xFFEF4444),
    },
    {
      'title': 'Monitor Weather Alerts',
      'description': 'Stay informed about weather conditions and landslide warnings through official channels.',
      'icon': LucideIcons.cloudRain,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'title': 'Avoid Steep Slopes During Rain',
      'description': 'Do not travel or stay near steep slopes during heavy rainfall or if landslide warning is issued.',
      'icon': LucideIcons.alertTriangle,
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Watch for Warning Signs',
      'description': 'Look for cracks in ground, tilting trees/poles, unusual water flow, or sounds of breaking rocks.',
      'icon': LucideIcons.eye,
      'color': const Color(0xFF06B6D4),
    },
    {
      'title': 'Create a Family Plan',
      'description': 'Establish communication plans and meeting points with family members for emergency situations.',
      'icon': LucideIcons.users,
      'color': const Color(0xFFEC4899),
    },
    {
      'title': 'Report Suspicious Changes',
      'description': 'Immediately report any unusual ground movements or structural damage to authorities.',
      'icon': LucideIcons.flag,
      'color': const Color(0xFFF97316),
    },
  ];

  List<Map<String, dynamic>> get _filteredTips {
    if (_showOnlySaved) {
      return _safetyTips.asMap().entries
          .where((entry) => _savedTips.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
    }
    return _safetyTips;
  }

  void _toggleSave(int index) {
    setState(() {
      if (_savedTips.contains(index)) {
        _savedTips.remove(index);
      } else {
        _savedTips.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(langProvider.safetyGuidelines),
        actions: [
          // Filter Button
          IconButton(
            icon: Icon(
              _showOnlySaved ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
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
      body: _filteredTips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
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
                    label: const Text('View All Tips'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              itemCount: _filteredTips.length,
              itemBuilder: (context, index) {
                final tip = _filteredTips[index];
                final originalIndex = _safetyTips.indexOf(tip);
                final isSaved = _savedTips.contains(originalIndex);
                
                return _buildTipCard(
                  context,
                  tip['title'],
                  tip['description'],
                  tip['icon'],
                  tip['color'],
                  isSaved,
                  () => _toggleSave(originalIndex),
                  index,
                )
                    .animate()
                    .fadeIn(
                      duration: 400.ms,
                      delay: (index * 100).ms,
                    )
                    .slideX(begin: 0.2, end: 0);
              },
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
    VoidCallback onToggleSave,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
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
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bookmark Button
              IconButton(
                icon: Icon(
                  isSaved ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
                  color: isSaved ? color : AppTheme.textSecondary,
                ),
                onPressed: onToggleSave,
                tooltip: isSaved ? 'Remove from saved' : 'Save tip',
              ),
            ],
          ),
          
          // Learn More Button (for special tips)
          if (title.contains('1122'))
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
              child: TextButton.icon(
                onPressed: () {
                  // Show emergency contacts
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(LucideIcons.phone, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Emergency Contacts'),
                        ],
                      ),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EmergencyContact(
                            name: 'Rescue 1122',
                            number: '1122',
                            description: 'Emergency Rescue Services',
                          ),
                          SizedBox(height: 12),
                          _EmergencyContact(
                            name: 'Police',
                            number: '15',
                            description: 'Police Emergency',
                          ),
                          SizedBox(height: 12),
                          _EmergencyContact(
                            name: 'Fire Brigade',
                            number: '16',
                            description: 'Fire Emergency',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(LucideIcons.info, size: 16),
                label: const Text('View All Emergency Contacts'),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmergencyContact extends StatelessWidget {
  final String name;
  final String number;
  final String description;

  const _EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

