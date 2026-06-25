import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  static Database? _database;

  String? _tableName;
  String? _wordColumn;
  String? _definitionColumn;

  factory DictionaryService() {
    return _instance;
  }

  DictionaryService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _discoverSchema(_database!);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'Dictionary.db');

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data =
          await rootBundle.load(join('assets', 'json', 'Dictionary.db'));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  Future<void> _discoverSchema(Database db) async {
    // Get all tables
    final tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");

    // Heuristic to find the main dictionary table
    // We look for tables carrying 'eng', 'dict', 'word', 'entry' etc.
    // Or just pick the largest one / first non-metadata one.

    for (var table in tables) {
      final name = table['name'] as String;
      if (name == 'android_metadata' || name == 'sqlite_sequence') continue;

      // Check columns
      final columns = await db.rawQuery('PRAGMA table_info($name)');
      final columnNames =
          columns.map((c) => (c['name'] as String).toLowerCase()).toList();

      // Look for a word column
      String? wCol;
      if (columnNames.contains('word'))
        wCol = 'word';
      else if (columnNames.contains('lemma'))
        wCol = 'lemma';
      else if (columnNames.contains('key')) wCol = 'key';

      // Look for a definition column
      String? dCol;
      if (columnNames.contains('definition'))
        dCol = 'definition';
      else if (columnNames.contains('meaning'))
        dCol = 'meaning';
      else if (columnNames.contains('def'))
        dCol = 'def';
      else if (columnNames.contains('html'))
        dCol = 'html'; // Some use html content
      else if (columnNames.contains('content')) dCol = 'content';

      // If we found candidates, use this table
      if (wCol != null && dCol != null) {
        _tableName = name;
        _wordColumn = wCol;
        _definitionColumn = dCol;
        print(
            'Discovered Dictionary Table: $_tableName, Word: $_wordColumn, Def: $_definitionColumn');
        return;
      }
    }

    // Fallback: If strict naming failed, just take the first table and its first 2 text columns?
    // Let's rely on the user testing if this fails, or try to be more aggressive.
    if (_tableName == null && tables.isNotEmpty) {
      for (var table in tables) {
        final name = table['name'] as String;
        if (name == 'android_metadata' || name == 'sqlite_sequence') continue;
        _tableName = name;
        // Just guess first two columns
        final columns = await db.rawQuery('PRAGMA table_info($name)');
        if (columns.length >= 2) {
          _wordColumn = columns[0]['name'] as String;
          _definitionColumn = columns[1]['name'] as String;
        }
        print(
            'Fallback Dictionary Table: $_tableName, Word: $_wordColumn, Def: $_definitionColumn');
        return;
      }
    }
  }

  Future<String?> getDefinition(String word) async {
    final db = await database;
    if (_tableName == null ||
        _wordColumn == null ||
        _definitionColumn == null) {
      return "Error: Could not identify dictionary database structure.";
    }

    // Try exact match first
    List<Map<String, dynamic>> result = await db.query(
      _tableName!,
      columns: [_definitionColumn!],
      where: '$_wordColumn COLLATE NOCASE = ?',
      whereArgs: [word],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first[_definitionColumn!] as String;
    }

    // Try LIKE match if exact fails (e.g. for capitalization issues if nocase isn't enough)
    // Or maybe try stripping punctuation?

    return null; // Not found
  }
}
