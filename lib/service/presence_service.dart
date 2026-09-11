import 'supabase_config.dart';

class PresenceSession {
  const PresenceSession({required this.id, required this.enteredAt, this.exitedAt});

  final String id;
  final DateTime enteredAt;
  final DateTime? exitedAt;

  factory PresenceSession.fromMap(Map<String, dynamic> row) => PresenceSession(
        id: '${row['id']}',
        enteredAt: DateTime.parse('${row['entered_at']}').toLocal(),
        exitedAt: row['exited_at'] == null ? null : DateTime.parse('${row['exited_at']}').toLocal(),
      );
}

class PresenceService {
  const PresenceService._();

  static dynamic get _client => SupabaseConfig.client;

  static Future<PresenceSession?> activeSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client
        .from('user_presence_sessions')
        .select()
        .eq('user_id', user.id)
        .isFilter('exited_at', null)
        .order('entered_at', ascending: false)
        .maybeSingle();
    return row == null ? null : PresenceSession.fromMap(Map<String, dynamic>.from(row));
  }

  static Future<PresenceSession> checkIn() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('not_authenticated');
    final row = await _client.from('user_presence_sessions').insert({
      'user_id': user.id,
      'entered_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();
    return PresenceSession.fromMap(Map<String, dynamic>.from(row));
  }

  static Future<void> checkOut(String sessionId) => _client
      .from('user_presence_sessions')
      .update({'exited_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', sessionId);
}