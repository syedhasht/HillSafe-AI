import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

/// Alert Management Screen — Authority view for creating and broadcasting alerts.
/// Loads real regions from the API; on submit saves to DB and sends push notifications.
class AlertManagementScreen extends StatefulWidget {
  const AlertManagementScreen({super.key});

  @override
  State<AlertManagementScreen> createState() => _AlertManagementScreenState();
}

class _AlertManagementScreenState extends State<AlertManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Form state
  String _severity = 'HIGH';
  Map<String, dynamic>? _selectedRegion;

  // Page state
  List<Map<String, dynamic>> _regions = [];
  bool _loadingRegions = true;
  bool _submitting = false;
  String? _regionLoadError;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _loadingRegions = true;
      _regionLoadError = null;
    });
    try {
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _loadingRegions = false;
          if (regions.isNotEmpty) _selectedRegion = regions.first;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRegions = false;
          _regionLoadError = 'Could not load regions. Tap to retry.';
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null) {
      _showSnack('Please select a region.', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final regionId = _selectedRegion!['id'] as int;
      final result = await _apiService.createAlert(
        regionId: regionId,
        severity: _severity,
        message: _messageController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      final sent = result['notifications_sent'] ?? 0;
      _showSnack(
        '✓ Alert broadcast to $sent device${sent == 1 ? '' : 's'}.',
        isError: false,
      );
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Color _severityColor(String s) {
    switch (s) {
      case 'CRITICAL': return Colors.red.shade700;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.amber;
      default: return Colors.green;
    }
  }

  IconData _severityIcon(String s) {
    switch (s) {
      case 'CRITICAL': return LucideIcons.alertOctagon;
      case 'HIGH': return LucideIcons.alertTriangle;
      case 'MEDIUM': return LucideIcons.alertCircle;
      default: return LucideIcons.info;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Create Alert'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Severity ────────────────────────────────────────────────
              _buildSection(
                icon: LucideIcons.alertTriangle,
                title: 'Severity Level',
                child: _buildSeveritySelector(),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: AppTheme.spacingLarge),

              // ── Region ──────────────────────────────────────────────────
              _buildSection(
                icon: LucideIcons.mapPin,
                title: 'Target Region',
                child: _buildRegionSelector(),
              ).animate().fadeIn(duration: 600.ms, delay: 100.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // ── Message ─────────────────────────────────────────────────
              _buildSection(
                icon: LucideIcons.fileText,
                title: 'Alert Message',
                child: _buildMessageField(),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // ── Preview badge ────────────────────────────────────────────
              if (_selectedRegion != null)
                _buildPreviewBadge()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // ── Broadcast button ─────────────────────────────────────────
              _buildBroadcastButton()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.accentTeal),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          child,
        ],
      ),
    );
  }

  // ── Severity selector ─────────────────────────────────────────────────────────

  Widget _buildSeveritySelector() {
    const severities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    return Wrap(
      spacing: AppTheme.spacingSmall,
      runSpacing: AppTheme.spacingSmall,
      children: severities.map((s) {
        final isSelected = _severity == s;
        final color = _severityColor(s);
        return GestureDetector(
          onTap: () => setState(() => _severity = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : AppTheme.borderColor,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_severityIcon(s),
                    size: 15,
                    color: isSelected ? color : AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  s[0] + s.substring(1).toLowerCase(),
                  style: TextStyle(
                    color: isSelected ? color : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Region selector ───────────────────────────────────────────────────────────

  Widget _buildRegionSelector() {
    if (_loadingRegions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: AppTheme.accentTeal),
        ),
      );
    }

    if (_regionLoadError != null) {
      return GestureDetector(
        onTap: _loadRegions,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.refreshCw, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_regionLoadError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    }

    if (_regions.isEmpty) {
      return Text('No regions available.',
          style: TextStyle(color: AppTheme.textSecondary));
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedRegion,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.accentTeal, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium, vertical: 12),
      ),
      items: _regions.map((region) {
        final name = region['name']?.toString() ?? 'Unknown';
        final district = region['district']?.toString() ?? '';
        return DropdownMenuItem<Map<String, dynamic>>(
          value: region,
          child: Text('$name${district.isNotEmpty ? ', $district' : ''}',
              overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedRegion = value),
      validator: (_) =>
          _selectedRegion == null ? 'Please select a region' : null,
    );
  }

  // ── Message field ─────────────────────────────────────────────────────────────

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      maxLines: 5,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: 'Describe the hazard, what residents should do, evacuation points…',
        hintStyle: TextStyle(color: AppTheme.textHint, fontSize: 13),
        filled: true,
        fillColor: AppTheme.surface,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppTheme.accentTeal, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Alert message is required';
        if (v.trim().length < 10) return 'Message must be at least 10 characters';
        return null;
      },
    );
  }

  // ── Preview badge ─────────────────────────────────────────────────────────────

  Widget _buildPreviewBadge() {
    final color = _severityColor(_severity);
    final regionName = _selectedRegion?['name']?.toString() ?? '';
    final district = _selectedRegion?['district']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_severityIcon(_severity), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_severity[0]}${_severity.substring(1).toLowerCase()} Alert',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14),
                ),
                Text(
                  '$regionName${district.isNotEmpty ? ', $district' : ''}',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              _severity,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Broadcast button ──────────────────────────────────────────────────────────

  Widget _buildBroadcastButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentTeal,
          disabledBackgroundColor: AppTheme.accentTeal.withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.accentTeal.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
        child: _submitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Broadcasting…',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.radio, size: 20),
                  SizedBox(width: 10),
                  Text('Broadcast Alert',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
