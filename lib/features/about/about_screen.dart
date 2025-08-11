import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skin_app_migration/core/constants/app_text.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KBackgroundScaffold(
      appBar: AppBar(),
      // showDrawer: true,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text("About us", style: TextStyle(fontSize: AppStyles.heading)),
              SizedBox(height: 0.02.sh),
              Text(AppText.aboutUs, textAlign: TextAlign.justify),
            ],
          ),
        ),
      ),
    );
  }
}
