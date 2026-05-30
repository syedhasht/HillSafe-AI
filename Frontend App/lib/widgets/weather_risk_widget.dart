import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';

enum _DaylightPhase { sunrise, day, sunset, night }

/// Smart Weather & Risk Widget
///
/// Location-aware widget that displays weather and landslide risk
/// for the user's nearest region with auto-refresh functionality
class WeatherRiskWidget extends StatefulWidget {
  const WeatherRiskWidget({super.key});

  @override
  State<WeatherRiskWidget> createState() => _WeatherRiskWidgetState();
}

class _WeatherRiskWidgetState extends State<WeatherRiskWidget>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  // State variables
  // State variables
  bool _isLoading = true;
  bool _isRefreshingSilently = false;
  String? _errorMessage;
  Map<String, dynamic>? _nearestRegion;
  Map<String, dynamic>? _weatherData;
  String? _locationName; // Added for reverse geocoding
  String? _safetyMessage;
  double? _riskScore;
  String? _riskLevel;
  DateTime? _lastUpdated;
  Timer? _autoRefreshTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Setup periodic refresh without interrupting the visible card.
  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _loadData(silent: true);
    });
  }

  /// Main data loading function
  Future<void> _loadData({bool silent = false}) async {
    if (_isLoading && _nearestRegion != null) return; // Prevent double loads
    if (_isRefreshingSilently) return;

    final shouldRefreshSilently = silent && _nearestRegion != null;
    if (shouldRefreshSilently) {
      _isRefreshingSilently = true;
    } else {
      _animationController.repeat();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Step 1: Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied permanently');
      }

      // Step 2: Get a fresh current position. Weather must use the user's
      // real area, so avoid old/approximate fallback coordinates.
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        );
      } catch (e) {
        print('getCurrentPosition timed out/failed: $e. Checking recent last known position.');
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          final lastTimestamp = lastKnown?.timestamp;
          final isRecent = lastTimestamp != null &&
              DateTime.now().difference(lastTimestamp).inMinutes <= 10;
          position = isRecent ? lastKnown : null;
        } catch (_) {}
      }

      if (position == null) {
        throw Exception('Fresh GPS location unavailable');
      }

      // Step 2.5: Fetch Location Name (Reverse Geocoding)
      String? locationName;
      try {
        locationName = await _apiService.fetchLocationName(
            position.latitude, position.longitude);
      } catch (e) {
        print('Location name fetch failed: $e');
      }

      // Step 3: Ask backend to fetch weather, find nearest region, and run ML
      final riskData = await _apiService.predictLocationRisk(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (riskData == null) {
        throw Exception('Backend prediction unavailable');
      }

      final nearest = riskData['nearest_region'] as Map<String, dynamic>?;
      final weather = riskData['weather'] as Map<String, dynamic>?;
      if (nearest == null) {
        throw Exception('Backend response missing nearest region');
      }
      if (weather == null) {
        throw Exception('Backend response missing weather data');
      }

      final currentLatitude = position.latitude;
      final currentLongitude = position.longitude;
      final displayWeather = Map<String, dynamic>.from(weather);
      final liveWeather =
          await _apiService.fetchLiveWeather(currentLatitude, currentLongitude);
      final liveTemperature = liveWeather?['temperature'];
      if (liveTemperature is num && liveTemperature > -30 && liveTemperature < 60) {
        displayWeather['temperature'] = liveTemperature.toDouble();
        displayWeather['rainfall_mm'] = liveWeather?['rainfall_mm'] ?? weather['rainfall_mm'];
        displayWeather['humidity'] = liveWeather?['humidity'] ?? weather['humidity'];
        displayWeather['source'] = liveWeather?['source'] ?? 'open-meteo';
      }

      if (mounted) {
        setState(() {
          _nearestRegion = nearest;
          _weatherData = displayWeather;
          _locationName = locationName ??
              '${currentLatitude.toStringAsFixed(4)}, ${currentLongitude.toStringAsFixed(4)}';
          _safetyMessage = riskData['safety_message'] as String?;
          _riskScore = (riskData['risk_score'] as num).toDouble();
          _riskLevel = _getRiskLevel(_riskScore!);
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
        if (!shouldRefreshSilently) {
          _animationController.stop();
        }
      }
    } catch (e) {
      if (mounted && !shouldRefreshSilently) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        _animationController.stop();
      }
    } finally {
      _isRefreshingSilently = false;
    }
  }

  /// Get risk level from score
  String _getRiskLevel(double score) {
    if (score >= 0.7) return 'CRITICAL';
    if (score >= 0.5) return 'HIGH';
    if (score >= 0.3) return 'MEDIUM';
    return 'LOW';
  }

  /// Get background color based on risk
  Color _getRiskColor(double score) {
    if (score >= 0.7) return Colors.red.shade400;
    if (score >= 0.5) return Colors.orange.shade400;
    if (score >= 0.3) return Colors.amber.shade400;
    return Colors.green.shade400;
  }

  /// Get weather icon based on rainfall and local daylight phase.
  IconData _getWeatherIcon(double rainfall) {
    if (rainfall > 50) return LucideIcons.cloudRain;
    if (rainfall > 20) return LucideIcons.cloudDrizzle;
    if (rainfall > 0) return LucideIcons.cloud;
    if (_daylightPhase == _DaylightPhase.sunrise) return LucideIcons.sunrise;
    if (_daylightPhase == _DaylightPhase.sunset) return LucideIcons.sunset;
    if (_isNight) return LucideIcons.moon;
    return LucideIcons.sun;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildWeatherRiskCard(),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.3),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(
              context.watch<LanguageProvider>().tr('Updating live data...'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              context
                  .watch<LanguageProvider>()
                  .tr(_errorMessage!.replaceAll('Exception: ', '')),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(context.watch<LanguageProvider>().tr('Retry')),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isNight {
    final phase = _daylightPhase;
    return phase == _DaylightPhase.night;
  }

  _DaylightPhase get _daylightPhase {
    final sunrise = _unixSeconds(_weatherData?['sunrise']);
    final sunset = _unixSeconds(_weatherData?['sunset']);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    if (sunrise != null && sunset != null && sunset > sunrise) {
      const transitionWindow = 45 * 60;

      if ((now - sunrise).abs() <= transitionWindow) {
        return _DaylightPhase.sunrise;
      }
      if ((now - sunset).abs() <= transitionWindow) {
        return _DaylightPhase.sunset;
      }
      if (now > sunrise && now < sunset) {
        return _DaylightPhase.day;
      }
      return _DaylightPhase.night;
    }

    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 7) return _DaylightPhase.sunrise;
    if (hour >= 17 && hour <= 19) return _DaylightPhase.sunset;
    if (hour >= 7 && hour < 17) return _DaylightPhase.day;
    return _DaylightPhase.night;
  }

  int? _unixSeconds(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  LinearGradient _getWeatherGradient(double rainfall, double temp) {
    if (_isNight) {
      return const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Deep Night Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (_daylightPhase == _DaylightPhase.sunrise) {
      return const LinearGradient(
        colors: [Color(0xFFFFB86B), Color(0xFF60A5FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (_daylightPhase == _DaylightPhase.sunset) {
      return const LinearGradient(
        colors: [Color(0xFFFB7185), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Snow (Cold + Precipitation)
    if (rainfall > 0 && temp <= 4) {
      return const LinearGradient(
        colors: [Color(0xFF93C5FD), Color(0xFFDBEAFE)], // Icy Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Rain
    if (rainfall > 0) {
      return const LinearGradient(
        colors: [Color(0xFF334155), Color(0xFF475569)], // Stormy Grey
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Sunny / Clear
    return const LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFF97316)], // Vibrant Orange
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getBackgroundIcon(double rainfall, double temp) {
    if (_isNight) return LucideIcons.moon;
    if (_daylightPhase == _DaylightPhase.sunrise) return LucideIcons.sunrise;
    if (_daylightPhase == _DaylightPhase.sunset) return LucideIcons.sunset;
    if (rainfall > 0 && temp <= 4) return LucideIcons.snowflake;
    if (rainfall > 0) return LucideIcons.cloudRain;
    return LucideIcons.sun;
  }

  String _getWeatherLabel(double rainfall, double temperature) {
    if (rainfall > 0) {
      return temperature <= 4 ? 'Snow' : 'Rain';
    }

    switch (_daylightPhase) {
      case _DaylightPhase.sunrise:
        return 'Sunrise';
      case _DaylightPhase.sunset:
        return 'Sunset';
      case _DaylightPhase.night:
        return 'Clear Night';
      case _DaylightPhase.day:
        return 'Sunny';
    }
  }

  Color _getRiskBadgeColor(double score) {
    if (score >= 0.7) return Colors.red;
    if (score >= 0.5) return Colors.orange;
    if (score >= 0.3) return Colors.amber;
    return Colors.green;
  }

  String _getRiskBadgeText() {
    return '$_riskLevel RISK';
  }

  String _localizedRiskBadge(LanguageProvider langProvider) {
    if (langProvider.isUrdu) {
      final level = switch (_riskLevel) {
        'CRITICAL' => 'انتہائی',
        'HIGH' => 'زیادہ',
        'MEDIUM' => 'درمیانہ',
        'LOW' => 'کم',
        _ => '',
      };
      return '$level خطرہ';
    }
    return '${langProvider.tr(_riskLevel ?? '')} ${langProvider.tr('RISK')}';
  }

  String _weatherLabelFor(
    LanguageProvider langProvider,
    double rainfall,
    double temperature,
  ) {
    final label = _getWeatherLabel(rainfall, temperature);
    if (langProvider.isEnglish) return label;

    return switch (label) {
      'Snow' => 'برف',
      'Rain' => 'بارش',
      'Sunrise' => 'طلوع آفتاب',
      'Sunset' => 'غروب آفتاب',
      'Clear Night' => 'صاف رات',
      'Sunny' => 'دھوپ',
      _ => label,
    };
  }

  String _placeNameFor(String value, LanguageProvider langProvider) {
    if (langProvider.isEnglish) return value;

    final parts = value.split(',').map((part) => part.trim()).toList();
    final translated = parts.map((part) {
      final key = part.toLowerCase();
      const places = {
        'kohistan': 'کوہستان',
        'upper kohistan': 'اپر کوہستان',
        'swat': 'سوات',
        'murree': 'مری',
        'rawalpindi': 'راولپنڈی',
        'abbottabad': 'ایبٹ آباد',
        'gilgit': 'گلگت',
        'mansehra': 'مانسہرہ',
        'neelum valley': 'وادی نیلم',
        'neelum': 'نیلم',
        'chitral': 'چترال',
        'hunza': 'ہنزہ',
        'skardu': 'سکردو',
        'pakistan': 'پاکستان',
      };
      return places[key] ?? part;
    }).toList();

    return translated.join('، ');
  }

  String _updatedAtFor(LanguageProvider langProvider) {
    final updated = _lastUpdated ?? DateTime.now();
    if (langProvider.isEnglish) {
      return DateFormat('EEE, d MMM - h:mm a').format(updated);
    }

    final rawHour = updated.hour % 12;
    final hour = rawHour == 0 ? 12 : rawHour;
    final minute = updated.minute.toString().padLeft(2, '0');
    final period = updated.hour < 12 ? 'صبح' : 'شام';
    return 'آخری اپ ڈیٹ: $hour:$minute $period';
  }

  String _safetyMessageFor(LanguageProvider langProvider) {
    final message = _safetyMessage ?? '';
    if (message.isEmpty || langProvider.isEnglish) return message;

    final level = _riskLevel ?? '';
    if (level == 'CRITICAL') {
      return 'انتہائی خطرہ ہے۔ غیر ضروری سفر سے گریز کریں اور حکام کی ہدایات پر عمل کریں۔';
    }
    if (level == 'HIGH') {
      return 'زیادہ خطرہ ہے۔ ڈھلوانوں اور کمزور راستوں کے قریب اضافی احتیاط کریں۔';
    }
    if (level == 'MEDIUM') {
      return 'درمیانہ خطرہ ہے۔ موسم کی اپ ڈیٹس دیکھتے رہیں اور بارش میں محتاط رہیں۔';
    }
    return 'خطرہ کم ہے، مگر پہاڑی علاقوں میں معمول کی احتیاط جاری رکھیں۔';
  }

  Widget _buildWeatherRiskCard() {
    final langProvider = context.watch<LanguageProvider>();
    final rainfall = (_weatherData?['rainfall_mm'] as num?)?.toDouble() ?? 0.0;
    final temperature =
        (_weatherData?['temperature'] as num?)?.toDouble() ?? 20.0;
    final locationName = _placeNameFor(
      _locationName ?? langProvider.tr('Your Location'),
      langProvider,
    );
    final nearestRegionName = _nearestRegion?['name']?.toString();
    final nearestDistance =
        (_nearestRegion?['distance_km'] as num?)?.toDouble();
    final nearestRegionLabel = nearestRegionName == null
        ? null
        : nearestDistance == null
            ? '${langProvider.tr('Nearest monitored')}: ${_placeNameFor(nearestRegionName, langProvider)}'
            : '${langProvider.tr('Nearest monitored')}: ${_placeNameFor(nearestRegionName, langProvider)} (${nearestDistance.toStringAsFixed(1)} ${langProvider.isUrdu ? 'کلومیٹر' : 'km'})';
    final safetyMessage = _safetyMessageFor(langProvider);

    final gradient = _getWeatherGradient(rainfall, temperature);
    final bgIcon = _getBackgroundIcon(rainfall, temperature);
    final riskBadgeColor = _getRiskBadgeColor(_riskScore!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final horizontalPadding = compact ? 16.0 : 24.0;

        return Container(
          constraints: BoxConstraints(minHeight: compact ? 220 : 200),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    bgIcon,
                    size: compact ? 140 : 180,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(LucideIcons.mapPin,
                                          color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        locationName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: compact ? 16 : 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _updatedAtFor(langProvider),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                if (nearestRegionLabel != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    nearestRegionLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.82),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _loadData,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: RotationTransition(
                                  turns: _animationController,
                                  child: const Icon(
                                    LucideIcons.refreshCw,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 24 : 36),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        runSpacing: 16,
                        spacing: 16,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compact
                                  ? constraints.maxWidth
                                  : constraints.maxWidth * 0.48,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${temperature.toStringAsFixed(0)}°',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 40 : 48,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getWeatherIcon(rainfall),
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _weatherLabelFor(
                                          langProvider,
                                          rainfall,
                                          temperature,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: riskBadgeColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: riskBadgeColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.alertTriangle,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _localizedRiskBadge(langProvider),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 12 : 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (safetyMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.16),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(LucideIcons.info,
                                    color: Colors.white, size: 15),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  safetyMessage,
                                  maxLines: compact ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.92),
                                    fontSize: compact ? 12 : 13,
                                    height: 1.25,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
