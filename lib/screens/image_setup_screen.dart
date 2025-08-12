import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/app_router.dart';
import 'package:skin_app_migration/constants/app_styles.dart';
import 'package:skin_app_migration/helpers/toast_helper.dart';
import 'package:skin_app_migration/models/user_model.dart';
import 'package:skin_app_migration/providers/image_picker_provider.dart';
import 'package:skin_app_migration/providers/my_auth_provider.dart';
import 'package:skin_app_migration/providers/provider_extensions.dart';
import 'package:skin_app_migration/screens/chat_screen.dart';
import 'package:skin_app_migration/widgets/k_custom_button.dart';

class ImageSetupScreen extends StatefulWidget {
  const ImageSetupScreen({super.key});

  @override
  State<ImageSetupScreen> createState() => _ImageSetupScreenState();
}

class _ImageSetupScreenState extends State<ImageSetupScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    final imagePickerProvider = context.watch<ImagePickerProvider>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                if (imagePickerProvider.selectedImage == null)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () async {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(context.readAuthProvider.user!.uid)
                              .update({'isImgSkipped': true});
                          context
                              .readAuthProvider
                              .userData = UsersModel.fromFirestore(
                            (await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(context.readAuthProvider.user!.uid)
                                        .get())
                                    .data()
                                as Map<String, dynamic>,
                          );

                          AppRouter.replace(context, ChatScreen());
                        },
                        child: Text(
                          "Skip",
                          style: TextStyle(
                            color: AppStyles.tertiary,
                            fontSize: AppStyles.heading,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SafeArea(child: SizedBox()),
                Expanded(
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            String status = await imagePickerProvider
                                .pickImage();
                            debugPrint("Image Pick Status: $status");
                            setState(() {});
                          },
                          child: CircleAvatar(
                            radius: 0.3.sw,
                            backgroundImage:
                                imagePickerProvider.selectedImage != null
                                ? FileImage(imagePickerProvider.selectedImage!)
                                : null, // ✅ Prevent error
                            child: imagePickerProvider.selectedImage == null
                                ? Icon(Icons.camera_alt, size: 85)
                                : null,
                          ),
                        ),

                        SizedBox(height: 40),
                        KCustomButton(
                          text: "Next",
                          isLoading: imagePickerProvider.isUploading,
                          onPressed: () async {
                            if (imagePickerProvider.selectedImage == null) {
                              ToastHelper.showErrorToast(
                                context: context,
                                message: "Please select a profile image",
                              );
                              return;
                            }

                            String userId = authProvider.user!.uid;
                            String? imageUrl = await imagePickerProvider
                                .uploadImageToFirebase(userId, context);

                            print(imageUrl);

                            if (imageUrl == null) {
                              ToastHelper.showErrorToast(
                                context: context,
                                message: "Image url not created",
                              );
                              return;
                            } else {
                              AppRouter.replace(context, ChatScreen());
                            }
                          },
                          width: 90.w,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isLoading)
              Positioned(
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
