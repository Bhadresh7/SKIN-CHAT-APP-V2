import 'dart:convert';

import 'package:path/path.dart';
import 'package:skin_app_migration/core/helpers/app_logger.dart';
import 'package:skin_app_migration/features/message/models/chat_message_model.dart';
import 'package:skin_app_migration/features/message/models/meta_model.dart';
import 'package:sqflite/sqflite.dart';

class LocalDBService {
  static final LocalDBService _instance = LocalDBService._internal();

  factory LocalDBService() => _instance;

  LocalDBService._internal();

  Database? _db;

  /// Initialize SQLite DB with custom filename 'chat_data.db'
  Future<void> init() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'chat_data.db');

      _db = await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          AppLoggerHelper.logInfo('Creating initial tables...');
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          AppLoggerHelper.logInfo(
            'Upgrading DB from $oldVersion to $newVersion...',
          );
          if (oldVersion < 2) {
            await _createChatMessagesTable(db);
          }
        },
      );

      AppLoggerHelper.logInfo('SQLite database initialized at $path');
    } catch (e) {
      AppLoggerHelper.logError('Error initializing SQLite: $e');
    }
  }

  /// Ensures all required tables are created
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT,
        timestamp TEXT
      )
    ''');

    await _createChatMessagesTable(db);
  }

  /// Creates the chat_messages table
  Future<void> _createChatMessagesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS chat_messages (
      messageId TEXT PRIMARY KEY,
      senderId TEXT,
      name TEXT,
      ts INTEGER,
      metadata TEXT
    )
  ''');
    AppLoggerHelper.logInfo('chat_messages table created or already exists.');
  }

  bool get isInitialized => _db != null;

  Database get database {
    if (_db == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _db!;
  }

  // ===== ChatMessageModel CRUD =====

  /// Insert chat message (main method)
  Future<void> insertChatMessage(ChatMessageModel message) async {
    final db = database;
    await db.insert('chat_messages', {
      'messageId': message.messageId,
      'senderId': message.senderId,
      'name': message.name,
      'ts': message.createdAt,
      'metadata': jsonEncode(message.metadata?.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    AppLoggerHelper.logInfo('Inserted message: ${message.toJson()}');
  }

  // Query all messages
  Future<List<ChatMessageModel>> getAllMessages() async {
    final db = database;
    final result = await db.query('chat_messages', orderBy: 'ts ASC');

    return result.map((map) {
      final metadataJson = map['metadata'] as String?;
      return ChatMessageModel(
        messageId: map['messageId'] as String? ?? '',
        senderId: map['senderId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        createdAt: map['ts'] as int? ?? 0,
        metadata: metadataJson != null
            ? MetaModel.fromJson(jsonDecode(metadataJson))
            : null,
      );
    }).toList();
  }

  /// ✅ Alias method for compatibility with ChatProvider
  Future<void> insertMessage(ChatMessageModel message) async {
    await insertChatMessage(message);
  }

  // delete message
  Future<void> deleteMessageFromLocalDb(String messageId) async {
    final db = database;
    final rowsDeleted = await db.delete(
      'chat_messages',
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    AppLoggerHelper.logInfo(
      'Deleted $rowsDeleted message(s) with id $messageId from local DB.',
    );
  }
}
