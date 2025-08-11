import 'package:flutter/material.dart';

class AppRouter {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void to(BuildContext? context, Widget screen) {
    Navigator.push(
      context ?? navigatorKey.currentContext!,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  static void offAll(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  static void back(BuildContext context) {
    Navigator.of(context).pop();
  }

  static void namedRout(String route, {BuildContext? context}) {
    Navigator.of(context ?? navigatorKey.currentContext!).pushNamed(route);
  }

  static void replace(BuildContext context, Widget screen) {
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation1, animation2) => screen,
      ),
    );
  }
}
