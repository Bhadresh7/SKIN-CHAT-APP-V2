import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lottie/lottie.dart';
import 'package:skin_app_migration/core/constants/app_assets.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/helpers/toast_helper.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';
import 'package:skin_app_migration/core/widgets/k_custom_input_field.dart';
import 'package:skin_app_migration/features/auth/screens/auth_forget_password_screen.dart';
import 'package:skin_app_migration/features/auth/screens/auth_registeration_screen.dart';
import 'package:skin_app_migration/features/auth/widgets/k_google_auth_button.dart';
import 'package:skin_app_migration/features/auth/widgets/k_or_bar.dart';
import 'package:skin_app_migration/features/message/screens/chat_screen.dart';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  ///controller
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  ///formKey
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void getAuthBaseScreen(BuildContext context, String result) {
    switch (result) {
      case AppStatus.kBlocked:
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    "Account Blocked",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Text(
                "Your account has been blocked and you cannot access the chat. Please contact support for more information.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppRouter.back(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("OK"),
                  ),
                ),
              ],
            );
          },
        );
        break;

      case AppStatus.kInvalidCredential:
        ToastHelper.showErrorToast(
          context: context,
          message: "Invalid email or password",
        );
        break;

      case AppStatus.kUserNotFound:
        ToastHelper.showErrorToast(
          context: context,
          message: "User not found. Please register first.",
        );
        break;

      case AppStatus.kSuccess:
        // User exists and login successful - go to home screen
        AppRouter.replace(context, ChatScreen());
        ToastHelper.showSuccessToast(
          context: context,
          message: "Login successful",
        );
        break;

      case AppStatus.kFailed:
      default:
        ToastHelper.showErrorToast(
          context: context,
          message: "Login failed. Please try again.",
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KBackgroundScaffold(
      loading: context.watchAuthProvider.isLoading,
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            spacing: 0.02.sh,
            children: [
              Lottie.asset(AppAssets.login, width: 0.80.sw),
              KCustomInputField(
                name: "email",
                hintText: "Email",
                controller: emailController,
                validators: [
                  FormBuilderValidators.email(),
                  FormBuilderValidators.required(
                    errorText: "Email is required",
                  ),
                ],
              ),
              KCustomInputField(
                isPassword: true,
                name: "password",
                hintText: "Password",
                controller: passwordController,
                validators: [
                  FormBuilderValidators.required(
                    errorText: "password is required",
                  ),
                  FormBuilderValidators.minLength(
                    6,
                    errorText: "Must be at least 6 characters",
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(right: AppStyles.padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () =>
                          AppRouter.to(context, AuthForgetPasswordScreen()),
                      child: Text("Forget password ?"),
                    ),
                  ],
                ),
              ),
              KCustomButton(
                text: "Login",
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (emailController.text.trim().isNotEmpty &&
                        passwordController.text.trim().isNotEmpty) {
                      print(emailController.text);
                      print(passwordController.text);

                      if (context.readInternetProvider.connectivityStatus ==
                          AppStatus.kDisconnected) {
                        print("Please connect to internet");
                      }
                      final result = await context.readAuthProvider
                          .signInWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            context: context,
                          );

                      getAuthBaseScreen(context, result);
                    }
                  }
                },
              ),
              KOrBar(),
              KGoogleAuthButton(
                onPressed: () async {
                  await context.readAuthProvider.signInWithGoogle(context);
                },
                text: 'continue with google',
              ),
              InkWell(
                onTap: () => AppRouter.to(context, AuthRegisterationScreen()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 0.02.sw,
                  children: [
                    Text(
                      "Not a member ?",
                      style: TextStyle(fontSize: AppStyles.subTitle),
                    ),
                    Text(
                      "Register",
                      style: TextStyle(
                        fontSize: AppStyles.subTitle,
                        color: AppStyles.links,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
