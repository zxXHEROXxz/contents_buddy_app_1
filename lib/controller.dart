import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class Controller {
  static Future<void> createTables(Database database) async {
    await database.execute("""CREATE TABLE contentsBuddy(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT,
        telephone TEXT,
        email TEXT,
        street TEXT,
        profilePic TEXT
      )
      """);
  }

  static Future<Database> db() async {
    return openDatabase(
      'contentsBuddy_db.db',
      version: 1,
      onCreate: (Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> createContact(
    String name,
    String telephone,
    String email,
    String street,
    String profilePic,
  ) async {
    final db = await Controller.db();

    final data = {
      'name': name,
      'telephone': telephone,
      'email': email,
      'street': street,
      'profilePic': profilePic,
    };
    final id = await db.insert('contentsBuddy', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await Controller.db();
    return db.query('contentsBuddy', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getContact(int id) async {
    final db = await Controller.db();
    return db.query('contentsBuddy',
        where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<int> updateContact(
    int id,
    String name,
    String telephone,
    String email,
    String street,
    String profilePic,
  ) async {
    final db = await Controller.db();

    // map the data to be updated
    final data = {
      'name': name,
      'telephone': telephone,
      'email': email,
      'street': street,
      'profilePic': profilePic,
    };

    final result = await db
        .update('contentsBuddy', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<void> deleteContact(int id) async {
    final db = await Controller.db();
    try {
      await db.delete("contentsBuddy", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      debugPrint("Could not be deleted: $e");
    }
  }

  // Image Encoding and Decoding Functions were added by my colleague..

  static String imageToBase64String(String path) {
    final bytes = File(path).readAsBytesSync();
    return base64.encode(bytes);
  }

  static void deleteBase64Image(String base64Image) {
    final RegExp regex = RegExp(r'^data:image/[^;]+;base64,');
    final String base64Str = base64Image.replaceAll(regex, '');
    final Uint8List bytes = base64.decode(base64Str);
    File.fromRawPath(bytes).deleteSync();
  }

  static String encodePhoto(String path) {
    final String base64Image = imageToBase64String(path);
    return base64Image;
  }

  static File decodePhoto(String base64Image, String fileName) {
    final RegExp regex = RegExp(r'^data:image/[^;]+;base64,');
    final String base64Str = base64Image.replaceAll(regex, '');
    final Uint8List bytes = base64.decode(base64Str);
    final file = File(fileName)..writeAsBytesSync(bytes);
    return file;
  }
}
