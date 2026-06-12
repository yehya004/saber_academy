import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Holds the authenticated user's profile and exposes sign-out.
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  ProfileModel? _profile;
  bool _isLoading = false;
  bool _disposed = false;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isTeacher => _profile?.isTeacher ?? false;
  bool get isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Fetches the profile row for the currently authenticated user.
  Future<void> loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    _safeNotify();

    try {
      _profile = await _authService.fetchProfile(userId);
      if (_profile != null) {
        // Save profile to local cache for offline usage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_profile_$userId', jsonEncode(_profile!.toMap()));
      }
      // Update FCM push notification token on successful profile load
      NotificationService().updateTokenOnServer();
    } catch (e, st) {
      debugPrint('AuthProvider.loadProfile error: $e\n$st');
      // If offline or network error, attempt to load from local cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('cached_user_profile_$userId');
        if (cachedData != null) {
          _profile = ProfileModel.fromMap(jsonDecode(cachedData) as Map<String, dynamic>);
          debugPrint('AuthProvider.loadProfile loaded profile from offline cache.');
        } else {
          _profile = null;
        }
      } catch (cacheErr) {
        debugPrint('AuthProvider.loadProfile offline cache error: $cacheErr');
        _profile = null;
      }
    }

    _isLoading = false;
    _safeNotify();
    if (_profile != null) {
      NotificationService().initWindowsRealtimeListener(_profile!.id);
    }
  }

  /// Updates the user's editable profile fields and reloads the profile.
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? country,
    String? avatarUrl,
  }) async {
    final userId = _profile?.id;
    if (userId == null) return false;
    try {
      await _authService.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        country: country,
        avatarUrl: avatarUrl,
      );
      await loadProfile();
      return true;
    } catch (e, st) {
      debugPrint('AuthProvider.updateProfile error: $e\n$st');
      return false;
    }
  }

  void updateLocalLanguagePreference(String lang) {
    if (_profile != null) {
      _profile = ProfileModel(
        id:                 _profile!.id,
        role:               _profile!.role,
        fullName:           _profile!.fullName,
        languagePreference: lang,
        createdAt:          _profile!.createdAt,
        phone:              _profile!.phone,
        messengerLink:      _profile!.messengerLink,
        country:            _profile!.country,
        avatarUrl:          _profile!.avatarUrl,
        email:              _profile!.email,
        level:              _profile!.level,
        lessonInLevel:      _profile!.lessonInLevel,
        isPaid:             _profile!.isPaid,
        isBlocked:          _profile!.isBlocked,
      );
      _safeNotify();
    }
  }

  Future<void> signOut() async {
    final userId = _profile?.id;
    NotificationService().cancelWindowsRealtimeListener();
    if (userId != null) {
      // Clear token from server before logout
      await NotificationService().removeTokenFromServer(userId);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cached_user_profile_$userId');
      } catch (_) {}
    }
    await Supabase.instance.client.auth.signOut();
    _profile = null;
    _safeNotify();
  }
}
