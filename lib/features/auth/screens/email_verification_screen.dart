import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';
import 'package:skin_app_migration/features/auth/screens/auth_registeration_screen.dart';
import 'package:skin_app_migration/features/profile/screens/basic_user_details_form_screen.dart';

import '../../../core/helpers/app_logger.dart';
import '../providers/my_auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Listen for changes in email verification status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
        await FirebaseAuth.instance.currentUser?.reload();
        AppLoggerHelper.logInfo(
          "${FirebaseAuth.instance.currentUser!.emailVerified}",
        );
        _checkAndNavigate();
      });
    });
  }

  void _checkAndNavigate() {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    authProvider.user = FirebaseAuth.instance.currentUser;
    if (FirebaseAuth.instance.currentUser!.emailVerified) {
      AppRouter.replace(context, BasicUserDetailsFormScreen());
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAuthProvider>(
      builder: (context, authProvider, child) {
        // Check for navigation when the provider updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndNavigate();
        });

        return PopScope(
          canPop: false,
          child: KBackgroundScaffold(
            loading: authProvider.isLoading,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.email, size: 100, color: Colors.yellow),
                  const SizedBox(height: 20),
                  Text(
                    "Please verify your email",
                    style: TextStyle(
                      fontSize: AppStyles.subTitle,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "A verification email has been sent to ${authProvider.emailController.text}",
                    style: TextStyle(fontSize: AppStyles.subTitle),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  KCustomButton(
                    text: "Resend Email",
                    onPressed: () async {
                      await authProvider.user!.sendEmailVerification();

                      // Force check verification status after resending
                      // await provider.forceCheckVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Resent Verification Email')),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 0.02.sh),
                  KCustomButton(
                    border: 1.0,
                    borderColor: AppStyles.primary,
                    fontColor: AppStyles.primary,
                    color: AppStyles.smoke,
                    text: "Change email",
                    onPressed: () async {
                      if (context.mounted) {
                        await FirebaseAuth.instance.signOut();
                        await GoogleSignIn().signOut();
                        AppRouter.replace(context, AuthRegisterationScreen());
                      }
                    },
                  ),
                  SizedBox(height: 0.02.sh),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
