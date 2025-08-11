import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skin_app_migration/core/constants/app_db.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';
import 'package:skin_app_migration/features/profile/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _store = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // login with email and password
  Future<UsersModel?> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);

    // check the user is already present in the firestore
    try {
      final userSnapshot = await _store
          .collection(AppDb.kUserCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data();
        return UsersModel.fromFirestore(userData);
      }

      final adminSnapshot = await _store
          .collection(AppDb.kSuperAdminCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        final adminData = adminSnapshot.docs.first.data();
        return UsersModel.fromFirestore(adminData);
      }

      return null;
    } catch (e) {
      print("Error fetching user by email: $e");
      return null;
    }
  }

  // register with email and password
  Future<String> registerWithEmailAndPassword({
    required String username,
    required String password,
    required String email,
  }) async {


    return AppStatus.kSuccess;
  }

  ///check if the user is already exists in the db(Auth purpose)
  Future<bool> isUserNameExists({required String username}) async {
    try {
      final result = await Future.wait([
        _store
            .collection(AppDb.kUserCollection)
            .where('username', isEqualTo: username)
            .limit(1)
            .get(),
        _store
            .collection(AppDb.kSuperAdminCollection)
            .where('username', isEqualTo: username)
            .limit(1)
            .get(),
      ]);
      final userExists = result[0].docs.isNotEmpty;
      final superAdminExists = result[1].docs.isNotEmpty;
      return userExists || superAdminExists;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // google authentication
  Future<UsersModel?> googleAuthentication() async {
    if (_googleSignIn.currentUser != null) {
      await _googleSignIn.disconnect();
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    if (userCredential.user == null) {
      return null;
    }

    final userSnapshot = await _store
        .collection(AppDb.kUserCollection)
        .where('email', isEqualTo: googleUser.email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      final userData = userSnapshot.docs.first.data();
      return UsersModel.fromFirestore(userData);
    }

    final adminSnapshot = await _store
        .collection(AppDb.kSuperAdminCollection)
        .where('email', isEqualTo: googleUser.email)
        .limit(1)
        .get();

    if (adminSnapshot.docs.isNotEmpty) {
      final adminData = adminSnapshot.docs.first.data();
      return UsersModel.fromFirestore(adminData);
    }

    return null;
  }

  // send email to the user after registeration
  Future<String> sendEmailVerification() async {
    return AppStatus.kSuccess;
  }

  // resend email if the user changes the email
  Future<String> resendEmailVerification() async {
    return AppStatus.kSuccess;
  }

  /// cancel the email verification when the user goes back to
  /// registeration screen to change the email
  Future<void> cancelEmailVerification() async {}
}
