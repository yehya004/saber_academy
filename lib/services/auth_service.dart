import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class AuthService {
  final _client = Supabase.instance.client;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<ProfileModel?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromMap(data);
  }

  Future<void> updateLanguagePreference(String userId, String lang) =>
      _client
          .from('profiles')
          .update({'language_preference': lang})
          .eq('id', userId);

  /// Updates editable profile fields. Only sends fields that are provided.
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? country,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{'full_name': fullName};
    if (phone     != null) updates['phone']      = phone;
    if (country   != null) updates['country']    = country;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  /// Uploads avatar bytes to Supabase Storage and returns the public URL.
  Future<String> uploadAvatar(
    String userId,
    Uint8List bytes,
    String ext,
  ) async {
    final path = '$userId/avatar.$ext';
    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/$ext',
        upsert: true,
      ),
    );
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}
