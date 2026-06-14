import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';
import '../../../services/db_service.dart';

final adminProvider =
    StateNotifierProvider.autoDispose<AdminNotifier, AdminState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final db = ref.watch(dbServiceProvider);
  return AdminNotifier(api, db);
});

class AdminState {
  final bool isLoading;
  final List<UserModel> users;
  final int pendingSubRequests;
  final String? error;

  const AdminState({
    this.isLoading = false,
    this.users = const [],
    this.pendingSubRequests = 0,
    this.error,
  });

  AdminState copyWith({
    bool? isLoading,
    List<UserModel>? users,
    int? pendingSubRequests,
    String? error,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      pendingSubRequests: pendingSubRequests ?? this.pendingSubRequests,
      error: error,
    );
  }

  UserModel? getUserById(String uid) {
    try {
      return users.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final ApiService _api;
  final DbService _db;

  AdminNotifier(this._api, this._db) : super(const AdminState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final usersData = await _api.fetchAllUsers();
      if (usersData != null) {
        final users = usersData.map((u) => UserModel.fromJson(u)).toList();
        users.sort((a, b) {
          if (a.status == 'pending' && b.status != 'pending') return -1;
          if (b.status == 'pending' && a.status != 'pending') return 1;
          return a.name.compareTo(b.name);
        });

        // Count pending subscription requests
        final subReqs = await _api.getSubscriptionRequests();
        final pendingSubs = subReqs.where((r) => r['status'] == 'pending').length;

        state = state.copyWith(
          isLoading: false,
          users: users,
          pendingSubRequests: pendingSubs,
        );
      } else {
        // Fallback to local cache
        final cached = await _db.getAllUsers();
        state = state.copyWith(isLoading: false, users: cached);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approveUser(String uid) async {
    final ok = await _api.adminApproveUser(uid, true);
    if (ok) {
      final users = state.users.map((u) {
        if (u.uid == uid) return u.copyWith(status: 'active');
        return u;
      }).toList();
      state = state.copyWith(users: users);
    }
    return ok;
  }

  Future<bool> rejectUser(String uid, String reason) async {
    final ok = await _api.adminUpdateUser(uid, {'status': 'rejected', 'rejectReason': reason});
    if (ok) {
      final users = state.users.map((u) {
        if (u.uid == uid) return u.copyWith(status: 'rejected', rejectReason: reason);
        return u;
      }).toList();
      state = state.copyWith(users: users);
    }
    return ok;
  }

  Future<bool> deleteUser(String uid) async {
    final ok = await _api.adminDeleteUser(uid);
    if (ok) {
      final users = state.users.where((u) => u.uid != uid).toList();
      state = state.copyWith(users: users);
    }
    return ok;
  }

  Future<bool> addUser(Map<String, dynamic> data) async {
    final res = await _api.register({...data, 'status': 'active', 'role': 'TRAINEE'});
    if (res['ok'] == true) {
      await load();
      return true;
    }
    return false;
  }

  Future<bool> updateUser(String uid, Map<String, dynamic> fields) async {
    final ok = await _api.adminUpdateUser(uid, fields);
    if (ok) await load();
    return ok;
  }

  UserModel? getUserById(String uid) {
    try {
      return state.users.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }
}
