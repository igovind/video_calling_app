import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:full_screen_notification/firebase_options.dart';

class NotificationService {
  static Future<void> _onBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log("onBackgroundMessage Called");
    onMessageReceived(message);
  }

  Future<void> firebaseMessaging() async {
    FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    // FCM Token
    await FirebaseMessaging.instance.getToken().then((token) {
      log("Token: $token");
    });

    // Terminatated
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log("onMessage Called");
      onMessageReceived(message);
    });

    // Coming from background to foreground
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      log("onMessageOpenedApp Called");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      onMessageReceived(message);
    });

    await FirebaseMessaging.instance.subscribeToTopic('all-users');
  }

  static onMessageReceived(RemoteMessage message) {
    if (message.notification != null) {
      show(message.notification!.title!, message.notification!.body!);
    }
  }

  Future onDidReceiveLocalNotification(
    int? id,
    String? title,
    String? body,
    String? payload,
  ) async {
    log("iOS notification $title $body $payload");
  }

  static void show(String title, String description) async {
    const AndroidNotificationChannel androidSettings =
        AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      playSound: true,
    );

    var notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        androidSettings.id,
        androidSettings.name,
        importance: Importance.high,
        color: Colors.blue,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    AndroidNotificationChannel? channel = const AndroidNotificationChannel(
      "",
      "High Importance Notifications",
      importance: Importance.high,
    );

    FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    flutterLocalNotificationsPlugin.show(
      0,
      title,
      description,
      notificationDetails,
    );
  }
}
