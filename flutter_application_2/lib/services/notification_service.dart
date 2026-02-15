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
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

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
    // Navigate to appropriate screen based on payload
    // This can be enhanced with navigation logic
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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'risk_alerts',
      'Risk Alerts',
      channelDescription: 'Critical landslide risk alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    final title = '⚠️ High Risk Alert: $regionName';
    final body = message ??
        'Landslide risk increased to ${(riskScore * 100).toInt()}%. Weather conditions have changed in your area. Stay alert!';

    await _notifications.show(
      0, // Notification ID (0 will replace previous notification)
      title,
      body,
      platformDetails,
      payload: 'risk_alert:$regionName:$riskScore',
    );

    print('Risk notification sent: $regionName - ${(riskScore * 100).toInt()}%');
  }

  /// Show general notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      1, // Different ID for general notifications
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}
