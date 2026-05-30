import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService();
  
  String _incidentType = 'Landslide Risk';
  int? _selectedRegionId;
  double? _latitude;
  double? _longitude;
  List<Map<String, dynamic>> _regions = [];
  bool _isSubmitting = false;
  bool _isLoadingRegions = true;
  bool _isLoadingLocation = false;

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
    } catch (e) {
      debugPrint('Report location load error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          if (_regions.isNotEmpty) {
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

      debugPrint('=== SUBMITTING INCIDENT REPORT ===');
      debugPrint('Region ID: $_selectedRegionId');
      debugPrint('Description: $fullDescription');

      try {
        final success = await _apiService.submitIncident(
          fullDescription,
          _selectedRegionId!,
          latitude: _latitude,
          longitude: _longitude,
          areaName: _locationController.text.trim(),
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
      return _buildFieldWrapper(
        label: 'Region',
        icon: LucideIcons.map,
        child: Text(context.read<LanguageProvider>().tr('No regions available')),
      );
    }

    return _buildFieldWrapper(
      label: 'Region',
      icon: LucideIcons.map,
      child: DropdownButtonFormField<int>(
        value: _selectedRegionId,
        decoration: AppTheme.inputDecoration(context),
        dropdownColor: AppTheme.surface,
        items: _regions.map((region) {
          return DropdownMenuItem(
            value: (region['id'] as num).toInt(),
            child: Text(region['name'] as String),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedRegionId = value!),
        validator: (value) => value == null ? context.read<LanguageProvider>().tr('Please select a region') : null,
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
