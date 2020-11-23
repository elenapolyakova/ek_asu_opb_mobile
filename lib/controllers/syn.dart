import 'package:ek_asu_opb_mobile/controllers/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/controllers/comGroup.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/utils/network.dart';

class SynController extends Controllers {
  static bool ongoingSync = false;
  static String _tableName = "syn";
  static Map<String, String> localRemoteTableNameMap = {
    'plan': 'mob.main.plan',
    'plan_item': 'mob.main.plan.item',
    'plan_item_check': 'mob.check.plan',
    'plan_item_check_item': 'mob.check.plan.item',
    'com_group': 'mob.check.plan.com_group',
    'department': 'eco.department',
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
  static Map<String, List<Map<String, dynamic>>> tableMany2ManyFieldsMap = {
    'com_group': [
      {
        // поле, в котором хранится отношение many2many на сервере
        'field': 'com_user_ids',
        // у модели 'to' есть поле odoo_id
        // пользователь может создавать записи 'to' модели
        'to_has_odoo_id': false,
        // целевая модель для отношения many2many
        'to': 'user',
        // промежуточная модель
        'through': 'rel_com_group_user',
        // поле промежуточной модели с id модели, указанной в ключе (com_group)
        'my_field': 'com_group_id',
        // поле промежуточной модели с id модели 'to'
        'other_field': 'user_id',
      }
    ],
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

  static Future loadFromOdoo() async {
    List lastDateDomain = await getLastSyncDateDomain(_tableName);
    DateTime dateTime = DateTime.now();
    if (lastDateDomain.length == 1) {
      await PlanController.firstLoadFromOdoo();
      await PlanItemController.firstLoadFromOdoo();
      await PlanItemController.firstLoadFromOdoo(true);
      await CheckPlanController.firstLoadFromOdoo();
      await CheckPlanItemController.firstLoadFromOdoo();
      await ComGroupController.firstLoadFromOdoo();
      await CheckPlanController.firstLoadFromOdoo(true);
      await CheckPlanItemController.firstLoadFromOdoo(true);
      await ComGroupController.firstLoadFromOdoo(true);
    } else {
      await PlanController.loadChangesFromOdoo();
      await PlanItemController.loadChangesFromOdoo();
      await PlanItemController.loadChangesFromOdoo(true);
      await CheckPlanController.loadChangesFromOdoo();
      await CheckPlanItemController.loadChangesFromOdoo();
      await ComGroupController.loadChangesFromOdoo();
      await CheckPlanController.loadChangesFromOdoo(true);
      await CheckPlanItemController.loadChangesFromOdoo(true);
      await ComGroupController.loadChangesFromOdoo(true);
    }
    await PlanItemController.finishSync(dateTime);
    await CheckPlanController.finishSync(dateTime);
    await CheckPlanItemController.finishSync(dateTime);
    await ComGroupController.finishSync(dateTime);
    await setLastSyncDateForDomain(_tableName, dateTime);
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
      print("Model ${syn.localTableName} has many2one fields");
      // For each many2one field in a record
      await Future.forEach(many2oneFields.entries, (el) async {
        final int many2oneFieldId = record[el.key];
        // If the record has a many2one
        if (many2oneFieldId != null) {
          final String localTable = el.value;
          // Replace many2one with odoo_id of its related record
          print(
              "Querying for ${syn.localTableName}.${el.key}=$many2oneFieldId");
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
              // If a record was found, but it has no odoo_id
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
            print(
                "${el.key} of ${syn.localTableName} to upload = ${many2oneRecord[0]['odoo_id']}");
            record[el.key] = many2oneRecord[0]['odoo_id'];
          });
        }
      });
    }

    // Add many2many records to upload
    final List<Map<String, dynamic>> many2manyFields =
        tableMany2ManyFieldsMap[syn.localTableName];
    // If a record contains any many2many fields
    if (many2manyFields != null && many2manyFields.length > 0) {
      print("Model ${syn.localTableName} has many2many fields");
      // For each many2many field in a record
      await Future.forEach(many2manyFields, (el) async {
        // 'field': 'com_user_ids',
        // 'to_has_odoo_id': false,
        // 'to': 'user',
        // 'through': 'rel_com_group_user',
        // 'my_field': 'com_group_id',
        // 'other_field': 'user_id',
        print("Querying for ${syn.localTableName}.${el['field']}.");
        List<int> ids;
        List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
          el['through'],
          columns: [el['other_field']],
          where: "${el['my_field']} = ?",
          whereArgs: [syn.recordId],
        );
        // Get ids to upload
        ids = queryRes
            .map((throughRecord) => throughRecord[el['other_field']] as int)
            .toList();
        print("Found ids of table ${el['to']}: ${ids.toString()}.");
        if (el['to_has_odoo_id']) {
          List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
            el['to'],
            columns: ['odoo_id'],
            where: ids.map((e) => "id = ?").join(' or '),
            whereArgs: [ids],
          );
          ids = queryRes.map((toRecord) => toRecord['odoo_id'] as int).toList();
          print(
              "${el['to']} has odoo_id field. New ids to upload: ${ids.toString()}.");
        }
        record[el['field']] = [
          [6, null, ids]
        ];
      });
    }

    // If there is no odoo_id in model,
    // then we are operating with a model we can't create records for
    // and method must be write
    if (!record.containsKey('odoo_id')) {
      if (syn.method == 'write')
        args = [record['id'], record];
      else {
        String error = "Odoo_id is absent but method was create.";
        print(error);
        await DBProvider.db.update(_tableName, {
          'id': syn.id,
          'error': error,
        });
        return false;
      }
    }
    // If odoo_id exists, then method must be write.
    // Unlinking was removed in favor of setting active to false.
    else if (record['odoo_id'] != null) {
      int odooId = record['odoo_id'];
      if (syn.method == 'write')
        args = [odooId, record];
      // else if (syn.method == 'unlink')
      //   args = [odooId];
      else {
        String error =
            "Odoo_id=${record['odoo_id']} was found but method was create.";
        print(error);
        await DBProvider.db.update(_tableName, {
          'id': syn.id,
          'error': error,
        });
        return false;
      }
    } else {
      // If odoo_id does not exist, then method must be create
      if (syn.method == 'create')
        args = [record];
      else {
        String error = "Odoo_id is null but method was write.";
        print(error);
        await DBProvider.db.update(_tableName, {
          'id': syn.id,
          'error': error,
        });
        return false;
      }
    }

    // Upload to backend
    print("Uploading $record");
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
  }

  static Future<bool> syncTask() async {
    if (ongoingSync) return true;
    ongoingSync = true;
    try {
      while (!await ping()) {
        await Future.delayed(Duration(seconds: 12));
      }
      await SynController.loadFromOdoo();
      while (true) {
        // Load a syn record
        List<Map<String, dynamic>> toSyn = await DBProvider.db.select(
            _tableName,
            limit: 1,
            orderBy: 'id',
            where: "error IS NULL");
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
    } finally {
      ongoingSync = false;
    }
  }
}
