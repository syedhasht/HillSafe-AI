import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/theme_provider.dart';

/// Report Incident Screen - Connects to Backend
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  static const int _yourLocationRegionValue = -1;
  static const double _yourLocationReportRadiusKm = 50.0;

  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService();
  final _reportMapController = MapController();
  
  String _incidentType = 'Landslide Risk';
  int? _selectedRegionId = _yourLocationRegionValue;
  double? _latitude;
  double? _longitude;
  List<Map<String, dynamic>> _regions = [];
  bool _isSubmitting = false;
  bool _isLoadingRegions = true;
  bool _isLoadingLocation = false;

  bool get _isYourLocationSelected =>
      _selectedRegionId == _yourLocationRegionValue;

  LatLng get _reportTarget => LatLng(
        _latitude ?? 30.3753,
        _longitude ?? 69.3451,
      );

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadRegions();
    _loadCurrentLocation();
  }

  Future<void> _checkAuthentication() async {
    final isLoggedIn = await _apiService.isLoggedIn();
    if (!isLoggedIn && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(context.read<LanguageProvider>().tr('Please log in to submit reports'))),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navigate to login screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/resident_login');
        }
      });
    }
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _apiService.getCurrentPosition();
      if (position == null) return;

      final locationName = await _apiService.fetchLocationName(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_locationController.text.trim().isEmpty && locationName != null) {
          _locationController.text = locationName;
        }
      });
      _moveReportMap(position.latitude, position.longitude, 11);
    } catch (e) {
      debugPrint('Report location load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _moveReportMap(double latitude, double longitude, double zoom) {
    try {
      _reportMapController.move(LatLng(latitude, longitude), zoom);
    } catch (_) {
      // The map may not be mounted yet during the first GPS lookup.
    }
  }

  void _setReportTarget(LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _locationController.text =
          'Selected coordinates: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    });
    _moveReportMap(point.latitude, point.longitude, 10);
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          if (_selectedRegionId == null && _regions.isNotEmpty) {
            _selectedRegionId = (_regions.first['id'] as num?)?.toInt();
          }
          _isLoadingRegions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRegions = false);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Construct full description with incident type and location
      final fullDescription = '$_incidentType at ${_locationController.text}: ${_descriptionController.text}';
      final isYourLocationReport = _selectedRegionId == _yourLocationRegionValue;
      final submitRegionId = isYourLocationReport ? null : _selectedRegionId;

      debugPrint('=== SUBMITTING INCIDENT REPORT ===');
      debugPrint('Region ID: $_selectedRegionId');
      debugPrint('Description: $fullDescription');

      try {
        final success = await _apiService.submitIncident(
          fullDescription,
          submitRegionId,
          latitude: _latitude,
          longitude: _longitude,
          areaName: _locationController.text.trim(),
          reportRadiusKm: isYourLocationReport ? _yourLocationReportRadiusKm : 50.0,
        );

        debugPrint('Submit result: $success');

        if (mounted) {
          setState(() => _isSubmitting = false);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(LucideIcons.checkCircle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text('✓ Report submitted successfully!')),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Clear form
            _descriptionController.clear();
            _locationController.clear();
            
            // Navigate back after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context);
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(context.read<LanguageProvider>().tr('Failed to submit report. Please try again.'))),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Submit error: $e');
        
        if (mounted) {
          setState(() => _isSubmitting = false);
          
          String errorMessage = 'Error: $e';
          if (e.toString().contains('Unauthorized')) {
            errorMessage = 'Please log in again to submit reports';
          } else if (e.toString().contains('Connection')) {
            errorMessage = 'Connection failed. Please check your internet';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.info, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(context.read<LanguageProvider>().tr('Please fill in all required fields'))),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: Text(context.watch<LanguageProvider>().tr('Report Incident')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner — using light teal palette
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.accentTealLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentTeal.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.info,
                      color: AppTheme.accentTeal,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        context.watch<LanguageProvider>().tr('Your report helps authorities respond quickly to potential hazards.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // Incident Type
              _buildDropdownField()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms),

              const SizedBox(height: AppTheme.spacingMedium),

              // Region Selector
              _buildRegionField()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 150.ms),

              const SizedBox(height: AppTheme.spacingMedium),

              // Location Field
              _buildLocationField()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms),

              const SizedBox(height: AppTheme.spacingMedium),

              if (_isYourLocationSelected) ...[
                _buildCoordinatePicker()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 250.ms),
                const SizedBox(height: AppTheme.spacingMedium),
              ],

              // Description Field
              _buildDescriptionField()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // Submit Button
              _buildSubmitButton()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldWrapper({
    required Widget child,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: AppTheme.bentoCardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppTheme.accentTeal,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                context.watch<LanguageProvider>().tr(label),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    final types = [
      'Landslide Risk',
      'Road Damage',
      'Flooding',
      'Rockfall',
      'Other Hazard',
    ];

    return _buildFieldWrapper(
      label: 'Incident Type',
      icon: LucideIcons.alertTriangle,
      child: DropdownButtonFormField<String>(
        value: _incidentType,
        decoration: AppTheme.inputDecoration(context),
        dropdownColor: AppTheme.surface,
        items: types.map((type) {
          return DropdownMenuItem(value: type, child: Text(context.read<LanguageProvider>().tr(type)));
        }).toList(),
        onChanged: (value) => setState(() => _incidentType = value!),
      ),
    );
  }

  Widget _buildRegionField() {
    if (_isLoadingRegions) {
      return _buildFieldWrapper(
        label: 'Region',
        icon: LucideIcons.map,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.accentTeal,
            ),
          ),
        ),
      );
    }

    if (_regions.isEmpty) {
      return _buildRegionDropdown(includeOnlyYourLocation: true);
    }

    return _buildRegionDropdown();
  }

  Widget _buildRegionDropdown({bool includeOnlyYourLocation = false}) {
    return _buildFieldWrapper(
      label: 'Region',
      icon: LucideIcons.map,
      child: DropdownButtonFormField<int>(
        value: _selectedRegionId,
        decoration: AppTheme.inputDecoration(context),
        dropdownColor: AppTheme.surface,
        items: [
          const DropdownMenuItem<int>(
            value: _yourLocationRegionValue,
            child: Text('Your Location (50 km radius)'),
          ),
          if (!includeOnlyYourLocation)
            ..._regions.map((region) {
              return DropdownMenuItem<int>(
                value: (region['id'] as num).toInt(),
                child: Text(region['name'] as String),
              );
            }),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedRegionId = value);
          if (value == _yourLocationRegionValue && (_latitude == null || _longitude == null)) {
            _loadCurrentLocation();
          } else if (value == _yourLocationRegionValue) {
            _moveReportMap(_latitude!, _longitude!, 11);
          }
        },
        validator: (value) {
          if (value == null) {
            return context.read<LanguageProvider>().tr('Please select a region');
          }
          if (value == _yourLocationRegionValue && (_latitude == null || _longitude == null)) {
            return context.read<LanguageProvider>().tr('Please allow location access to submit your location report');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCoordinatePicker() {
    final target = _reportTarget;

    return _buildFieldWrapper(
      label: 'Target Coordinates',
      icon: LucideIcons.crosshair,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              border: Border.all(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _reportMapController,
              options: MapOptions(
                initialCenter: target,
                initialZoom: _latitude == null || _longitude == null ? 5.5 : 10,
                minZoom: 4,
                maxZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, point) => _setReportTarget(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hillsafe.app',
                  maxNativeZoom: 19,
                ),
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.png',
                  userAgentPackageName: 'com.hillsafe.app',
                  maxNativeZoom: 18,
                  tileBuilder: (context, tileWidget, tile) {
                    return Opacity(opacity: 0.88, child: tileWidget);
                  },
                ),
                if (_latitude != null && _longitude != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: target,
                        radius: _yourLocationReportRadiusKm * 1000,
                        useRadiusInMeter: true,
                        color: AppTheme.accentTeal.withOpacity(0.22),
                        borderColor: AppTheme.accentTeal,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (_latitude != null && _longitude != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: target,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal,
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.tealShadow,
                          ),
                          child: const Icon(
                            LucideIcons.mapPin,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              const Icon(LucideIcons.radar, size: 16, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _latitude == null || _longitude == null
                      ? context.read<LanguageProvider>().tr('Tap the map to select report coordinates')
                      : '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)} • 50 km radius',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return _buildFieldWrapper(
      label: 'Specific Location',
      icon: LucideIcons.mapPin,
        child: TextFormField(
          controller: _locationController,
          decoration: AppTheme.inputDecoration(context).copyWith(
            hintText: context.read<LanguageProvider>().tr('e.g., Near Mall Road, Main Bazaar'),
            suffixIcon: _isLoadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.accentTeal,
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: context.read<LanguageProvider>().tr('Use current location'),
                    icon: const Icon(LucideIcons.locateFixed, color: AppTheme.accentTeal),
                    onPressed: _loadCurrentLocation,
                  ),
          ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.read<LanguageProvider>().tr('Please enter the specific location');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _buildFieldWrapper(
      label: 'Description',
      icon: LucideIcons.fileText,
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        decoration: AppTheme.inputDecoration(context).copyWith(
          hintText: context.read<LanguageProvider>().tr('Describe what you observed in detail...'),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.read<LanguageProvider>().tr('Please describe the incident');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accentTeal,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.tealShadow,
      ),
      child: ElevatedButton(
        onPressed: (_isSubmitting || _isLoadingRegions) ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                context.watch<LanguageProvider>().tr('Submit Report'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}
