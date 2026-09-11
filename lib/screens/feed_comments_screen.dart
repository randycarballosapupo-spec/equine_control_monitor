import 'package:flutter/material.dart';
import '../models/feed_comment.dart';
import '../models/feed_post.dart';
import '../service/app_language.dart';
import '../service/auth_service.dart';
import '../service/feed_comment_service.dart';

class FeedCommentsScreen extends StatefulWidget {
  const FeedCommentsScreen({super.key, required this.languageController, required this.post});
  final AppLanguageController languageController;
  final FeedPost post;
  @override State<FeedCommentsScreen> createState() => _FeedCommentsScreenState();
}

class _FeedCommentsScreenState extends State<FeedCommentsScreen> {
  final controller = TextEditingController();
  List<FeedComment> comments = [];
  String? currentUserId;
  FeedComment? replyTo;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { controller.dispose(); super.dispose(); }
  Future<void> _load() async { final user = await AuthService.currentUser(); final list = await FeedCommentService.fetch(widget.post.id); if (mounted) setState(() { currentUserId = user?.id; comments = list; }); }
  Future<void> _send(AppLanguage language) async { if (controller.text.trim().isEmpty) return; await FeedCommentService.create(postId: widget.post.id, text: controller.text, parentId: replyTo?.id); controller.clear(); setState(() => replyTo = null); await _load(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.languageController, builder: (context, _) { final language = widget.languageController.language; return Scaffold(appBar: AppBar(title: Text(AppText.translate(language, 'comments'))), body: Column(children: [
    Expanded(child: comments.isEmpty ? Center(child: Text(AppText.translate(language, 'no_comments'))) : ListView.builder(itemCount: comments.length, itemBuilder: (context, index) { final comment = comments[index]; return Padding(padding: EdgeInsets.only(left: comment.parentId == null ? 8 : 32, right: 8, top: 4), child: Card(child: ListTile(title: Text(comment.authorName), subtitle: Text(comment.text), trailing: PopupMenuButton<String>(onSelected: (value) async { if (value == 'reply') setState(() => replyTo = comment); if (value == 'delete') { await FeedCommentService.delete(comment.id); await _load(); } }, itemBuilder: (context) => [PopupMenuItem(value: 'reply', child: Text(AppText.translate(language, 'reply'))), if (comment.authorId == currentUserId) PopupMenuItem(value: 'delete', child: Text(AppText.translate(language, 'delete')))])))); })),
    if (replyTo != null) ListTile(dense: true, title: Text('${AppText.translate(language, 'comment_reply')} ${replyTo!.authorName}', maxLines: 1), trailing: IconButton(onPressed: () => setState(() => replyTo = null), icon: const Icon(Icons.close))),
    SafeArea(child: Row(children: [Expanded(child: TextField(controller: controller, decoration: InputDecoration(hintText: AppText.translate(language, 'write_comment')))), IconButton(onPressed: () => _send(language), icon: const Icon(Icons.send))]))
  ])); });
}