import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import 'supabase_config.dart';

/// Centralized auth/user management backed by Supabase, shared across all devices.
class AuthService {
  static const _table = 'profiles';

  static dynamic get _client => SupabaseConfig.client;

  static Future<List<AppUser>> users() async {
    final rows = await _client.from(_table).select().order('created_at');
    final current = _client.auth.currentUser;
    final currentRow = current == null
      ? null
      : await _client.from(_table).select('is_owner').eq('id', current.id).maybeSingle();
    final canSeeOwner = currentRow?['is_owner'] == true;
    final visibleRows = canSeeOwner
      ? rows as List
      : (rows as List).where((row) => row['is_owner'] != true).toList();
    return visibleRows
        .map((row) => AppUser.fromProfileRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required List<String> roles,
    required String stableName,
    required DateTime birthDate,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final auth = await _client.auth.signUp(email: normalizedEmail, password: password.trim());
      final user = auth.user;
      if (user == null) return 'Supabase no devolvio un usuario.';
      await _client.from(_table).insert({
        'id': user.id,
        'email': normalizedEmail,
        'name': name.trim(),
        'roles': roles,
        'stable_name': stableName.trim(),
        'birth_date': birthDate.toIso8601String().split('T').first,
        'preferred_language': 'pl',
      });
      return null;
    } catch (error) {
      debugPrint('registerUser error: $error');
      return error.toString();
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );
      if (res.user == null) return false;
      final profile = await currentUser();
      return profile != null && profile.isApproved;
    } catch (error) {
      debugPrint('login error: $error');
      return false;
    }
  }

  static Future<String> loginFailureReason(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );
      final profile = await currentUser();
      if (profile == null) return 'no_account_found';
      if (!profile.isApproved) return 'account_pending_approval';
      return 'login_failed_generic';
    } catch (error) {
      debugPrint('loginFailureReason error: $error');
      return 'password_mismatch';
    }
  }

  static Future<AppUser?> currentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    final row = await _client.from(_table).select().eq('id', authUser.id).maybeSingle();
    if (row == null) return null;
    return AppUser.fromProfileRow(Map<String, dynamic>.from(row));
  }

  static Future<bool> isCurrentAdmin() async => (await currentUser())?.isAdmin ?? false;

  static Future<bool> isCurrentPrimaryAdmin() async => (await currentUser())?.isPrimary ?? false;

  static Future<bool> isCurrentOwner() async => (await currentUser())?.isOwner ?? false;

  static Future<void> updatePreferredLanguage(String language) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from(_table).update({'preferred_language': language}).eq('id', user.id);
  }

  static Future<String?> preferredLanguage() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client.from(_table).select('preferred_language').eq('id', user.id).maybeSingle();
    return row?['preferred_language'] as String?;
  }

  static Future<bool> hasPrimaryAdmin() async {
    try {
      final result = await _client.rpc('has_primary_admin');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> pendingUsersCount() async {
    final rows = await _client.from(_table).select('id').eq('status', 'pending');
    return (rows as List).length;
  }

  static Future<int> administratorCount() async {
    final all = await users();
    return all.where((user) => user.isAdmin).length;
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  static Future<void> updateUserStatus(String email, String status) async {
    await _client.from(_table).update({'status': status}).eq('email', email.trim().toLowerCase());
  }

  static Future<bool> chatAccess(String email) async {
    final row = await _client.from(_table).select('chat_enabled').eq('email', email.trim().toLowerCase()).maybeSingle();
    return row?['chat_enabled'] == true;
  }

  static Future<void> updateChatAccess(String email, bool enabled) async {
    await _client.from(_table).update({'chat_enabled': enabled}).eq('email', email.trim().toLowerCase());
  }

  static Future<bool> deleteUser(String email) async {
    final current = await currentUser();
    if (current == null || !(current.isAdmin || current.isOwner)) return false;
    final normalizedEmail = email.trim().toLowerCase();
    await _client.from(_table).delete().eq('email', normalizedEmail);
    if (current.email == normalizedEmail) {
      await _client.auth.signOut();
    }
    return true;
  }

  static Future<bool> addAdministrator({
    required String email,
    required String password,
    required String name,
    required String stableName,
  }) async {
    final isOwner = await isCurrentOwner();
    if (!isOwner && (!await isCurrentPrimaryAdmin() || await administratorCount() >= 5)) return false;
    final normalizedEmail = email.trim().toLowerCase();
    final previousSession = _client.auth.currentSession;
    try {
      final auth = await _client.auth.signUp(email: normalizedEmail, password: password.trim());
      final user = auth.user;
      if (user == null) return false;
      await _client.from(_table).insert({
        'id': user.id,
        'email': normalizedEmail,
        'name': name.trim(),
        'roles': ['admin'],
        'stable_name': stableName.trim(),
        'status': 'approved',
      });
      return true;
    } catch (_) {
      return false;
    } finally {
      // Creating a user via signUp() switches the active session to the new
      // account. Restore the primary admin's session so they stay logged in.
      final refreshToken = previousSession?.refreshToken;
      if (refreshToken != null) {
        try {
          await _client.auth.setSession(refreshToken);
        } catch (_) {
          // If restoring fails, the admin will simply need to log in again.
        }
      }
    }
  }

  static Future<bool> deleteCurrentUser() async {
    final current = await currentUser();
    if (current == null) return false;
    await _client.from(_table).delete().eq('id', current.id ?? '');
    await _client.auth.signOut();
    return true;
  }

  static Future<bool> transferPrimaryAdmin(String targetEmail) async {
    final current = await currentUser();
    if (current == null || !(current.isPrimary || current.isOwner)) return false;
    final normalizedEmail = targetEmail.trim().toLowerCase();
    if (normalizedEmail == current.email) return false;
    final matches = (await users()).where((user) => user.email == normalizedEmail);
    if (matches.isEmpty) return false;
    final target = matches.first;
    if (!target.isAdmin || !target.isApproved) return false;
    await _client.from(_table).update({'is_primary': true}).eq('email', normalizedEmail);
    final previousPrimaryMatches = (await users()).where((user) => user.isPrimary && user.email != normalizedEmail);
    for (final previous in previousPrimaryMatches) {
      await _client.from(_table).update({'is_primary': false}).eq('id', previous.id ?? '');
    }
    return true;
  }

  static Future<void> rememberEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remembered_email', email.trim().toLowerCase());
  }

  static Future<String> rememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('remembered_email') ?? '';
  }

  static Future<bool> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
      return true;
    } catch (_) {
      return false;
    }
  }
}

