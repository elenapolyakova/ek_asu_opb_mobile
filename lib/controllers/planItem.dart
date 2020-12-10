import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'package:ek_asu_opb_mobile/models/planItem.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class PlanItemController extends Controllers {
  static const String _tableName = "plan_item";

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

  static Future loadFromOdoo({bool clean: false, int limit, int offset}) async {
    List<String> fields = [
      'name',
      'department_txt',
      'check_type',
      'period',
      'responsible',
      'check_result',
      'parent_id',
      'active',
      'write_date',
    ];
    List domain;
    if (clean) {
      domain = [];
      await DBProvider.db.deleteAll(_tableName);
    } else {
      domain = await getLastSyncDateDomain(_tableName, excludeActive: true);
    }
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });
    await Future.forEach(json, (e) async {
      int planItemId = (await selectByOdooId(e['id']))?.id;
      int parentId = (await PlanController.selectByOdooId(
              unpackListId(e['parent_id'])['id']))
          ?.id;
      Map<String, dynamic> res = {
        ...e,
        'odoo_id': e['id'],
        'parent_id': parentId,
        'active': e['active'] ? 'true' : 'false',
      };
      if (planItemId != null) {
        res['id'] = planItemId;
        await DBProvider.db.update(_tableName, PlanItem.fromJson(res).toJson());
      } else {
        res['odoo_id'] = e['id'];
        await DBProvider.db.insert(_tableName, PlanItem.fromJson(res).toJson());
      }
    });
    print('loaded ${json.length} records of $_tableName');
    await setLatestWriteDate(_tableName, json);
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
        .then((rowsAffected) async {
      res['code'] = 1;
      res['id'] = rowsAffected;
      return SynController.edit(_tableName, planItem.id, await odooId)
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
