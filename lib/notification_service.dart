import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:full_screen_notification/firebase_options.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static const platform = MethodChannel('samples.flutter.dev/calling');

  Future<void> _invokeIncomingCall() async {
    try {
      await platform.invokeMethod('showIncomingCallScreen');
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
    }
  }

  @pragma('vm:entry-point')
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
      // show(message.notification!.title!, message.notification!.body!);
      // NotificationService()._invokeIncomingCall();
      showCallkitIncoming(const Uuid().v4());
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

Future<void> showCallkitIncoming(String uuid) async {
  final params = CallKitParams(
    id: uuid,
    nameCaller: 'Hien Nguyen',
    appName: 'Callkit',
    avatar: 'https://i.pravatar.cc/100',
    handle: '0123456789',
    type: 0,
    duration: 30000,
    textAccept: 'Accept',
    textDecline: 'Decline',
    textMissedCall: 'Missed call',
    textCallback: 'Call back',
    extra: <String, dynamic>{'userId': '1a2b3c4d'},
    headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      isShowCallback: true,
      isShowMissedCallNotification: true,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      backgroundUrl: 'assets/test.png',
      actionColor: '#4CAF50',
    ),
    ios: IOSParams(
      iconName: 'CallKitLogo',
      handleType: '',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}
