import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/screens/community/risk_map_screen.dart';
import 'package:frontend_app/widgets/weather_risk_widget.dart';

class CommunityDashboard extends StatefulWidget {
  const CommunityDashboard({super.key});

  @override
  State<CommunityDashboard> createState() => _CommunityDashboardState();
}

class _CommunityDashboardState extends State<CommunityDashboard>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  static final Set<String> _playedRegionEntryAnimations = <String>{};
  bool _isMarkedSafe = false;
  bool _isMarkingSafe = false;
  bool _isSendingSOS = false;
  bool _isRegionsLoading = true;
  bool _animateRegionCardsOnFirstLoad = true;
  String? _regionsError;
  List<Map<String, dynamic>> _regions = [];
  int? _nearestRegionId;
  DateTime? _nextSafeMarkAt;
  DateTime? _nextSOSAllowedAt;
  Timer? _safeUnlockTimer;
  Timer? _sosUnlockTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _safeUnlockTimer?.cancel();
    _sosUnlockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData({bool rethrowErrors = false}) async {
    if (mounted) {
      setState(() {
        _isRegionsLoading = _regions.isEmpty;
        _regionsError = null;
      });
    }

    try {
      final shouldAnimateLoadedRegions = _regions.isEmpty;
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _isRegionsLoading = false;
          _animateRegionCardsOnFirstLoad = shouldAnimateLoadedRegions;
          _regionsError = null;
        });
        if (shouldAnimateLoadedRegions) {
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) {
              setState(() => _animateRegionCardsOnFirstLoad = false);
            }
          });
        }
        await _initialSafetyCheck();
        await _initialSOSStatusCheck();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegionsLoading = false;
          _regionsError = 'Unable to load monitored regions. Please try again.';
          if (_regions.isEmpty) {
            _nearestRegionId = null;
            _isMarkedSafe = false;
            _nextSafeMarkAt = null;
          }
        });
      }
      if (rethrowErrors) {
        rethrow;
      }
    }
  }

  Future<void> _initialSOSStatusCheck() async {
    try {
      final sosStatus = await _apiService.fetchSOSStatus();
      if (!mounted || sosStatus.isEmpty) return;
      _applySOSStatus(sosStatus);
    } catch (e) {
      print('Initial SOS status check error: $e');
    }
  }

  Future<void> _initialSafetyCheck() async {
    if (_regions.isEmpty) return;

    try {
      // Step 1: Get current position to find nearest region
      final position = await _apiService.getCurrentPosition();

      if (position != null) {
        unawaited(_apiService.registerDeviceForAlerts(
          latitude: position.latitude,
          longitude: position.longitude,
        ));

        // Find nearest region (simplified logic matching WeatherRiskWidget)
        final nearest =
            _findNearestRegion(position.latitude, position.longitude, _regions);
        if (nearest != null && mounted) {
          final regionId = (nearest['id'] as num).toInt();
          setState(() => _nearestRegionId = regionId);

          // Step 2: Check backend for active 30-minute safety status
          final safetyStatus =
              await _apiService.checkSafetyStatusDetails(regionId);
          if (mounted) {
            _applySafetyStatus(safetyStatus);
          }
        }
      } else if (_regions.isNotEmpty) {
        // Fallback to first region if GPS fails
        final regionId = (_regions.first['id'] as num).toInt();
        setState(() => _nearestRegionId = regionId);
        final safetyStatus =
            await _apiService.checkSafetyStatusDetails(regionId);
        if (mounted) {
          _applySafetyStatus(safetyStatus);
        }
      }
    } catch (e) {
      print('Initial safety check error: $e');
    }
  }

  Map<String, dynamic>? _findNearestRegion(
      double lat, double lon, List<Map<String, dynamic>> regions) {
    Map<String, dynamic>? nearest;
    double minDistance = double.infinity;
    for (var region in regions) {
      final rLat = (region['latitude'] as num?)?.toDouble();
      final rLon = (region['longitude'] as num?)?.toDouble();
      if (rLat == null || rLon == null) continue;
      final distance = _calculateDistance(lat, lon, rLat, rLon);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = region;
      }
    }
    return nearest;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const radiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  void _applySafetyStatus(Map<String, dynamic> data) {
    final seconds = (data['seconds_until_next_mark'] as num?)?.toInt() ?? 0;
    final isActive = data['is_active'] == true;

    setState(() {
      _isMarkedSafe = isActive && seconds > 0;
      _nextSafeMarkAt =
          _isMarkedSafe ? DateTime.now().add(Duration(seconds: seconds)) : null;
    });
    _scheduleSafeUnlock();
  }

  void _scheduleSafeUnlock() {
    _safeUnlockTimer?.cancel();
    if (_nextSafeMarkAt == null) return;

    final remaining = _nextSafeMarkAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      setState(() {
        _isMarkedSafe = false;
        _nextSafeMarkAt = null;
      });
      return;
    }

    _safeUnlockTimer = Timer(remaining, () {
      if (!mounted) return;
      setState(() {
        _isMarkedSafe = false;
        _nextSafeMarkAt = null;
      });
    });
  }

  DateTime? _parseApiDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  void _applySOSStatus(Map<String, dynamic> data) {
    final status = data['status']?.toString();
    final rawSeconds = (data['seconds_until_next_sos'] as num?)?.toInt();
    final seconds = rawSeconds ??
        (status == 'success' || status == 'cooldown' ? 300 : 0);
    final sos = data['sos'] is Map<String, dynamic>
        ? data['sos'] as Map<String, dynamic>
        : null;
    final endTime = _parseApiDateTime(data['sos_end_time']) ??
        _parseApiDateTime(sos?['end_time']);
    final isActive = data['is_on_cooldown'] == true ||
        status == 'success' ||
        status == 'cooldown' ||
        seconds > 0;

    setState(() {
      _nextSOSAllowedAt = isActive ? DateTime.now().add(Duration(seconds: seconds)) : null;
      if (isActive && rawSeconds == null && endTime != null && endTime.isAfter(DateTime.now())) {
        _nextSOSAllowedAt = endTime;
      }
    });
    _scheduleSOSUnlock();
  }

  void _scheduleSOSUnlock() {
    _sosUnlockTimer?.cancel();
    if (_nextSOSAllowedAt == null) return;

    _sosUnlockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_isSOSOnCooldown) {
        timer.cancel();
        setState(() => _nextSOSAllowedAt = null);
        return;
      }

      setState(() {});
    });
  }

  String _formatSafeCooldown() {
    if (_nextSafeMarkAt == null) return 'Notify authorities that you are safe';
    final remaining = _nextSafeMarkAt!.difference(DateTime.now());
    if (remaining <= Duration.zero)
      return 'You can mark yourself safe again now';
    final minutes =
        remaining.inMinutes + (remaining.inSeconds % 60 == 0 ? 0 : 1);
    return 'Authorities notified. You can update again in ${minutes}m';
  }

  Future<void> _refreshData() async {
    try {
      debugPrint('=== REFRESHING DASHBOARD DATA ===');

      // Refresh regions
      await _loadInitialData(rethrowErrors: true);

      debugPrint('✓ Dashboard data refreshed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(LucideIcons.checkCircle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('✓ Data refreshed successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('✗ Refresh failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Refresh failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _markAsSafe() async {
    if (_isMarkedSafe) return;

    setState(() => _isMarkingSafe = true);
    print(
        'DEBUG: Starting _markAsSafe. Current nearestRegionId: $_nearestRegionId');

    try {
      final position = await _apiService.getCurrentPosition();
      if (position == null) {
        throw Exception('Location permission is required to mark yourself safe.');
      }

      final nearest = _findNearestRegion(
        position.latitude,
        position.longitude,
        _regions,
      );
      final regionId = (nearest?['id'] as num?)?.toInt() ??
          _nearestRegionId ??
          (_regions.isNotEmpty ? (_regions.first['id'] as num).toInt() : null);

      if (regionId == null) {
        throw Exception('No monitored regions available. Please refresh.');
      }

      final areaName = await _apiService.fetchLocationName(
            position.latitude,
            position.longitude,
          ) ??
          'Current location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      print('DEBUG: Calling apiService.markAsSafe for region: $regionId');
      final response = await _apiService.markAsSafe(
        regionId,
        latitude: position.latitude,
        longitude: position.longitude,
        areaName: areaName,
      );
      final success = response?['status'] == 'success';
      final cooldown = response?['status'] == 'cooldown';

      if (mounted) {
        setState(() {
          _isMarkingSafe = false;
          if (success || cooldown) {
            _isMarkedSafe = true;
            final seconds =
                (response?['seconds_until_next_mark'] as num?)?.toInt() ?? 1800;
            _nextSafeMarkAt = DateTime.now().add(Duration(seconds: seconds));
          }
        });
        if (success || cooldown) {
          _scheduleSafeUnlock();
        }

        if (success) {
          _showSafeConfirmationDialog(
            latitude: position.latitude,
            longitude: position.longitude,
            areaName: areaName,
          );
        } else if (cooldown) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatSafeCooldown()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Failed to update safety status. Please check login and location permission.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Caught exception in _markAsSafe: $e');
      if (mounted) {
        setState(() => _isMarkingSafe = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSafeConfirmationDialog({
    required double latitude,
    required double longitude,
    required String areaName,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Safety status sent',
      barrierColor: Colors.black.withOpacity(0.82),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF065F46),
                    Color(0xFF047857),
                    Color(0xFF064E3B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        LucideIcons.x,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 112,
                    height: 112,
                    margin: const EdgeInsets.only(bottom: 26),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                  Text(
                    'YOU ARE MARKED SAFE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authorities can now see your safe check-in.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.28)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          areaName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(LucideIcons.checkCircle),
                    label: const Text('I understand'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF065F46),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _sendSOS() async {
    if (_isSendingSOS) return;
    if (_isSOSOnCooldown) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatSOSCooldown()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSendingSOS = true);

    try {
      final position = await _apiService.getCurrentPosition();
      if (position == null) {
        throw Exception('Location permission is required to send SOS.');
      }

      final nearest = _findNearestRegion(
        position.latitude,
        position.longitude,
        _regions,
      );
      final regionId = (nearest?['id'] as num?)?.toInt();
      final areaName = await _apiService.fetchLocationName(
            position.latitude,
            position.longitude,
          ) ??
          'Current location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      final riskData = await _apiService.predictLocationRisk(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final riskLevel =
          riskData?['risk_level']?.toString() ?? _riskLevelFromRegion(nearest);
      final riskScore = (riskData?['risk_score'] as num?)?.toDouble() ??
          (nearest?['current_risk_score'] as num?)?.toDouble();

      final response = await _apiService.submitSOS(
        latitude: position.latitude,
        longitude: position.longitude,
        regionId: regionId,
        areaName: areaName,
        riskLevel: riskLevel,
        riskScore: riskScore,
        message: 'Emergency SOS. User needs immediate help.',
      );

      if (!mounted) return;
      setState(() => _isSendingSOS = false);

      if (response?['status'] == 'success' || response?['status'] == 'cooldown') {
        _applySOSStatus(response!);
        if (response['status'] == 'success') {
          _showSOSConfirmationDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatSOSCooldown()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Unable to send SOS. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingSOS = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('SOS failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSOSConfirmationDialog() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'SOS sent',
      barrierColor: Colors.black.withOpacity(0.92),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF7F1D1D),
                    Color(0xFF991B1B),
                    Color(0xFF450A0A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(
                        LucideIcons.x,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 112,
                    height: 112,
                    margin: const EdgeInsets.only(bottom: 26),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.siren,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                  Text(
                    'SOS SENT',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authorities are being alerted.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your emergency location and risk details have been sent. Keep your phone nearby and move to a safer place if you can.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(LucideIcons.checkCircle),
                    label: const Text('I understand'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7F1D1D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  bool get _isSOSOnCooldown {
    final nextAllowed = _nextSOSAllowedAt;
    return nextAllowed != null && DateTime.now().isBefore(nextAllowed);
  }

  String _formatSOSCooldown() {
    final nextAllowed = _nextSOSAllowedAt;
    if (nextAllowed == null) return 'SOS available soon';

    final remaining = nextAllowed.difference(DateTime.now());
    final totalSeconds = remaining.inSeconds.clamp(0, 300);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return 'SOS in $minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSafeCooldownFor(LanguageProvider langProvider) {
    final text = _formatSafeCooldown();
    if (langProvider.isEnglish) return text;
    if (_nextSafeMarkAt == null) return langProvider.tr('Notify authorities that you are safe');
    final remaining = _nextSafeMarkAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) return langProvider.tr('You can mark yourself safe again now');
    final minutes = remaining.inMinutes + (remaining.inSeconds % 60 == 0 ? 0 : 1);
    return 'حکام کو اطلاع دے دی گئی۔ آپ ${minutes} منٹ بعد دوبارہ اپ ڈیٹ کر سکتے ہیں';
  }

  String _formatSOSCooldownFor(LanguageProvider langProvider) {
    final nextAllowed = _nextSOSAllowedAt;
    if (langProvider.isEnglish) return _formatSOSCooldown();
    if (nextAllowed == null) return 'SOS جلد دستیاب ہوگا';
    final remaining = nextAllowed.difference(DateTime.now());
    final totalSeconds = remaining.inSeconds.clamp(0, 300);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return 'SOS $minutes:${seconds.toString().padLeft(2, '0')} بعد';
  }

  String _riskLevelFromRegion(Map<String, dynamic>? region) {
    final score = (region?['current_risk_score'] as num?)?.toDouble() ?? 0.0;
    if (score >= 0.7) return 'CRITICAL';
    if (score >= 0.5) return 'HIGH';
    if (score >= 0.3) return 'MEDIUM';
    return 'LOW';
  }

  Widget _buildRegionsSliver(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    if (_isRegionsLoading && _regions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: AppTheme.accentTeal,
              ),
              const SizedBox(height: 16),
              Text(
                langProvider.tr('Loading regions...'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    if (_regionsError != null && _regions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.wifiOff,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  langProvider.tr('Connection Error'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  langProvider.tr(_regionsError!.replaceAll('Exception: ', '')),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(LucideIcons.refreshCw),
                  label: Text(langProvider.tr('Retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_regions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              children: [
                 Icon(
                  LucideIcons.mapPin,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  langProvider.tr('No regions available'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate(
        _regions.asMap().entries.map((entry) {
          final index = entry.key;
          final region = entry.value;
          final regionKey = (region['id'] ?? region['name'] ?? index).toString();
          final card = Padding(
            key: ValueKey(region['id'] ?? region['name'] ?? index),
            padding: const EdgeInsets.only(
              bottom: AppTheme.spacingMedium,
            ),
            child: _RegionCard(region: region),
          );

          return _RegionCardEntrance(
            animationKey: regionKey,
            shouldAnimate: _animateRegionCardsOnFirstLoad &&
                !_playedRegionEntryAnimations.contains(regionKey),
            delay: Duration(milliseconds: index * 80),
            onAnimationComplete: () {
              _playedRegionEntryAnimations.add(regionKey);
            },
            child: card,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      // Light warm-white scaffold background
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppTheme.accentTeal,
          child: CustomScrollView(
            slivers: [
              // App header row — white surface with dark text
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      // Logo + Title
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.cardShadow,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Logo.jpeg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                langProvider.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Language Toggle
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(LucideIcons.globe, size: 18),
                              color: AppTheme.accentTeal,
                              onPressed: () {
                                context
                                    .read<LanguageProvider>()
                                    .toggleLanguage();
                              },
                              tooltip: langProvider.tr('Toggle Language'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(LucideIcons.settings, size: 18),
                              color: AppTheme.accentTeal,
                              onPressed: () {
                                Navigator.of(context).pushNamed('/settings');
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(LucideIcons.bell, size: 18),
                              color: AppTheme.accentTeal,
                              onPressed: () {
                                Navigator.of(context).pushNamed('/alert_feed');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.1, end: 0),
              ),

              // Smart Weather & Risk Widget
              const SliverToBoxAdapter(
                child: WeatherRiskWidget(),
              ),

              // Prominent "I'm Safe" Button Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                    vertical: AppTheme.spacingMedium,
                  ),
                  child: _SafetyButton(
                    isMarkedSafe: _isMarkedSafe,
                    isLoading: _isMarkingSafe,
                    subtitle: _formatSafeCooldownFor(langProvider),
                    onPressed: _markAsSafe,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        langProvider.tr('Quick Actions'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final buttonWidth =
                              (constraints.maxWidth -
                                      (AppTheme.spacingMedium * 2)) /
                                  3;

                          return Wrap(
                            spacing: AppTheme.spacingMedium,
                            runSpacing: AppTheme.spacingMedium,
                            children: [
                              SizedBox(
                                width: buttonWidth,
                                child: _QuickActionButton(
                                  icon: LucideIcons.lightbulb,
                                  label: langProvider.tr('Safety Tips'),
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushNamed('/safety_guidelines');
                                  },
                                ),
                              ),
                              SizedBox(
                                width: buttonWidth,
                                child: _QuickActionButton(
                                  icon: LucideIcons.flag,
                                  label: langProvider.tr('Report'),
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushNamed('/report_incident');
                                  },
                                ),
                              ),
                              SizedBox(
                                width: buttonWidth,
                                child: _QuickActionButton(
                                  icon: LucideIcons.siren,
                                  label: _isSOSOnCooldown
                                      ? _formatSOSCooldownFor(langProvider)
                                      : langProvider.tr('SOS'),
                                  onTap: _sendSOS,
                                  isLoading: _isSendingSOS,
                                  isDisabled: _isSOSOnCooldown,
                                  color: Colors.red,
                                  isCritical: true,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(begin: 0.2, end: 0),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingLarge),
              ),

              // Regions Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: Text(
                    langProvider.tr('Monitored Regions'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingMedium),
              ),

              // Live Region Cards with Traffic Light System
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                ),
                sliver: _buildRegionsSliver(context),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingXLarge),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AssistantFloatingButton(
            onTap: () => Navigator.of(context).pushNamed('/assistant'),
            tooltip: langProvider.tr('HillSafe Assistant'),
            label: langProvider.tr('AI Assistant'),
          ).animate().fadeIn(duration: 500.ms, delay: 650.ms).scale(),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'risk_map_fab',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RiskMapScreen(),
                ),
              );
            },
            // FAB uses accentTeal as per new design system
            backgroundColor: AppTheme.accentTeal,
            icon: const Icon(LucideIcons.map, color: Colors.white),
            label: Text(
              langProvider.tr('Risk Map'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 800.ms).scale(),
        ],
      ),
    );
  }
}

class _RegionCardEntrance extends StatefulWidget {
  final String animationKey;
  final bool shouldAnimate;
  final Duration delay;
  final VoidCallback onAnimationComplete;
  final Widget child;

  const _RegionCardEntrance({
    required this.animationKey,
    required this.shouldAnimate,
    required this.delay,
    required this.onAnimationComplete,
    required this.child,
  });

  @override
  State<_RegionCardEntrance> createState() => _RegionCardEntranceState();
}

class _RegionCardEntranceState extends State<_RegionCardEntrance>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: widget.shouldAnimate ? 0 : 1,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curved);

    if (widget.shouldAnimate) {
      Future.delayed(widget.delay, () {
        if (!mounted) return;
        _controller.forward().whenComplete(widget.onAnimationComplete);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _RegionCardEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.shouldAnimate && _controller.value != 1) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.shouldAnimate && _controller.value == 1) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _AssistantFloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;
  final String label;

  const _AssistantFloatingButton({
    required this.onTap,
    required this.tooltip,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 52,
            padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
            decoration: BoxDecoration(
              // FAB uses accentTeal as per new design system
              color: AppTheme.accentTeal,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.92), width: 1.5),
              boxShadow: AppTheme.tealShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.bot,
                    color: AppTheme.accentTeal,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 7),
                 Icon(
                  LucideIcons.sparkles,
                  color: AppTheme.accentTealLight,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Region Card with Traffic Light System
class _RegionCard extends StatelessWidget {
  final Map<String, dynamic> region;

  const _RegionCard({required this.region});

  // 4-Level Risk System
  RiskLevel _getRiskLevel(double score) {
    if (score < 0.3) {
      return RiskLevel.low;
    } else if (score < 0.5) {
      return RiskLevel.medium;
    } else if (score < 0.7) {
      return RiskLevel.high;
    } else {
      return RiskLevel.critical;
    }
  }

  String _formatLastUpdated(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatLastUpdatedFor(String? timestamp, LanguageProvider langProvider) {
    final formatted = _formatLastUpdated(timestamp);
    if (langProvider.isEnglish) return formatted;
    if (formatted == 'Unknown') return 'نامعلوم';
    if (formatted == 'Just now') return 'ابھی';
    if (formatted.endsWith('m ago')) {
      return '${formatted.replaceAll('m ago', '')} منٹ پہلے';
    }
    if (formatted.endsWith('h ago')) {
      return '${formatted.replaceAll('h ago', '')} گھنٹے پہلے';
    }
    return formatted;
  }

  String _translatedRegionName(String value, LanguageProvider langProvider) {
    if (langProvider.isEnglish) return value;
    final key = value.toLowerCase().trim();
    const names = {
      'kohistan': 'کوہستان',
      'swat': 'سوات',
      'murree': 'مری',
      'abbottabad': 'ایبٹ آباد',
      'gilgit': 'گلگت',
      'mansehra': 'مانسہرہ',
      'neelum valley': 'وادی نیلم',
      'chitral': 'چترال',
      'hunza': 'ہنزہ',
      'skardu': 'سکردو',
    };
    return names[key] ?? value;
  }

  String _translatedDistrict(String value, LanguageProvider langProvider) {
    if (langProvider.isEnglish || value.trim().isEmpty) return value;
    final key = value.toLowerCase().trim();
    const districts = {
      'upper kohistan': 'اپر کوہستان',
      'swat': 'سوات',
      'rawalpindi': 'راولپنڈی',
      'abbottabad': 'ایبٹ آباد',
      'gilgit': 'گلگت',
      'mansehra': 'مانسہرہ',
      'neelum': 'نیلم',
      'chitral': 'چترال',
      'hunza': 'ہنزہ',
      'skardu': 'سکردو',
    };
    return districts[key] ?? value;
  }

  String _riskLabelFor(RiskLevel riskLevel, LanguageProvider langProvider) {
    if (langProvider.isEnglish) return riskLevel.label;
    return switch (riskLevel) {
      RiskLevel.low => 'کم',
      RiskLevel.medium => 'درمیانہ',
      RiskLevel.high => 'زیادہ',
      RiskLevel.critical => 'انتہائی',
    };
  }

  String _regionComment(RiskLevel riskLevel, LanguageProvider langProvider) {
    final rawName = (region['name'] ?? 'This area').toString();
    final rawDistrict = (region['district'] ?? '').toString();
    final place = _shortPlaceName(_translatedRegionName(rawName, langProvider));
    final key = '${rawName.toLowerCase()} ${rawDistrict.toLowerCase()}';

    if (langProvider.isUrdu) {
      final comments = switch (riskLevel) {
        RiskLevel.low => [
            '$place میں حالات فی الحال محفوظ ہیں۔',
            '$place میں خطرے کی علامات کم ہیں۔',
            '$place کے راستے ابھی مستحکم ہیں۔',
            '$place میں معمول کی احتیاط کافی ہے۔',
          ],
        RiskLevel.medium => [
            '$place میں بارش کے بعد احتیاط کریں۔',
            '$place میں ڈھلوانوں پر نظر رکھیں۔',
            '$place کے سفر سے پہلے اپ ڈیٹ دیکھیں۔',
            '$place میں درمیانی سطح کا خطرہ ہے۔',
          ],
        RiskLevel.high => [
            '$place میں غیر مستحکم جگہوں سے بچیں۔',
            '$place کے راستوں پر اضافی احتیاط کریں۔',
            '$place میں بارش کے بعد خطرہ بڑھ سکتا ہے۔',
            '$place میں محفوظ راستہ اختیار کریں۔',
          ],
        RiskLevel.critical => [
            '$place میں غیر ضروری سفر سے گریز کریں۔',
            '$place میں فوری احتیاط ضروری ہے۔',
            '$place کی ڈھلوانوں سے دور رہیں۔',
            '$place کے لیے سرکاری ہدایات پر عمل کریں۔',
          ],
      };
      final index =
          key.codeUnits.fold<int>(0, (sum, code) => sum + code) % comments.length;
      return comments[index];
    }

    final terrain = _terrainPhrase(key);
    final comments = switch (riskLevel) {
      RiskLevel.low => [
          '$place routes look stable.',
          'No active concern in $place.',
          '$place looks calm for now.',
          '$place slopes appear steady.',
          'Normal conditions around $place.',
          '$place travel looks clear.',
          'No fresh risk signs in $place.',
          '$place area looks stable.',
          'Routine watch only in $place.',
          '$place routes are calm.',
          'No warning signs near $terrain.',
          '$terrain around $place look safe.',
        ],
      RiskLevel.medium => [
          '$place: stay aware near $terrain.',
          'Watch $terrain in $place after rain.',
          '$place needs routine alert checks.',
          'Medium risk around $place routes.',
          '$place: keep an eye on $terrain.',
          'Travel normally, watch $place.',
          '$place slopes need light caution.',
          'Check updates before $place travel.',
          '$place remains mostly stable.',
          '$terrain in $place look manageable.',
          'Stay alert on $place roads.',
          '$place: monitor rain changes.',
        ],
      RiskLevel.high => [
          '$place: use caution near $terrain.',
          'Watch $place $terrain after rain.',
          'Avoid weak spots in $place.',
          'Travel carefully through $place.',
          '$place routes need extra care.',
          'Slow down near $place slopes.',
          '$place: check alerts before travel.',
          'Limit risky movement in $place.',
          'Stay clear of loose $terrain.',
          '$place may shift after showers.',
          'Use safer routes around $place.',
          '$place: avoid unstable edges.',
        ],
      RiskLevel.critical => [
          '$place: avoid risky $terrain.',
          'Critical danger around $place.',
          'Follow alerts for $place now.',
          'Avoid travel through $place.',
          '$place routes may be unsafe.',
          'Stay away from $place slopes.',
          '$place: move only if needed.',
          'Keep clear of $place danger zones.',
          'Do not use risky $terrain.',
          '$place needs urgent caution.',
          'Delay nonessential $place travel.',
          'Follow official guidance in $place.',
        ],
    };

    final index =
        key.codeUnits.fold<int>(0, (sum, code) => sum + code) % comments.length;
    return comments[index];
  }

  String _shortPlaceName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'This area';
    if (trimmed.length <= 16) return trimmed;
    return trimmed.split(RegExp(r'\s+')).take(2).join(' ');
  }

  String _terrainPhrase(String key) {
    if (key.contains('murree')) return 'hillside roads';
    if (key.contains('swat')) return 'valley routes';
    if (key.contains('kohistan')) return 'steep slopes';
    if (key.contains('hunza')) return 'mountain passes';
    if (key.contains('skardu')) return 'high routes';
    if (key.contains('neelum')) return 'valley edges';
    if (key.contains('gilgit')) return 'exposed roads';
    if (key.contains('abbottabad')) return 'hill roads';
    if (key.contains('mansehra')) return 'slope paths';
    if (key.contains('chitral')) return 'mountain roads';
    return 'local slopes';
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final score = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = _getRiskLevel(score);
    final lastUpdated = _formatLastUpdatedFor(
      region['last_updated'],
      langProvider,
    );
    final comment = _regionComment(riskLevel, langProvider);
    final regionName = _translatedRegionName(
      (region['name'] ?? 'Unknown Region').toString(),
      langProvider,
    );
    final districtName = _translatedDistrict(
      (region['district'] ?? '').toString(),
      langProvider,
    );

    // Alert cards: white surface with colored left border for severity
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RiskMapScreen(selectedRegion: region),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Left Severity Color Bar
            Container(
              width: 5,
              height: 72,
              decoration: BoxDecoration(
                color: riskLevel.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),

            // Risk Icon
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: riskLevel.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                riskLevel.icon,
                color: riskLevel.color,
                size: 32,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    regionName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    districtName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lastUpdated,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Risk Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: riskLevel.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _riskLabelFor(riskLevel, langProvider),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(score * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Risk Level Enum
enum RiskLevel {
  low(
    label: 'LOW',
    color: Colors.green,
    icon: LucideIcons.checkCircle,
  ),
  medium(
    label: 'MEDIUM',
    color: Colors.amber,
    icon: LucideIcons.alertTriangle,
  ),
  high(
    label: 'HIGH',
    color: Colors.orange,
    icon: LucideIcons.alertTriangle,
  ),
  critical(
    label: 'CRITICAL',
    color: Colors.red,
    icon: LucideIcons.alertOctagon,
  );

  final String label;
  final Color color;
  final IconData icon;

  const RiskLevel({
    required this.label,
    required this.color,
    required this.icon,
  });
}

// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;
  final Color? color;
  final bool isCritical;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.color,
    this.isCritical = false,
  });

  @override
  Widget build(BuildContext context) {
    // Non-critical buttons use accentTeal; critical (SOS) keeps its red color
    final actionColor = color ?? AppTheme.accentTeal;
    final enabled = !isLoading && !isDisabled;
    final cardColor = isCritical && enabled
        ? const Color(0xFFB91C1C)
        : AppTheme.surface;
    final labelColor = isCritical
        ? (enabled ? Colors.white : const Color(0xFFB91C1C))
        : AppTheme.textPrimary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMedium,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: isCritical && enabled
                  ? const Color(0xFFDC2626).withOpacity(0.36)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isCritical && enabled ? 22 : 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
          border: isCritical
              ? Border.all(
                  color: enabled
                      ? const Color(0xFFFCA5A5)
                      : actionColor.withOpacity(0.18),
                  width: 1.2,
                )
              : Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: isCritical ? 1 : (enabled ? 1 : 0.55),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isCritical && enabled)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.28),
                          width: 2,
                        ),
                      ),
                    )
                        .animate(
                          onPlay: (controller) => controller.repeat(),
                        )
                        .scale(
                          begin: const Offset(0.82, 0.82),
                          end: const Offset(1.2, 1.2),
                          duration: 1400.ms,
                        )
                        .fadeOut(duration: 1400.ms),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCritical && enabled
                          ? Colors.white
                          : actionColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCritical && enabled
                                    ? const Color(0xFFB91C1C)
                                    : actionColor,
                              ),
                            ),
                          )
                        : Icon(
                            icon,
                            size: 24,
                            color: isCritical && enabled
                                ? const Color(0xFFB91C1C)
                                : actionColor,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isCritical ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 10,
                    color: labelColor,
                    height: 1.05,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Safety Button Widget for "I AM SAFE" functionality
class _SafetyButton extends StatelessWidget {
  final bool isMarkedSafe;
  final bool isLoading;
  final String subtitle;
  final VoidCallback onPressed;

  const _SafetyButton({
    required this.isMarkedSafe,
    required this.isLoading,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingMedium,
          horizontal: AppTheme.spacingMedium,
        ),
        decoration: BoxDecoration(
          color: isMarkedSafe
              ? Colors.green.shade600
              : AppTheme.surface, // White surface when unactivated
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isMarkedSafe
                ? Colors.green.shade700
                : AppTheme.borderColor, // Teal border hint when inactive
            width: 2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // Use accentTeal for loading spinner
                  valueColor: AlwaysStoppedAnimation(AppTheme.accentTeal),
                ),
              )
            else
              Icon(
                isMarkedSafe
                    ? LucideIcons.checkCircle
                    : LucideIcons.shieldCheck,
                size: 28,
                color: isMarkedSafe ? Colors.white : AppTheme.accentTeal,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMarkedSafe ? 'STATUS: SAFE' : 'I am Safe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isMarkedSafe
                              ? Colors.white
                              : AppTheme.textPrimary,
                          letterSpacing: isMarkedSafe ? 1.2 : 0,
                        ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isMarkedSafe
                              ? Colors.white.withOpacity(0.8)
                              : AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (!isMarkedSafe && !isLoading)
              Icon(LucideIcons.chevronRight,
                  size: 20, color: AppTheme.accentTeal),
          ],
        ),
      ),
    );
  }
}
