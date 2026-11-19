import 'dart:convert';

class PendingOperation {
  const PendingOperation({
    required this.userId,
    required this.kind,
    required this.id,
    required this.action,
    required this.payload,
    required this.revision,
    required this.updatedAt,
  });
  final String userId, kind, id, action, revision;
  final Map<String, dynamic> payload;
  final int updatedAt;
  factory PendingOperation.fromRow(Map<String, Object?> m) => PendingOperation(
    userId: m['user_id'] as String,
    kind: m['kind'] as String,
    id: m['record_id'] as String,
    action: m['action'] as String,
    payload: Map<String, dynamic>.from(
      jsonDecode(m['payload'] as String) as Map,
    ),
    revision: m['revision'] as String,
    updatedAt: m['updated_at'] as int,
  );
}
