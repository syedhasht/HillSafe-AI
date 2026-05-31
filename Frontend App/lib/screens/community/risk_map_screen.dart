import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:frontend_app/constants/risk_constants.dart';

/// Risk Map Screen - Visualizes regions with color-coded risk levels
class RiskMapScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedRegion;
  
  const RiskMapScreen({
    super.key,
    this.selectedRegion,
  });

  @override
  State<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends State<RiskMapScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();
  
  List<Map<String, dynamic>> _regions = [];
  bool _isLoading = true;
  bool _isLoadingMap = true;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  String _selectedFilter = 'All';
  bool _showSatellite = false;
  LatLng? _userPosition;
  LatLng? _cachedUserPosition;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadRegions();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return; // Prevent duplicate calls
    
    setState(() => _isLoadingLocation = true);
    
    try {
      debugPrint('Attempting to get current location...');
      final position = await _apiService.getCurrentPosition();
      if (position != null && mounted) {
        debugPrint('✓ Location obtained: ${position.latitude}, ${position.longitude}');
        setState(() {
          _userPosition = LatLng(position.latitude, position.longitude);
          _cachedUserPosition = _userPosition; // Cache for instant access
          _isLoadingLocation = false;
        });
      } else {
        debugPrint('Location is null or widget unmounted');
        if (mounted) setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      debugPrint('✗ Error getting location: $e');
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadRegions() async {
    if (widget.selectedRegion != null) {
      setState(() {
        _regions = [widget.selectedRegion!];
        _isLoading = false;
        _isLoadingMap = false;
        _errorMessage = null;
      });
      _scheduleCameraFit();
      return;
    }

    setState(() {
      _isLoading = true;
      _isLoadingMap = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Loading regions...');
      final regions = await _apiService.fetchRegions();
      
      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoading = false;
          _isLoadingMap = false;
        });
        
        debugPrint('✓ Regions loaded: ${regions.length}');
        
        if (_regions.isNotEmpty) {
          _scheduleCameraFit();
        }
      }
    } catch (e) {
      debugPrint('✗ Failed to load regions: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load regions: $e';
          _isLoading = false;
          _isLoadingMap = false;
        });
      }
    }
  }

  void _scheduleCameraFit() {
    // Single deferred call — the double-call was causing mid-gesture NaN crashes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitCameraToBounds();
    });
  }

  LatLng get _initialMapCenter {
    final selected = widget.selectedRegion;
    if (selected != null) {
      return _regionPoint(selected) ?? const LatLng(30.3753, 69.3451);
    }
    return const LatLng(30.3753, 69.3451);
  }

  double get _initialMapZoom => widget.selectedRegion == null ? 5.5 : 9.8;

  List<Map<String, dynamic>> get _filteredRegions {
    if (widget.selectedRegion != null) {
      return _regionPoint(widget.selectedRegion!) == null
          ? []
          : [widget.selectedRegion!];
    }

    if (_selectedFilter == 'All') return _regions;
    return _regions.where((region) {
      final riskScore = _regionRiskScore(region);
      if (_selectedFilter == 'Critical') return riskScore >= RiskConstants.criticalThreshold;
      if (_selectedFilter == 'High Risk') return riskScore >= RiskConstants.highThreshold && riskScore < RiskConstants.criticalThreshold;
      if (_selectedFilter == 'Medium Risk') return riskScore >= RiskConstants.mediumThreshold && riskScore < RiskConstants.highThreshold;
      if (_selectedFilter == 'Low Risk') return riskScore < RiskConstants.mediumThreshold;
      return true;
    }).toList();
  }

  void _fitCameraToBounds() {
    try {
      if (widget.selectedRegion != null) {
        final point = _regionPoint(widget.selectedRegion!);
        if (point == null) return;
        _mapController.move(point, 9.8);
        return;
      }

      if (_regions.isEmpty) return;

      final points = _regions
          .map(_regionPoint)
          .whereType<LatLng>()
          // Strictly filter out any point whose lat/lng is not a real finite number.
          .where((p) =>
              p.latitude.isFinite &&
              p.longitude.isFinite &&
              !p.latitude.isNaN &&
              !p.longitude.isNaN)
          .toList();

      if (points.isEmpty) return;

      if (points.length == 1) {
        _mapController.move(points.first, 13.0);
        return;
      }

      final bounds = LatLngBounds.fromPoints(points);

      // Guard against degenerate (zero-size) bounding boxes —
      // these occur when all points share the same lat or lng,
      // causing flutter_map's fitCamera to divide-by-zero and produce NaN.
      final latSpan = bounds.north - bounds.south;
      final lngSpan = bounds.east - bounds.west;
      if (latSpan < 0.001 || lngSpan < 0.001 || !latSpan.isFinite || !lngSpan.isFinite) {
        _mapController.move(points.first, 7.0);
        return;
      }

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (e) {
      // Silently swallow any residual engine NaN errors during camera fit.
      debugPrint('Camera fit skipped: $e');
    }
  }

  double? _asDouble(dynamic value) {
    double? val;
    if (value is num) {
      val = value.toDouble();
    } else if (value is String) {
      val = double.tryParse(value.trim());
    }
    if (val != null && (val.isNaN || val.isInfinite)) return null;
    return val;
  }

  LatLng? _regionPoint(Map<String, dynamic> region) {
    final lat = _asDouble(region['latitude']);
    final lng = _asDouble(region['longitude']);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  double _regionRiskScore(Map<String, dynamic> region) {
    return _asDouble(region['current_risk_score']) ?? 0.0;
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore >= RiskConstants.criticalThreshold) {
      return Colors.red;
    } else if (riskScore >= RiskConstants.highThreshold) {
      return Colors.orange;
    } else if (riskScore >= RiskConstants.mediumThreshold) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  String _getRiskLabel(double riskScore) {
    if (riskScore >= RiskConstants.criticalThreshold) return 'Critical Risk';
    if (riskScore >= RiskConstants.highThreshold) return 'High Risk';
    if (riskScore >= RiskConstants.mediumThreshold) return 'Medium Risk';
    return 'Low Risk';
  }

  List<String> _riskExplanation(Map<String, dynamic> region, double riskScore) {
    final regionName = region['name']?.toString() ?? 'This region';
    if (riskScore >= RiskConstants.criticalThreshold) {
      return [
        '$regionName has a very high model score.',
        'Heavy rainfall, steep terrain, or weak soil may be active factors.',
        'Avoid unstable slopes and follow authority instructions.',
      ];
    }
    if (riskScore >= RiskConstants.highThreshold) {
      return [
        '$regionName is showing high warning signals.',
        'Rainfall and terrain conditions can increase landslide probability.',
        'Limit travel near slopes and watch for fresh cracks or falling rocks.',
      ];
    }
    if (riskScore >= RiskConstants.mediumThreshold) {
      return [
        '$regionName has moderate risk indicators.',
        'Weather or slope conditions need monitoring before they worsen.',
        'Stay updated and avoid unnecessary movement during rain.',
      ];
    }
    return [
      '$regionName is currently under low risk.',
      'Model signals are below the danger threshold.',
      'Continue normal caution in steep or rain-affected areas.',
    ];
  }

  void _showRegionDetails(Map<String, dynamic> region) {
    final riskScore = _regionRiskScore(region);
    final color = _getRiskColor(riskScore);
    final explanation = _riskExplanation(region, riskScore);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.mapPin, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                region['name'] ?? 'Unknown Region',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('District', region['district'] ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow('Risk Level', _getRiskLabel(riskScore)),
            const SizedBox(height: 8),
            _buildInfoRow('Risk Score', '${(riskScore * 100).toInt()}%'),
            const SizedBox(height: 20),
            Text(
              context.read<LanguageProvider>().tr('Why this alert?'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...explanation.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.circle, size: 8, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.read<LanguageProvider>().tr(reason),
                        style: const TextStyle(fontSize: 12, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    riskScore >= RiskConstants.criticalThreshold 
                        ? LucideIcons.alertOctagon 
                        : riskScore >= RiskConstants.mediumThreshold 
                            ? LucideIcons.alertTriangle 
                            : LucideIcons.checkCircle,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      riskScore >= RiskConstants.criticalThreshold 
                          ? 'Critical landslide risk - Evacuate if advised'
                          : riskScore >= RiskConstants.highThreshold 
                              ? 'High risk - Exercise extreme caution'
                              : riskScore >= RiskConstants.mediumThreshold 
                                  ? 'Medium risk - Stay informed'
                                  : 'Low risk - Safe conditions verified',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.read<LanguageProvider>().tr('Dismiss')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    const systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0F172A), // Dark Navy Background
      statusBarIconBrightness: Brightness.light, // White Text/Icons
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: Scaffold(
      // Light scaffold background
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'recenter_risk_map',
        onPressed: () async {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(context.read<LanguageProvider>().tr('Getting your location...')),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          if (_userPosition != null) {
            // User position already available, just center on it
            _mapController.move(_userPosition!, 15.0);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(context.read<LanguageProvider>().tr('Centered on your location')),
                  ],
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Try to get user position
            await _getCurrentLocation();
            if (_userPosition != null) {
              _mapController.move(_userPosition!, 15.0);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(context.read<LanguageProvider>().tr('Centered on your location')),
                    ],
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              // Location not available, show error and fit to regions
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(context.read<LanguageProvider>().tr('Location unavailable. Please enable GPS.')),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                ),
              );
              _fitCameraToBounds();
            }
          }
        },
        // FAB uses accentTeal
        backgroundColor: AppTheme.accentTeal,
        elevation: 4,
        child: const Icon(LucideIcons.navigation, color: Colors.white, size: 24),
      ).animate().scale(begin: const Offset(0, 0), delay: 600.ms),
      appBar: AppBar(
        // White AppBar with dark text/icons
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.selectedRegion == null
              ? context.watch<LanguageProvider>().tr('Interactive Risk Map')
              : widget.selectedRegion!['name']?.toString() ??
                  context.watch<LanguageProvider>().tr('Risk Map'),
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppTheme.accentTeal),
            onPressed: () {
              _loadRegions();
              _getCurrentLocation();
            },
            tooltip: context.read<LanguageProvider>().tr('Refresh All Data'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.accentTeal,
                  ),
                  const SizedBox(height: 16),
                  Text(context.watch<LanguageProvider>().tr('Fetching live risk map...')),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialMapCenter,
                    initialZoom: _initialMapZoom,
                    minZoom: 4.0,
                    maxZoom: 16.0,
                    onMapReady: _scheduleCameraFit,
                    // Disables fling/inertia animation — the root cause of the
                    // LatLng(NaN, NaN) crash on Android. The physics deceleration
                    // divides by a near-zero timestep producing NaN coordinates.
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.flingAnimation,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hillsafe.app',
                      maxNativeZoom: 19,
                      errorTileCallback: (tile, error, stackTrace) {
                        debugPrint('Base map tile failed: $tile - $error');
                      },
                    ),
                    if (_showSatellite)
                      TileLayer(
                        urlTemplate:
                            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.png',
                        userAgentPackageName: 'com.hillsafe.app',
                        maxNativeZoom: 18,
                        tileBuilder: (context, tileWidget, tile) {
                          return Opacity(
                            opacity: 0.88,
                            child: tileWidget,
                          );
                        },
                        errorTileCallback: (tile, error, stackTrace) {
                          debugPrint('Satellite map tile failed: $tile - $error');
                        },
                      ),
                    
                    CircleLayer(
                      circles: _filteredRegions.map((region) {
                        final point = _regionPoint(region);
                        if (point == null) return null;
                        final riskScore = _regionRiskScore(region);
                        final color = _getRiskColor(riskScore);
                        final radius = RiskConstants.getCircleRadius(riskScore);
                        
                        return CircleMarker(
                          point: point,
                          radius: widget.selectedRegion == null ? 30.0 : 60.0, 
                          useRadiusInMeter: false,
                          color: color.withOpacity(widget.selectedRegion == null ? 0.2 : 0.14),
                          borderColor: color.withOpacity(0.75),
                          borderStrokeWidth: widget.selectedRegion == null ? 2 : 1.5,
                        );
                      }).whereType<CircleMarker>().toList(),
                    ),
                    
                    MarkerLayer(
                      markers: [
                        // User Position Marker
                        if (_userPosition != null)
                          Marker(
                            point: _userPosition!,
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing outer circle — using accentTeal for user location
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentTeal.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                ).animate(
                                  onPlay: (controller) => controller.repeat(),
                                ).scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.2, 1.2),
                                  duration: 1500.ms,
                                ).fadeOut(duration: 1500.ms),
                                // Inner solid circle
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentTeal,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Region Markers
                        ..._filteredRegions.map((region) {
                        final point = _regionPoint(region);
                        if (point == null) return null;
                        final riskScore = _regionRiskScore(region);
                        final color = _getRiskColor(riskScore);
                        
                        return Marker(
                          point: point,
                          width: 140,
                          height: 60,
                          child: GestureDetector(
                            onTap: () => _showRegionDetails(region),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                    border: Border.all(color: color.withOpacity(0.5)),
                                  ),
                                    child: Text(
                                    region['name'] ?? 'Region',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(LucideIcons.mapPin, color: color, size: 24),
                              ],
                            ),
                          ),
                        );
                      }).whereType<Marker>().toList(),
                    ],
                  ),
                ],
              ),
                
                if (widget.selectedRegion == null)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: ['All', 'Critical', 'High Risk', 'Medium Risk', 'Low Risk'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(context.watch<LanguageProvider>().tr(filter)),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedFilter = filter);
                              },
                              // Selected chip uses accentTeal
                              selectedColor: AppTheme.accentTeal,
                              backgroundColor: AppTheme.surface,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Legend
                Positioned(
                  bottom: 24,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Legend',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        _buildLegendItem(Colors.green, 'Low (< 30%)'),
                        _buildLegendItem(Colors.orange, 'Moderate (30-70%)'),
                        _buildLegendItem(Colors.red, 'High (> 70%)'),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),
                Positioned(
                  top: widget.selectedRegion == null ? 76 : 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => setState(() => _showSatellite = !_showSatellite),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _showSatellite ? AppTheme.primaryDark : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor.withOpacity(0.4), width: 1),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showSatellite ? LucideIcons.map : LucideIcons.globe,
                            color: _showSatellite ? Colors.white : AppTheme.accentTeal,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            _showSatellite ? 'Map View' : 'Satellite',
                            style: TextStyle(
                              color: _showSatellite ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ],
            ),
    ),),);
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
