import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

class DatabaseHelper {
  DatabaseHelper({required this.factory, this.databasePath});
  final DatabaseFactory factory;
  final String? databasePath;
  Database? _db;
  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    final path =
        databasePath ??
        p.join(await factory.getDatabasesPath(), 'pourfolio.db');
    return _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''CREATE TABLE pending_operations (
          user_id TEXT NOT NULL, kind TEXT NOT NULL, record_id TEXT NOT NULL,
          action TEXT NOT NULL CHECK(action IN ('upsert','delete')),
          payload TEXT NOT NULL, revision TEXT NOT NULL, updated_at INTEGER NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0 CHECK(synced IN (0,1)),
          PRIMARY KEY(user_id,kind,record_id))''');
          await db.execute('''CREATE TABLE photo_attachments (
          user_id TEXT NOT NULL, record_id TEXT NOT NULL, path TEXT NOT NULL,
          PRIMARY KEY(user_id,record_id))''');
        },
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
