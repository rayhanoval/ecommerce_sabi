import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access Supabase/Firebase in background, initialize them here too.
  // But usually, simple notifications are handled by the system.
  print('Handling a background message ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // 1b. Set Foreground Presentation Options (for iOS/Android 13+)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Local Notifications (for foreground display on Android)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Create this icon in android/app/src/main/res/drawable if not exists,
    // or use default @mipmap/ic_launcher

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        if (response.payload != null) {
          _handleMessagePayload(jsonDecode(response.payload!));
        }
      },
    );

    // Create the channel on the device (Android 8.0+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
      ),
    );

    // 3. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show local notification
        _showLocalNotification(message);
      }
    });

    // 5. Message Opened App Handler (Background -> Foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });

    // 6. Token Refresh Listener
    _fcm.onTokenRefresh.listen((newToken) {
      uploadToken(newToken);
    });

    _isInitialized = true;
  }

  Future<void> uploadToken(String? token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    token ??= await _fcm.getToken();

    if (token == null) return;

    print("Uploading FCM Token: $token");

    try {
      await _supabase.from('user_devices').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
          'platform': Platform.operatingSystem, // 'android' or 'ios'
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
    } catch (e) {
      print("Error uploading token: $e");
    }
  }

  // Handle standard RemoteMessage (from onMessageOpenedApp or getInitialMessage)
  void _handleMessage(RemoteMessage message) {
    _handleMessagePayload(message.data);
  }

  // Common handler for data payload
  void _handleMessagePayload(Map<String, dynamic> data) {
    // Navigate based on data
    // Edge function sends 'order_update'
    final type = data['type'];
    if (type == 'order_update' || type == 'order_delivered') {
      final orderId = data['order_id'];
      if (orderId != null) {
        print("Navigate to Order Detail: $orderId");
        // Navigation Logic here (requires context or router)
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // name
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}
