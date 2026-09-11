import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_post.dart';
import '../service/app_language.dart';
import '../service/auth_service.dart';
import '../service/feed_service.dart';
import 'feed_comments_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<FeedPost> posts = [];
  Map<String, int> reactionCounts = {};
  Map<String, String> userReactions = {};
  bool canModerate = false;
  String? currentUserId;
  bool loading = true;
  Uint8List? pendingMediaBytes;
  String? pendingMediaType;
  String? pendingFileName;
  final captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final fetchedPosts = await FeedService.fetchPosts();
      final counts = await FeedService.reactionCounts();
      final reacted = await FeedService.userReactions();
      final moderator = await AuthService.isCurrentAdmin() || await AuthService.isCurrentOwner();
      final currentUser = await AuthService.currentUser();
      if (!mounted) return;
      setState(() {
        posts = fetchedPosts;
        reactionCounts = counts;
        userReactions = reacted;
        canModerate = moderator;
        currentUserId = currentUser?.id;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggleReaction(String postId, String reaction) async {
    await FeedService.toggleReaction(postId, reaction);
    await _load();
  }

  Future<void> _deletePost(FeedPost post, AppLanguage language) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppText.translate(language, 'delete_post')),
        content: Text(AppText.translate(language, 'delete_post_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppText.translate(language, 'cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppText.translate(language, 'delete'))),
        ],
      ),
    );
    if (confirmed != true) return;
    await FeedService.deletePost(post.id);
    await _load();
  }

  IconData _reactionIcon(String? reaction) {
    switch (reaction) {
      case 'love':
        return Icons.favorite;
      case 'laugh':
        return Icons.sentiment_very_satisfied;
      case 'celebrate':
        return Icons.celebration;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.thumb_up;
    }
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.pickFiles(type: FileType.media);
    if (result.isEmpty) return;
    final file = result.first;
    final bytes = await file.readAsBytes();
    final extension = file.extension?.toLowerCase() ?? '';
    final isVideo = ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(extension);
    if (!mounted) return;
    setState(() {
      pendingMediaBytes = bytes;
      pendingMediaType = isVideo ? 'video' : 'image';
      pendingFileName = file.name;
    });
  }

  Future<void> _createPost(AppLanguage language) async {
    final caption = captionController.text.trim();
    if (caption.isEmpty && pendingMediaBytes == null) return;
    try {
      String? mediaUrl;
      if (pendingMediaBytes != null) {
        mediaUrl = await FeedService.uploadImage(pendingMediaBytes!, pendingFileName ?? 'media');
      }
      await FeedService.createPost(caption: caption, imageUrl: mediaUrl, mediaType: pendingMediaType);
      captionController.clear();
      pendingMediaBytes = null;
      pendingMediaType = null;
      pendingFileName = null;
      if (!mounted) return;
      Navigator.pop(context);
      await _load();
    } catch (error) {
      debugPrint('Feed post creation failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(AppText.translate(language, 'post_error')),
        ),
      );
    }
  }

  Future<void> _showCreatePostDialog(AppLanguage language) async {
    pendingMediaBytes = null;
    pendingMediaType = null;
    pendingFileName = null;
    captionController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(AppText.translate(language, 'new_post')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: captionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppText.translate(language, 'post_caption_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (pendingMediaBytes != null && pendingMediaType == 'image')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(pendingMediaBytes!, height: 140, fit: BoxFit.cover),
                  ),
                if (pendingMediaBytes != null && pendingMediaType == 'video')
                  Row(
                    children: [
                      const Icon(Icons.videocam, size: 32),
                      const SizedBox(width: 8),
                      Expanded(child: Text(pendingFileName ?? '', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _pickMedia();
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.perm_media),
                  label: Text(AppText.translate(language, 'add_photo_video')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(AppText.translate(language, 'cancel'))),
            FilledButton(onPressed: () => _createPost(language), child: Text(AppText.translate(language, 'publish'))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.languageController,
      builder: (context, _) {
        final language = widget.languageController.language;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/images/equi_harmony_logo.png', height: 32, width: 32, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Flexible(child: Text(AppText.translate(language, 'feed'), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePostDialog(language),
            child: const Icon(Icons.add_a_photo),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/caballos_fondo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: loading
              ? const Center(child: CircularProgressIndicator())
              : posts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 16),
                            Text(
                              AppText.translate(language, 'no_posts'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _showCreatePostDialog(language),
                              icon: const Icon(Icons.add_a_photo),
                              label: Text(AppText.translate(language, 'new_post')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final likes = reactionCounts[post.id] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(post.authorName),
                                  subtitle: Text(post.createdAt),
                                  trailing: canModerate || post.authorId == currentUserId
                                      ? IconButton(
                                          tooltip: AppText.translate(language, 'delete_post'),
                                          onPressed: () => _deletePost(post, language),
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        )
                                      : null,
                                ),
                                if (post.imageUrl != null && post.imageUrl!.isNotEmpty && !post.isVideo)
                                  Image.network(
                                    post.imageUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                  ),
                                if (post.imageUrl != null && post.imageUrl!.isNotEmpty && post.isVideo)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: OutlinedButton.icon(
                                      onPressed: () => launchUrl(Uri.parse(post.imageUrl!), mode: LaunchMode.externalApplication),
                                      icon: const Icon(Icons.play_circle_outline),
                                      label: Text(AppText.translate(language, 'play_video')),
                                    ),
                                  ),
                                if (post.caption.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(post.caption),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      PopupMenuButton<String>(
                                        tooltip: AppText.translate(language, 'reaction'),
                                        onSelected: (reaction) => _toggleReaction(post.id, reaction),
                                        icon: Icon(
                                          _reactionIcon(userReactions[post.id]),
                                          color: userReactions.containsKey(post.id) ? Colors.red : null,
                                        ),
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'like', child: Text('👍')),
                                          PopupMenuItem(value: 'love', child: Text('❤️')),
                                          PopupMenuItem(value: 'laugh', child: Text('😂')),
                                          PopupMenuItem(value: 'celebrate', child: Text('🎉')),
                                          PopupMenuItem(value: 'sad', child: Text('😢')),
                                          PopupMenuItem(value: 'angry', child: Text('😡')),
                                        ],
                                      ),
                                      Text('$likes'),
                                      const SizedBox(width: 12),
                                      TextButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FeedCommentsScreen(
                                              languageController: widget.languageController,
                                              post: post,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        label: Text(AppText.translate(language, 'comment')),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
          ),
        );
      },
    );
  }
}
