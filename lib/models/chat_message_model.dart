import 'package:skin_app_migration/models/meta_model.dart';

class ChatMessageModel {
  final String messageId;
  final String senderId;
  final int createdAt;
  final String name;
  final String text;
  final String? imageUrl;
  final MetaModel? metadata;

  ChatMessageModel({
    required this.messageId,
    required this.senderId,
    required this.createdAt,
    required this.text,
    required this.imageUrl,
    required this.name,
    required this.metadata,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String docId) {
    return ChatMessageModel(
      messageId: docId,
      metadata: json['metadata'] != null
          ? MetaModel.fromJson(Map<String, dynamic>.from(json['metadata']))
          : null, // ✅ null-safe
      imageUrl: json['imageUrl'] as String,
      text: json['text'] as String,
      senderId: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': senderId,
      'ts': createdAt,
      'senderId': senderId,
      'name': name,
      'text': text,
      'imageUrl': imageUrl,
      'metadata': metadata?.toJson(),
    };
  }

  int get timestamp => createdAt;

  @override
  String toString() {
    return 'ChatMessageModel{messageId: $messageId, createdAt: $createdAt}';
  }
}
