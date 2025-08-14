// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_image_viewer/easy_image_viewer.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:logger/logger.dart';
// import 'package:metadata_fetch/metadata_fetch.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:skin_app_migration/constants/app_styles.dart';
// import 'package:skin_app_migration/helpers/app_logger.dart';
// import 'package:skin_app_migration/models/chat_message_model.dart';
// import 'package:skin_app_migration/providers/chat_provider.dart';
// import 'package:skin_app_migration/providers/provider_extensions.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ChatBubble extends StatefulWidget {
//   final ChatMessageModel chatMessage;
//
//   const ChatBubble({super.key, required this.chatMessage});
//
//   @override
//   State<ChatBubble> createState() => _ChatBubbleState();
// }
//
// class _ChatBubbleState extends State<ChatBubble> {
//   Metadata? previewData;
//   String? avatar;
//
//   String formatChatTimestamp(int createdAt) {
//     final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt).toLocal();
//     final formatter = DateFormat("dd MMM yy hh.mm a");
//     return formatter.format(dateTime);
//   }
//
//   late Widget content;
//   @override
//   void initState() {
//     super.initState();
//     AppLoggerHelper.logInfo("---------${widget.chatMessage.toJson()}");
//     FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.chatMessage.senderId)
//         .get()
//         .then((value) {
//           if (mounted && value.exists) {
//             setState(() {
//               avatar = value.data()!['imageUrl'];
//               AppLoggerHelper.logResponse(avatar);
//             });
//           }
//         });
//     AppLoggerHelper.logInfo("init called");
//     if (isUrl) {
//       print("isURl");
//       MetadataFetch.extract(widget.chatMessage.metadata!.url!).then((value) {
//         if (mounted && value != null) {
//           setState(() {
//             previewData = value;
//           });
//           print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$previewData");
//         }
//       });
//     }
//   }
//
//   bool get isImage => widget.chatMessage.metadata?.img != null;
//
//   bool get isUrl => widget.chatMessage.metadata?.url != null;
//
//   bool get isSender =>
//       widget.chatMessage.senderId == context.readAuthProvider.user!.uid;
//
//   String formatMessageTime(DateTime dateTime) {
//     return DateFormat('hh:mm a').format(dateTime);
//   }
//
//   BorderRadius getBubbleRadius() {
//     if (isSender) {
//       return const BorderRadius.only(
//         topLeft: Radius.circular(16),
//         topRight: Radius.circular(16),
//         bottomLeft: Radius.circular(16),
//         bottomRight: Radius.circular(0),
//       );
//     } else {
//       return const BorderRadius.only(
//         topLeft: Radius.circular(16),
//         topRight: Radius.circular(16),
//         bottomRight: Radius.circular(16),
//         bottomLeft: Radius.circular(0),
//       );
//     }
//   }
//
//   void _showDeleteDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         if (context.readAuthProvider.user!.uid == widget.chatMessage.senderId ||
//             context.readAuthProvider.userData!.role == "super_admin") {
//           return AlertDialog(
//             title: const Text('Delete Message'),
//             content: const Text(
//               'Are you sure you want to delete this message?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   Navigator.of(context).pop();
//                   await _deleteMessage();
//                 },
//                 style: TextButton.styleFrom(foregroundColor: Colors.red),
//                 child: const Text('Delete'),
//               ),
//             ],
//           );
//         } else {
//           return const SizedBox.shrink();
//         }
//       },
//     );
//   }
//
//   Future<void> _deleteMessage() async {
//     try {
//       final chatProvider = context.read<ChatProvider>();
//       await chatProvider.deleteMessage(widget.chatMessage.messageId);
//       AppLoggerHelper.logWarning(widget.chatMessage.senderId);
//       AppLoggerHelper.logWarning(widget.chatMessage.messageId);
//     } catch (e) {
//       debugPrint('❌ Error deleting message: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bubbleColor = isSender ? AppStyles.primary : Colors.grey[300];
//     final textColor = isSender ? Colors.white : Colors.black;
//     final maxWidth = MediaQuery.of(context).size.width * 0.6;
//
//     if (isImage) {
//       content = Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Hero(
//               transitionOnUserGestures: true,
//               tag: widget.chatMessage.metadata!.img!,
//               child: GestureDetector(
//                 onTap: () {
//                   showImageViewer(
//                     context,
//                     CachedNetworkImageProvider(
//                       widget.chatMessage.metadata!.img!,
//                     ),
//                     swipeDismissible: true,
//                     doubleTapZoomable: true,
//                     useSafeArea: true,
//                   );
//                 },
//                 child: CachedNetworkImage(
//                   imageUrl: widget.chatMessage.metadata!.img!,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           if (widget.chatMessage.metadata!.text != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 6.0),
//               child: Text(
//                 widget.chatMessage.metadata!.text!,
//                 style: TextStyle(color: textColor, fontSize: 16),
//               ),
//             ),
//         ],
//       );
//     } else if (isUrl &&
//         previewData != null &&
//         widget.chatMessage.metadata!.text != null) {
//       content = Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (previewData!.image != null)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: CachedNetworkImage(
//                 imageUrl: previewData!.image!,
//                 height: 0.6.sw,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           const SizedBox(height: 6),
//           if (previewData!.title != null)
//             Text(
//               previewData!.title!,
//               style: TextStyle(
//                 color: textColor,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           if (previewData!.description != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(
//                 previewData!.description!,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(color: textColor.withOpacity(0.8)),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.only(top: 4),
//             child: GestureDetector(
//               onTap: () async {
//                 final url = Uri.parse(widget.chatMessage.metadata!.url!);
//                 if (await canLaunchUrl(url)) {
//                   await launchUrl(url, mode: LaunchMode.externalApplication);
//                 } else {
//                   debugPrint("Cannot launch URL");
//                 }
//               },
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 spacing: 0.02.sh,
//                 children: [
//                   Text(
//                     widget.chatMessage.metadata!.url!,
//                     style: TextStyle(
//                       color: AppStyles.links,
//                       fontSize: 15,
//                       decoration: TextDecoration.underline,
//                       decorationColor: AppStyles.links,
//                       wordSpacing: 2.0,
//                       height: 1.5,
//                     ),
//                   ),
//                   Text(
//                     widget.chatMessage.metadata!.text!,
//                     style: TextStyle(
//                       color: isSender ? AppStyles.smoke : AppStyles.dark,
//                       fontSize: 15,
//                       wordSpacing: 2.0,
//                       height: 1.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     } else if (isUrl && previewData != null) {
//       content = Column(
//         children: [
//           if (previewData!.image != null)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: CachedNetworkImage(
//                 imageUrl: previewData!.image!,
//                 height: 0.6.sw,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           const SizedBox(height: 6),
//           if (previewData!.title != null)
//             Text(
//               previewData!.title!,
//               style: TextStyle(
//                 color: textColor,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           if (previewData!.description != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(
//                 previewData!.description!,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(color: textColor.withOpacity(0.8)),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.only(top: 4),
//             child: GestureDetector(
//               onTap: () async {
//                 final url = Uri.parse(widget.chatMessage.metadata!.url!);
//                 if (await canLaunchUrl(url)) {
//                   await launchUrl(url, mode: LaunchMode.externalApplication);
//                 } else {
//                   debugPrint("Cannot launch URL");
//                 }
//               },
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 spacing: 0.02.sh,
//                 children: [
//                   Text(
//                     widget.chatMessage.metadata!.url!,
//                     style: TextStyle(
//                       color: AppStyles.links,
//                       fontSize: 15,
//                       decoration: TextDecoration.underline,
//                       decorationColor: AppStyles.links,
//                       wordSpacing: 2.0,
//                       height: 1.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     } else if (isUrl) {
//       content = Text(
//         widget.chatMessage.metadata!.url!,
//         style: TextStyle(color: textColor, fontSize: 16),
//       );
//     } else {
//       content = Text(
//         widget.chatMessage.metadata!.text ?? "",
//         style: TextStyle(color: textColor, fontSize: 16),
//       );
//     }
//
//     Widget bubbleContent = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         content,
//         const SizedBox(height: 4),
//         Text(
//           formatChatTimestamp(widget.chatMessage.createdAt),
//           style: TextStyle(
//             fontWeight: FontWeight.w500,
//             fontSize: 10,
//             color: isSender ? AppStyles.smoke : AppStyles.dark,
//           ),
//         ),
//       ],
//     );
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//       child: isSender
//           ? Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Flexible(
//                   child: GestureDetector(
//                     onLongPress: isSender ? _showDeleteDialog : null,
//                     child: Container(
//                       padding: isImage || isUrl
//                           ? const EdgeInsets.all(6)
//                           : const EdgeInsets.symmetric(
//                               vertical: 10,
//                               horizontal: 14,
//                             ),
//                       decoration: BoxDecoration(
//                         color: bubbleColor,
//                         borderRadius: getBubbleRadius(),
//                       ),
//                       constraints: BoxConstraints(maxWidth: maxWidth),
//                       child: bubbleContent,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 avatar == null
//                     ? CircleAvatar(
//                         radius: 12,
//                         child: Text(widget.chatMessage.name[0]),
//                       )
//                     : CircleAvatar(
//                         radius: 12,
//                         backgroundImage: NetworkImage(avatar!),
//                       ),
//               ],
//             )
//           : Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 avatar == null
//                     ? CircleAvatar(
//                         radius: 12,
//                         child: Text(widget.chatMessage.name[0]),
//                       )
//                     : CircleAvatar(
//                         radius: 12,
//                         backgroundImage: CachedNetworkImageProvider(avatar!),
//                       ),
//                 const SizedBox(width: 8),
//                 Flexible(
//                   child: GestureDetector(
//                     onLongPress: isSender ? _showDeleteDialog : null,
//                     child: Container(
//                       padding: isImage || isUrl
//                           ? const EdgeInsets.all(6)
//                           : const EdgeInsets.symmetric(
//                               vertical: 10,
//                               horizontal: 14,
//                             ),
//                       decoration: BoxDecoration(
//                         color: bubbleColor,
//                         borderRadius: getBubbleRadius(),
//                       ),
//                       constraints: BoxConstraints(maxWidth: maxWidth),
//                       child: bubbleContent,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_linkify/flutter_linkify.dart';
// import 'package:intl/intl.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:skin_app_migration/constants/app_styles.dart';
// import 'package:skin_app_migration/models/chat_message_model.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ChatBubble extends StatelessWidget {
//   final ChatMessageModel chatMessage;
//   final bool isSender;
//   final String? avatarUrl;
//   final VoidCallback? onDelete;
//
//   const ChatBubble({
//     super.key,
//     required this.chatMessage,
//     this.avatarUrl,
//     this.onDelete,
//   });
//
//   bool get hasMainImage => (chatMessage.imageUrl?.isNotEmpty ?? false);
//
//   bool get hasMetadataImage =>
//       (chatMessage.metadata?.image?.isNotEmpty ?? false);
//
//   String formatChatTimestamp(int timestamp) {
//     final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
//     return DateFormat("d MMM yyyy hh:mm a").format(date).toLowerCase();
//   }
//
//   BorderRadius getBubbleRadius() {
//     return BorderRadius.only(
//       topLeft: Radius.circular(isSender ? 12 : 0),
//       topRight: Radius.circular(isSender ? 0 : 12),
//       bottomLeft: const Radius.circular(12),
//       bottomRight: const Radius.circular(12),
//     );
//   }
//
//   Future<void> _onOpenLink(LinkableElement link) async {
//     final Uri uri = Uri.parse(link.url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
//
//   Widget _buildMainImage(BuildContext context) {
//     final maxWidth = MediaQuery.of(context).size.width * 0.7;
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(12),
//       child: GestureDetector(
//         onTap: () {
//           // TODO: Implement image full-screen viewer
//         },
//         child: CachedNetworkImage(
//           imageUrl: chatMessage.imageUrl!,
//           width: maxWidth,
//           fit: BoxFit.cover,
//           placeholder: (context, url) => Shimmer.fromColors(
//             baseColor: Colors.grey[300]!,
//             highlightColor: Colors.grey[100]!,
//             child: Container(width: maxWidth, height: 200, color: Colors.white),
//           ),
//           errorWidget: (_, __, ___) =>
//               const Icon(Icons.broken_image, size: 50, color: Colors.grey),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMetadataCard(BuildContext context) {
//     final maxWidth = MediaQuery.of(context).size.width * 0.7;
//     final metadata = chatMessage.metadata!;
//
//     return Container(
//       decoration: BoxDecoration(
//         color: isSender ? AppStyles.primary.withOpacity(0.1) : Colors.grey[100],
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (metadata.image != null)
//             ClipRRect(
//               borderRadius: const BorderRadius.vertical(
//                 top: Radius.circular(12),
//               ),
//               child: CachedNetworkImage(
//                 imageUrl: metadata.image!,
//                 width: maxWidth,
//                 height: 180,
//                 fit: BoxFit.cover,
//                 placeholder: (context, url) => Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[100]!,
//                   child: Container(
//                     width: maxWidth,
//                     height: 180,
//                     color: Colors.white,
//                   ),
//                 ),
//                 errorWidget: (_, __, ___) => const Icon(
//                   Icons.broken_image,
//                   size: 50,
//                   color: Colors.grey,
//                 ),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (metadata.title != null)
//                   Text(
//                     metadata.title!,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 if (metadata.description != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Text(
//                       metadata.description!,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.black.withOpacity(0.8),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLinkifiedText() {
//     return SelectableLinkify(
//       text: chatMessage.text,
//       style: const TextStyle(fontSize: 16),
//       linkStyle: const TextStyle(
//         color: Colors.blue,
//         decoration: TextDecoration.underline,
//       ),
//       onOpen: _onOpenLink,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bubbleColor = isSender ? AppStyles.primary : Colors.grey[200];
//     final textColor = isSender ? Colors.white : Colors.black;
//     final maxWidth = MediaQuery.of(context).size.width * 0.7;
//
//     Widget messageContent;
//     if (hasMainImage) {
//       messageContent = _buildMainImage(context);
//     } else if (hasMetadataImage) {
//       messageContent = _buildMetadataCard(context);
//     } else {
//       messageContent = _buildLinkifiedText();
//     }
//
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//       child: Row(
//         mainAxisAlignment: isSender
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!isSender)
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: avatarUrl != null
//                   ? CachedNetworkImageProvider(avatarUrl!)
//                   : null,
//               child: avatarUrl == null
//                   ? Text(chatMessage.name[0].toUpperCase())
//                   : null,
//             ),
//           if (!isSender) const SizedBox(width: 8),
//
//           Flexible(
//             child: GestureDetector(
//               onLongPress: isSender ? onDelete : null,
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: bubbleColor,
//                   borderRadius: getBubbleRadius(),
//                 ),
//                 constraints: BoxConstraints(maxWidth: maxWidth),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     messageContent,
//                     const SizedBox(height: 4),
//                     Text(
//                       formatChatTimestamp(chatMessage.createdAt),
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: textColor.withOpacity(0.6),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           if (isSender) const SizedBox(width: 8),
//           if (isSender)
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: avatarUrl != null
//                   ? CachedNetworkImageProvider(avatarUrl!)
//                   : null,
//               child: avatarUrl == null
//                   ? Text(chatMessage.name[0].toUpperCase())
//                   : null,
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skin_app_migration/constants/app_styles.dart';
import 'package:skin_app_migration/helpers/app_logger.dart';
import 'package:skin_app_migration/models/chat_message_model.dart';
import 'package:skin_app_migration/providers/chat_provider.dart';
import 'package:skin_app_migration/providers/my_auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessageModel chatMessage;
  final String? avatarUrl;

  const ChatBubble({super.key, required this.chatMessage, this.avatarUrl});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  late bool isSender;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
    isSender = widget.chatMessage.senderId == authProvider.userData?.uid;
  }

  bool get hasMainImage => (widget.chatMessage.imageUrl?.isNotEmpty ?? false);

  bool get hasMetadataImage =>
      (widget.chatMessage.metadata?.image?.isNotEmpty ?? false);

  String formatChatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat("d MMM yyyy hh:mm a").format(date).toLowerCase();
  }

  BorderRadius getBubbleRadius() {
    return BorderRadius.only(
      topLeft: Radius.circular(isSender ? 12 : 0),
      topRight: Radius.circular(isSender ? 0 : 12),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );
  }

  Future<void> _onOpenLink(LinkableElement link) async {
    final Uri uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  void _showDeleteDialog() {
    final authProvider = context.read<MyAuthProvider>();
    final isSuperAdmin = authProvider.userData?.role == "super_admin";

    if (authProvider.userData?.uid == widget.chatMessage.senderId ||
        isSuperAdmin) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _deleteMessage();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildMainImage(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.7;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          // TODO: Implement full screen image viewer
        },
        child: CachedNetworkImage(
          imageUrl: widget.chatMessage.imageUrl!,
          width: maxWidth,
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: maxWidth, height: 200, color: Colors.white),
          ),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.7;
    final metadata = widget.chatMessage.metadata!;

    return Container(
      decoration: BoxDecoration(
        color: isSender ? AppStyles.primary.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: metadata.image!,
                width: maxWidth,
                height: 180,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: maxWidth,
                    height: 180,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metadata.title != null)
                  Text(
                    metadata.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                if (metadata.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      metadata.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkifiedText() {
    return SelectableLinkify(
      text: widget.chatMessage.text,
      style: const TextStyle(fontSize: 16),
      linkStyle: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
      onOpen: _onOpenLink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSender ? AppStyles.primary : Colors.grey[200];
    final textColor = isSender ? Colors.white : Colors.black;
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    Widget messageContent;
    if (hasMainImage) {
      messageContent = _buildMainImage(context);
    } else if (hasMetadataImage) {
      messageContent = _buildMetadataCard(context);
    } else {
      messageContent = _buildLinkifiedText();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isSender
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender)
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? Text(widget.chatMessage.name[0].toUpperCase())
                  : null,
            ),
          if (!isSender) const SizedBox(width: 8),

          Flexible(
            child: GestureDetector(
              onLongPress: _showDeleteDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: getBubbleRadius(),
                ),
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    messageContent,
                    const SizedBox(height: 4),
                    Text(
                      formatChatTimestamp(widget.chatMessage.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isSender) const SizedBox(width: 8),
          if (isSender)
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? Text(widget.chatMessage.name[0].toUpperCase())
                  : null,
            ),
        ],
      ),
    );
  }
}
