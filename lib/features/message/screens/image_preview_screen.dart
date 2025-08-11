import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/features/message/models/chat_message_model.dart';
import 'package:skin_app_migration/features/message/models/meta_model.dart';

class ImagePreviewScreen extends StatefulWidget {
  final File image;
  final String? initialText; // Add this parameter

  const ImagePreviewScreen({
    required this.image,
    this.initialText, // Make it optional
    super.key,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController textController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set initial text if provided
    print(
      "QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQq${widget.image.path}",
    );
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      textController.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // keep layout fixed
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () async {
          return !isLoading;
        },
        child: Stack(
          children: [
            // Main image viewer
            InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(child: Image.file(widget.image)),
            ),

            // Close button
            Positioned(
              top: AppStyles.screenHeight(context) * 0.05,
              left: AppStyles.screenWidth(context) * 0.04,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => isLoading ? () {} : AppRouter.back(context),
              ),
            ),

            // Caption input that moves with keyboard
            Positioned(
              left: 0,
              right: 0,
              bottom: AppStyles.bottomInset(context) > 0
                  ? AppStyles.bottomInset(context)
                  : AppStyles.screenHeight(context) / 15,
              child: Container(
                color: Colors.black54,
                padding: EdgeInsets.symmetric(
                  horizontal: AppStyles.screenWidth(context) * 0.03,
                  vertical: AppStyles.screenHeight(context) * 0.015,
                ),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          Expanded(
                            child: TextField(
                              cursorColor: AppStyles.smoke,
                              controller: textController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Add a caption...',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                              });
                              File? compressedImage = await context
                                  .readImagePickerProvider
                                  .compressImage(widget.image);

                              if (compressedImage == null) return;
                              String filePath =
                                  "chat_imgs/${context.readAuthProvider.user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg";
                              Reference storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(filePath);
                              UploadTask uploadTask = storageRef.putFile(
                                compressedImage,
                              );

                              // Optional: Show upload progress
                              uploadTask.snapshotEvents.listen((
                                TaskSnapshot snapshot,
                              ) {
                                double progress =
                                    snapshot.bytesTransferred /
                                    snapshot.totalBytes;
                                print(
                                  "📤 Upload Progress: ${(progress * 100).toStringAsFixed(2)}%",
                                );
                              });

                              TaskSnapshot snapshot = await uploadTask;
                              String downloadUrl = await snapshot.ref
                                  .getDownloadURL();
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .add(
                                    ChatMessageModel(
                                      messageId: '',
                                      metadata: MetaModel(
                                        img: downloadUrl,
                                        text: textController.text,
                                        url: extractFirstUrl(
                                          textController.text.trim(),
                                        ),
                                      ),
                                      senderId:
                                          context.readAuthProvider.user!.uid,
                                      createdAt:
                                          DateTime.now().millisecondsSinceEpoch,
                                      name:
                                          context
                                              .readAuthProvider
                                              .userData!
                                              .username ??
                                          context
                                              .readAuthProvider
                                              .user!
                                              .displayName ??
                                          "UnKnown",
                                    ).toJson(),
                                  );

                              isLoading = false;

                              AppRouter.back(context);
                            },
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

  String? extractFirstUrl(String text) {
    final urlRegex = RegExp(
      r'(?:(?:https?|ftp)://)?(?:[\w-]+\.)+[a-z]{2,}(?:/\S*)?',
      caseSensitive: false,
    );

    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }
}
