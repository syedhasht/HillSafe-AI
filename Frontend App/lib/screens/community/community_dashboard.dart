import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/screens/community/risk_map_screen.dart';
import 'package:frontend_app/widgets/weather_risk_widget.dart';

class CommunityDashboard extends StatefulWidget {
  const CommunityDashboard({super.key});

  @override
  State<CommunityDashboard> createState() => _CommunityDashboardState();
}

class _CommunityDashboardState extends State<CommunityDashboard> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _regionsFuture;
  bool _isMarkedSafe = false;
  bool _isMarkingSafe = false;
  List<Map<String, dynamic>> _regions = [];
  int? _nearestRegionId;
  DateTime? _nextSafeMarkAt;
  Timer? _safeUnlockTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _safeUnlockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _regionsFuture = _apiService.fetchRegions();
    final regions = await _regionsFuture;
    if (mounted) {
      setState(() {
        _regions = regions;
      });
      await _initialSafetyCheck();
    }
  }

  Future<void> _initialSafetyCheck() async {
    if (_regions.isEmpty) return;

    try {
      // Step 1: Get current position to find nearest region
      final position = await _apiService.getCurrentPosition();
      
      if (position != null) {
        // Find nearest region (simplified logic matching WeatherRiskWidget)
        final nearest = _findNearestRegion(position.latitude, position.longitude, _regions);
        if (nearest != null && mounted) {
          final regionId = (nearest['id'] as num).toInt();
          setState(() => _nearestRegionId = regionId);
          
          // Step 2: Check backend for active 30-minute safety status
          final safetyStatus = await _apiService.checkSafetyStatusDetails(regionId);
          if (mounted) {
            _applySafetyStatus(safetyStatus);
          }
        }
      } else if (_regions.isNotEmpty) {
        // Fallback to first region if GPS fails
        final regionId = (_regions.first['id'] as num).toInt();
        setState(() => _nearestRegionId = regionId);
        final safetyStatus = await _apiService.checkSafetyStatusDetails(regionId);
        if (mounted) {
          _applySafetyStatus(safetyStatus);
        }
      }
    } catch (e) {
      print('Initial safety check error: $e');
    }
  }

  Map<String, dynamic>? _findNearestRegion(double lat, double lon, List<Map<String, dynamic>> regions) {
    Map<String, dynamic>? nearest;
    double minDistance = double.infinity;
    for (var region in regions) {
      final rLat = (region['latitude'] as num?)?.toDouble();
      final rLon = (region['longitude'] as num?)?.toDouble();
      if (rLat == null || rLon == null) continue;
      final distance = _calculateDistance(lat, lon, rLat, rLon);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = region;
      }
    }
    return nearest;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const radiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  void _applySafetyStatus(Map<String, dynamic> data) {
    final seconds = (data['seconds_until_next_mark'] as num?)?.toInt() ?? 0;
    final isActive = data['is_active'] == true;

    setState(() {
      _isMarkedSafe = isActive && seconds > 0;
      _nextSafeMarkAt = _isMarkedSafe ? DateTime.now().add(Duration(seconds: seconds)) : null;
    });
    _scheduleSafeUnlock();
  }

  void _scheduleSafeUnlock() {
    _safeUnlockTimer?.cancel();
    if (_nextSafeMarkAt == null) return;

    final remaining = _nextSafeMarkAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      setState(() {
        _isMarkedSafe = false;
        _nextSafeMarkAt = null;
      });
      return;
    }

    _safeUnlockTimer = Timer(remaining, () {
      if (!mounted) return;
      setState(() {
        _isMarkedSafe = false;
        _nextSafeMarkAt = null;
      });
    });
  }

  String _formatSafeCooldown() {
    if (_nextSafeMarkAt == null) return 'Notify authorities that you are safe';
    final remaining = _nextSafeMarkAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) return 'You can mark yourself safe again now';
    final minutes = remaining.inMinutes + (remaining.inSeconds % 60 == 0 ? 0 : 1);
    return 'Authorities notified. You can update again in ${minutes}m';
  }

  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    
    try {
      debugPrint('=== REFRESHING DASHBOARD DATA ===');
      
      // Refresh regions
      await _loadInitialData();
      
      debugPrint('✓ Dashboard data refreshed successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(LucideIcons.checkCircle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('✓ Data refreshed successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('✗ Refresh failed: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Refresh failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _markAsSafe() async {
    if (_isMarkedSafe) return;
    
    setState(() => _isMarkingSafe = true);
    print('DEBUG: Starting _markAsSafe. Current nearestRegionId: $_nearestRegionId');

    try {
      final regionId = _nearestRegionId ?? (_regions.isNotEmpty ? (_regions.first['id'] as num).toInt() : null);

      if (regionId == null) {
        throw Exception('No monitored regions available. Please refresh.');
      }

      final position = await _apiService.getCurrentPosition();
      final areaName = position == null
          ? null
          : await _apiService.fetchLocationName(position.latitude, position.longitude);

      print('DEBUG: Calling apiService.markAsSafe for region: $regionId');
      final response = await _apiService.markAsSafe(
        regionId,
        latitude: position?.latitude,
        longitude: position?.longitude,
        areaName: areaName,
      );
      final success = response?['status'] == 'success';
      final cooldown = response?['status'] == 'cooldown';

      if (mounted) {
        setState(() {
          _isMarkingSafe = false;
          if (success || cooldown) {
            _isMarkedSafe = true;
            final seconds = (response?['seconds_until_next_mark'] as num?)?.toInt() ?? 1800;
            _nextSafeMarkAt = DateTime.now().add(Duration(seconds: seconds));
          }
        });
        if (success || cooldown) {
          _scheduleSafeUnlock();
        }

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Marked as safe successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (cooldown) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatSafeCooldown()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update safety status. Please check login and location permission.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Caught exception in _markAsSafe: $e');
      if (mounted) {
        setState(() => _isMarkingSafe = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 360
                        ? AppTheme.spacingMedium
                        : AppTheme.spacingLarge,
                  ),
                  child: Row(
                    children: [
                      // Logo + Title
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Logo.jpeg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                langProvider.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Language Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(LucideIcons.globe),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () {
                                context.read<LanguageProvider>().toggleLanguage();
                              },
                              tooltip: 'Toggle Language',
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(LucideIcons.settings),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () {
                                Navigator.of(context).pushNamed('/settings');
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(LucideIcons.bell),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () {
                                Navigator.of(context).pushNamed('/alert_feed');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),
              ),

              // Smart Weather & Risk Widget
              const SliverToBoxAdapter(
                child: WeatherRiskWidget(),
              ),

              // Prominent "I'm Safe" Button Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                    vertical: AppTheme.spacingMedium,
                  ),
                  child: _SafetyButton(
                    isMarkedSafe: _isMarkedSafe,
                    isLoading: _isMarkingSafe,
                    subtitle: _formatSafeCooldown(),
                    onPressed: _markAsSafe,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final buttonWidth = (constraints.maxWidth - AppTheme.spacingMedium) / 2;

                          return Wrap(
                            spacing: AppTheme.spacingMedium,
                            runSpacing: AppTheme.spacingMedium,
                            children: [
                              SizedBox(
                                width: buttonWidth,
                                child: _QuickActionButton(
                                  icon: LucideIcons.map,
                                  label: 'Map View',
                                  onTap: () {
                                    Navigator.of(context).pushNamed('/community_map');
                                  },
                                ),
                              ),
                              SizedBox(
                                width: buttonWidth,
                                child: _QuickActionButton(
                                  icon: LucideIcons.lightbulb,
                                  label: 'Safety Tips',
                                  onTap: () {
                                    Navigator.of(context).pushNamed('/safety_guidelines');
                                  },
                                ),
                              ),
                              SizedBox(
                                width: buttonWidth,
                                child: _QuickActionButton(
                                  icon: LucideIcons.flag,
                                  label: 'Report',
                                  onTap: () {
                                    Navigator.of(context).pushNamed('/report_incident');
                                  },
                                ),
                              ),
                              SizedBox(
                                width: buttonWidth,
                                child: _QuickActionButton(
                                  icon: LucideIcons.refreshCw,
                                  label: 'Refresh',
                                  onTap: _refreshData,
                                  isLoading: _isRefreshing,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingLarge),
              ),

              // Regions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: Text(
                    'Monitored Regions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingMedium),
              ),

              // Live Region Cards with Traffic Light System
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                ),
                sliver: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _regionsFuture,
                  builder: (context, snapshot) {
                    // Loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Loading regions...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      );
                    }

                    // Capture data for "I am Safe" feature
                    if (snapshot.hasData) {
                      _regions = snapshot.data!;
                    }

                    // Error state
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLarge),
                            child: Column(
                              children: [
                                const Icon(
                                  LucideIcons.wifiOff,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Connection Error',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Could not load regions. Please check your connection.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _refreshData,
                                  icon: const Icon(LucideIcons.refreshCw),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Empty state
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLarge),
                            child: Column(
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 48,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No regions available',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Success state with region cards
                    final regions = snapshot.data!;
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final region = regions[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingMedium,
                            ),
                            child: _RegionCard(region: region)
                                .animate()
                                .fadeIn(
                                  duration: 600.ms,
                                  delay: (600 + (index * 100)).ms,
                                )
                                .slideX(begin: 0.2, end: 0),
                          );
                        },
                        childCount: regions.length,
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingLarge),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RiskMapScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(LucideIcons.map, color: Colors.white),
        label: const Text(
          'Risk Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate().fadeIn(duration: 600.ms, delay: 800.ms).scale(),
    );
  }
}

// Region Card with Traffic Light System
class _RegionCard extends StatelessWidget {
  final Map<String, dynamic> region;

  const _RegionCard({required this.region});

  // Traffic Light Risk System
  RiskLevel _getRiskLevel(double score) {
    if (score < 0.15) {
      return RiskLevel.noRisk;
    } else if (score < 0.3) {
      return RiskLevel.safe;
    } else if (score < 0.7) {
      return RiskLevel.caution;
    } else {
      return RiskLevel.danger;
    }
  }

  String _formatLastUpdated(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = _getRiskLevel(score);
    final lastUpdated = _formatLastUpdated(region['last_updated']);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RiskMapScreen(selectedRegion: region),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: riskLevel.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: riskLevel.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: riskLevel.color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Risk Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: riskLevel.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                riskLevel.icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
  
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region['name'] ?? 'Unknown Region',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    region['district'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lastUpdated,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
  
            // Risk Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: riskLevel.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    riskLevel.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(score * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Risk Level Enum
enum RiskLevel {
  noRisk(
    label: 'NO RISK',
    color: Colors.green,
    icon: LucideIcons.checkCircle,
  ),
  safe(
    label: 'LOW',
    color: Colors.green,
    icon: LucideIcons.checkCircle,
  ),
  caution(
    label: 'CAUTION',
    color: Colors.orange,
    icon: LucideIcons.alertTriangle,
  ),
  danger(
    label: 'DANGER',
    color: Colors.red,
    icon: LucideIcons.alertOctagon,
  );

  final String label;
  final Color color;
  final IconData icon;

  const RiskLevel({
    required this.label,
    required this.color,
    required this.icon,
  });
}

// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMedium,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      icon,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Safety Button Widget for "I AM SAFE" functionality
class _SafetyButton extends StatelessWidget {
  final bool isMarkedSafe;
  final bool isLoading;
  final String subtitle;
  final VoidCallback onPressed;

  const _SafetyButton({
    required this.isMarkedSafe,
    required this.isLoading,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMedium,
          horizontal: AppTheme.spacingMedium,
        ),
        decoration: BoxDecoration(
          color: isMarkedSafe 
              ? Colors.green.shade600 
              : Colors.grey.shade100, // Explicitly grey unpressed
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isMarkedSafe 
                ? Colors.green.shade700 
                : Colors.grey.shade300, // Explicit grey border
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isMarkedSafe ? Colors.green : Colors.black).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                ),
              )
            else
              Icon(
                isMarkedSafe ? LucideIcons.checkCircle : LucideIcons.shieldCheck,
                size: 28,
                color: isMarkedSafe ? Colors.white : Colors.grey.shade400,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMarkedSafe ? 'STATUS: SAFE' : 'I am Safe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isMarkedSafe ? Colors.white : Colors.grey.shade700,
                      letterSpacing: isMarkedSafe ? 1.2 : 0,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isMarkedSafe ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMarkedSafe && !isLoading)
              Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}


