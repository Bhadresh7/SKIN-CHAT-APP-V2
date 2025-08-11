import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/constants/app_assets.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/features/auth/providers/my_auth_provider.dart';

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
