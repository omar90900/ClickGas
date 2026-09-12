import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import 'my_orders_controller.dart';

enum SessionStatus { initializing, signedOut, loadingProfile, ready, profileError }

/// Single source of truth for "who is signed in": follows Supabase auth,
/// loads the matching `profiles` row, and binds the order stream to it.
class SessionController extends ChangeNotifier {
  SessionController(this._auth, this._profiles, this._orders) {
    _sub = _auth.changes.listen((state) => _handleUser(state.session?.user));
    // Start outside the build phase that created this controller.
    scheduleMicrotask(() => _handleUser(_auth.currentUser));
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final MyOrdersController _orders;
  late final StreamSubscription<AuthState> _sub;

  SessionStatus _status = SessionStatus.initializing;
  Profile? _profile;
  String? _userId;

  SessionStatus get status => _status;
  Profile? get profile => _profile;

  Future<void> _handleUser(User? user) async {
    if (user?.id == _userId && _status != SessionStatus.initializing) return;
    _userId = user?.id;
    if (user == null) {
      _profile = null;
      _status = SessionStatus.signedOut;
      _orders.bind(null);
      notifyListeners();
      return;
    }
    await _loadProfile(user.id);
  }

  Future<void> _loadProfile(String userId) async {
    _status = SessionStatus.loadingProfile;
    notifyListeners();
    try {
      final profile = await _profiles.fetch(userId);
      if (userId != _userId) return; // signed out meanwhile
      _profile = profile;
      _status = profile == null ? SessionStatus.profileError : SessionStatus.ready;
    } catch (e) {
      debugPrint('Profile load failed: $e');
      if (userId != _userId) return;
      _status = SessionStatus.profileError;
    }
    _orders.bind(_status == SessionStatus.ready ? userId : null);
    notifyListeners();
  }

  Future<void> retry() async {
    final id = _userId;
    if (id != null) await _loadProfile(id);
  }

  void updateProfile(Profile profile) {
    _profile = profile;
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
