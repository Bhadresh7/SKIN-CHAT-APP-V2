import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/constants/app_assets.dart';
import 'package:skin_app_migration/providers/my_auth_provider.dart';
import 'package:skin_app_migration/widgets/k_background_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 1), () async {
      Provider.of<MyAuthProvider>(context, listen: false).initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return KBackgroundScaffold(
      body: Center(child: Image.asset(AppAssets.logo)),
    );
  }
}
