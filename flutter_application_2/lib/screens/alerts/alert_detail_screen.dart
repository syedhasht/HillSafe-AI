import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Alert Detail Screen - Critical Warning Display
/// High urgency design with red/black theme for critical alerts
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alert = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final severity = (alert['severity'] as String).toUpperCase();
    final isCritical = severity == 'CRITICAL';
    
    // Theme colors based on severity
    final themeColor = _getSeverityColor(severity);
    final bgColor = isCritical ? const Color(0xFF0F0F0F) : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with close button
              _buildHeader(context, severity, themeColor),

              // Critical Alert Banner (Only for Critical/High)
              if (isCritical || severity == 'HIGH')
                _buildCriticalBanner(severity, alert['message'], themeColor)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, end: 0),

              // Alert Info
              _buildAlertInfo(context, alert, themeColor)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: 0.1, end: 0),

              // Map Zone
              _buildMapZone(alert, themeColor)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),

              // Emergency Instructions
              _buildEmergencyInstructions(severity, themeColor)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideY(begin: 0.1, end: 0),

              // Emergency Contacts
              _buildEmergencyContacts(themeColor)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 800.ms)
                  .slideY(begin: 0.1, end: 0),

              // Check-in Button
              _buildCheckInButton(context)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 1000.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
     switch (severity) {
      case 'CRITICAL': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.amber;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildHeader(BuildContext context, String severity, Color color) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(LucideIcons.x, color: color),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.siren,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'ACTIVE $severity ALERT',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
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

  Widget _buildCriticalBanner(String severity, String message, Color color) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingLarge),
      padding: const EdgeInsets.all(AppTheme.spacingXLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            color: Colors.white,
            size: 64,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.2, 1.2),
                duration: 1000.ms,
              )
              .then()
              .scale(
                begin: const Offset(1.2, 1.2),
                end: const Offset(1, 1),
                duration: 1000.ms,
              ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            severity == 'CRITICAL' ? 'EVACUATE NOW' : 'TAKE CAUTION',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertInfo(BuildContext context, Map<String, dynamic> alert, Color color) {
    final population = alert['affected_population'] ?? 0;
    final timestamp = DateTime.parse(alert['timestamp']);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: LucideIcons.mapPin,
              label: 'Location',
              value: '${alert['region_name']}, ${alert['region_district']}',
            ),
            const Divider(color: Colors.grey, height: 24),
            _InfoRow(
              icon: LucideIcons.clock,
              label: 'Issued',
              value: '${timestamp.day}/${timestamp.month} at ${timestamp.hour}:${timestamp.minute}',
            ),
            const Divider(color: Colors.grey, height: 24),
            _InfoRow(
              icon: LucideIcons.alertTriangle,
              label: 'Severity',
              value: '${alert['severity']} - Level ${_getSeverityLevel(alert['severity'])}',
              valueColor: color,
            ),
            const Divider(color: Colors.grey, height: 24),
            _InfoRow(
              icon: LucideIcons.users,
              label: 'Affected Population',
              value: '~$population residents',
            ),
          ],
        ),
      ),
    );
  }

  int _getSeverityLevel(String severity) {
     switch (severity) {
      case 'CRITICAL': return 5;
      case 'HIGH': return 4;
      case 'MEDIUM': return 3;
      case 'LOW': return 1;
      default: return 0;
    }
  }

  Widget _buildMapZone(Map<String, dynamic> alert, Color color) {
    final lat = alert['region_lat'] as double?;
    final lng = alert['region_lng'] as double?;
    
    if (lat == null || lng == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingLarge),
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Stack(
          children: [
            // Flutter Map
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                 TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hillsafe.app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(lat, lng),
                      color: color.withOpacity(0.3),
                      borderColor: color,
                      borderStrokeWidth: 2,
                      radius: 500,
                      useRadiusInMeter: true,
                    ),
                  ],
                ),
                 MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      child: Icon(LucideIcons.alertTriangle, color: color, size: 32),
                    ),
                  ],
                ),
              ],
            ),

            // Map Label
            Positioned(
              top: AppTheme.spacingSmall,
              left: AppTheme.spacingSmall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.map, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Danger Zone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildEmergencyInstructions(String severity, Color color) {
    List<String> instructions;
    
    switch (severity) {
      case 'CRITICAL':
      case 'HIGH':
        instructions = [
          'Move to higher ground immediately',
          'Avoid steep slopes and river banks',
          'Take emergency supplies if safe',
          'Alert your neighbors',
          'Follow designated evacuation routes',
        ];
        break;
      case 'MEDIUM':
        instructions = [
          'Stay informed about changing conditions',
          'Avoid unnecessary travel in risk areas',
          'Prepare emergency kit just in case',
          'Monitor local news channels',
        ];
        break;
      default: // LOW
        instructions = [
          'No immediate danger',
          'Monitor weather updates',
          'Report any unusual soil movement',
        ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.clipboardList,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                const Text(
                  'Emergency Instructions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            ...instructions.map((instruction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts(Color color) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.phone,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            _ContactButton(
              label: 'Rescue Hotline',
              number: '1122',
              icon: LucideIcons.siren,
              color: Colors.red,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _ContactButton(
              label: 'District Office',
              number: '+92-51-9204830',
              icon: LucideIcons.building,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLarge,
        vertical: AppTheme.spacingXLarge,
      ),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Safety check-in recorded'),
              backgroundColor: Colors.green,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.checkCircle2, size: 24),
            SizedBox(width: AppTheme.spacingSmall),
            Text(
              'I am Safe - Check In',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: AppTheme.spacingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final String label;
  final String number;
  final IconData icon;
  final Color color;

  const _ContactButton({
    required this.label,
    required this.number,
    required this.icon,
    required this.color,
  });

  Future<void> _makeCall(BuildContext context) async {
     // Remove non-numeric characters for the actual call intent
     final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
     
     final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Fallback or error message
        print('Could not launch $launchUri');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch dialer for $number')),
          );
        }
      }
    } catch (e) {
      print('Error launching call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _makeCall(context),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.phone, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
