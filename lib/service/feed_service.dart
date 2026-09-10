import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feed_post.dart';
import 'supabase_config.dart';

/// Community feed backed by Supabase, shared across all devices.
class FeedService {
  static const _postsTable = 'posts';
  static const _reactionsTable = 'post_reactions';
  static const _bucket = 'post-images';

  static dynamic get _client => SupabaseConfig.client;

  static Future<List<FeedPost>> fetchPosts() async {
    final rows = await _client.from(_postsTable).select().order('created_at', ascending: false);
    return (rows as List)
        .map((row) => FeedPost.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Stream<List<FeedPost>> subscribe() {
    final stream = _client.from(_postsTable).stream(primaryKey: ['id']);
    return stream.map((rows) => rows
        .map((row) => FeedPost.fromMap(Map<String, dynamic>.from(row)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  static Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final safeExtension = RegExp(r'^[a-z0-9]+$').hasMatch(extension) ? extension : 'jpg';
    final path = '${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => 'image/jpeg',
    };
    try {
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
    } catch (error) {
      throw StateError('No se pudo subir el archivo al bucket $_bucket. Detalle: $error');
    }
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  static Future<void> createPost({required String caption, String? imageUrl, String? mediaType}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Debe iniciar sesión para publicar.');
    final profile = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    await _client.from(_postsTable).insert({
      'author_id': user.id,
      'author_name': profile?['name'] ?? user.email ?? 'Usuario',
      'caption': caption.trim(),
      'image_url': imageUrl,
      'media_type': mediaType,
    });
  }

  static Future<void> deletePost(String postId) async {
    await _client.from(_postsTable).delete().eq('id', postId);
  }

  static Future<int> reactionCount(String postId) async {
    final rows = await _client.from(_reactionsTable).select().eq('post_id', postId);
    return (rows as List).length;
  }

  static Future<Map<String, int>> reactionCounts() async {
    final rows = await _client.from(_reactionsTable).select('post_id');
    final counts = <String, int>{};
    for (final row in rows as List) {
      final postId = '${(row as Map)['post_id']}';
      counts[postId] = (counts[postId] ?? 0) + 1;
    }
    return counts;
  }

  static Future<Map<String, String>> userReactions() async {
    final user = _client.auth.currentUser;
    if (user == null) return {};
    final rows = await _client.from(_reactionsTable).select('post_id, reaction').eq('user_id', user.id);
    return {
      for (final row in rows as List)
        '${(row as Map)['post_id']}': '${row['reaction'] ?? 'like'}',
    };
  }

  static Future<void> toggleReaction(String postId, String reaction) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final existing = await _client
        .from(_reactionsTable)
        .select()
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();
    if (existing != null && existing['reaction'] == reaction) {
      await _client.from(_reactionsTable).delete().eq('post_id', postId).eq('user_id', user.id);
    } else {
      await _client.from(_reactionsTable).upsert({
        'post_id': postId,
        'user_id': user.id,
        'reaction': reaction,
      }, onConflict: 'post_id,user_id');
    }
  }
}
