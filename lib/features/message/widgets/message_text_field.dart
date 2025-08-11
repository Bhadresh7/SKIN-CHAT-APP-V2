import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/features/message/models/chat_message_model.dart';
import 'package:skin_app_migration/features/message/models/meta_model.dart';
import 'package:skin_app_migration/features/message/provider/chat_provider.dart';
import 'package:skin_app_migration/features/message/screens/image_preview_screen.dart';

class MessageTextField extends StatefulWidget {
  final TextEditingController messageController;

  const MessageTextField({super.key, required this.messageController});

  @override
  State<MessageTextField> createState() => _MessageTextFieldState();
}

class _MessageTextFieldState extends State<MessageTextField> {
  // late NotificationService service;
  int? maxLines;

  @override
  void initState() {
    super.initState();
    // service = NotificationService();
    // Initialize maxLines
    maxLines = widget.messageController.text.trim().isEmpty ? null : 2;
  }

  // Fixed _updateMaxLines method
  void _updateMaxLines() {
    if (mounted) {
      setState(() {
        maxLines = widget.messageController.text.trim().isEmpty ? null : 2;
      });
    }
  }

  String? extractFirstUrl(String text) {
    final urlRegex = RegExp(
      r'(?:(?:https?|ftp)://)?(?:[\w-]+\.)+[a-z]{2,}(?:/\S*)?',
      caseSensitive: false,
    );

    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  void _sendMessage() async {
    if (widget.messageController.text.trim().isEmpty) return;

    final chatProvider = context.read<ChatProvider>();

    final rawMessage = ChatMessageModel(
      metadata: MetaModel(text: widget.messageController.text.trim()),
      senderId: context.readAuthProvider.user?.uid ?? 'unknown',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      name:
          context.readAuthProvider.userData?.username ??
          context.readAuthProvider.user?.displayName ??
          'Unknown',
      messageId: '',
    );
    widget.messageController.clear();
    _updateMaxLines();
    await chatProvider.sendMessage(rawMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: AppStyles.primary,
                borderRadius: BorderRadius.circular(50),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Attachment button
                  IconButton(
                    onPressed: () async {
                      final status = await context.readImagePickerProvider
                          .pickImage();

                      if (status == AppStatus.kSuccess) {
                        AppRouter.to(
                          context,
                          ImagePreviewScreen(
                            image:
                                context.readImagePickerProvider.selectedImage!,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.attach_file, color: AppStyles.smoke),
                  ),

                  // Text field
                  Expanded(
                    child: TextField(
                      autofocus: false,
                      onChanged: (values) {
                        _updateMaxLines();
                      },
                      controller: widget.messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        hintStyle: TextStyle(color: AppStyles.smoke),
                      ),
                      style: TextStyle(color: AppStyles.smoke),
                      cursorColor: AppStyles.smoke,
                      maxLines: maxLines,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  const SizedBox(width: 8),
                  // Send button
                  IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: AppStyles.smoke),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
