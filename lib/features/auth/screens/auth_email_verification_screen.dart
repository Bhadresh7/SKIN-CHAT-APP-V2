import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';

class AuthEmailVerificationScreen extends StatefulWidget {
  const AuthEmailVerificationScreen({super.key});

  @override
  State<AuthEmailVerificationScreen> createState() =>
      _AuthEmailVerificationScreenState();
}

class _AuthEmailVerificationScreenState
    extends State<AuthEmailVerificationScreen> {
  // bool _hasNavigated = false;

  // @override
  // void initState() {
  //   super.initState();
  //   // Listen for changes in email verification status
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _checkAndNavigate();
  //   });
  // }

  // void _checkAndNavigate() {
  //   final provider = Provider.of<EmailVerificationProvider>(
  //     context,
  //     listen: false,
  //   );
  //   final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
  //
  //   if (!_hasNavigated &&
  //       (provider.isEmailVerified || authProvider.isEmailVerified)) {
  //     _hasNavigated = true;
  //     MyNavigation.replace(context, BasicDetailsScreen());
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: KBackgroundScaffold(
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
              // Text(
              // "A verification email has been sent to ${authProvider.email}",
              // style: TextStyle(fontSize: AppStyles.subTitle),
              // textAlign: TextAlign.center,
              // ),
              const SizedBox(height: 20),
              KCustomButton(
                text: "Resend Email",
                onPressed: () async {
                  // final result = await provider.resendVerificationEmail();
                  // Force check verification status after resending
                  // await provider.forceCheckVerification();
                  // if (context.mounted) {
                  //   ScaffoldMessenger.of(
                  //     context,
                  //   ).showSnackBar(SnackBar(content: Text(result)));
                  // }
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
                  // await provider.cancelEmailVerification();
                  // if (context.mounted) {
                  //   MyNavigation.replace(context, RegisterScreen());
                  // }
                },
              ),
              SizedBox(height: 0.02.sh),
            ],
          ),
        ),
      ),
    );
  }
}
