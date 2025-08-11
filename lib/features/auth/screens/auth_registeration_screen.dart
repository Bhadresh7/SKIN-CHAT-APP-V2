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
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart'
    show KBackgroundScaffold;
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';
import 'package:skin_app_migration/core/widgets/k_custom_input_field.dart';
import 'package:skin_app_migration/features/auth/providers/my_auth_provider.dart';
import 'package:skin_app_migration/features/auth/screens/auth_login_screen.dart';
import 'package:skin_app_migration/features/auth/screens/email_verification_screen.dart';
import 'package:skin_app_migration/features/auth/widgets/k_google_auth_button.dart';
import 'package:skin_app_migration/features/auth/widgets/k_or_bar.dart';

class AuthRegisterationScreen extends StatefulWidget {
  const AuthRegisterationScreen({super.key});

  @override
  State<AuthRegisterationScreen> createState() =>
      _AuthRegisterationScreenState();
}

class _AuthRegisterationScreenState extends State<AuthRegisterationScreen> {
  @override
  Widget build(BuildContext context) {
    /// formKey
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return KBackgroundScaffold(
      loading: context.watchAuthProvider.isLoading,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Form(
          key: formKey,
          child: Column(
            spacing: 0.025.sh,
            children: [
              Lottie.asset(AppAssets.login, height: 0.25.sh),

              KCustomInputField(
                name: "email",
                hintText: "Email",
                controller: context.readAuthProvider.emailController,
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
                controller: context.readAuthProvider.passwordController,
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
              KCustomInputField(
                isPassword: true,
                name: "confirm password",
                hintText: "Confirm Password",
                controller: context.readAuthProvider.confirmPasswordController,
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
              KCustomButton(
                text: "Register",
                onPressed: () async {
                  MyAuthProvider authProvider = context.readAuthProvider;
                  if (formKey.currentState!.validate()) {
                    if (!(authProvider.passwordController.text.trim() ==
                        authProvider.confirmPasswordController.text.trim())) {
                      return ToastHelper.showErrorToast(
                        context: context,
                        message: "Password doesn't match",
                      );
                    }

                    final result = await authProvider
                        .signUpWithEmailAndPassword(
                          email: authProvider.emailController.text.trim(),
                          password: authProvider.passwordController.text.trim(),
                        );
                    if (context.mounted) {
                      switch (result) {
                        case AppStatus.kUserNameAlreadyExists:
                          return ToastHelper.showErrorToast(
                            context: context,
                            message: AppStatus.kUserNameAlreadyExists,
                          );
                        case AppStatus.kEmailAlreadyExists:
                          return ToastHelper.showErrorToast(
                            context: context,
                            message: AppStatus.kEmailAlreadyExists,
                          );
                        case AppStatus.kUserFound:
                          return ToastHelper.showErrorToast(
                            context: context,
                            message: "Username already exists",
                          );
                        case AppStatus.kFailed:
                          return ToastHelper.showErrorToast(
                            context: context,
                            message: "Failed to Register",
                          );
                        case AppStatus.kSuccess:
                          ToastHelper.showSuccessToast(
                            context: context,
                            message: "Registeration successful",
                          );
                          AppRouter.replace(context, EmailVerificationScreen());
                          break;
                        default:
                          return ToastHelper.showErrorToast(
                            context: context,
                            message: result,
                          );
                      }
                    }
                  }
                },
              ),

              ///---or--- Divider
              KOrBar(),

              ///OAuthButton
              KGoogleAuthButton(
                onPressed: () async {
                  await context.readAuthProvider.signInWithGoogle(context);
                },
                text: 'continue with google',
              ),

              InkWell(
                onTap: () => AppRouter.replace(context, AuthLoginScreen()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 0.02.sw,
                  children: [
                    Text(
                      "Already a member ?",
                      style: TextStyle(fontSize: AppStyles.subTitle),
                    ),
                    Text(
                      "Login",
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
