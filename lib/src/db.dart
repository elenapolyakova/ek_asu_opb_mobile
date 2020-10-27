import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  initDB() async {
    WidgetsFlutterBinding.ensureInitialized();
    String dbPath = await getDatabasesPath();

    return await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(dbPath, "ek_asu_opb.db"),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) async {
        await db.execute(
            "CREATE TABLE railway(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER)");
        await db.execute(
            "CREATE TABLE department(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER, railway_id INTEGER)");
        await db.execute(
            "CREATE TABLE user(id INTEGER PRIMARY KEY, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT)");
        await db.execute("CREATE TABLE log(date TEXT, message TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS userInfo(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT)");
      },
      onOpen: (db) async {
         await db.execute(
            "CREATE TABLE IF NOT EXISTS log (date TEXT, message TEXT)");

        await db.execute(
            "CREATE TABLE IF NOT EXISTS userInfo(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT)");
      },

      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  Future<void> reCreateDictionary() async {
    final Database db = await database;
    await db.execute("DROP TABLE IF EXISTS railway");
    await db.execute("DROP TABLE IF EXISTS department");
    await db.execute("DROP TABLE IF EXISTS user");
    // await db.execute("DROP TABLE IF EXISTS log");
    await db.execute(
        "CREATE TABLE railway(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER)");
    await db.execute(
        "CREATE TABLE department(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER, railway_id INTEGER)");
    await db.execute(
        "CREATE TABLE user(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT)");
  }

  Future<void> reCreateTable() async {
    final Database db = await database;
  }

  Future<void> insert(String tableName, Map<String, dynamic> values,
      {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) async {
    final Database db = await database;

    await db.insert(
      tableName,
      values,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  Future<List<Map<String, dynamic>>> selectAll(String tableName) async {
    // Get a reference to the database.
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(tableName);

    return maps;
    // Convert the List<Map<String, dynamic> into a List<Dog>.
    /* return List.generate(maps.length, (i) {
      return Dog(
        id: maps[i]['id'],
        name: maps[i]['name'],
        age: maps[i]['age'],
      );
    });*/
  }

  Future<Map<String, dynamic>> select(String tableName, int id) async {
    // Get a reference to the database.
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return maps.length > 0 ? maps[0] : null;
  }

  Future<void> update(String tableName, Map<String, dynamic> values) async {
    // Get a reference to the database.
    final Database db = await database;

    await db.update(
      tableName,
      values,
      where: "id = ?",
      whereArgs: [values["id"]],
    );
  }

  Future<void> delete(String tableName, int id) async {
    final Database db = await database;

    await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> deleteAll(String tableName) async {
    // Get a reference to the database.
    final Database db = await database;
    await db.delete(tableName);
  }
}
