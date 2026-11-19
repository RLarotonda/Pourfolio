import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../model/pending_operation.dart';

class DatabaseService {
  DatabaseService(this.helper);
  final DatabaseHelper helper;
  Future<List<PendingOperation>> pending(String uid) async {
    final db = await helper.database;
    final rows = await db.query(
      'pending_operations',
      where: 'user_id = ? AND synced = 0',
      whereArgs: [uid],
      orderBy: 'updated_at ASC, record_id ASC',
    );
    return rows.map(PendingOperation.fromRow).toList();
  }

  Future<void> enqueue(
    String uid,
    String kind,
    String id,
    Map<String, dynamic> data, {
    bool delete = false,
    bool updatePhoto = false,
    String? photo,
  }) async {
    final db = await helper.database;
    await db.transaction((tx) async {
      final old = await tx.query(
        'pending_operations',
        where: 'user_id = ? AND kind = ? AND record_id = ?',
        whereArgs: [uid, kind, id],
      );
      final previous = old.isEmpty ? 0 : old.first['updated_at'] as int;
      final dataTime = (data['updatedAt'] as num?)?.toInt() ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final stamp = [
        now,
        previous + 1,
        dataTime + 1,
      ].reduce((a, b) => a > b ? a : b);
      final revision = const Uuid().v4();
      final payload = {
        ...data,
        'id': id,
        'userId': uid,
        'updatedAt': stamp,
        'revision': revision,
        'synced': false,
      };
      if (updatePhoto) {
        await tx.delete(
          'photo_attachments',
          where: 'user_id = ? AND record_id = ?',
          whereArgs: [uid, id],
        );
        if (photo != null) {
          await tx.insert('photo_attachments', {
            'user_id': uid,
            'record_id': id,
            'path': photo,
          });
        }
      }
      await tx.insert('pending_operations', {
        'user_id': uid,
        'kind': kind,
        'record_id': id,
        'action': delete ? 'delete' : 'upsert',
        'payload': jsonEncode(payload),
        'revision': revision,
        'updated_at': stamp,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  // A confirmação de uma versão antiga nunca apaga uma edição mais recente.
  Future<void> acknowledge(PendingOperation op) async {
    final db = await helper.database;
    await db.transaction((tx) async {
      final args = [op.userId, op.kind, op.id, op.revision];
      const sameVersion =
          'user_id = ? AND kind = ? AND record_id = ? AND revision = ?';
      await tx.update(
        'pending_operations',
        {'synced': 1},
        where: sameVersion,
        whereArgs: args,
      );
      await tx.delete(
        'pending_operations',
        where: '$sameVersion AND synced = 1',
        whereArgs: args,
      );
    });
  }

  Future<Map<String, String>> photos(String uid) async {
    final db = await helper.database;
    final rows = await db.query(
      'photo_attachments',
      where: 'user_id = ?',
      whereArgs: [uid],
    );
    return {
      for (final row in rows) row['record_id'] as String: row['path'] as String,
    };
  }

  Future<void> setPhoto(String uid, String id, String? path) async {
    final db = await helper.database;
    if (path == null) {
      await db.delete(
        'photo_attachments',
        where: 'user_id = ? AND record_id = ?',
        whereArgs: [uid, id],
      );
    } else {
      await db.insert('photo_attachments', {
        'user_id': uid,
        'record_id': id,
        'path': path,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
