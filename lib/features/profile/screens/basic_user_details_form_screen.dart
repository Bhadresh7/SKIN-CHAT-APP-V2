import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/constants/app_assets.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/helpers/app_logger.dart';
import 'package:skin_app_migration/core/helpers/toast_helper.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';
import 'package:skin_app_migration/core/widgets/k_custom_input_field.dart';
import 'package:skin_app_migration/core/widgets/k_date_input_field.dart';
import 'package:skin_app_migration/features/about/terms_and_conditions.dart';
import 'package:skin_app_migration/features/auth/providers/my_auth_provider.dart';
import 'package:skin_app_migration/features/message/screens/chat_screen.dart';
import 'package:skin_app_migration/features/profile/models/user_model.dart';
import 'package:skin_app_migration/features/profile/screens/image_setup_screen.dart';

class BasicUserDetailsFormScreen extends StatefulWidget {
  const BasicUserDetailsFormScreen({super.key});

  @override
  State<BasicUserDetailsFormScreen> createState() =>
      _BasicUserDetailsFormScreenState();
}

class _BasicUserDetailsFormScreenState
    extends State<BasicUserDetailsFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController userNameController;
  late TextEditingController mobileNumberController;
  late TextEditingController dateController;

  String? selectedRole;

  bool isLoading = false;

  @override
  void initState() {
    userNameController = TextEditingController();
    mobileNumberController = TextEditingController();
    dateController = TextEditingController();
    super.initState();
    print("BASIC USER DETAILS ${userNameController.text}");
  }

  @override
  void dispose() {
    userNameController.dispose();
    dateController.dispose();
    mobileNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    return PopScope(
      canPop: false,
      child: KBackgroundScaffold(
        loading: isLoading,
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            key: _formKey,
            child: Center(
              child: Column(
                spacing: 0.025.sh,
                children: [
                  Lottie.asset(AppAssets.login, height: 0.3.sh),
                  KCustomInputField(
                    controller: userNameController,
                    name: "name",
                    hintText: "name",
                    validators: [
                      FormBuilderValidators.required(
                        errorText: "name is required",
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: FormBuilderRadioGroup<String>(
                      name: 'role',
                      decoration: InputDecoration(border: InputBorder.none),
                      validator: FormBuilderValidators.required(
                        errorText: "Please select a role",
                      ),
                      options: [
                        FormBuilderFieldOption(
                          value: "admin",
                          child: Text(
                            "Employer",
                            style: TextStyle(fontSize: AppStyles.subTitle),
                          ),
                        ),
                        FormBuilderFieldOption(
                          value: "user",
                          child: Text(
                            "Candidate",
                            style: TextStyle(fontSize: AppStyles.subTitle),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        selectedRole = value;
                      },
                    ),
                  ),
                  KCustomInputField(
                    controller: mobileNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    name: "mobile number",
                    hintText: "mobile number",
                    validators: [
                      FormBuilderValidators.required(
                        errorText: "Mobile number is required",
                      ),
                      FormBuilderValidators.match(
                        RegExp(r'^[6-9]\d{9}$'),
                        errorText: "Enter a valid 10-digit mobile number",
                      ),
                    ],
                  ),
                  DateInputField(controller: dateController),
                  KCustomButton(
                    text: "submit",
                    onPressed: () async {
                      print('submitting.....');
                      if (_formKey.currentState!.validate() &&
                          selectedRole != null) {
                        isLoading = true;
                        setState(() {});
                        QuerySnapshot _tempData = await FirebaseFirestore
                            .instance
                            .collection('users')
                            .where(
                              'username',
                              isEqualTo: userNameController.text.trim(),
                            )
                            .get();
                        if (_tempData.docs.isNotEmpty) {
                          ToastHelper.showErrorToast(
                            context: context,
                            message:
                                'Username already exists, Try a different name.',
                          );
                          isLoading = false;
                          setState(() {});
                          return;
                        }
                        print('submitting..... 1');

                        UsersModel user = UsersModel(
                          dob: dateController.text.trim(),
                          mobileNumber: mobileNumberController.text.trim(),
                          uid: authProvider.user!.uid,
                          username: userNameController.text.trim(),
                          email: authProvider.user!.email!,
                          role: selectedRole!,
                          isGoogle:
                              authProvider
                                      .user!
                                      .providerData
                                      .first
                                      .providerId ==
                                  "google.com"
                              ? true
                              : false,
                          isBlocked: false,
                          canPost: false,
                          isAdmin: selectedRole! == "admin" ? true : false,
                        );
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(authProvider.user!.uid)
                            .set(user.toJson());
                        print('submitting..... 2');

                        print(
                          "BASIC USER DEATILS SCREEN ==================${user.toJson()}",
                        );
                        isLoading = false;

                        if (authProvider.user!.providerData.first.providerId ==
                            "google.com") {
                          authProvider.userData = UsersModel.fromFirestore(
                            (await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(context.readAuthProvider.user!.uid)
                                    .get())
                                .data()!,
                          );

                          if (authProvider.userData != null) {
                            AppLoggerHelper.logInfo(
                              "Before navigating to the chat screen",
                            );
                            AppRouter.replace(context, ChatScreen());
                          }
                        } else {
                          AppRouter.replace(context, ImageSetupScreen());
                        }
                      } else {
                        ToastHelper.showErrorToast(
                          context: context,
                          message: "Add All data",
                        );
                      }
                    },
                  ),
                  InkWell(
                    onTap: () =>
                        AppRouter.to(context, TermsAndConditionsScreen()),
                    child: Text(
                      "Terms & Conditions",
                      style: TextStyle(color: AppStyles.links),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
