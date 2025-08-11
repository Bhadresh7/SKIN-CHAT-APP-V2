// import 'dart:convert';
//
// import 'package:path/path.dart';
// import 'package:skin_app_migration/features/message/models/chat_message_model.dart';
// import 'package:sqflite/sqflite.dart';
//
// import 'app_logger.dart';
//
// class LocalDbHelper {
//   static final LocalDbHelper _instance = LocalDbHelper._internal();
//
//   factory LocalDbHelper() => _instance;
//
//   LocalDbHelper._internal();
//
//   Database? _db;
//
//   /// Initialize SQLite DB with custom filename 'chat_data.db'
//   Future<void> init() async {
//     try {
//       final dbPath = await getDatabasesPath();
//       final path = join(dbPath, 'chat_data.db'); // ✅ custom name
//
//       _db = await openDatabase(
//         path,
//         version: 2, // Increment when schema changes
//         onCreate: (db, version) async {
//           AppLoggerHelper.logInfo('Creating initial tables...');
//           await _createTables(db);
//         },
//         onUpgrade: (db, oldVersion, newVersion) async {
//           AppLoggerHelper.logInfo(
//             'Upgrading DB from $oldVersion to $newVersion...',
//           );
//           if (oldVersion < 2) {
//             await _createChatMessagesTable(db);
//           }
//         },
//       );
//
//       AppLoggerHelper.logInfo('SQLite database initialized at $path');
//     } catch (e) {
//       AppLoggerHelper.logError('Error initializing SQLite: $e');
//     }
//   }
//
//   /// Ensures all required tables are created
//   Future<void> _createTables(Database db) async {
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS app_logs (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         message TEXT,
//         timestamp TEXT
//       )
//     ''');
//
//     await _createChatMessagesTable(db);
//   }
//
//   /// Creates the chat_messages table
//   Future<void> _createChatMessagesTable(Database db) async {
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS chat_messages (
//         id TEXT PRIMARY KEY,
//         message_id TEXT,
//         name TEXT,
//         ts INTEGER,
//         metadata TEXT
//       )
//     ''');
//     AppLoggerHelper.logInfo('chat_messages table created or already exists.');
//   }
//
//   bool get isInitialized => _db != null;
//
//   Database get database {
//     if (_db == null) {
//       throw Exception('Database not initialized. Call init() first.');
//     }
//     return _db!;
//   }
//
//   // ===== ChatMessageModel CRUD =====
//
//   //  Inset Messages
//   Future<void> insertChatMessage(ChatMessageModel message) async {
//     final db = database;
//     await db.insert('chat_messages', {
//       'messageId': message.messageId, // store Firestore doc ID
//       'id': message.senderId,
//       'ts': message.createdAt,
//       'name': message.name,
//       'metadata': jsonEncode(message.metadata?.toJson()),
//     }, conflictAlgorithm: ConflictAlgorithm.replace);
//   }
//
//   // Get All Messages
//   Future<List<ChatMessageModel>> getAllMessages() async {
//     final db = database;
//     final result = await db.query(
//       'chat_messages',
//       orderBy: 'ts ASC',
//       limit: 10,
//     );
//
//     return result.map((map) {
//       final metadataJson = map['metadata'] as String?;
//       return ChatMessageModel.fromJson({
//         'id': map['id'],
//         'name': map['name'],
//         'metadata': metadataJson != null ? jsonDecode(metadataJson) : null,
//       });
//     }).toList();
//   }
// }
