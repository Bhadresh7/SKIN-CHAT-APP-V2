import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skin_app_migration/core/constants/app_db.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';
import 'package:skin_app_migration/features/super_admin/model/view_users_model.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _documentLimit = 10;

  /// Check if the given email belongs to a super admin
  Future<bool> findAdminByEmail({required String email}) async {
    try {
      var querySnapshot = await _firestore
          .collection(AppDb.kUserCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("❌ Error finding super admin: $e");
      return false;
    }
  }

  /// Toggle posting access for a user by email
  Future<void> togglePosting({required String email}) async {
    try {
      final snapshot = await _firestore
          .collection(AppDb.kUserCollection)
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final docId = doc.id;
        final currentCanPost = doc.get("canPost") as bool? ?? false;
        final newCanPost = !currentCanPost;

        await _firestore.collection(AppDb.kUserCollection).doc(docId).update({
          "canPost": newCanPost,
        });

        print("✅ canPost toggled to $newCanPost for $email");
      } else {
        print("⚠️ No user found with email: $email");
      }
    } catch (e) {
      print("❌ Error toggling canPost: $e");
    }
  }

  /// Update user posting access by user ID
  Future<void> updateUserPostingAccess(String userId, bool canPost) async {
    await _firestore.collection(AppDb.kUserCollection).doc(userId).update({
      'canPost': canPost,
    });
  }

  /// Block users by UID (legacy method - sets isBlocked to true and deletes token)
  Future<String> blockUsers({required String uid}) async {
    try {
      await _firestore.collection(AppDb.kUserCollection).doc(uid).update({
        'isBlocked': true,
      });

      await _firestore.collection('tokens').doc(uid).delete();
      return AppStatus.kSuccess;
    } catch (e) {
      print("❌ Error blocking user: $e");
      return AppStatus.kFailed;
    }
  }

  /// Update user block status by user ID (new method)
  Future<void> updateUserBlockStatus(String userId, bool isBlocked) async {
    await _firestore.collection(AppDb.kUserCollection).doc(userId).update({
      'isBlocked': isBlocked,
    });

    // If blocking user, also delete their token
    if (isBlocked) {
      try {
        await _firestore.collection('tokens').doc(userId).delete();
      } catch (e) {
        print("⚠️ Warning: Could not delete token for user $userId: $e");
      }
    }
  }

  /// Get filtered query based on filter type
  Query<Map<String, dynamic>> _getFilteredQuery(String filter) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      AppDb.kUserCollection,
    );

    switch (filter) {
      case "Employer":
        query = query.where('role', isEqualTo: 'admin');
        break;
      case "Candidates":
        query = query.where('role', isEqualTo: 'user');
        break;
      case "Blocked":
        query = query.where('isBlocked', isEqualTo: true);
        break;
    }
    return query.orderBy('username').limit(_documentLimit);
  }

  /// Get users with pagination support
  Future<QuerySnapshot> getUsers(
    String filter, {
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _getFilteredQuery(filter);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return await query.get();
  }

  /// Fetch users (legacy method for backward compatibility)
  Future<List<DocumentSnapshot>> fetchUsers({
    required String filter,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(AppDb.kUserCollection)
        .limit(limit);

    if (filter == "Employer") {
      query = query.where('role', isEqualTo: 'admin');
    } else if (filter == "Candidates") {
      query = query.where('role', isEqualTo: 'user');
    } else if (filter == "Blocked") {
      query = query.where('isBlocked', isEqualTo: true);
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  /// Get a specific user document by ID
  Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await _firestore.collection(AppDb.kUserCollection).doc(userId).get();
  }

  /// Get all user data by email
  Future<ViewUsersModel?> getAllUsers({required String email}) async {
    try {
      final userSnapshot = await _firestore
          .collection(AppDb.kUserCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();
        userData.forEach((key, value) {
          print("$key===>$value");
        });
        return ViewUsersModel.fromJson(userData);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user: ${e.toString()}');
      return null;
    }
  }
}
