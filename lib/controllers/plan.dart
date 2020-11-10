import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class PlanController extends Controllers {
  static String _tableName = "plan";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return null;
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<Plan> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return Plan.fromJson(json);
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
        'type',
        'name',
        'railway_id',
        'year',
        'date_set',
        'signer_name',
        'signer_post',
        'num_set',
        'state',
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
              'active': 'true',
            })
        .forEach((e) => insert(Plan.fromJson(e), true));
  }

  /// Select the first record matching passed year, type and railwayId.
  /// Returns selected record or null.
  static Future<Plan> select(int year, String type, int railwayId) async {
    Map<String, dynamic> where = Controllers.getNullSafeWhere(
        {'year': year, 'type': type, 'railway_id': railwayId});
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: where['where'] + " and active = 'true'",
      whereArgs: where['whereArgs'],
    );
    Plan plan;
    if (queryRes.length == 1)
      plan = Plan.fromJson(queryRes[0]);
    else if (queryRes.length > 1) {
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message':
            "There is more than one record of $_tableName with year=$year, type=$type and railway_id=$railwayId"
      });
      plan = Plan.fromJson(queryRes[0]);
    } else
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message':
            "There is no records of $_tableName with year=$year, type=$type and railway_id=$railwayId"
      });
    return plan;
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
  static Future<Map<String, dynamic>> insert(Plan plan,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> where = Controllers.getNullSafeWhere(
        {'year': plan.year, 'type': plan.type, 'railway_id': plan.railwayId});
    List uniqueChecked = await DBProvider.db.select(
      _tableName,
      columns: ['id'],
      where: where['where'] + " and active = 'true'",
      whereArgs: where['whereArgs'],
    );
    if (uniqueChecked.length > 0) {
      res['code'] = -1;
      res['message'] =
          'There is already a $_tableName record with year=${plan.year}, type=${plan.type}, railway=${plan.railwayId}';
      DBProvider.db
          .insert('log', {'date': nowStr(), 'message': res.toString()});
      return res;
    }
    Map<String, dynamic> json = plan.toJson(!saveOdooId);
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
  static Future<Map<String, dynamic>> update(Plan plan) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(plan.id);
    Map<String, dynamic> where = Controllers.getNullSafeWhere(
        {'year': plan.year, 'type': plan.type, 'railway_id': plan.railwayId});
    List uniqueChecked = await DBProvider.db.select(
      _tableName,
      columns: ['id'],
      where: where['where'] + " and id != ? and active = 'true'",
      whereArgs: where['whereArgs'] + [plan.id],
    );
    if (uniqueChecked.length > 0) {
      res['code'] = -1;
      res['message'] =
          'There is already a $_tableName record with year=${plan.year}, type=${plan.type}, railway=${plan.railwayId}';
      DBProvider.db
          .insert('log', {'date': nowStr(), 'message': res.toString()});
      return res;
    }
    await DBProvider.db.update(_tableName, plan.toJson()).then((resId) async {
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
