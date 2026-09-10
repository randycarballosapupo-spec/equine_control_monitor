import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'auth_service.dart';

class AccessService {
  const AccessService._();

  static Future<String> scopedKey(String suffix) async {
    final user = await AuthService.currentUser();
    final email = user?.email ?? 'anonymous';
    final scope = sha256.convert(utf8.encode(email)).toString().substring(0, 16);
    return 'user_${scope}_$suffix';
  }

  static Future<bool> canUseChat() async {
    final user = await AuthService.currentUser();
    if (user == null) return false;
    if (user.isAdmin || user.isOwner) return true;
    return user.isApproved && await AuthService.chatAccess(user.email);
  }

  static Future<List<String>> chatMembers() async {
    final users = await AuthService.users();
    final members = <String>[];
    for (final user in users) {
      if (await AuthService.chatAccess(user.email)) members.add(user.email);
    }
    return members;
  }

  static Future<void> setChatAccess(String email, bool enabled) async {
    await AuthService.updateChatAccess(email, enabled);
  }
}
