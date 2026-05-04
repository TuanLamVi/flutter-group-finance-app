import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  Future<void> initialize() async {
    // Request permission for iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Initialize local notifications
    _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap
    _firebaseMessaging.getInitialMessage().then(_handleNotificationTap);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Lấy Device Token
  Future<String> getDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      return token ?? '';
    } catch (e) {
      print('Get device token error: $e');
      return '';
    }
  }

  /// Xử lý thông báo khi app ở background/terminated
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    await _showNotification(message);
  }

  /// Xử lý thông báo khi app ở foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling foreground message: ${message.messageId}');
    await _showNotification(message);
  }

  /// Xử lý khi người dùng nhấp vào thông báo
  Future<void> _handleNotificationTap(RemoteMessage? message) async {
    if (message != null) {
      print('Notification tapped: ${message.data}');
      // TODO: Navigate to appropriate screen based on notification data
    }
  }

  /// Hiển thị thông báo cục bộ
  Future<void> _showNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'group_finance_channel',
        'Group Finance Notifications',
        channelDescription: 'Notifications for Group Finance App',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? 'Group Finance',
        message.notification?.body ?? 'Bạn có thông báo mới',
        notificationDetails,
        payload: message.data.toString(),
      );
    } catch (e) {
      print('Show notification error: $e');
    }
  }

  /// Subscribe vào topic (nhóm)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Subscribe to topic error: $e');
    }
  }

  /// Unsubscribe khỏi topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Unsubscribe from topic error: $e');
    }
  }
}