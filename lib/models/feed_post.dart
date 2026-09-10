class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.caption,
    this.imageUrl,
    this.mediaType,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String caption;
  final String? imageUrl;
  final String? mediaType;
  final String createdAt;

  bool get isVideo => mediaType == 'video';

  factory FeedPost.fromMap(Map<String, dynamic> map) {
    return FeedPost(
      id: '${map['id'] ?? ''}',
      authorId: '${map['author_id'] ?? ''}',
      authorName: '${map['author_name'] ?? 'Usuario'}',
      caption: '${map['caption'] ?? ''}',
      imageUrl: map['image_url'] == null ? null : '${map['image_url']}',
      mediaType: map['media_type'] == null ? null : '${map['media_type']}',
      createdAt: '${map['created_at'] ?? DateTime.now().toUtc().toIso8601String()}',
    );
  }
}
