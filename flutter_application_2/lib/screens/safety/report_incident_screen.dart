import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/services/api_service.dart';

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
  List<Map<String, dynamic>> _regions = [];
  bool _isSubmitting = false;
  bool _isLoadingRegions = true;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadRegions();
  }

  Future<void> _checkAuthentication() async {
    final isLoggedIn = await _apiService.isLoggedIn();
    if (!isLoggedIn && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(LucideIcons.alertCircle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please log in to submit reports')),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navigate to login screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
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
                  children: const [
                    Icon(LucideIcons.alertCircle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text('Failed to submit report. Please try again.')),
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
            children: const [
              Icon(LucideIcons.info, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please fill in all required fields')),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).appBarTheme.backgroundColor
            : AppTheme.primaryColor,
        title: const Text('Report Incident'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade300
                          : AppTheme.accentBlue,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        'Your report helps authorities respond quickly to potential hazards.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.shade100
                              : Colors.blue.shade900,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: isDark ? AppTheme.bentoCardDark : AppTheme.bentoCardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Theme.of(context).colorScheme.primary : AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
        dropdownColor: Theme.of(context).cardTheme.color,
        items: types.map((type) {
          return DropdownMenuItem(value: type, child: Text(type));
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
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_regions.isEmpty) {
      return _buildFieldWrapper(
        label: 'Region',
        icon: LucideIcons.map,
        child: const Text('No regions available'),
      );
    }

    return _buildFieldWrapper(
      label: 'Region',
      icon: LucideIcons.map,
      child: DropdownButtonFormField<int>(
        value: _selectedRegionId,
        decoration: AppTheme.inputDecoration(context),
        dropdownColor: Theme.of(context).cardTheme.color,
        items: _regions.map((region) {
          return DropdownMenuItem(
            value: (region['id'] as num).toInt(),
            child: Text(region['name'] as String),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedRegionId = value!),
        validator: (value) => value == null ? 'Please select a region' : null,
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
          hintText: 'e.g., Near Mall Road, Main Bazaar',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the specific location';
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
          hintText: 'Describe what you observed in detail...',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please describe the incident';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
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
            : const Text(
                'Submit Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}
