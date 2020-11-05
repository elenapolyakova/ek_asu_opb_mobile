import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/models/models.dart' as models;
import "package:ek_asu_opb_mobile/models/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class SynController extends Controllers {
  static String _tableName = "syn";
  static Map<String, String> localRemoteTableNameMap = {
    'plan': 'mob.main.plan',
  };
  static Map<String, dynamic> tableNameClassMap = {
    'plan': Plan,
    'department': models.Department,
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
  static Future<int> edit(localTableName, resId, odooId) async {
    List toSyn = await DBProvider.db.select(
      _tableName,
      columns: ['id'],
      where: "record_id = ? and local_table_name = ? and method = 'create'",
      whereArgs: [resId, localTableName],
    );
    if (toSyn.length != 0 && odooId == null)
      //sync record exists and local record does not exist => wasn't uploaded
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
    List toSyn = await DBProvider.db.select(
      _tableName,
      columns: ['id'],
      where: "record_id = ? and local_table_name = ? and method = 'create'",
      whereArgs: [resId, localTableName],
    );
    if (toSyn.length == 0 && odooId != null)
      //sync record does not exist and local record exists => was uploaded
      return DBProvider.db.delete(_tableName, toSyn[0]['id']);
    return DBProvider.db.insert(_tableName, {
      'record_id': resId,
      'local_table_name': localTableName,
      'method': 'unlink',
    });
  }

  /// Perform a synchronization of a syn record with backend.
  /// Remove the record from syn table if successful.
  /// Return true if successful
  static Future<bool> doSync(Syn syn) async {
    // Get syn's local db record
    List<Map<String, dynamic>> records = await DBProvider.db
        .select(syn.localTableName, where: 'id = ?', whereArgs: [syn.recordId]);
    Map<String, dynamic> record = records[0];

    List<dynamic> args = [];
    if (record['odooId'] != null) {
      int odooId = record.remove('odooId');
      if (syn.method == 'write')
        args = [odooId, record];
      else if (syn.method == 'unlink')
        args = [odooId];
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
      // If successful, delete syn and return true
      await DBProvider.db.delete(_tableName, syn.id);
      return true;
    }).catchError((err) {
      // If unsuccessful, return false
      return false;
    });
    // }
  }

  static syncTask() async {
    while (true) {
      // Load a syn record
      List<Map<String, dynamic>> toSyn =
          await DBProvider.db.select(_tableName, limit: 1, orderBy: 'id');
      if (toSyn.length != 0) {
        //Синхронизация завершена
        //TODO: вывести уведомление
        print('Finished synchronization');
        DBProvider.db.insert(
            'log', {'date': nowStr(), 'message': "Finished synchronization"});
        break;
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
