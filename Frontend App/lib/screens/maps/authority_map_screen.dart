import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/services/map_update_service.dart';
import 'package:frontend_app/constants/risk_constants.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

/// Authority Map Screen - "War Room" View
/// Full-screen real map with per-region heatmap controls
class AuthorityMapScreen extends StatefulWidget {
  const AuthorityMapScreen({super.key});

  @override
  State<AuthorityMapScreen> createState() => _AuthorityMapScreenState();
}

class _AuthorityMapScreenState extends State<AuthorityMapScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  bool _showHeatmap = false;
  bool _showSatellite = false;
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _reportZones = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<String>? _mapUpdateSubscription;

  // Verification overlay state
  bool _isVerifyingLocation = false;
  LatLng? _verificationCoords;
  String? _verificationName;
  String? _verificationType;
  bool _isFirstLoad = true;
  bool _isMapReady = false;
  int _tileRefreshNonce = 0;

  // Pakistan center
  static const LatLng _pakistanCenter = LatLng(34.0, 71.5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRegions();
    _mapUpdateSubscription = MapUpdateService.instance.updates.listen((_) {
      _loadRegions();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRegions();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      _isFirstLoad = false;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final double? lat = args['latitude'];
        final double? lon = args['longitude'];
        if (lat != null && lon != null) {
          _isVerifyingLocation = true;
          _verificationCoords = LatLng(lat, lon);
          _verificationName = args['name']?.toString() ?? 'Resident';
          _verificationType = args['type']?.toString() ?? 'SAFE';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusVerificationLocation();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapUpdateSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    try {
      final results = await Future.wait([
        _apiService.fetchRegions(),
        _apiService.fetchActiveReportZones(),
      ]);
      final regions = results[0];
      final reportZones = results[1];
      if (mounted) {
        setState(() {
          _regions = regions;
          _reportZones = reportZones;
          _isLoading = false;
          _errorMessage = null;
        });
        // Fit camera to show all region markers after load (only if NOT verifying a specific coordinate)
        if (!_isVerifyingLocation) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusVerificationLocation();
            _refreshMapTiles();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load regions';
        });
      }
    }
  }

  void _fitCamera() {
    if (!_isMapReady) return;
    try {
      final points = _regions
          .map(_regionLatLng)
          .whereType<LatLng>()
          .where((p) =>
              p.latitude.isFinite &&
              p.longitude.isFinite &&
              !p.latitude.isNaN &&
              !p.longitude.isNaN)
          .toList();

      if (points.isEmpty) return;

      if (points.length == 1) {
        _mapController.move(points.first, 10.0);
        return;
      }

      final bounds = LatLngBounds.fromPoints(points);

      // Guard against degenerate (zero-size) bounding boxes —
      // these occur when all points share the same lat or lng,
      // causing flutter_map's fitCamera to divide-by-zero → NaN.
      final latSpan = bounds.north - bounds.south;
      final lngSpan = bounds.east - bounds.west;
      if (latSpan < 0.001 ||
          lngSpan < 0.001 ||
          !latSpan.isFinite ||
          !lngSpan.isFinite) {
        _mapController.move(points.first, 7.0);
        return;
      }

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(60, 140, 60, 300),
        ),
      );
    } catch (e) {
      debugPrint('Authority camera fit skipped: $e');
    }
  }

  void _handleMapReady() {
    if (!mounted) return;
    _isMapReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isVerifyingLocation) {
        _focusVerificationLocation();
      } else {
        _fitCamera();
      }
      _refreshMapTiles();
    });
  }

  void _focusVerificationLocation() {
    if (!_isMapReady || _verificationCoords == null) return;
    try {
      _mapController.move(_verificationCoords!, 16.0);
    } catch (e) {
      debugPrint('Authority map verification focus skipped: $e');
    }
  }

  void _refreshMapTiles() {
    if (!mounted) return;
    setState(() => _tileRefreshNonce++);
  }

  LatLng? _regionLatLng(Map<String, dynamic> region) {
    final lat = _asDouble(region['latitude']);
    final lng = _asDouble(region['longitude']);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  double? _asDouble(dynamic v) {
    double? val;
    if (v is num) {
      val = v.toDouble();
    } else if (v is String) {
      val = double.tryParse(v.trim());
    }
    if (val != null && (val.isNaN || val.isInfinite)) return null;
    return val;
  }

  double _regionRiskScore(Map<String, dynamic> region) =>
      _asDouble(region['current_risk_score']) ?? 0.0;

  Color _reportZoneColor(Map<String, dynamic> report) {
    switch (report['hazard_level']?.toString().toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFF7F1D1D);
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _showReportZoneDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${report['hazard_level']} Resident Report'),
        content: Text(
          '${report['area_name'] ?? report['region_name'] ?? 'Reported location'}\n\n'
          '${report['description'] ?? ''}\n\nApproved radius: 20 km',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // ── Colour helpers ────────────────────────────────────────────────────────

  Color _riskColor(double score) {
    if (score >= RiskConstants.criticalThreshold) return Colors.red;
    if (score >= RiskConstants.highThreshold) return Colors.orange;
    if (score >= RiskConstants.mediumThreshold) return Colors.amber;
    return Colors.green;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
        // Light scaffold background — map fills the body, scaffold just shows in safe area
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Real Map ──────────────────────────────────────────────────
              _buildMap(),

              // ── Top App Bar (white bg, dark text) ─────────────────────────
              _buildTopBar(),

              // ── Toggles (top-right) ────────────────────────────────
              Positioned(
                top: 72,
                right: AppTheme.spacingMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSatelliteButton()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 300.ms)
                        .slideX(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    _buildHeatmapButton()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideX(begin: 0.2, end: 0),
                  ],
                ),
              ),

              // ── Recenter FAB ──────────────────────────────────────────────
              Positioned(
                bottom: 24,
                right: AppTheme.spacingMedium,
                child: FloatingActionButton.small(
                  heroTag: 'war_room_recenter',
                  backgroundColor: AppTheme.surface,
                  onPressed: _fitCamera,
                  child: Icon(
                    LucideIcons.maximize2,
                    color: AppTheme.accentTeal,
                    size: 18,
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ),

              // ── Loading Overlay ───────────────────────────────────────────
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentTeal),
                  ),
                ),

              // ── Error Banner ──────────────────────────────────────────────
              if (_errorMessage != null && !_isLoading)
                Positioned(
                  top: 72,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.refreshCw,
                              color: Colors.white, size: 14),
                          onPressed: () {
                            setState(() => _errorMessage = null);
                            _loadRegions();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Verification HUD (bottom center-left) ──
              if (_isVerifyingLocation && _verificationCoords != null)
                Positioned(
                  bottom: 24,
                  left: AppTheme.spacingMedium,
                  right: 76, // Leave room for recenter FAB on the right
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _verificationType == 'SOS'
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _verificationType == 'SOS'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _verificationType == 'SOS'
                              ? LucideIcons.siren
                              : LucideIcons.shieldCheck,
                          color: _verificationType == 'SOS'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VERIFYING ${_verificationType} LOCATION',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: _verificationType == 'SOS'
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _verificationName!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Clear / Close button
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isVerifyingLocation = false;
                              _verificationCoords = null;
                              _verificationName = null;
                              _verificationType = null;
                            });
                            _fitCamera(); // Re-center map to normal bounds
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            backgroundColor: _verificationType == 'SOS'
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDCFCE7),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Exit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _verificationType == 'SOS'
                                  ? const Color(0xFFB91C1C)
                                  : const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  // ── Map widget ─────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pakistanCenter,
        initialZoom: 6.0,
        minZoom: 4.0,
        maxZoom: 16.0,
        onMapReady: _handleMapReady,
        // Disables fling/inertia animation — the root cause of the
        // LatLng(NaN, NaN) crash on Android. The physics deceleration
        // divides by a near-zero timestep producing NaN coordinates.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.flingAnimation,
        ),
      ),
      children: [
        // Base tile layer
        TileLayer(
          key: ValueKey(
              'authority-tiles-${_showSatellite ? 'satellite' : 'street'}-$_tileRefreshNonce'),
          urlTemplate: _showSatellite
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: _showSatellite ? const [] : const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.hillsafe.app',
          maxNativeZoom: 19,
        ),

        // ── Heatmap: semi-transparent filled circles per region ──
        if (_showHeatmap && _regions.isNotEmpty)
          CircleLayer(
            circles: _regions
                .map((region) {
                  final point = _regionLatLng(region);
                  if (point == null) return null;
                  final color = _riskColor(_regionRiskScore(region));
                  return CircleMarker(
                    point: point,
                    radius: RiskConstants.hazardZoneRadiusMeters,
                    useRadiusInMeter: true,
                    color: color.withOpacity(0.12),
                    borderColor: color.withOpacity(0.75),
                    borderStrokeWidth: 2,
                  );
                })
                .whereType<CircleMarker>()
                .toList(),
          ),

        // ── Always-visible risk circles (smaller) ──
        if (_regions.isNotEmpty && !_showHeatmap)
          CircleLayer(
            circles: _regions
                .map((region) {
                  final point = _regionLatLng(region);
                  if (point == null) return null;
                  final riskScore = _regionRiskScore(region);
                  final color = _riskColor(riskScore);
                  return CircleMarker(
                    point: point,
                    radius: RiskConstants.hazardZoneRadiusMeters,
                    useRadiusInMeter: true,
                    color: color.withOpacity(0.08),
                    borderColor: color.withOpacity(0.8),
                    borderStrokeWidth: 2.0,
                  );
                })
                .whereType<CircleMarker>()
                .toList(),
          ),

        // ── Region name + pin markers ──
        if (_reportZones.isNotEmpty)
          CircleLayer(
            circles: _reportZones
                .map((report) {
                  final point = _regionLatLng(report);
                  if (point == null) return null;
                  final color = _reportZoneColor(report);
                  return CircleMarker(
                    point: point,
                    radius: RiskConstants.hazardZoneRadiusMeters,
                    useRadiusInMeter: true,
                    color: color.withOpacity(0.14),
                    borderColor: color,
                    borderStrokeWidth: 3,
                  );
                })
                .whereType<CircleMarker>()
                .toList(),
          ),

        if (_regions.isNotEmpty ||
            _reportZones.isNotEmpty ||
            (_isVerifyingLocation && _verificationCoords != null))
          MarkerLayer(
            markers: [
              ..._regions
                  .map((region) {
                    final point = _regionLatLng(region);
                    if (point == null) return null;
                    final riskScore = _regionRiskScore(region);
                    final color = _riskColor(riskScore);
                    final name = region['name']?.toString() ?? 'Region';

                    return Marker(
                      point: point,
                      width: 120,
                      height: 52,
                      child: GestureDetector(
                        onTap: () => _showRegionDetails(region),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border:
                                    Border.all(color: color.withOpacity(0.6)),
                              ),
                              child: Text(
                                name.length > 12
                                    ? '${name.substring(0, 12)}…'
                                    : name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  color: color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(LucideIcons.mapPin, color: color, size: 20),
                          ],
                        ),
                      ),
                    );
                  })
                  .whereType<Marker>()
                  .toList(),

              ..._reportZones
                  .map((report) {
                    final point = _regionLatLng(report);
                    if (point == null) return null;
                    final color = _reportZoneColor(report);
                    return Marker(
                      point: point,
                      width: 145,
                      height: 58,
                      child: GestureDetector(
                        onTap: () => _showReportZoneDetails(report),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: color),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${report['hazard_level']} Report',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9),
                              ),
                            ),
                            Icon(LucideIcons.triangleAlert,
                                color: color, size: 23),
                          ],
                        ),
                      ),
                    );
                  })
                  .whereType<Marker>()
                  .toList(),

              // If verifying a location, add the custom verification pin!
              if (_isVerifyingLocation && _verificationCoords != null)
                Marker(
                  point: _verificationCoords!,
                  width: 160,
                  height: 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A), // Premium Dark Navy
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _verificationType == 'SOS'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '${_verificationName} (${_verificationType})',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Pulsing beacon pin!
                      Animate(
                        onInit: (controller) =>
                            controller.repeat(reverse: true),
                        effects: const [
                          ScaleEffect(
                              begin: Offset(0.8, 0.8),
                              end: Offset(1.2, 1.2),
                              duration: Duration(milliseconds: 1000),
                              curve: Curves.easeInOut),
                        ],
                        child: Icon(
                          _verificationType == 'SOS'
                              ? LucideIcons.siren
                              : LucideIcons.shieldCheck,
                          color: _verificationType == 'SOS'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  // ── Top bar (white bg, dark text) ─────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'War Room',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${_regions.length} Regions Monitored',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const Spacer(),
          // LIVE badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(end: 1.4, duration: 900.ms)
                    .then()
                    .scaleXY(end: 1.0, duration: 900.ms),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggles ─────────────────────────────────────────────────────────

  Widget _buildSatelliteButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSatellite = !_showSatellite;
          _tileRefreshNonce++;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showSatellite ? AppTheme.primaryDark : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showSatellite ? LucideIcons.map : LucideIcons.globe,
              color: _showSatellite ? Colors.white : AppTheme.textPrimary,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              _showSatellite ? 'Map View' : 'Satellite',
              style: TextStyle(
                color: _showSatellite ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapButton() {
    const activeColor = Colors.red;
    return GestureDetector(
      onTap: () => setState(() => _showHeatmap = !_showHeatmap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              _showHeatmap ? activeColor.withOpacity(0.85) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showHeatmap ? LucideIcons.eye : LucideIcons.eyeOff,
              color: _showHeatmap ? Colors.white : AppTheme.accentTeal,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
              style: TextStyle(
                color: _showHeatmap ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Region detail dialog ───────────────────────────────────────────────────

  void _showRegionDetails(Map<String, dynamic> region) {
    final riskScore = _regionRiskScore(region);
    final color = _riskColor(riskScore);
    final name = region['name']?.toString() ?? 'Unknown';
    final district = region['district']?.toString() ?? 'N/A';
    final label = riskScore >= RiskConstants.criticalThreshold
        ? 'Critical Risk'
        : riskScore >= RiskConstants.highThreshold
            ? 'High Risk'
            : riskScore >= RiskConstants.mediumThreshold
                ? 'Medium Risk'
                : 'Low Risk';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.mapPin, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('District', district),
            const SizedBox(height: 10),
            _infoRow('Risk Level', label),
            const SizedBox(height: 6),
            _infoRow('Risk Score', '${(riskScore * 100).toInt()}%'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
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
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      riskScore >= RiskConstants.criticalThreshold
                          ? 'Critical — Evacuate if advised'
                          : riskScore >= RiskConstants.highThreshold
                              ? 'High risk — Exercise extreme caution'
                              : riskScore >= RiskConstants.mediumThreshold
                                  ? 'Medium risk — Stay informed'
                                  : 'Low risk — Safe conditions',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600),
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
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
