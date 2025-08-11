import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';
import 'package:skin_app_migration/core/helpers/app_logger.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/service/local_db_service.dart';
import 'package:skin_app_migration/core/service/push_notification_service.dart';
import 'package:skin_app_migration/features/auth/screens/auth_login_screen.dart';
import 'package:skin_app_migration/features/auth/screens/email_verification_screen.dart';
import 'package:skin_app_migration/features/message/provider/chat_provider.dart';
import 'package:skin_app_migration/features/message/screens/chat_screen.dart';
import 'package:skin_app_migration/features/profile/models/user_model.dart';
import 'package:skin_app_migration/features/profile/screens/basic_user_details_form_screen.dart';
import 'package:skin_app_migration/features/profile/screens/image_setup_screen.dart';

class MyAuthProvider extends ChangeNotifier {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController userNameController = TextEditingController();

  final PushNotificationService _notificationService =
      PushNotificationService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  User? user;
  UsersModel? userData;

  // Add stream subscription for real-time updates
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  void _setLoadingState(bool value) {
    AppLoggerHelper.logInfo(value.toString());
    isLoading = value;
    notifyListeners();
  }

  // Method to start listening to user data changes
  void _startUserDataListener() {
    if (user == null) return;
    AppLoggerHelper.logInfo("Starting listener ...............");

    // Cancel existing subscription if any
    _userDataSubscription?.cancel();

    // Start listening to user document changes
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
            if (snapshot.exists) {
              try {
                final newUserData = UsersModel.fromFirestore(
                  snapshot.data()! as Map<String, dynamic>,
                );

                // Only update and notify if data actually changed
                if (_hasUserDataChanged(newUserData)) {
                  userData = newUserData;
                  AppLoggerHelper.logInfo(
                    'User data updated: canPost = ${userData!.canPost}',
                  );
                  notifyListeners();
                }
              } catch (e) {
                AppLoggerHelper.logError('Error parsing user data: $e');
              }
            }
          },
          onError: (error) {
            AppLoggerHelper.logError('Error listening to user data: $error');
          },
        );
  }

  // Helper method to check if user data has changed
  bool _hasUserDataChanged(UsersModel newUserData) {
    if (userData == null) return true;

    return userData!.canPost != newUserData.canPost ||
        userData!.isBlocked != newUserData.isBlocked;
  }

  // Method to stop listening to user data changes
  void _stopUserDataListener() {
    _userDataSubscription?.cancel();
    _userDataSubscription = null;
  }

  void initialize(context) async {
    _setLoadingState(true);
    notifyListeners();

    try {
      // Get current user without network call first
      await LocalDBService().init();
      user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          // Try to reload user data to get fresh auth state
          await user!.reload();
          // Update user reference after reload
          user = FirebaseAuth.instance.currentUser;
          print("User reloaded successfully");
        } catch (e) {
          print("Network error during user reload: $e");
          // Continue with cached user data if network fails
          print("Continuing with cached user data");
        }
      }

      print("Current user: $user");

      if (user == null) {
        AppRouter.replace(context, AuthLoginScreen());
      } else if (!(user!.emailVerified)) {
        // Check email verification with network fallback
        try {
          await user!.reload();
          user = FirebaseAuth.instance.currentUser;
          if (!(user!.emailVerified)) {
            AppRouter.replace(context, EmailVerificationScreen());
          } else {
            // Email was verified, continue to next step
            await _proceedToUserDataCheck(context);
          }
        } catch (e) {
          print("Network error checking email verification: $e");
          // If network fails, assume email needs verification based on cached state
          AppRouter.replace(context, EmailVerificationScreen());
        }
      } else {
        ChatProvider chatProvider = Provider.of<ChatProvider>(
          context,
          listen: false,
        );
        chatProvider.initializeSharingIntent(context);
        chatProvider.initIntentHandling();
        await _proceedToUserDataCheck(context);
      }
    } catch (e) {
      print("Error during initialization: $e");
      // Fallback to login screen if initialization fails completely
      AppRouter.replace(context, AuthLoginScreen());
    } finally {
      _setLoadingState(false);
      notifyListeners();
    }
  }

  Future<void> _proceedToUserDataCheck(context) async {
    try {
      print(user!.uid);
      // Try to get user data from Firestore
      DocumentSnapshot tempData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (!tempData.exists) {
        print("User data does not exist");
        AppRouter.replace(context, BasicUserDetailsFormScreen());
      } else {
        userData = UsersModel.fromFirestore(
          tempData.data()! as Map<String, dynamic>,
        );

        // Start listening to real-time updates
        _startUserDataListener();

        if (!(userData!.isGoogle)! &&
            (userData!.imageUrl) == null &&
            !(userData!.isImgSkipped)) {
          AppRouter.replace(context, ImageSetupScreen());
        } else {
          // Initialize chat provider only after successful auth
          try {
            final chatProvider = Provider.of<ChatProvider>(
              context,
              listen: false,
            );

            await chatProvider.loadMessages();
            chatProvider.startFirestoreListener();
            await chatProvider.syncNewMessagesFromFirestore();
          } catch (e) {
            print("Error initializing chat provider: $e");
          }
          AppRouter.replace(context, ChatScreen());
        }
      }
    } catch (e) {
      print("Error accessing user data: $e");
      // If Firestore fails, go to basic user details to ensure user can proceed
      AppRouter.replace(context, BasicUserDetailsFormScreen());
    }
  }

  // login with email and password
  Future<String> signInWithEmailAndPassword({
    required String email,
    required String password,
    context,
  }) async {
    try {
      _setLoadingState(true);
      notifyListeners();

      var userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        user = userCredential.user;

        await _notificationService.subscribeToUserTopic(user!.email!);

        if (!user!.emailVerified) {
          _setLoadingState(false);
          AppRouter.replace(context, EmailVerificationScreen());
          return AppStatus.kSuccess;
        }

        try {
          // Try to get user data from Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

          if (userDoc.exists) {
            userData = UsersModel.fromFirestore(
              userDoc.data()! as Map<String, dynamic>,
            );

            // Start listening to real-time updates after successful login
            _startUserDataListener();
          }
          if (userData!.isBlocked) {
            return AppStatus.kBlocked;
          }
        } catch (e) {
          print("Error fetching user data after login: $e");
          // Continue without user data, will be handled in initialize
        }

        _setLoadingState(false);
        notifyListeners();
        return AppStatus.kSuccess;
      } else {
        _setLoadingState(false);
        notifyListeners();
        return AppStatus.kFailed;
      }
    } on FirebaseAuthException catch (e) {
      _setLoadingState(false);
      notifyListeners();
      print("Login error: ${e.code} - ${e.message}");
      return e.message ?? AppStatus.kFailed;
    } catch (e) {
      _setLoadingState(false);
      notifyListeners();
      print("Login error: $e");
      return AppStatus.kFailed;
    }
  }

  Future<String> signInWithGoogle(BuildContext context) async {
    try {
      _setLoadingState(true);
      notifyListeners();

      AppLoggerHelper.logInfo('Google sign-in started.');

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setLoadingState(false);
        AppLoggerHelper.logInfo('Google sign-in cancelled by user.');
        notifyListeners();
        return AppStatus.kFailed;
      }

      AppLoggerHelper.logInfo(
        'Google sign-in account selected: ${googleUser.email}',
      );

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      AppLoggerHelper.logInfo('Google auth token received.');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      AppLoggerHelper.logInfo('Firebase credential created.');

      var userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        user = userCredential.user;
        final uid = user!.uid;

        AppLoggerHelper.logInfo('Google sign-in successful. UID: $uid');

        // Subscribe to push notifications
        await _notificationService.subscribeToUserTopic(user!.email!);

        // 🔍 Fetch user data from Firestore
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;

          AppLoggerHelper.logInfo(data.values.toString());
          final isBlocked = data['isBlocked'] ?? false;

          if (isBlocked == true) {
            AppLoggerHelper.logInfo('Blocked user attempted to sign in: $uid');
            // 🔐 Sign out the blocked user
            await _auth.signOut();
            await GoogleSignIn().signOut();

            _setLoadingState(false);
            notifyListeners();

            // 📌 Show dialog
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Access Denied'),
                content: const Text(
                  'Your account has been blocked. Please contact support.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );

            return AppStatus.kFailed;
          } else {
            AppLoggerHelper.logInfo("After google auth In the else block");
            // Store user data and start listening to updates
            userData = UsersModel.fromFirestore(data);
            final user = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get();

            AppLoggerHelper.logInfo(
              "In the else block ${user.data()!.values.toString()}",
            );

            // Navigate to appropriate screen based on user data
            _setLoadingState(false);
            if (userData != null) {
              AppLoggerHelper.logInfo(
                "After checking the user data in the else block",
              );
              AppRouter.replace(context, ChatScreen());
              AppLoggerHelper.logInfo(
                "After checking the user data in the else block....",
              );
              _startUserDataListener();
            }

            notifyListeners();
            return AppStatus.kSuccess;
          }
        } else {
          // User document doesn't exist, navigate to basic user details
          _setLoadingState(false);
          notifyListeners();
          AppRouter.replace(context, BasicUserDetailsFormScreen());
          return AppStatus.kSuccess;
        }
      }

      AppLoggerHelper.logError(
        'Firebase returned null user after Google sign-in.',
      );
      _setLoadingState(false);
      notifyListeners();
      return AppStatus.kFailed;
    } on FirebaseAuthException catch (e) {
      _setLoadingState(false);
      AppLoggerHelper.logError(
        'FirebaseAuthException during Google sign-in: ${e.code} - ${e.message}',
      );
      notifyListeners();
      return e.message ?? AppStatus.kFailed;
    } catch (e) {
      _setLoadingState(false);
      AppLoggerHelper.logError('Unexpected error during Google sign-in: $e');
      notifyListeners();
      return AppStatus.kFailed;
    }
  }

  // Registration using email and password
  Future<String> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoadingState(true);

      // Create user
      var userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      await _notificationService.subscribeToUserTopic(user!.email!);

      if (user == null) {
        _setLoadingState(false);
        notifyListeners();
        return AppStatus.kFailed;
      }

      // Send email verification
      try {
        await user!.sendEmailVerification();
        print("Email verification sent");
      } catch (e) {
        print("Error sending verification email: $e");
        // Continue even if email verification fails
      }

      _setLoadingState(false);
      notifyListeners();
      return AppStatus.kSuccess;
    } on FirebaseAuthException catch (e) {
      _setLoadingState(false);
      notifyListeners();

      if (e.code == 'email-already-in-use') {
        return AppStatus.kEmailAlreadyExists;
      }
      return e.message ?? "Authentication failed";
    } catch (e) {
      _setLoadingState(false);
      notifyListeners();
      debugPrint("Sign up error: $e");
      return "Sign up failed";
    }
  }

  Future<String> resetPassword({required String email}) async {
    try {
      _setLoadingState(true);
      // Check if the email exists in Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _auth.setLanguageCode("en");
        await _auth.sendPasswordResetEmail(email: email);
        _setLoadingState(false);
        return AppStatus.kSuccess;
      } else {
        _setLoadingState(false);
        return AppStatus.kEmailNotFound;
      }
    } catch (e) {
      _setLoadingState(false);
      debugPrint("Reset password error: $e");
      return "Password reset failed. Try again.";
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      AppRouter.offAll(context, AuthLoginScreen());

      // Stop listening to user data updates
      _stopUserDataListener();

      await _notificationService.unsubscribeFromUserTopic(user!.email!);

      await _auth.signOut();
      if (await GoogleSignIn().isSignedIn()) {
        await GoogleSignIn().signOut();
      }

      // Clear user data
      user = null;
      userData = null;
    } catch (e) {
      print("Sign-out error: $e");
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _stopUserDataListener();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    userNameController.dispose();
    super.dispose();
  }
}
