import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../translations/tr_extension.dart';

/// Handles FCM messages received while the app is in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log(
    'Background FCM message received: ${message.messageId}',
    name: 'NotificationService',
  );
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _topic = 'all_users';

  static AndroidNotificationChannel get _channel => AndroidNotificationChannel(
    'high_importance_channel',
    'notification_channel_name'.tr,
    description: 'notification_channel_description'.tr,
    importance: Importance.max,
  );

  bool _initialized = false;
  bool _registered = false;

  /// Initializes FCM and local notifications.
  Future<void> init() async {
    if (_initialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          log(
            'Local notification tapped: ${response.payload}',
            name: 'NotificationService',
          );
        },
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(_channel);

      // Display system-style notifications while the app is open.
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) async {
          final RemoteNotification? notification = message.notification;

          final String? title =
              notification?.title ?? message.data['title']?.toString();

          final String? body =
              notification?.body ?? message.data['body']?.toString();

          log(
            'Foreground FCM message: ${message.messageId}',
            name: 'NotificationService',
          );

          if (title == null && body == null) return;

          await _localNotifications.show(
            id: message.hashCode,
            title: title ?? '',
            body: body ?? '',
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'notification_channel_name'.tr,
                channelDescription: 'notification_channel_description'.tr,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data.toString(),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          log(
            'Foreground FCM error: $error',
            name: 'NotificationService',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );

      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

      final RemoteMessage? initialMessage = await _messaging
          .getInitialMessage();

      if (initialMessage != null) {
        _handleTap(initialMessage);
      }

      _messaging.onTokenRefresh.listen((String token) {
        log('FCM token refreshed: $token', name: 'NotificationService');
      });

      _initialized = true;

      log('NotificationService initialized', name: 'NotificationService');
    } catch (error, stackTrace) {
      log(
        'NotificationService initialization failed: $error',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Requests permission and subscribes to the all_users topic.
  Future<void> requestPermissionAndSubscribe() async {
    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      log(
        'Notification permission: ${settings.authorizationStatus}',
        name: 'NotificationService',
      );

      final bool authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!authorized) return;

      if (!_registered) {
        await _messaging.subscribeToTopic(_topic);
        _registered = true;

        log('Subscribed to topic: $_topic', name: 'NotificationService');
      }

      final String? token = await _messaging.getToken();

      if (token != null) {
        log('FCM token: $token', name: 'NotificationService');
      }
    } catch (error, stackTrace) {
      log(
        'Permission or subscription failed: $error',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleTap(RemoteMessage message) {
    log(
      'Notification tapped: ${message.messageId}',
      name: 'NotificationService',
    );

    log('Notification data: ${message.data}', name: 'NotificationService');
  }
}
