import 'package:flutter/material.dart';
import 'package:skin_app_migration/constants/app_styles.dart';
import 'package:skin_app_migration/constants/app_text.dart';

import '../constants/app_assets.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About us", style: TextStyle(fontSize: AppStyles.heading)),
      ),
      // showDrawer: true,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            SizedBox(
              height: 200,
              width: 200,
              child: Image.asset(AppAssets.logo),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Text(AppText.aboutUs, textAlign: TextAlign.justify),
            ),
          ],
        ),
      ),
    );
  }
}
