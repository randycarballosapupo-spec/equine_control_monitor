import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SharedCareTask {
  const SharedCareTask({
    required this.id,
    required this.ownerId,
    required this.caregiverId,
    required this.horseName,
    required this.itemName,
    required this.category,
    required this.scheduledFor,
    required this.completedAt,
    required this.notes,
  });

  final String id;
  final String ownerId;
  final String caregiverId;
  final String horseName;
  final String itemName;
  final String category;
  final DateTime scheduledFor;
  final DateTime? completedAt;
  final String notes;

  bool get isCompleted => completedAt != null;

  factory SharedCareTask.fromMap(Map<String, dynamic> row) => SharedCareTask(
        id: '${row['id']}',
        ownerId: '${row['owner_id']}',
        caregiverId: '${row['caregiver_id']}',
        horseName: '${row['horse_name'] ?? ''}',
        itemName: '${row['item_name'] ?? ''}',
        category: '${row['category'] ?? 'medication'}',
        scheduledFor: DateTime.parse('${row['scheduled_for']}').toLocal(),
        completedAt: row['completed_at'] == null ? null : DateTime.parse('${row['completed_at']}').toLocal(),
        notes: '${row['notes'] ?? ''}',
      );
}

class SharedCareService {
  const SharedCareService._();

  static SupabaseClient get _client => SupabaseConfig.client;

  static Future<List<SharedCareTask>> fetchTasks() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final rows = await _client.from('shared_care_tasks').select().order('scheduled_for');
    return (rows as List).map((row) => SharedCareTask.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  static Stream<List<SharedCareTask>> subscribe() => _client
      .from('shared_care_tasks')
      .stream(primaryKey: ['id'])
      .map((rows) => rows.map((row) => SharedCareTask.fromMap(Map<String, dynamic>.from(row))).toList()..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor)));

  static Future<void> createTask({
    required String ownerId,
    required String caregiverId,
    required String horseName,
    required String itemName,
    required String category,
    required DateTime scheduledFor,
    required String notes,
  }) async {
    await _client.from('shared_care_tasks').insert({
      'owner_id': ownerId,
      'caregiver_id': caregiverId,
      'horse_name': horseName.trim(),
      'item_name': itemName.trim(),
      'category': category,
      'scheduled_for': scheduledFor.toUtc().toIso8601String(),
      'notes': notes.trim(),
    });
  }

  static Future<void> completeTask(String taskId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('not_authenticated');
    await _client.from('shared_care_tasks').update({
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'completed_by': user.id,
    }).eq('id', taskId);
  }

  static Future<void> deleteTask(String taskId) => _client.from('shared_care_tasks').delete().eq('id', taskId);
}