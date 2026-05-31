import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notification Service
/// 
/// Handles local system notifications for risk alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (for future iOS support)
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Explicitly create the high-priority notification channels on Android
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // 1. Critical Alerts Channel (Red buzzer, intense vibration, max importance)
      final AndroidNotificationChannel criticalChannel = AndroidNotificationChannel(
        'critical_alerts',
        '🚨 Critical Emergency Alerts',
        description: 'Immediate landslide danger warnings',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000]),
        ledColor: const Color(0xFFD32F2F),
        enableLights: true,
      );

      // 2. Risk Alerts Channel (Normal alerts, standard vibration, high importance)
      final AndroidNotificationChannel normalChannel = AndroidNotificationChannel(
        'risk_alerts',
        '🔔 Safety Alerts & Updates',
        description: 'Landslide risk updates and warnings',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        ledColor: const Color(0xFF0F172A),
        enableLights: true,
      );

      await androidPlugin.createNotificationChannel(criticalChannel);
      await androidPlugin.createNotificationChannel(normalChannel);
      print('Android Notification Channels initialized successfully');
    }

    _isInitialized = true;
    print('NotificationService initialized');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  /// Show risk alert notification
  Future<void> showRiskNotification({
    required String regionName,
    required double riskScore,
    String? message,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check permission
    if (!await requestPermissions()) {
      print('Notification permission denied');
      return;
    }

    final isCritical = riskScore >= 0.8;
    final channelId = isCritical ? 'critical_alerts' : 'risk_alerts';
    final largeIcon = isCritical ? 'ic_red_buzzer' : 'ic_normal_buzzer';
    final color = isCritical ? const Color(0xFFD32F2F) : const Color(0xFF0F172A);

    final title = isCritical
        ? '🚨 CRITICAL WARNING: Landslide Danger in $regionName'
        : '⚠️ Safety Update: $regionName';
    final body = message ??
        'Landslide risk increased to ${(riskScore * 100).toInt()}%. Weather conditions have changed in your area. Stay alert!';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      isCritical ? '🚨 Critical Emergency Alerts' : '🔔 Safety Alerts & Updates',
      channelDescription: isCritical ? 'Immediate landslide danger warnings' : 'Landslide risk updates and warnings',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: isCritical
          ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000])
          : Int64List.fromList([0, 500, 250, 500]),
      playSound: true,
      color: color,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: isCritical ? '🚨 EMERGENCY' : '🔔 UPDATE',
      ),
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: 'risk_alert:$regionName:$riskScore',
    );

    print('Risk notification sent: $regionName - ${(riskScore * 100).toInt()}%');
  }

  /// Show general notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? severity,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final isCritical = severity?.toUpperCase() == 'CRITICAL';
    final channelId = isCritical ? 'critical_alerts' : 'risk_alerts';
    final largeIcon = isCritical ? 'ic_red_buzzer' : 'ic_normal_buzzer';
    final color = isCritical ? const Color(0xFFD32F2F) : const Color(0xFF0F172A);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      isCritical ? '🚨 Critical Emergency Alerts' : '🔔 Safety Alerts & Updates',
      channelDescription: isCritical ? 'Immediate landslide danger warnings' : 'Landslide risk updates and warnings',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      vibrationPattern: isCritical
          ? Int64List.fromList([0, 1000, 500, 1000, 500, 1000, 500, 1000])
          : Int64List.fromList([0, 500, 250, 500]),
      playSound: true,
      color: color,
      largeIcon: DrawableResourceAndroidBitmap(largeIcon),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: isCritical ? '🚨 EMERGENCY' : '🔔 UPDATE',
      ),
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }
}
