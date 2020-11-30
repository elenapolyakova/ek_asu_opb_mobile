import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'package:ek_asu_opb_mobile/models/planItem.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class PlanItemController extends Controllers {
  static String _tableName = "plan_item";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<PlanItem> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return PlanItem.fromJson(json);
  }

  static Future<PlanItem> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return PlanItem.fromJson(json[0]);
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
      fields = ['parent_id'];
      List<Map<String, dynamic>> queryRes =
          await DBProvider.db.select(_tableName, columns: ['odoo_id']);
      domain = [
        ['id', 'in', queryRes.map((e) => e['odoo_id'] as int).toList()]
      ];
    } else {
      List<List> toAdd = [];
      await Future.forEach(
          SynController.tableMany2oneFieldsMap[_tableName].entries,
          (element) async {
        List<Map<String, dynamic>> queryRes =
            await DBProvider.db.select(element.value, columns: ['odoo_id']);
        toAdd.add([
          element.key,
          'in',
          queryRes.map((e) => e['odoo_id'] as int).toList()
        ]);
      });
      domain += toAdd;
      fields = [
        'name',
        'department_txt',
        'check_type',
        'period',
        'responsible',
        'check_result',
      ];
    }
    print('first load plan_item $loadRelated');
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });
    if (!loadRelated) {
      await DBProvider.db.deleteAll(_tableName);
    }
    var result = json.forEach((e) async {
      if (loadRelated) {
        if (e['parent_id'] is bool && !e['parent_id']) return null;
        Plan plan = await PlanController.selectByOdooId(
            unpackListId(e['parent_id'])['id']);
        assert(plan != null, "Model plan has to be loaded before $_tableName");
        PlanItem planItem = await selectByOdooId(e['id']);
        Map<String, dynamic> res = {
          'id': planItem.id,
          'parent_id': plan.id,
        };
        return await DBProvider.db.update(_tableName, res);
      } else {
        Map<String, dynamic> res = {
          ...e,
          'id': null,
          'odoo_id': e['id'],
          'active': 'true',
        };
        return await insert(PlanItem.fromJson(res), true);
      }
    });
    print('first load plan_item $loadRelated finish');
    return result;
  }

  static loadChangesFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['parent_id'];
    else
      fields = [
        'name',
        'department_txt',
        'check_type',
        'period',
        'responsible',
        'check_result',
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
      PlanItem planItem = await selectByOdooId(e['id']);
      if (loadRelated) {
        if (e['parent_id'] is bool && !e['parent_id']) return null;
        Plan plan = await PlanController.selectByOdooId(
            unpackListId(e['parent_id'])['id']);
        assert(plan != null, "Model plan has to be loaded before $_tableName");
        Map<String, dynamic> res = {
          'id': planItem.id,
          'parent_id': plan.id,
        };
        return DBProvider.db.update(_tableName, res);
      } else {
        if (planItem == null) {
          Map<String, dynamic> res = PlanItem.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = PlanItem.fromJson({
          ...e,
          'id': planItem.id,
          'odoo_id': planItem.odooId,
          'active': e['active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
  }

  static Future finishSync(dateTime) {
    return setLastSyncDateForDomain(_tableName, dateTime);
  }

  /// Select all records with matching parentId
  /// Returns found records or null.
  static Future<List<PlanItem>> select(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<PlanItem> planItems =
        queryRes.map((e) => PlanItem.fromJson(e)).toList();
    return planItems;
  }

  /// Try to insert into the table.
  /// ======
  /// Returns ```{
  ///   'code':[1|-1|-2|-3],
  ///   'message':[
  ///     null|
  ///     There is already a $_tableName record with year=${plan.year}, type=${plan.type}, railway=${plan.railwayId}|
  ///     Error updating syn|
  ///     Error inserting into $_tableName|
  ///   ]
  ///   'id':record_id
  /// }```
  static Future<Map<String, dynamic>> insert(PlanItem planItem,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> json = planItem.toJson(!saveOdooId);
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
    await DBProvider.db
        .insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  /// Try to update a record of the table.
  /// Returns ```{
  ///   'code':[1|-1|-2|-3],
  ///   'message':[
  ///     null|
  ///     There is already a $_tableName record with year=${plan.year}, type=${plan.type}, railway=${plan.railwayId}|
  ///     Error updating syn|
  ///     Error updating $_tableName|
  ///   ]
  ///   'id':null
  /// }```
  static Future<Map<String, dynamic>> update(PlanItem planItem) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(planItem.id);
    await DBProvider.db
        .update(_tableName, planItem.toJson())
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
