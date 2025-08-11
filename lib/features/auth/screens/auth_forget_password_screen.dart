import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/helpers/toast_helper.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';
import 'package:skin_app_migration/core/widgets/k_custom_input_field.dart';

class AuthForgetPasswordScreen extends StatelessWidget {
  AuthForgetPasswordScreen({super.key});

  ///formKey
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  ///controller
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return KBackgroundScaffold(
      appBar: AppBar(),
      body: Form(
        key: formKey,
        child: Column(
          spacing: 0.03.sh,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KCustomInputField(
              name: "email",
              hintText: "Email",
              controller: emailController,
              validators: [
                FormBuilderValidators.email(),
                FormBuilderValidators.required(errorText: "Email is required"),
              ],
            ),
            KCustomButton(
              // isLoading: myAuthProvider.isLoading,
              prefixWidget: Icon(Icons.email, size: 0.025.sh),
              text: "Get email",
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final result = await context.readAuthProvider.resetPassword(
                  email: emailController.text.trim(),
                );

                if (context.mounted) {
                  if (result == AppStatus.kSuccess) {
                    ToastHelper.showSuccessToast(
                      context: context,
                      message: "Email has sent to your email",
                    );
                    AppRouter.back(context);
                  } else if (result == AppStatus.kEmailNotFound) {
                    ToastHelper.showErrorToast(
                      context: context,
                      message: "Email not exists",
                    );
                  } else {
                    ToastHelper.showErrorToast(
                      context: context,
                      message: "Error while sending email",
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
