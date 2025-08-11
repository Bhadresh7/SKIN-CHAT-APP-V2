import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/helpers/app_logger.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/features/message/models/chat_message_model.dart';
import 'package:skin_app_migration/features/message/provider/chat_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessageModel chatMessage;

  const ChatBubble({super.key, required this.chatMessage});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  Metadata? metadata;
  String? avatar;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.chatMessage.senderId)
        .get()
        .then((value) {
          if (mounted && value.exists) {
            setState(() {
              avatar = value.data()!['imageUrl'];
            });
          }
        });

    if (isUrl) {
      print("isURl");
      MetadataFetch.extract(widget.chatMessage.metadata!.url!).then((value) {
        if (mounted && value != null) {
          setState(() {
            metadata = value;
          });
          print(metadata);
        }
      });
    }
  }

  bool get isImage => widget.chatMessage.metadata?.img != null;

  bool get isUrl => widget.chatMessage.metadata?.url != null;

  bool get isSender =>
      widget.chatMessage.senderId == context.readAuthProvider.user!.uid;

  String formatMessageTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  BorderRadius getBubbleRadius() {
    if (isSender) {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(0),
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
        bottomLeft: Radius.circular(0),
      );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        if (context.readAuthProvider.user!.uid == widget.chatMessage.senderId ||
            context.readAuthProvider.userData!.role == "super_admin") {
          return AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _deleteMessage();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _deleteMessage() async {
    try {
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.deleteMessage(widget.chatMessage.messageId);
      AppLoggerHelper.logWarning(widget.chatMessage.senderId);
      AppLoggerHelper.logWarning(widget.chatMessage.messageId);
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSender ? AppStyles.primary : Colors.grey[300];
    final textColor = isSender ? Colors.white : Colors.black;
    final maxWidth = MediaQuery.of(context).size.width * 0.6;

    Widget content;
    if (isImage) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              transitionOnUserGestures: true,
              tag: widget.chatMessage.metadata!.img!,
              child: GestureDetector(
                onTap: () {
                  showImageViewer(
                    context,
                    CachedNetworkImageProvider(
                      widget.chatMessage.metadata!.img!,
                    ),
                    swipeDismissible: true,
                    doubleTapZoomable: true,
                    useSafeArea: true,
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: widget.chatMessage.metadata!.img!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (widget.chatMessage.metadata!.text != null)
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Text(
                widget.chatMessage.metadata!.text!,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
        ],
      );
    } else if (isUrl &&
        metadata != null &&
        widget.chatMessage.metadata!.text != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata!.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                metadata!.image!,
                height: 0.6.sw,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 6),
          if (metadata!.title != null)
            Text(
              metadata!.title!,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (metadata!.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                metadata!.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor.withOpacity(0.8)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () async {
                final url = Uri.parse(widget.chatMessage.metadata!.url!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  debugPrint("Cannot launch URL");
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 0.02.sh,
                children: [
                  Text(
                    widget.chatMessage.metadata!.url!,
                    style: TextStyle(
                      color: AppStyles.links,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: AppStyles.links,
                      wordSpacing: 2.0,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    widget.chatMessage.metadata!.text!,
                    style: TextStyle(
                      color: AppStyles.smoke,
                      fontSize: 12,
                      wordSpacing: 2.0,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (isUrl) {
      content = Text(
        widget.chatMessage.metadata!.url!,
        style: TextStyle(color: textColor, fontSize: 16),
      );
    } else {
      content = Text(
        widget.chatMessage.metadata!.text ?? "",
        style: TextStyle(color: textColor, fontSize: 16),
      );
    }

    Widget bubbleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        const SizedBox(height: 4),
        Text(
          DateFormat("hh:mm a")
              .format(
                DateTime.fromMillisecondsSinceEpoch(
                  widget.chatMessage.createdAt,
                ),
              )
              .toLowerCase(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 0.02.sw,
            color: isSender ? AppStyles.smoke : AppStyles.dark,
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: isSender
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: GestureDetector(
                    onLongPress: isSender ? _showDeleteDialog : null,
                    child: Container(
                      padding: isImage || isUrl
                          ? const EdgeInsets.all(6)
                          : const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: getBubbleRadius(),
                      ),
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: bubbleContent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                avatar == null
                    ? CircleAvatar(
                        radius: 12,
                        child: Text(widget.chatMessage.name[0]),
                      )
                    : CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(avatar!),
                      ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                avatar == null
                    ? CircleAvatar(
                        radius: 12,
                        child: Text(widget.chatMessage.name[0]),
                      )
                    : CircleAvatar(
                        radius: 12,
                        backgroundImage: CachedNetworkImageProvider(avatar!),
                      ),
                const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    onLongPress: isSender ? _showDeleteDialog : null,
                    child: Container(
                      padding: isImage || isUrl
                          ? const EdgeInsets.all(6)
                          : const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: getBubbleRadius(),
                      ),
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: bubbleContent,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
