import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skin_app_migration/core/helpers/timestamp_helper.dart';

class UsersModel {
  UsersModel({
    required this.mobileNumber,
    required this.uid,
    required this.username,
    required this.email,
    this.password,
    required this.role,
    this.isGoogle,
    this.isAdmin = false,
    this.canPost = false,
    this.isBlocked = false,
    required this.dob,
    this.createdAt,
    this.imageUrl,
    this.isImgSkipped = false,
  });

  final String uid;
  final String? username;
  final String email;
  String? password;
  bool? isGoogle;
  String role;
  final bool isAdmin;
  bool canPost;
  bool isBlocked;
  bool isImgSkipped;

  final String mobileNumber;
  final String dob;
  final String? createdAt;
  String? imageUrl;

  /// Convert the data to a map to store in Firebase
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'isGoogle': isGoogle,
      'isAdmin': isAdmin,
      'canPost': canPost,
      'isBlocked': isBlocked,
      'mobileNumber': mobileNumber,
      'dob': dob,
      'createdAt': createdAt != null
          ? TimestampHelper.stringToTimestamp(createdAt)
          : FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'isImgSkipped': isImgSkipped,
    };
  }

  /// Convert Firestore document to a `UsersModel` object
  factory UsersModel.fromFirestore(Map<String, dynamic> data) {
    return UsersModel(
      uid: data['uid'] ?? '',
      username: data['username'],
      email: data['email'] ?? '',
      password: data['password'],
      role: data['role'] ?? '',
      isGoogle: data['isGoogle'],
      isAdmin: data['isAdmin'] ?? false,
      canPost: data['canPost'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      mobileNumber: data['mobileNumber'] ?? '',
      dob: data['dob'] ?? '',
      createdAt: data['createdAt'] != null
          ? TimestampHelper.timestampToString(data['createdAt'] as Timestamp)
          : null,
      imageUrl: data['imageUrl'],
      isImgSkipped: data['isImgSkipped'] ?? false,
    );
  }

  @override
  String toString() {
    return '''
Users {
  uid: $uid,
  username: $username,
  email: $email,
  password: ${password ?? 'N/A'},
  isGoogle: ${isGoogle ?? 'N/A'},
  role: $role,
  isAdmin: $isAdmin,
  canPost: $canPost,
  isBlocked: $isBlocked,
  mobileNumber: $mobileNumber,
  dob: $dob,
  createdAt: $createdAt,
  imageUrl: ${imageUrl ?? 'N/A'},
  isImgSkipped: ${isImgSkipped},
}
''';
  }
}
