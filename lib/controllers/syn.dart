import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class SynController extends Controllers {
  static String _tableName = "syn";
  static Map<String, String> localRemoteTableNameMap = {
    'plan': 'mob.main.plan',
    'plan_item': 'mob.main.plan.item',
    'plan_item_check': 'mob.check.plan',
    'plan_item_check_item': 'mob.check.plan.item',
    'com_group': 'mob.check.plan.com_group',
  };
  static Map<String, List<String>> tableBooleanFieldsMap = {
    'plan': ['active'],
    'plan_item': ['active'],
    'plan_item_check': ['active'],
    'plan_item_check_item': ['active'],
    'com_group': ['active', 'is_main'],
  };
  static Map<String, Map<String, String>> tableMany2oneFieldsMap = {
    'plan': {},
    'plan_item': {
      'parent_id': 'plan',
    },
    'plan_item_check': {
      'parent_id': 'plan_item',
      'main_com_group_id': 'com_group',
    },
    'plan_item_check_item': {
      'parent_id': 'plan_item_check',
      'com_group_id': 'com_group',
    },
    'com_group': {
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

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  /// Adds a record to create into syn table
  static Future<int> create(String localTableName, int resId) async {
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
  static Future<int> delete(
      String localTableName, int resId, int odooId) async {
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
    Map<String, dynamic> record = Map.from(records.single);

    List<dynamic> args = [];

    // turn local boolean text fields into boolean for odoo
    final List<String> booleanFields =
        tableBooleanFieldsMap[syn.localTableName];
    // If a record contains any boolean fields
    if (booleanFields != null && booleanFields.length > 0) {
      // For each boolean field in a record
      booleanFields.forEach((el) {
        record[el] = record[el] == 'true';
      });
    }

    // turn local many2one ids into Odoo ids
    final Map<String, String> many2oneFields =
        tableMany2oneFieldsMap[syn.localTableName];
    // If a record contains any many2one fields
    if (many2oneFields != null && many2oneFields.length > 0) {
      // For each many2one field in a record
      Future.forEach(many2oneFields.entries, (el) async {
        final int many2oneFieldId = record[el.key];
        // If the record has a many2one
        if (many2oneFieldId != null) {
          final String localTable = el.value;
          // Replace many2one with odoo_id of its related record
          return DBProvider.db
              .select(
            localTable,
            columns: ['odoo_id'],
            where: "id = ?",
            whereArgs: [many2oneFieldId],
          )
              .then((List<Map<String, dynamic>> many2oneRecord) async {
            if (many2oneRecord == null || many2oneRecord.length == 0) {
              // If no record is found, log error and exit
              print(
                  'Tried to synchronize record $syn. Specified record has ${el.key}=$many2oneFieldId. But no record of table $localTable with id=$many2oneFieldId was found');
              DBProvider.db.insert('log', {
                'date': nowStr(),
                'message':
                    "Tried to synchronize record $syn. Specified record has ${el.key}=$many2oneFieldId. But no record of table $localTable with id=$many2oneFieldId was found"
              });
              return false;
            } else if (many2oneRecord[0]['odoo_id'] == null) {
              // If a record was found, but is has no odoo_id
              List<Map<String, dynamic>> synList = await DBProvider.db.select(
                _tableName,
                limit: 1,
                where: "record_id = ? and local_table_name = ? and method = ?",
                whereArgs: [many2oneRecord[0]['id'], localTable, 'create'],
              );
              print(
                  'Tried to synchronize record $syn. Specified record has ${el.key}=$many2oneFieldId. Synchronizing it first...');
              DBProvider.db.insert('log', {
                'date': nowStr(),
                'message':
                    "Tried to synchronize record $syn. Specified record has ${el.key}=$many2oneFieldId. Synchronizing it first..."
              });
              // Synchronize the related record first
              await doSync(Syn.fromJson(synList[0]));
              // Try to synchronize the original record again
              return doSync(syn);
            }
            record[el.key] = many2oneRecord[0]['odoo_id'];
          });
        }
      });
    }

    // If odoo_id exists, then method must be write.
    // Unlinking was removed in favor of setting active to false.
    // If odoo_id does not exist, then method must be create
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
        print(
            "Created ${syn.localTableName} with id = ${syn.recordId}. New odoo_id = $value");
        await DBProvider.db.update(syn.localTableName,
            {'id': syn.recordId, 'odoo_id': int.parse(value.toString())});
      }
      // If successful, delete syn and return true
      print("Deleting $syn");
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
