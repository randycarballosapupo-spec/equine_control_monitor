class FeedComment {
  const FeedComment({required this.id, required this.postId, required this.authorId, required this.authorName, required this.text, this.parentId, required this.createdAt});
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final String? parentId;
  final String createdAt;

  factory FeedComment.fromMap(Map<String, dynamic> row) => FeedComment(
        id: '${row['id']}', postId: '${row['post_id']}', authorId: '${row['author_id']}', authorName: '${row['author_name'] ?? ''}', text: '${row['text'] ?? ''}', parentId: row['parent_id'] == null ? null : '${row['parent_id']}', createdAt: '${row['created_at'] ?? ''}',
      );
}