import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckPlanController extends Controllers {
  static String _tableName = "plan_item_check";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return null;
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<CheckPlan> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return CheckPlan.fromJson(json);
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static loadFromOdoo([limit]) async {
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      [],
      [
        'parent_id',
        'name',
        'rw_id',
        'date_from',
        'date_to',
        'date_set',
        'state',
        'signer_name',
        'signer_post',
        'app_name',
        'app_post',
        'num_set',
        'main_com_group_id',
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    json
        .map((e) => {
              ...e,
              'id': null,
              'odoo_id': e['id'],
              'active': true,
            })
        .forEach((e) => insert(CheckPlan.fromJson(e), true));
  }

  /// Select a list of CheckPlan with provided parentId
  /// Returns selected record or null.
  static Future<List<CheckPlan>> select(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return null;
    List<CheckPlan> planItemCheckPlans;
    planItemCheckPlans = queryRes.map((e) => CheckPlan.fromJson(e)).toList();
    return planItemCheckPlans;
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
  static Future<Map<String, dynamic>> insert(CheckPlan checkPlan,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> json = checkPlan.toJson(!saveOdooId);
    if (saveOdooId) json.remove('id');
    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
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
  ///     There is already a $_tableName record with year=${plan.year}, type=${plan.type}, railway=${plan.railwayId}|
  ///     Error updating syn|
  ///     Error updating $_tableName|
  ///   ]
  ///   'id':null
  /// }```
  static Future<Map<String, dynamic>> update(CheckPlan checkPlan) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(checkPlan.id);
    await DBProvider.db
        .update(_tableName, checkPlan.toJson())
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
