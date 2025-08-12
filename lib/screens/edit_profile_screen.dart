import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/constants/app_assets.dart';
import 'package:skin_app_migration/helpers/toast_helper.dart';
import 'package:skin_app_migration/models/user_model.dart';
import 'package:skin_app_migration/providers/my_auth_provider.dart';
import 'package:skin_app_migration/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/widgets/k_custom_button.dart';
import 'package:skin_app_migration/widgets/k_custom_input_field.dart';
import 'package:skin_app_migration/widgets/k_date_input_field.dart';

import '../providers/image_picker_provider.dart';
import '../providers/provider_extensions.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final ValueNotifier<bool> isUpdateEnabled = ValueNotifier(false);
  bool isLoading = true;
  bool isUpdating = false;

  late ImagePickerProvider imagePickerProvider;
  String? _userId;

  @override
  void initState() {
    super.initState();
    imagePickerProvider = context.read<ImagePickerProvider>();

    _userId = context.readAuthProvider.userData?.uid;

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _userId;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final data = doc.data();
    imagePickerProvider.selectProfileImage = null;
    if (data != null) {
      usernameController.text = data['username'] ?? '';
      mobileNumberController.text = data['mobileNumber'] ?? '';
      dateController.text = data['dob'] ?? '';

      print(context.readAuthProvider.userData!.dob);
      print(data['dob']);
      print(dateController.text.length);

      setState(() {
        isLoading = false;
      });
    }
    usernameController.addListener(_checkForChanges);
    mobileNumberController.addListener(_checkForChanges);
    dateController.addListener(_checkForChanges);
    imagePickerProvider.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final currentUser = context.readAuthProvider.userData;
    final selectedImage = context.readImagePickerProvider.selectProfileImage;

    final isChanged =
        usernameController.text.trim() != (currentUser?.username ?? "user") ||
        mobileNumberController.text.trim() !=
            (currentUser?.mobileNumber ?? "") ||
        dateController.text.trim() != (currentUser?.dob ?? "") ||
        selectedImage != null;
    print(isChanged);

    print(dateController.text);
    print(dateController.text.trim() != (currentUser?.dob ?? ""));

    isUpdateEnabled.value = isChanged;
  }

  Future<String?> _uploadImage(File file, String userId) async {
    final ref = FirebaseStorage.instance.ref().child(
      "users/$userId/profile.jpg",
    );
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = _userId;
    if (userId == null) return;

    String? imageUrl;
    final pickedImage = imagePickerProvider.selectProfileImage;
    isUpdating = true;
    setState(() {});
    if (pickedImage != null) {
      imageUrl = await _uploadImage(pickedImage, userId);
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'username': usernameController.text.trim(),
      'mobileNumber': mobileNumberController.text.trim(),
      'dob': dateController.text.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    Provider.of<MyAuthProvider>(
      context,
      listen: false,
    ).userData = UsersModel.fromFirestore(
      (await FirebaseFirestore.instance.collection('users').doc(userId).get())
              .data()
          as Map<String, dynamic>,
    );

    imagePickerProvider.clear();
    isUpdateEnabled.value = false;
    isUpdating = false;
    setState(() {});
    if (context.mounted) {
      ToastHelper.showSuccessToast(
        context: context,
        message: "Profile Updated Successfully",
      );
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    mobileNumberController.dispose();
    dateController.dispose();
    imagePickerProvider.removeListener(_checkForChanges);
    isUpdateEnabled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyAuthProvider authProvider = Provider.of<MyAuthProvider>(context);
    return PopScope(
      canPop: !isUpdating,
      child: KBackgroundScaffold(
        appBar: AppBar(title: Text('Edit Profile')),
        body: isLoading
            ? CircularProgressIndicator()
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Consumer<ImagePickerProvider>(
                            builder: (context, imgPickerProvider, _) {
                              return CircleAvatar(
                                radius: 0.3.sw,
                                backgroundImage:
                                    imgPickerProvider.selectProfileImage != null
                                    ? FileImage(
                                        imgPickerProvider.selectProfileImage!,
                                      )
                                    : authProvider.userData!.imageUrl != null
                                    ? NetworkImage(
                                        context
                                            .readAuthProvider
                                            .userData!
                                            .imageUrl!,
                                      )
                                    : authProvider.userData!.isGoogle!
                                    ? NetworkImage(
                                        context
                                            .readAuthProvider
                                            .user!
                                            .photoURL!,
                                      )
                                    : AssetImage(AppAssets.profileImage),
                              );
                            },
                          ),
                        ),
                        isUpdating
                            ? SizedBox()
                            : Positioned(
                                top: -0,
                                left:
                                    (MediaQuery.of(context).size.width / 2) +
                                    20,
                                // right: -10,
                                child: GestureDetector(
                                  onTap: () async {
                                    await imagePickerProvider
                                        .pickProfileImage();
                                  },
                                  child: CircleAvatar(child: Icon(Icons.edit)),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    KCustomInputField(
                      controller: usernameController,
                      name: 'name',
                      hintText: 'username',
                      readOnly: isUpdating,
                      validators: [FormBuilderValidators.required()],
                    ),
                    const SizedBox(height: 20),
                    KCustomInputField(
                      controller: mobileNumberController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      name: '',
                      readOnly: isUpdating,

                      hintText: '',
                      validators: [],
                    ),
                    const SizedBox(height: 20),

                    DateInputField(
                      controller: dateController,
                      readOnly: isUpdating,
                    ),
                    const SizedBox(height: 30),
                    isUpdating
                        ? Center(child: CircularProgressIndicator())
                        : ValueListenableBuilder<bool>(
                            valueListenable: isUpdateEnabled,
                            builder: (context, enabled, _) {
                              return !enabled
                                  ? SizedBox()
                                  : KCustomButton(
                                      text: "Update",
                                      onPressed: () {
                                        _handleUpdate();
                                      },
                                    );
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
