import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _fcm.requestPermission();
    print("FCM Permission granted");

    // FirebaseMessaging.onBackgroundMessage.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked: ${message.notification?.title}');
    });
  }

  Future<void> subscribeToUserTopic(String email) async {
    final topic = _sanitizeEmail(email);
    await _fcm.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromUserTopic(String email) async {
    final topic = _sanitizeEmail(email);
    await _fcm.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  String _sanitizeEmail(String email) {
    return email.replaceAll(RegExp(r'[^\w]'), '_');
  }

  Future<void> initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('ic_notification');
    InitializationSettings(android: androidInit);

    // Handling background notifications
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🌟 Background Notification Tapped!");
    });
  }

  Future<void> showHeadsUpNotification(RemoteMessage message) async {
    try {
      print("ONE ----------");

      String? imgUrl = message.notification?.android?.imageUrl;
      AndroidNotificationDetails androidDetails;

      // download the image from the internet
      if (imgUrl != null && imgUrl.isNotEmpty) {
        // creating image object to show in the notification
        final bigPicture = BigPictureStyleInformation(
          FilePathAndroidBitmap(imgUrl),
          contentTitle: message.notification?.title,
          summaryText: message.notification?.body,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
          hideExpandedLargeIcon: false,
        );

        androidDetails = AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          styleInformation: bigPicture,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          fullScreenIntent: true,
          largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
          // sound: RawResourceAndroidNotificationSound();
        );
      } else {
        androidDetails = AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.max,
          ticker: 'ticker',
          fullScreenIntent: true,

          // sound: RawResourceAndroidNotificationSound();
        );
      }

      final platformDetails = NotificationDetails(android: androidDetails);
      print("TWO ----------");

      await _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.body,
        message.notification?.title,
        platformDetails,
        payload: message.data.toString(),
      );

      print("THREE --------------------------");
    } catch (e) {
      print("🔥 Error showing heads-up notification: $e");
    }
  }
}
