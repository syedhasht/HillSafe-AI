import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
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

class _AuthorityMapScreenState extends State<AuthorityMapScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  bool _showHeatmap = false;
  List<Map<String, dynamic>> _regions = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  // Pakistan center
  static const LatLng _pakistanCenter = LatLng(34.0, 71.5);

  @override
  void initState() {
    super.initState();
    _loadRegions();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRegions();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoading = false;
          _errorMessage = null;
        });
        // Fit camera to show all region markers after load
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
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
    final points = _regions
        .map(_regionLatLng)
        .whereType<LatLng>()
        .toList();

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController.move(points.first, 10.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(60, 140, 60, 300),
      ),
    );
  }

  LatLng? _regionLatLng(Map<String, dynamic> region) {
    final lat = _asDouble(region['latitude']);
    final lng = _asDouble(region['longitude']);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  double _regionRiskScore(Map<String, dynamic> region) =>
      _asDouble(region['current_risk_score']) ?? 0.0;

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
    context.watch<ThemeProvider>();
    return Scaffold(
      // Light scaffold background — map fills the body, scaffold just shows in safe area
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Real Map ──────────────────────────────────────────────────
            _buildMap(),

            // ── Top App Bar (white bg, dark text) ─────────────────────────
            _buildTopBar(),

            // ── Heatmap Toggle (top-right) ────────────────────────────────
            Positioned(
              top: 72,
              right: AppTheme.spacingMedium,
              child: _buildHeatmapButton()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms)
                  .slideX(begin: 0.2, end: 0),
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
                  child: CircularProgressIndicator(color: AppTheme.accentTeal),
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
          ],
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
      ),
      children: [
        // Base OSM tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hillsafe.app',
          maxNativeZoom: 19,
        ),

        // ── Heatmap: semi-transparent filled circles per region ──
        if (_showHeatmap && _regions.isNotEmpty)
          CircleLayer(
            circles: _regions.map((region) {
              final point = _regionLatLng(region);
              if (point == null) return null;
              final color = _riskColor(_regionRiskScore(region));
              final riskScore = _regionRiskScore(region);
              // Larger radius for heatmap blobs
              final radius = RiskConstants.getCircleRadius(riskScore) * 3.5;
              return CircleMarker(
                point: point,
                radius: radius,
                useRadiusInMeter: true,
                color: color.withOpacity(0.28),
                borderColor: color.withOpacity(0.55),
                borderStrokeWidth: 1.5,
              );
            }).whereType<CircleMarker>().toList(),
          ),

        // ── Always-visible risk circles (smaller) ──
        if (_regions.isNotEmpty)
          CircleLayer(
            circles: _regions.map((region) {
              final point = _regionLatLng(region);
              if (point == null) return null;
              final riskScore = _regionRiskScore(region);
              final color = _riskColor(riskScore);
              final radius = RiskConstants.getCircleRadius(riskScore);
              return CircleMarker(
                point: point,
                radius: radius,
                useRadiusInMeter: true,
                color: color.withOpacity(0.18),
                borderColor: color.withOpacity(0.8),
                borderStrokeWidth: 2.0,
              );
            }).whereType<CircleMarker>().toList(),
          ),

        // ── Region name + pin markers ──
        if (_regions.isNotEmpty)
          MarkerLayer(
            markers: _regions.map((region) {
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
            }).whereType<Marker>().toList(),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  // ── Heatmap button ─────────────────────────────────────────────────────────

  Widget _buildHeatmapButton() {
    const activeColor = Colors.red;
    return GestureDetector(
      onTap: () => setState(() => _showHeatmap = !_showHeatmap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showHeatmap
              ? activeColor.withOpacity(0.85)
              : AppTheme.surface,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            _infoRow(
                'Risk Score', '${(riskScore * 100).toInt()}%'),
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
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
