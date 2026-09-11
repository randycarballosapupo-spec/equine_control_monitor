import '../models/feed_comment.dart';
import 'supabase_config.dart';

class FeedCommentService {
  const FeedCommentService._();
  static dynamic get _client => SupabaseConfig.client;

  static Future<List<FeedComment>> fetch(String postId) async {
    final rows = await _client.from('post_comments').select().eq('post_id', postId).order('created_at');
    return (rows as List).map((row) => FeedComment.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  static Future<void> create({required String postId, required String text, String? parentId}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('not_authenticated');
    final profile = await _client.from('profiles').select('name').eq('id', user.id).maybeSingle();
    await _client.from('post_comments').insert({'post_id': postId, 'author_id': user.id, 'author_name': profile?['name'] ?? user.email ?? '', 'text': text.trim(), 'parent_id': parentId});
  }

  static Future<void> delete(String commentId) => _client.from('post_comments').delete().eq('id', commentId);
}