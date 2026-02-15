import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:flutter_application_2/constants/risk_constants.dart';

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
  LatLng? _userPosition;
  LatLng? _cachedUserPosition;

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
             _fitCameraToBounds();
          });
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

  List<Map<String, dynamic>> get _filteredRegions {
    if (_selectedFilter == 'All') return _regions;
    return _regions.where((region) {
      final riskScore = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
      if (_selectedFilter == 'High Risk') return riskScore >= RiskConstants.highRiskThreshold;
      if (_selectedFilter == 'Safe Zones') return riskScore < RiskConstants.moderateRiskThreshold;
      return true;
    }).toList();
  }

  void _fitCameraToBounds() {
    if (widget.selectedRegion != null) {
      final lat = (widget.selectedRegion!['latitude'] as num?)?.toDouble() ?? 34.0;
      final lng = (widget.selectedRegion!['longitude'] as num?)?.toDouble() ?? 73.0;
      _mapController.move(LatLng(lat, lng), 13.0);
      return;
    }

    if (_regions.isEmpty) return;

    final points = _regions.map((region) {
      final lat = (region['latitude'] as num?)?.toDouble() ?? 34.0;
      final lng = (region['longitude'] as num?)?.toDouble() ?? 73.0;
      return LatLng(lat, lng);
    }).toList();

    if (points.isEmpty) return;
    
    if (points.length == 1) {
       _mapController.move(points.first, 13.0);
       return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore >= RiskConstants.highRiskThreshold) {
      return Colors.red;
    } else if (riskScore >= RiskConstants.moderateRiskThreshold) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getRiskLabel(double riskScore) {
    if (riskScore >= RiskConstants.highRiskThreshold) return 'High Risk';
    if (riskScore >= RiskConstants.moderateRiskThreshold) return 'Moderate Risk';
    return 'Low Risk';
  }

  void _showRegionDetails(Map<String, dynamic> region) {
    final riskScore = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
    final color = _getRiskColor(riskScore);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                    riskScore >= RiskConstants.highRiskThreshold 
                        ? LucideIcons.alertOctagon 
                        : riskScore >= RiskConstants.moderateRiskThreshold 
                            ? LucideIcons.alertTriangle 
                            : LucideIcons.checkCircle,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      riskScore >= RiskConstants.highRiskThreshold 
                          ? 'High landslide risk - Exercise extreme caution'
                          : riskScore >= RiskConstants.moderateRiskThreshold 
                              ? 'Moderate risk - Stay informed'
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
            child: const Text('Dismiss'),
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
            color: Colors.grey.shade600,
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
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      floatingActionButton: FloatingActionButton(
        heroTag: 'recenter_risk_map',
        onPressed: () async {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Getting your location...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );

          if (_userPosition != null) {
            // User position already available, just center on it
            _mapController.move(_userPosition!, 15.0);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Centered on your location'),
                  ],
                ),
                duration: Duration(seconds: 1),
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
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Centered on your location'),
                    ],
                  ),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              // Location not available, show error and fit to regions
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Location unavailable. Please enable GPS.'),
                      ),
                    ],
                  ),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.orange,
                ),
              );
              _fitCameraToBounds();
            }
          }
        },
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        child: const Icon(LucideIcons.navigation, color: Colors.white, size: 24),
      ).animate().scale(begin: const Offset(0, 0), delay: 600.ms),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Interactive Risk Map'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              _loadRegions();
              _getCurrentLocation();
            },
            tooltip: 'Refresh All Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching live satellite data...'),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(30.3753, 69.3451),
                    initialZoom: 5.5,
                    minZoom: 4.0,
                    maxZoom: 16.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.hillsafe.app',
                    ),
                    
                    CircleLayer(
                      circles: _filteredRegions.map((region) {
                        final riskScore = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
                        final color = _getRiskColor(riskScore);
                        final radius = RiskConstants.getCircleRadius(riskScore);
                        
                        return CircleMarker(
                          point: LatLng(
                            (region['latitude'] as num).toDouble(),
                            (region['longitude'] as num).toDouble(),
                          ),
                          radius: radius, 
                          useRadiusInMeter: true,
                          color: color.withOpacity(0.2),
                          borderColor: color.withOpacity(0.8),
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
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
                                // Pulsing outer circle
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
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
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Region Markers
                        ..._filteredRegions.map((region) {
                        final riskScore = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
                        final color = _getRiskColor(riskScore);
                        
                        return Marker(
                          point: LatLng(
                            (region['latitude'] as num).toDouble(),
                            (region['longitude'] as num).toDouble(),
                          ),
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
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
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
                      }).toList(),
                    ],
                  ),
                ],
              ),
                
                // Filters Top Bar
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: ['All', 'High Risk', 'Safe Zones'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedFilter = filter);
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
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
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4)),
                      ],
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
              ],
            ),
    );
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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}

