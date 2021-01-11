import 'dart:io';

import 'package:ek_asu_opb_mobile/controllers/comGroup.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/controllers/report.dart';
import 'package:ek_asu_opb_mobile/models/checkPlan.dart';
import 'package:ek_asu_opb_mobile/models/comGroup.dart';
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckPlanController extends Controllers {
  static const String _tableName = "plan_item_check";
  static const String xlsReportXmlId = 'report_mob_check_plan_xls';
  static const String pdfReportXmlId = 'report_mob_check_plan_pdf';

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
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

  static Future<CheckPlan> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return CheckPlan.fromJson(json[0]);
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static Future<List<int>> loadFromOdoo(
      {bool clean: false, List<int> parentIds}) async {
    const List<String> fields = [
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
      'parent_id',
      'main_com_group_id',
      'write_date',
    ];
    List domain = [];
    if (parentIds != null)
      domain += [
        ['parent_id', 'in', parentIds]
      ];
    if (clean) {
      await DBProvider.db.deleteAll(_tableName);
    } else {
      domain += await getLastSyncDateDomain(_tableName);
    }
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName],
        'search_read',
        [domain, fields],
        {});
    await Future.forEach(json, (e) async {
      int checkPlanId = (await selectByOdooId(e['id']))?.id;
      int parentId = (await PlanItemController.selectByOdooId(
              unpackListId(e['parent_id'])['id']))
          ?.id;
      Map<String, dynamic> res = {
        ...e,
        'odoo_id': e['id'],
        'parent_id': parentId,
        'active': e['active'] ? 'true' : 'false',
      };
      if (checkPlanId != null) {
        res['id'] = checkPlanId;
        await DBProvider.db
            .update(_tableName, CheckPlan.fromJson(res).toJson());
      } else {
        res['odoo_id'] = e['id'];
        await DBProvider.db
            .insert(_tableName, CheckPlan.fromJson(res).toJson());
      }
    });
    print('loaded ${json.length} records of $_tableName');
    await setLatestWriteDate(_tableName, json);
    return json.map((e) => e['id'] as int).toList();
  }

  static Future<List<int>> firstLoadFromOdoo(
      {bool loadRelated = false, List<int> parentIds = const []}) async {
    List<String> fields;
    List<List> domain = [];
    if (loadRelated) {
      domain += [
        ['id', 'in', parentIds]
      ];
      fields = ['write_date', 'parent_id', 'main_com_group_id'];
    } else {
      domain += [
        ['parent_id', 'in', parentIds]
      ];
      await DBProvider.db.deleteAll(_tableName);
      fields = [
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
      ];
    }
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'context': {'create_or_update': true}
    });
    await Future.forEach(json, (e) async {
      if (loadRelated) {
        Map<String, dynamic> res = {};
        CheckPlan checkPlan = await selectByOdooId(e['id']);
        if (checkPlan == null) return null;
        if (e['parent_id'] is List) {
          PlanItem planItem = await PlanItemController.selectByOdooId(
              unpackListId(e['parent_id'])['id']);
          if (planItem == null) return null;
          res['id'] = checkPlan.id;
          res['parent_id'] = planItem.id;
        }
        if (e['main_com_group_id'] is List) {
          ComGroup comGroup = await ComGroupController.selectByOdooId(
              unpackListId(e['main_com_group_id'])['id']);
          if (comGroup == null) return null;
          res['id'] = checkPlan.id;
          res['main_com_group_id'] = comGroup.id;
        }
        if (res['id'] != null)
          return await DBProvider.db.update(_tableName, res);
        return null;
      } else {
        Map<String, dynamic> res = {
          ...e,
          'id': null,
          'odoo_id': e['id'],
          'active': 'true',
        };
        return insert(CheckPlan.fromJson(res), true);
      }
    });
    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');
    if (loadRelated) await setLatestWriteDate(_tableName, json);
    return json.map((e) => e['id'] as int).toList();
  }

  static Future<List<int>> loadChangesFromOdoo(
      [bool loadRelated = false]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['write_date', 'parent_id', 'main_com_group_id'];
    else
      fields = [
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
        'active',
      ];
    List domain = await getLastSyncDateDomain(_tableName);
    List<dynamic> json = await getDataWithAttemp(
      SynController.localRemoteTableNameMap[_tableName],
      'search_read',
      [domain, fields],
      {
        'context': {'create_or_update': true}
      },
    );
    await Future.forEach(json, (e) async {
      CheckPlan checkPlan = await selectByOdooId(e['id']);
      if (loadRelated) {
        Map<String, dynamic> res = {};
        if (checkPlan == null) return null;
        if (e['parent_id'] is List) {
          PlanItem planItem = await PlanItemController.selectByOdooId(
              unpackListId(e['parent_id'])['id']);
          if (planItem == null) return null;
          // assert(planItem != null,
          //     "Model plan_item has to be loaded before $_tableName");
          res['id'] = checkPlan.id;
          res['parent_id'] = planItem.id;
        }
        if (e['main_com_group_id'] is List) {
          ComGroup comGroup = await ComGroupController.selectByOdooId(
              unpackListId(e['main_com_group_id'])['id']);
          if (comGroup == null) return null;
          // assert(comGroup != null,
          //     "Model com_group has to be loaded before $_tableName");
          res['id'] = checkPlan.id;
          res['main_com_group_id'] = comGroup.id;
        }
        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        if (checkPlan == null) {
          Map<String, dynamic> res = CheckPlan.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = CheckPlan.fromJson({
          ...e,
          'id': checkPlan.id,
          'odoo_id': checkPlan.odooId,
          'active': e['active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');
    if (loadRelated) await setLatestWriteDate(_tableName, json);
    return json.map((e) => e['id'] as int).toList();
  }

  /// Select a list of CheckPlan with provided parentId
  /// Returns selected record or null.
  static Future<List<CheckPlan>> select(int parentId) async {
    if (parentId == null) return [];
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
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
    var checkPlanJson = checkPlan.toJson();
    checkPlanJson.remove('odoo_id');
    await DBProvider.db
        .update(_tableName, checkPlanJson)
        .then((rowsAffected) async {
      res['code'] = 1;
      res['id'] = checkPlan.id;
      return SynController.edit(_tableName, checkPlan.id, await odooId)
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

  static Future<File> downloadPdfReport(int odooId) async {
    return ReportController.downloadReport(
        SynController.localRemoteTableNameMap[_tableName],
        odooId,
        pdfReportXmlId);
  }

  static Future<File> downloadXlsReport(int odooId) async {
    return ReportController.downloadReport(
        SynController.localRemoteTableNameMap[_tableName],
        odooId,
        xlsReportXmlId);
  }
}
