import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SecureDbService {
  static final SecureDbService _instance = SecureDbService._internal();
  factory SecureDbService() => _instance;
  SecureDbService._internal();

  Database? _db;
  static const _storage = FlutterSecureStorage();
  static const _dbName = 'fate_secure.db';
  static const _dbKeyName = 'fate_db_encryption_key';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    // 1. Get or generate encryption key from Secure Storage
    String? encryptionKey = await _storage.read(key: _dbKeyName);
    if (encryptionKey == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      encryptionKey = base64Url.encode(values);
      await _storage.write(key: _dbKeyName, value: encryptionKey);
      debugPrint("[SecureDB] Generated new hardware-backed encryption key.");
    }

    // 2. Open SQLCipher database
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      password: encryptionKey,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE location_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL,
            lat REAL,
            lng REAL,
            mapped_zone TEXT,
            periods_count INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE digital_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL,
            package_name TEXT,
            duration_ms INTEGER,
            usage_duration_seconds REAL,
            prev_package TEXT,
            switch_time_seconds REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE proximity_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL,
            nearby_peers_count INTEGER,
            peer_name TEXT,
            distance REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE notification_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL,
            app_category TEXT,
            content TEXT,
            response_time_seconds REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE engagement_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_device_id TEXT,
            timestamp REAL,
            engagement_duration_seconds REAL,
            peer_cas_at_time REAL
          )
        ''');

        await db.execute('''
          CREATE TABLE daily_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            cas_score REAL,
            spatial_score REAL,
            social_score REAL,
            digital_score REAL
          )
        ''');
        
        debugPrint("[SecureDB] Encrypted database tables created.");
      },
    );
  }

  // ─── Insertion Methods ───

  Future<void> insertLocationLog(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('location_logs', {
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
      'lat': data['lat'],
      'lng': data['lng'],
      'mapped_zone': data['zone'],
      'periods_count': data['periods_count'] ?? 1,
    });
  }

  Future<void> insertDigitalLog(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('digital_logs', {
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
      'package_name': data['package'],
      'duration_ms': data['duration'] ?? 10000,
      'usage_duration_seconds': (data['duration'] ?? 10000) / 1000.0,
      'prev_package': data['prev_package'],
      'switch_time_seconds': data['switch_time_seconds'],
    });
  }

  Future<void> insertProximityLog(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('proximity_logs', {
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
      'nearby_peers_count': data['nearby_peers'],
      'peer_name': data['peer_name'],
      'distance': data['distance'],
    });
  }

  Future<void> insertNotificationLog(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('notification_logs', {
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
      'app_category': data['app_category'],
      'content': data['content'],
      'response_time_seconds': data['response_time_seconds'],
    });
  }

  Future<void> insertEngagementLog(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('engagement_logs', {
      'peer_device_id': data['peer_device_id'],
      'timestamp': DateTime.now().millisecondsSinceEpoch / 1000.0,
      'engagement_duration_seconds': data['engagement_duration_seconds'],
      'peer_cas_at_time': data['peer_cas_at_time'],
    });
  }

  // ─── Retrieval Methods ───

  Future<List<Map<String, dynamic>>> getLogs(String table, {int? limit, String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.query(
      table,
      orderBy: 'timestamp DESC',
      limit: limit,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> upsertDailyScore(Map<String, dynamic> scoreData) async {
    final db = await database;
    await db.insert(
      'daily_scores',
      scoreData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Garbage Collection ───

  Future<int> runGarbageCollection() async {
    final db = await database;
    final cutoff = (DateTime.now().millisecondsSinceEpoch / 1000.0) - 86400; // 24h ago
    
    int totalDeleted = 0;
    final tables = [
      'location_logs',
      'digital_logs',
      'proximity_logs',
      'notification_logs',
      'engagement_logs'
    ];

    for (var table in tables) {
      int deleted = await db.delete(table, where: 'timestamp < ?', whereArgs: [cutoff]);
      totalDeleted += deleted;
    }
    
    debugPrint("[SecureDB] GC deleted $totalDeleted rows older than 24h.");
    return totalDeleted;
  }
}
