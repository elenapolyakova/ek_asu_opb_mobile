import 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
import 'package:ek_asu_opb_mobile/controllers/comGroup.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/comGroup.dart';
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'package:ek_asu_opb_mobile/models/checkPlanItem.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckPlanItemController extends Controllers {
  static String _tableName = "plan_item_check_item";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<CheckPlanItem> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return CheckPlanItem.fromJson(json);
  }

  static Future<CheckPlanItem> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return CheckPlanItem.fromJson(json[0]);
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static firstLoadFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    List<List> domain = [];
    if (loadRelated) {
      fields = ['parent_id', 'com_group_id'];

      List<Map<String, dynamic>> queryRes =
          await DBProvider.db.select(_tableName, columns: ['odoo_id']);
      domain = [
        ['id', 'in', queryRes.map((e) => e['odoo_id'] as int).toList()]
      ];
    } else
      fields = [
        'name',
        'type',
        'department_id',
        'date',
        'dt_from',
        'dt_to',
      ];
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });
    if (!loadRelated) DBProvider.db.deleteAll(_tableName);
    return Future.forEach(json, (e) async {
      if (loadRelated) {
        CheckPlan checkPlan = await CheckPlanController.selectByOdooId(
            unpackListId(e['parent_id'])['id']);
        assert(checkPlan != null,
            "Model plan_item_check has to be loaded before $_tableName");
        ComGroup comGroup = await ComGroupController.selectByOdooId(
            unpackListId(e['com_group_id'])['id']);
        assert(comGroup != null,
            "Model com_group has to be loaded before $_tableName");
        CheckPlanItem checkPlanItem = await selectByOdooId(e['id']);
        Map<String, dynamic> res = {
          ...e,
          'id': checkPlanItem.id,
          'parent_id': checkPlan.id,
          'com_group_id': comGroup.id,
        };
        return DBProvider.db.update(_tableName, res);
      } else {
        Map<String, dynamic> res = {
          ...e,
          'id': null,
          'odoo_id': e['id'],
          'active': 'true',
        };
        return insert(CheckPlanItem.fromJson(res), true);
      }
    });
  }

  static loadChangesFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['parent_id', 'com_group_id'];
    else
      fields = [
        'name',
        'type',
        'department_id',
        'date',
        'dt_from',
        'dt_to',
        'active',
      ];
    List domain = await getLastSyncDateDomain(_tableName);
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });
    return Future.forEach(json, (e) async {
      CheckPlanItem checkPlanItem = await selectByOdooId(e['id']);
      if (loadRelated) {
        CheckPlan checkPlan = await CheckPlanController.selectByOdooId(
            unpackListId(e['parent_id'])['id']);
        assert(checkPlan != null,
            "Model plan_item_check has to be loaded before $_tableName");
        ComGroup comGroup = await ComGroupController.selectByOdooId(
            unpackListId(e['com_group_id'])['id']);
        assert(comGroup != null,
            "Model com_group has to be loaded before $_tableName");
        Map<String, dynamic> res = {
          'id': checkPlanItem.id,
          'parent_id': checkPlan.id,
          'com_group_id': comGroup.id,
        };
        return DBProvider.db.update(_tableName, res);
      } else {
        if (checkPlanItem == null) {
          Map<String, dynamic> res = CheckPlanItem.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = CheckPlanItem.fromJson({
          ...e,
          'id': checkPlanItem.id,
          'odoo_id': checkPlanItem.odooId,
          'active': e['active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
  }

  static finishSync(dateTime) {
    setLastSyncDateForDomain(_tableName, dateTime);
  }

  /// Select all records with provided parentId
  /// Returns found records or null.
  static Future<List<CheckPlanItem>> select(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<CheckPlanItem> planItems =
        queryRes.map((e) => CheckPlanItem.fromJson(e)).toList();
    return planItems;
  }

  /// Try to insert into the table.
  /// ======
  /// Returns ```{
  ///   'code':[1|-1|-2|-3],
  ///   'message':[
  ///     null|
  ///     Error updating syn|
  ///     Error inserting into $_tableName|
  ///   ]
  ///   'id':record_id
  /// }```
  static Future<Map<String, dynamic>> insert(CheckPlanItem checkPlanItem,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> json = checkPlanItem.toJson(!saveOdooId);
    if (saveOdooId) json.remove('id');
    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      if (!saveOdooId)
        return SynController.create(_tableName, resId).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error inserting into $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  /// Try to update a record of the table.
  /// Returns ```{
  ///   'code':[1|-1|-2|-3],
  ///   'message':[
  ///     null|
  ///     Error updating syn|
  ///     Error updating $_tableName|
  ///   ]
  ///   'id':null
  /// }```
  static Future<Map<String, dynamic>> update(
      CheckPlanItem checkPlanItem) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(checkPlanItem.id);
    await DBProvider.db
        .update(_tableName, checkPlanItem.toJson())
        .then((resId) async {
      res['code'] = 1;
      res['id'] = resId;
      return SynController.edit(_tableName, resId, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error updating $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  /// Try to delete a record from the table.
  /// Returns ```{
  ///   'code':[1|-2|-3],
  ///   'message':[null|Error deleting from syn|Error deleting from $_tableName],
  ///   'id':null
  /// }```
  static Future<Map<String, dynamic>> delete(int id) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(id);
    await DBProvider.db
        .update(_tableName, {'id': id, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      return SynController.delete(_tableName, id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });
    return res;
  }
}
