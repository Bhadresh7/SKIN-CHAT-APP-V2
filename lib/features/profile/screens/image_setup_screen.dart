import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/constants/app_assets.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/helpers/toast_helper.dart';
import 'package:skin_app_migration/core/provider/image_picker_provider.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';
import 'package:skin_app_migration/features/auth/providers/my_auth_provider.dart';
import 'package:skin_app_migration/features/message/screens/chat_screen.dart';
import 'package:skin_app_migration/features/profile/models/user_model.dart';

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
      child: KBackgroundScaffold(
        loading: isLoading,
        body: Column(
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
                      context.readAuthProvider.userData =
                          UsersModel.fromFirestore(
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
              ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        String status = await imagePickerProvider.pickImage();
                        debugPrint("Image Pick Status: $status");
                        setState(() {});
                      },
                      child: imagePickerProvider.selectedImage == null
                          ? SvgPicture.asset(AppAssets.profile, width: 0.7.sw)
                          : CircleAvatar(
                              radius: 0.4.sw,
                              backgroundImage:
                                  imagePickerProvider.selectedImage != null
                                  ? FileImage(
                                      imagePickerProvider.selectedImage!,
                                    )
                                  : null, // ✅ Prevent error
                              child: imagePickerProvider.selectedImage == null
                                  ? Icon(Icons.person, size: 50)
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
      ),
    );
  }
}
