import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class SynController extends Controllers {
  static String _tableName = "syn";
  static Map<String, String> localRemoteTableNameMap = {
    'plan': 'mob.main.plan',
  };
  static Map<String, Map<String, String>> tableNameMany2oneFieldsMap = {
    'plan': {},
    'plan_item': {
      'parent_id': 'plan',
    },
    'plan_item_check': {
      'parent_id': 'plan_item_check',
    },
  };
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Syn syn = Syn.fromJson(json); //нужно, чтобы преобразовать одоо rel в id
    return await DBProvider.db.insert(_tableName, syn.toJson());
  }

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return null;
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  /// Adds a record to create into syn table
  static Future<int> create(localTableName, resId) async {
    return DBProvider.db.insert(_tableName, {
      'record_id': resId,
      'local_table_name': localTableName,
      'method': 'create',
    });
  }

  /// If a record wasn't uploaded yet, do nothing.
  /// Else adds a record to edit into syn table
  static Future<int> edit(String localTableName, int resId, int odooId) async {
    List toSyn = await DBProvider.db.select(
      _tableName,
      columns: ['method'],
      where:
          "record_id = ? and local_table_name = ? and (method = 'create' or method = 'write')",
      whereArgs: [resId, localTableName],
    );
    if (toSyn.length != 0 &&
        (toSyn[0]['method'] == 'create' && odooId == null ||
            toSyn[0]['method'] == 'write' && odooId != null))
      //sync record 'create' exists and local record does not have odooId => check for 'write'
      //sync record 'write' exists and local record has odooId => wasn't uploaded
      return null;
    return DBProvider.db.insert(_tableName, {
      'record_id': resId,
      'local_table_name': localTableName,
      'method': 'write',
    });
  }

  /// If a record to delete wasn't uploaded, removes existing records to sync.
  /// Else adds a record to delete into syn table.
  static Future<int> delete(localTableName, resId, odooId) async {
    return edit(localTableName, resId, odooId);
    // List toSyn = await DBProvider.db.select(
    //   _tableName,
    //   columns: ['id'],
    //   where: "record_id = ? and local_table_name = ? and method = 'create'",
    //   whereArgs: [resId, localTableName],
    // );
    // if (toSyn.length == 0 && odooId != null)
    //   //sync record does not exist and local record exists => was uploaded
    //   return DBProvider.db.delete(_tableName, toSyn[0]['id']);
    // return DBProvider.db.insert(_tableName, {
    //   'record_id': resId,
    //   'local_table_name': localTableName,
    //   'method': 'unlink',
    // });
  }

  /// Perform a synchronization of a syn record with backend.
  /// Remove the record from syn table if successful.
  /// Return true if successful
  static Future<bool> doSync(Syn syn) async {
    // Get syn's local db record
    List<Map<String, dynamic>> records = await DBProvider.db
        .select(syn.localTableName, where: 'id = ?', whereArgs: [syn.recordId]);
    // if (records.length == 0 && syn.method == 'unlink') {}
    Map<String, dynamic> record = records[0];

    List<dynamic> args = [];
    record['active'] = record['active'] == 'true' ? true : false;

    // turn local many2one ids into Odoo ids
    final Map<String, String> many2oneFields =
        tableNameMany2oneFieldsMap[syn.localTableName];
    // If a record contains any many2one fields
    if (many2oneFields != null && many2oneFields.length > 0) {
      // For each many2one field in a record
      Future.forEach(many2oneFields.entries, (el) async {
        final int many2oneFieldId = record[el.key];
        // If the record has a many2one
        if (many2oneFieldId != null) {
          final String localTable = el.value;
          return DBProvider.db.select(
            localTable,
            where: "id = ?",
            whereArgs: [many2oneFieldId],
          ).then((List<Map<String, dynamic>> many2oneRecord) {
            if (many2oneRecord == null || many2oneRecord.length == 0) {
              DBProvider.db.insert('log', {
                'date': nowStr(),
                'message':
                    "Tried to synchronize record $syn. Specified record has ${el.key}=$many2oneFieldId. But no record of table $localTable with id=$many2oneFieldId was found"
              });
              return;
            }
            record[el.key] = many2oneRecord[0]['odoo_id'];
          });
        }
      });
    }

    if (record['odoo_id'] != null) {
      int odooId = record['odoo_id'];
      if (syn.method == 'write')
        args = [odooId, record];
      // else if (syn.method == 'unlink')
      //   args = [odooId];
      else
        return Future.value(false);
    } else {
      if (syn.method == 'create')
        args = [record];
      else
        return Future.value(false);
    }

    // Upload to backend
    return await getDataWithAttemp(
            localRemoteTableNameMap[syn.localTableName], syn.method, args, {})
        .then((value) async {
      if (syn.method == 'create') {
        print(value);
        record['odoo_id'] = int.parse(value.toString());
        await DBProvider.db.update(syn.localTableName, record);
      }
      // If successful, delete syn and return true
      print(syn.id);
      await DBProvider.db.delete(_tableName, syn.id);
      return true;
    }).catchError((err) {
      // If unsuccessful, put error into syn and return false
      syn.error = err.toString();
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message': "Error: ${err.toString()}; Record: $syn"
      });
      DBProvider.db.update(_tableName, syn.toJson());
      return false;
    });
    // }
  }

  static Future<bool> syncTask() async {
    while (true) {
      // Load a syn record
      List<Map<String, dynamic>> toSyn = await DBProvider.db
          .select(_tableName, limit: 1, orderBy: 'id', where: "error IS NULL");
      if (toSyn.length == 0) {
        //Синхронизация завершена
        //TODO: вывести уведомление
        print('Finished synchronization');
        DBProvider.db.insert(
            'log', {'date': nowStr(), 'message': "Finished synchronization"});
        return true;
      }

      // For each syn record:
      Syn syn = Syn.fromJson(toSyn[0]);
      print('Synchronizing $syn');
      bool result = await SynController.doSync(syn);
      if (!result) {
        //Синхронизация не прошла
        //TODO: вывести уведомление
        DBProvider.db.insert(
            'log', {'date': nowStr(), 'message': "Error synchronizing $syn"});
      }
    }
  }
}
