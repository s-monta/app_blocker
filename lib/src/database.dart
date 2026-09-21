import 'package:sqflite/sqflite.dart';

import 'models.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final path = '${await getDatabasesPath()}/app_blocker.db';
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            mode TEXT NOT NULL,
            start_at INTEGER NOT NULL,
            end_at INTEGER NOT NULL,
            start_minute INTEGER,
            end_minute INTEGER,
            days_mask INTEGER NOT NULL DEFAULT 127,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE rule_apps (
            rule_id INTEGER NOT NULL,
            package_name TEXT NOT NULL,
            app_name TEXT NOT NULL,
            PRIMARY KEY (rule_id, package_name),
            FOREIGN KEY (rule_id) REFERENCES rules(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_rule_apps_package ON rule_apps(package_name)',
        );
      },
    );
  }

  Future<int> insertRule(BlockRule rule) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('rules', {
        'name': rule.name,
        'mode': rule.mode == RuleMode.oneTime ? 'one_time' : 'daily',
        'start_at': rule.startAt.millisecondsSinceEpoch,
        'end_at': rule.endAt.millisecondsSinceEpoch,
        'start_minute': rule.startMinute,
        'end_minute': rule.endMinute,
        'days_mask': rule.daysMask,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      for (final app in rule.apps) {
        await txn.insert('rule_apps', {
          'rule_id': id,
          'package_name': app.packageName,
          'app_name': app.name,
        });
      }
      return id;
    });
  }

  Future<List<BlockRule>> getRules() async {
    final db = await database;
    final rows = await db.query('rules', orderBy: 'end_at DESC');
    final result = <BlockRule>[];
    for (final row in rows) {
      final appRows = await db.query(
        'rule_apps',
        where: 'rule_id = ?',
        whereArgs: [row['id']],
        orderBy: 'app_name COLLATE NOCASE',
      );
      result.add(
        BlockRule(
          id: row['id']! as int,
          name: row['name']! as String,
          mode: row['mode'] == 'daily' ? RuleMode.daily : RuleMode.oneTime,
          startAt: DateTime.fromMillisecondsSinceEpoch(row['start_at']! as int),
          endAt: DateTime.fromMillisecondsSinceEpoch(row['end_at']! as int),
          startMinute: row['start_minute'] as int?,
          endMinute: row['end_minute'] as int?,
          daysMask: row['days_mask']! as int,
          apps: appRows
              .map(
                (a) => InstalledApp(
                  name: a['app_name']! as String,
                  packageName: a['package_name']! as String,
                ),
              )
              .toList(),
        ),
      );
    }
    return result;
  }
}
