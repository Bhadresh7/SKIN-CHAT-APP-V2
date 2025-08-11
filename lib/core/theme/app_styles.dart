import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppStyles {
  // FONTS
  static const String primaryFont = 'Poppins';

  // FONT SIZES
  static double heading = 20.sp;
  static double subTitle = 15.sp;
  static double bodyText = 12.sp;
  static double msgText = 13.sp;
  static double hintText = 15.sp;

  // SPACING
  static double hMargin = 20.sp;
  static double vMargin = 25.sp;
  static double padding = 20.sp;

  // UI
  static double borderRadius = 8.r;
  static double borderThickness = 1.sp;

  // COLORS
  static const Color primary = Color(0xff734FDB);
  static const Color tertiary = Color(0xff707073);
  static const Color green = Color(0xff34A853);
  static const Color smoke = Color(0xffF5F5F5);
  static const Color links = Colors.blue;
  static const Color dark = Colors.black;
  static const Color danger = Colors.red;

  // MEDIA QUERY BASED VALUES
  static Size screenSize(BuildContext context) => MediaQuery.of(context).size;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double bottomInset(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom;
}
