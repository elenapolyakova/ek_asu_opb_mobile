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
            "CREATE TABLE IF NOT EXISTS railway(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS department(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER, railway_id INTEGER, parent_id INTEGER,  active TEXT, search_field TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS user(id INTEGER PRIMARY KEY, login TEXT,  display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT, active TEXT, function TEXT, search_field TEXT,  user_role TEXT)");

        await db
            .execute("CREATE TABLE IF NOT EXISTS log(date TEXT, message TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS userInfo(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT, active TEXT, function TEXT)");
      },
      onUpgrade: (db, oldVersion, version) async {
        if (version >= 4 && oldVersion <= 3)
          await db.execute('ALTER TABLE user ADD COLUMN user_role TEXT');
        if (version == 5) {
          await db.execute(
              "CREATE TABLE IF NOT EXISTS plan_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, department_txt TEXT, check_type INTEGER, period INTEGER, responsible TEXT, check_result TEXT, active TEXT)");
          await db.execute('ALTER TABLE syn ADD COLUMN error TEXT');
        }
        if (version == 6) {

           await db.execute("DROP TABLE IF EXISTS plan");
           await db.execute("DROP TABLE IF EXISTS plan_item");   

        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan(id INTEGER PRIMARY KEY, odoo_id INTEGER, type TEXT, name TEXT, rw_id INTEGER, year INTEGER, date_set TEXT, state TEXT, signer_name TEXT, signer_post TEXT, num_set TEXT, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, department_txt TEXT, check_type INTEGER, period INTEGER, responsible TEXT, check_result TEXT, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan_item_check(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, rw_id INTEGER, date_from TEXT, date_to TEXT, date_set TEXT, state TEXT, signer_name TEXT, signer_post TEXT, app_name TEXT, app_post TEXT, num_set TEXT, active TEXT, main_com_group_id INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan_item_check_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, type INTEGER, department_id INTEGER, date TEXT, dt_from TEXT, dt_to TEXT, active TEXT, com_group_id INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS com_group(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, head_id INTEGER, group_num INTEGER, is_main TEXT, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS rel_com_group_user(id INTEGER PRIMARY KEY, com_group_id INTEGER, user_id INTEGER)");
        }
      },
      onOpen: (db) async {
        await db.execute(
            "CREATE TABLE IF NOT EXISTS log (date TEXT, message TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS userInfo(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS syn (id INTEGER PRIMARY KEY, record_id INTEGER, local_table_name TEXT, method TEXT, error TEXT)");
      },

      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 6,
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
        "CREATE TABLE department(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER, railway_id INTEGER, parent_id INTEGER, active TEXT, search_field TEXT)");
    await db.execute(
        "CREATE TABLE user(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT, active TEXT, function TEXT, search_field TEXT, user_role TEXT)");
  }

  Future<int> insert(String tableName, Map<String, dynamic> values,
      {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) async {
    final Database db = await database;

    return db.insert(
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
  }

  Future<Map<String, dynamic>> selectById(String tableName, int id) async {
    // Get a reference to the database.
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
    return (maps.length > 0) ? maps[0] : null;
  }

  Future<List<Map<String, dynamic>>> select(String tableName,
      {bool distinct,
      List<String> columns,
      String where,
      List<dynamic> whereArgs,
      String groupBy,
      String having,
      String orderBy,
      int limit,
      int offset}) async {
    // Get a reference to the database.
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(tableName,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    return maps;
  }

  Future<int> update(String tableName, Map<String, dynamic> values) async {
    // Get a reference to the database.
    final Database db = await database;

    return db.update(
      tableName,
      values,
      where: "id = ?",
      whereArgs: [values["id"]],
    );
  }

  Future<int> delete(String tableName, int id) async {
    final Database db = await database;

    return db.delete(
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
