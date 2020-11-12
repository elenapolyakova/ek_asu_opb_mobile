import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'package:ek_asu_opb_mobile/models/comGroup.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class ComGroupController extends Controllers {
  static String _tableName = "com_group";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return null;
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<ComGroup> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return ComGroup.fromJson(json);
  }

  static Future<List<ComGroup>> selectByIds(List<int> ids) async {
    if (ids == null || ids.length == 0) return null;
    var json = await DBProvider.db.select(
      _tableName,
      where: "id in ?",
      whereArgs: [ids],
    );
    return json.map((e) => ComGroup.fromJson(e));
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
        'head_id',
        'group_num',
        'is_main',
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    json.map((e) {
      return PlanController.selectById(e['parent_id']).then((Plan plan) {
        var res = {
          ...e,
          'id': null,
          'odoo_id': e['id'],
          'parent_id': plan.id,
          'active': 'true',
        };
        return res;
      });
    }).forEach((e) async => insert(ComGroup.fromJson(await e), true));
  }

  /// Select all records with matching parentId
  /// Returns found records or null.
  static Future<List<ComGroup>> select(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return null;
    List<ComGroup> planItems =
        queryRes.map((e) => ComGroup.fromJson(e)).toList();
    return planItems;
  }

  /// Select all records with matching parentId and isMain = false
  /// Returns found records or null.
  static Future<List<ComGroup>> selectWorkGroups(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and is_main = 'false' and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return null;
    List<ComGroup> planItems =
        queryRes.map((e) => ComGroup.fromJson(e)).toList();
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
  static Future<Map<String, dynamic>> insert(ComGroup comGroup,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> json = comGroup.toJson(!saveOdooId);
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
  static Future<Map<String, dynamic>> update(ComGroup comGroup) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(comGroup.id);
    await DBProvider.db
        .update(_tableName, comGroup.toJson())
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
