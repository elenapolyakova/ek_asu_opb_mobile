import 'dart:async';
import 'package:ek_asu_opb_mobile/controllers/railway.dart';
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

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
            "CREATE TABLE IF NOT EXISTS department(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER, railway_id INTEGER, parent_id INTEGER,  active TEXT, search_field TEXT, f_inn TEXT, f_ogrn TEXT, f_okpo TEXT, f_addr TEXT, director_fio TEXT, director_email TEXT, director_phone TEXT, deputy_fio TEXT, deputy_email TEXT, deputy_phone TEXT, rel_sector_id INTEGER, rel_sector_name TEXT, f_coord_n REAL, f_coord_e REAL)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS user(id INTEGER PRIMARY KEY, login TEXT,  display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT, active TEXT, function TEXT, search_field TEXT,  user_role TEXT)");
        await db
            .execute("CREATE TABLE IF NOT EXISTS log(date TEXT, message TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS userInfo(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT, active TEXT, function TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan(id INTEGER PRIMARY KEY, odoo_id INTEGER, type TEXT, name TEXT, rw_id INTEGER, year INTEGER, date_set TEXT, state TEXT, signer_name TEXT, signer_post TEXT, num_set TEXT, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, department_txt TEXT, check_type INTEGER, period INTEGER, responsible TEXT, check_result TEXT, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan_item_check(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, rw_id INTEGER, date_from TEXT, date_to TEXT, date_set TEXT, state TEXT, signer_name TEXT, signer_post TEXT, app_name TEXT, app_post TEXT, num_set TEXT, active TEXT, main_com_group_id INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS plan_item_check_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, type INTEGER, department_id INTEGER, date TEXT, dt_from TEXT, dt_to TEXT, active TEXT, com_group_id INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS com_group(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, head_id INTEGER, group_num TEXT, is_main TEXT, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS rel_com_group_user(id INTEGER PRIMARY KEY, com_group_id INTEGER, user_id INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS check_list(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, base_id INTEGER, is_base TEXT, name TEXT, is_active TEXT, type INTEGER, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS check_list_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, base_id INTEGER, name TEXT, question TEXT, result TEXT, description TEXT, active TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS fault(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, name TEXT, desc TEXT, fine_desc TEXT, fine INTEGER, koap_id INTEGER, date TEXT, date_done TEXT, desc_done TEXT, active TEXT, plan_fix_date TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS fault_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, name TEXT, type INTEGER, parent_id INTEGER, image TEXT, active TEXT, file_name TEXT, file_data TEXT, coord_n REAL, coord_e REAL)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS koap(id INTEGER PRIMARY KEY, article TEXT, paragraph TEXT, text TEXT, man_fine_from INTEGER, man_fine_to INTEGER, firm_fine_from INTEGER, firm_fine_to INTEGER, firm_stop INTEGER, desc TEXT, search_field TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS department_document(id INTEGER PRIMARY KEY, section TEXT, model TEXT, file_name TEXT, file_id INTEGER, department_id INTEGER, file_path TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS document_list(id INTEGER PRIMARY KEY, name TEXT, parent_id INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS isp_document(id INTEGER PRIMARY KEY, parent2_id INTEGER, name TEXT, date TEXT, number TEXT, description TEXT, file_name TEXT, file_path TEXT, type INTEGER, is_new TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS chat(id INTEGER PRIMARY KEY, odoo_id INTEGER, name TEXT, type INTEGER, group_id INTEGER, last_update TEXT, last_read TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS chat_message(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, msg TEXT, create_date TEXT, create_uid INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS rel_chat_user(id INTEGER PRIMARY KEY, chat_id INTEGER, user_id INTEGER)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS fault_fix(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, desc TEXT, date TEXT, active TEXT, is_finished TEXT)");
        await db.execute(
            "CREATE TABLE IF NOT EXISTS fault_fix_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, name TEXT, type INTEGER, parent3_id INTEGER, image TEXT, active TEXT, file_name TEXT, file_data TEXT, coord_n REAL, coord_e REAL)");
      },
      onUpgrade: (db, oldVersion, version) async {
        switch (oldVersion) {
          case 1:
            await db.transaction((txn) async {
              await txn.execute(
                  'ALTER TABLE chat_message ADD COLUMN create_uid INTEGER');
              await txn.execute('ALTER TABLE chat ADD COLUMN last_update TEXT');
              await txn.execute('ALTER TABLE chat ADD COLUMN last_read TEXT');
              // Переименование колонки group_id в chat_id
              await txn.execute(
                  "CREATE TABLE new_rel_chat_user(id INTEGER PRIMARY KEY, chat_id INTEGER, user_id INTEGER)");
              await txn.execute(
                  "INSERT INTO new_rel_chat_user(id, chat_id, user_id) SELECT id, group_id, user_id FROM rel_chat_user");
              await txn.execute("DROP TABLE rel_chat_user");
              await txn.execute(
                  "ALTER TABLE new_rel_chat_user RENAME TO rel_chat_user");
            });
            continue v2;
          v2:
          case 2:
          case 3:
            await db.execute(
                "CREATE TABLE IF NOT EXISTS fault_fix(id INTEGER PRIMARY KEY, odoo_id INTEGER, parent_id INTEGER, desc TEXT, date TEXT, active TEXT, is_finished TEXT)");
            await db.execute(
                "CREATE TABLE IF NOT EXISTS fault_fix_item(id INTEGER PRIMARY KEY, odoo_id INTEGER, name TEXT, type INTEGER, parent3_id INTEGER, image TEXT, active TEXT, file_name TEXT, file_data TEXT, coord_n REAL, coord_e REAL)");
            continue v3;
          v3:
          case 4:
          default:
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
      version: 4,
    );
  }

  Future<void> reCreateDB() async {
    await deleteAll("railway");
    await deleteAll("department");
    await deleteAll("user");
    await deleteAll("log");
    await deleteAll("userInfo");
    await deleteAll("plan");
    await deleteAll("plan_item");
    await deleteAll("plan_item_check");
    await deleteAll("plan_item_check_item");
    await deleteAll("com_group");
    await deleteAll("rel_com_group_user");
    await deleteAll("check_list");
    await deleteAll("check_list_item");
    await deleteAll("fault");

    for (Map<String, dynamic> element
        in (await DBProvider.db.selectAll('fault_item'))) {
      String filePath = element["image"];
      if (!['', null].contains(filePath)) await File(filePath).delete();
    }
    await deleteAll("fault_item");

    await deleteAll("fault_fix");

    for (Map<String, dynamic> element
        in (await DBProvider.db.selectAll('fault_fix_item'))) {
      String filePath = element["image"];
      if (!['', null].contains(filePath)) await File(filePath).delete();
    }
    await deleteAll("fault_fix_item");

    await deleteAll("koap");

    for (Map<String, dynamic> element
        in (await DBProvider.db.selectAll('department_document'))) {
      String filePath = element["file_path"];
      if (!['', null].contains(filePath)) await File(filePath).delete();
    }
    await deleteAll("department_document");

    await deleteAll("document_list");

    for (Map<String, dynamic> element
        in (await DBProvider.db.selectAll('isp_document'))) {
      String filePath = element["file_path"];
      if (!['', null].contains(filePath)) await File(filePath).delete();
    }
    await deleteAll("isp_document");

    await deleteAll("chat");
    await deleteAll("chat_message");
    await deleteAll("rel_chat_user");
    await deleteAll("syn");
  }

  Future<void> reCreateDictionary() async {
    await deleteAll("railway");
    await deleteAll("department");
    await deleteAll("user");
    await deleteAll("koap");

    /* await db.execute("DROP TABLE IF EXISTS railway");
    await db.execute("DROP TABLE IF EXISTS department");
    await db.execute("DROP TABLE IF EXISTS user");
    await db.execute("DROP TABLE IF EXISTS koap");

    // await db.execute("DROP TABLE IF EXISTS log");
    await db.execute(
        "CREATE TABLE railway(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER)");
    await db.execute(
        "CREATE TABLE department(id INTEGER PRIMARY KEY, name TEXT, short_name INTEGER, railway_id INTEGER, parent_id INTEGER, active TEXT, search_field TEXT)");
    await db.execute(
        "CREATE TABLE user(id INTEGER PRIMARY KEY, login TEXT, display_name TEXT, department_id int, f_user_role_txt TEXT, railway_id INTEGER, email TEXT, phone TEXT, active TEXT, function TEXT, search_field TEXT, user_role TEXT)");
    await db.execute(
        "CREATE TABLE IF NOT EXISTS koap(id INTEGER PRIMARY KEY, article TEXT, paragraph TEXT, text TEXT, man_fine_from INTEGER, man_fine_to INTEGER, firm_fine_from INTEGER, firm_fine_to INTEGER, firm_stop INTEGER, desc TEXT, search_field TEXT)");
*/
    // await SynController.loadFromOdoo();
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

  Future<Batch> get batch async {
    final Database db = await database;
    return db.batch();
  }

  Future<List<Map<String, dynamic>>> executeQuery(String query) async {
    final Database db = await database;
    return db.rawQuery(query);
  }
}
