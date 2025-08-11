import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skin_app_migration/core/constants/app_status.dart';
import 'package:skin_app_migration/features/super_admin/model/view_users_model.dart';
import 'package:skin_app_migration/features/super_admin/service/super_admin_service.dart';

class SuperAdminProvider with ChangeNotifier {
  final SuperAdminService _service = SuperAdminService();

  // Super Admin Status
  bool _isSuperAdmin = false;

  bool get isSuperAdmin => _isSuperAdmin;

  // Loading States
  bool _loading = false;
  bool _isBlockLoading = false;
  bool _isAdminLoading = false;
  bool _isLoading = false;

  bool get loading => _loading;

  bool get isBlockLoading => _isBlockLoading;

  bool get isAdminLoading => _isAdminLoading;

  bool get isLoading => _isLoading;

  // User Data
  ViewUsersModel? _viewUsers;

  ViewUsersModel? get viewUsers => _viewUsers;

  // Pagination Data
  List<DocumentSnapshot> _users = [];
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _currentFilter = "";

  List<DocumentSnapshot> get users => _users;

  bool get hasMore => _hasMore;

  bool get isEmpty => _users.isEmpty;

  // Set general loading state
  void setLoadingState(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// Check if user is super admin
  Future<void> checkSuperAdminStatus(String email) async {
    try {
      setLoadingState(true);
      _isSuperAdmin = await _service.findAdminByEmail(email: email);
    } catch (e) {
      print("❌ Error checking super admin status: $e");
    } finally {
      setLoadingState(false);
      notifyListeners();
    }
  }

  /// Make user admin (toggle posting access by email)
  Future<String> makeAsAdmin({required String email}) async {
    try {
      _isAdminLoading = true;
      notifyListeners();
      await _service.togglePosting(email: email);
      await getAllUsers(email: email);
      return AppStatus.kSuccess;
    } catch (e) {
      print("❌ Error making user admin: $e");
      return AppStatus.kFailed;
    } finally {
      _isAdminLoading = false;
      notifyListeners();
    }
  }

  /// Block users (legacy method using UID)
  Future<String> blockUsers({required String uid}) async {
    try {
      _isBlockLoading = true;
      notifyListeners();

      final status = await _service.blockUsers(uid: uid);
      print("🔄 Block toggle result: $status");
      await getAllUsers(email: viewUsers?.email ?? '');

      return status;
    } catch (e) {
      print("❌ Error in provider blockUsers: $e");
      return AppStatus.kFailed;
    } finally {
      _isBlockLoading = false;
      notifyListeners();
    }
  }

  /// Initialize users with filter
  Future<void> initUsers(String filter) async {
    _currentFilter = filter;
    await refreshUsers();
  }

  /// Refresh user list - Fixed to defer execution
  Future<void> refreshUsers() async {
    // Defer the execution to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _users = [];
      _lastDocument = null;
      _hasMore = true;
      notifyListeners();
      await _loadMoreUsers();
    });
  }

  /// Load more users for pagination
  Future<void> _loadMoreUsers() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _service.getUsers(
        _currentFilter,
        lastDocument: _lastDocument,
      );

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _users.addAll(snapshot.docs);
        _hasMore = snapshot.docs.length >= 10;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('❌ Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Legacy fetch users method (for backward compatibility)
  Future<void> fetchUsers(String filter, {bool reset = false}) async {
    if (_isLoading) return;

    if (reset) {
      _users.clear();
      _lastDocument = null;
      _hasMore = true;
      _currentFilter = filter;
      notifyListeners();
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newUsers = await _service.fetchUsers(
        filter: filter,
        lastDocument: _lastDocument,
      );

      if (newUsers.isNotEmpty) {
        _lastDocument = newUsers.last;
        _users.addAll(newUsers);
        if (newUsers.length < 10) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle scroll events for pagination
  void onScroll(ScrollController scrollController) {
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadMoreUsers();
    }
  }

  /// Change filter and refresh users - Fixed to defer execution
  void changeFilter(String newFilter) {
    if (_currentFilter != newFilter) {
      _currentFilter = newFilter;
      // Defer the execution to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        refreshUsers();
      });
    }
  }

  /// Toggle user block status
  Future<void> toggleBlockStatus(String userId, bool newBlockStatus) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateUserBlockStatus(userId, newBlockStatus);
      await _updateUserLocally(userId, {'isBlocked': newBlockStatus});
    } catch (e) {
      print('❌ Error toggling block status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle user posting access
  Future<void> togglePostingAccess(String userId, bool newPostAccess) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateUserPostingAccess(userId, newPostAccess);
      await _updateUserLocally(userId, {'canPost': newPostAccess});
    } catch (e) {
      print('❌ Error toggling posting access: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user in local state
  Future<void> _updateUserLocally(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final index = _users.indexWhere((doc) => doc.id == userId);
      if (index != -1) {
        final newSnapshot = await _service.getUserDocument(userId);
        _users[index] = newSnapshot;
        print("==================");
        print(newSnapshot.data());
        print("==================");
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error updating user locally: $e');
    }
  }

  /// Get all users by email
  Future<ViewUsersModel?> getAllUsers({required String email}) async {
    try {
      final user = await _service.getAllUsers(email: email);
      if (user != null) {
        _viewUsers = user;
        notifyListeners();
      } else {
        print(AppStatus.kUserNotFound);
      }
      return user;
    } catch (e) {
      print('❌ Error fetching user: ${e.toString()}');
      return null;
    }
  }

  Stream<Map<String, int>> get userAndAdminCountStream {
    return FirebaseFirestore.instance.collection('users').snapshots().map((
      snapshot,
    ) {
      int adminCount = 0;
      int userCount = 0;
      int blockedUserCount = 0;
      int allCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        allCount++;
        if (data.containsKey('isBlocked') && data['isBlocked'] == true) {
          blockedUserCount++;
        }

        if (data.containsKey('role')) {
          if (data['role'] == 'admin') {
            adminCount++;
          } else if (data['role'] == 'user') {
            userCount++;
          }
        }
      }

      return {
        'admin': adminCount,
        'user': userCount,
        'blocked': blockedUserCount,
        'all': allCount,
      };
    });
  }
}
