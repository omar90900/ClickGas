import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/admin_models.dart';
import '../data/admin_repository.dart';

enum StaffStatus { initializing, signedOut, loading, ready, notStaff, error }

/// Who is signed in: Supabase auth -> `admin_whoami()`. Accounts that are
/// not active staff land on [StaffStatus.notStaff] and see nothing else.
class StaffSession extends ChangeNotifier {
  StaffSession(this._auth, this._admin) {
    _sub = _auth.changes.listen((s) => _handleUser(s.session?.user));
    scheduleMicrotask(() => _handleUser(_auth.currentUser));
  }

  final AuthRepository _auth;
  final AdminRepository _admin;
  late final StreamSubscription<AuthState> _sub;

  StaffStatus _status = StaffStatus.initializing;
  StaffMember? _me;
  String? _userId;
  Object? _error;

  StaffStatus get status => _status;
  StaffMember? get me => _me;
  Object? get error => _error;

  /// The least powerful role until [me] is known.
  StaffRole get role => _me?.role ?? StaffRole.support;

  Future<void> _handleUser(User? user) async {
    if (user?.id == _userId && _status != StaffStatus.initializing) return;
    _userId = user?.id;
    if (user == null) {
      _me = null;
      _status = StaffStatus.signedOut;
      notifyListeners();
      return;
    }
    await _load(user.id);
  }

  Future<void> _load(String userId) async {
    _status = StaffStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final me = await _admin.whoami();
      if (userId != _userId) return; // signed out meanwhile
      _me = me;
      _status = me == null ? StaffStatus.notStaff : StaffStatus.ready;
      if (me != null) Log.i('staff_ready', {'role': me.role.name});
    } catch (e) {
      if (userId != _userId) return;
      _error = e;
      _status = StaffStatus.error;
    }
    notifyListeners();
  }

  Future<void> retry() async {
    final id = _userId;
    if (id != null) await _load(id);
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmail(email, password);

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
