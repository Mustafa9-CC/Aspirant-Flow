import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  test('Inspect Database Structure', () async {
    // Initialize FFI
    sqfliteFfiInit();
    final databaseFactory = databaseFactoryFfi;

    final dbPath = r'c:\Laiban\aspirant_flow\assets\json\Dictionary.db';

    // Check if file exists
    if (!File(dbPath).existsSync()) {
      print('Database file not found at $dbPath');
      return;
    }

    final db = await databaseFactory.openDatabase(dbPath,
        options: OpenDatabaseOptions(readOnly: true));

    print('\n--- Database Tables ---');
    final tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print(tables);

    for (var table in tables) {
      final tableName = table['name'] as String;
      if (tableName != 'android_metadata' && tableName != 'sqlite_sequence') {
        print('\n--- Structure of $tableName ---');
        final columns = await db.rawQuery('PRAGMA table_info($tableName)');
        for (var col in columns) {
          print(col);
        }

        print('\n--- First Row of $tableName ---');
        final rows = await db.rawQuery('SELECT * FROM $tableName LIMIT 1');
        if (rows.isNotEmpty) {
          print(rows.first);
        } else {
          print('Table is empty');
        }
      }
    }

    await db.close();
  });
}
