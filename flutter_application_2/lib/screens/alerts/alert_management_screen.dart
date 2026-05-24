import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';

/// Alert Management Screen - For Authorities to Create Alerts
/// Professional alert creation interface with severity levels and targeting
class AlertManagementScreen extends StatefulWidget {
  const AlertManagementScreen({super.key});

  @override
  State<AlertManagementScreen> createState() => _AlertManagementScreenState();
}

class _AlertManagementScreenState extends State<AlertManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _severity = 'High';
  String _selectedDistrict = 'Murree';
  bool _sendSMS = true;
  bool _sendPushNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Create Alert'),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Alert sent successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'SEND',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity Selection
              _buildSeveritySelector()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: AppTheme.spacingLarge),

              // Title Field
              _buildTextField(
                label: 'Alert Title',
                hint: 'e.g., Heavy Rainfall Warning',
                icon: LucideIcons.type,
                maxLines: 1,
              ).animate().fadeIn(duration: 600.ms, delay: 100.ms),

              const SizedBox(height: AppTheme.spacingMedium),

              // Message Field
              _buildTextField(
                label: 'Alert Message',
                hint: 'Detailed warning message for residents...',
                icon: LucideIcons.fileText,
                maxLines: 5,
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // District Selection
              _buildDistrictSelector()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // Delivery Options
              _buildDeliveryOptions()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms),

              const SizedBox(height: AppTheme.spacingLarge),

              // Send Button
              _buildSendButton()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 500.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeveritySelector() {
    final severities = [
      {'level': 'Critical', 'color': Colors.red.shade700},
      {'level': 'High', 'color': Colors.red},
      {'level': 'Moderate', 'color': Colors.orange},
      {'level': 'Low', 'color': Colors.amber},
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Severity Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Wrap(
            spacing: AppTheme.spacingSmall,
            runSpacing: AppTheme.spacingSmall,
            children: severities.map((s) {
              final isSelected = _severity == s['level'];
              return GestureDetector(
                onTap: () => setState(() => _severity = s['level'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: AppTheme.spacingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (s['color'] as Color).withOpacity(0.2)
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (s['color'] as Color)
                          : Theme.of(context).dividerColor,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    s['level'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? (s['color'] as Color)
                          : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          TextFormField(
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
              ),
              contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictSelector() {
    final districts = ['Murree', 'Swat', 'Abbottabad', 'Mansehra', 'All Districts'];

    return Container(
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
            children: [
              Icon(LucideIcons.mapPin, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Target District',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
            ),
            items: districts.map((district) {
              return DropdownMenuItem(
                value: district,
                child: Text(district),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedDistrict = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Container(
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
            children: [
              const Icon(LucideIcons.send, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Delivery Options',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          CheckboxListTile(
            title: const Text('Send SMS'),
            subtitle: const Text('Alert via text message'),
            value: _sendSMS,
            onChanged: (value) => setState(() => _sendSMS = value!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Push Notification'),
            subtitle: const Text('In-app notification'),
            value: _sendPushNotification,
            onChanged: (value) => setState(() => _sendPushNotification = value!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Alert broadcast initiated'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.send, size: 20),
            SizedBox(width: AppTheme.spacingSmall),
            Text(
              'Broadcast Alert',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
