import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/helpers/app_logger.dart';
import 'package:skin_app_migration/core/provider/image_picker_provider.dart';
import 'package:skin_app_migration/core/provider/internet_provider.dart';
import 'package:skin_app_migration/core/service/local_db_service.dart';
import 'package:skin_app_migration/core/service/push_notification_service.dart';
import 'package:skin_app_migration/features/auth/providers/my_auth_provider.dart';
import 'package:skin_app_migration/features/message/provider/chat_provider.dart';
import 'package:skin_app_migration/features/splash/screens/splash_screen.dart';
import 'package:skin_app_migration/features/super_admin/provider/super_admin_provider.dart';

import 'core/theme/app_styles.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  PushNotificationService().showHeadsUpNotification(message);
  AppLoggerHelper.logInfo(message.notification?.body ?? "");
  AppLoggerHelper.logInfo(message.notification?.title ?? "");
  AppLoggerHelper.logInfo(message.data.entries.toString());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalDBService().init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  // init notification service
  PushNotificationService pushNotificationService = PushNotificationService();
  await pushNotificationService.init();

  /// firebase messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(create: (_) => InternetProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ImagePickerProvider()),
        ChangeNotifierProvider(create: (_) => ImagePickerProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: AppStyles.primaryFont,
            appBarTheme: AppBarTheme(color: Colors.white),
            scaffoldBackgroundColor: Colors.white,
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}
