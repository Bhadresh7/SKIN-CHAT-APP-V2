import 'meta_model.dart';

class ChatMessageModel {
  final String messageId;
  final String senderId;
  final int createdAt;
  final String name;
  final MetaModel? metadata;

  ChatMessageModel({
    required this.messageId,
    required this.senderId,
    required this.createdAt,
    required this.name,
    required this.metadata,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String docId) {
    return ChatMessageModel(
      messageId: docId,
      metadata: MetaModel.fromJson(json['metadata']),
      senderId: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['ts'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': senderId,
      'ts': createdAt,
      'name': name,
      'metadata': metadata?.toJson(),
    };
  }

  int get timestamp => createdAt;

  @override
  String toString() {
    return 'ChatMessageModel{messageId: $messageId, createdAt: $createdAt}';
  }
}
