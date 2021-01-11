import 'package:ek_asu_opb_mobile/controllers/checkListItem.dart';
import 'package:ek_asu_opb_mobile/controllers/checkPlanItem.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkList.dart";
import 'package:ek_asu_opb_mobile/models/checkListItem.dart';
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class CheckListController extends Controllers {
  static const String _tableName = "check_list";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckList checkList = CheckList.fromJson(json);

    print("CheckList Insert() to DB");
    print(checkList);

    return await DBProvider.db.insert(_tableName, checkList.toJson());
  }

  static Future<Map<String, dynamic>> create(CheckList checkList,
      {bool saveOdooId = false, bool dontSync = false}) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Create() checkList");
    print(checkList);

    Map<String, dynamic> json = checkList.toJson(!saveOdooId);
    if (saveOdooId) json.remove("id");

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      if (!saveOdooId && !dontSync) {
        return SynController.create(_tableName, resId).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
      }
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create checkList into $_tableName';
    });

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<CheckList> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return CheckList.fromJson(json);
  }

  /// Select all CheckLists with matching parentId
  /// Returns found records or null.
  static Future<List<CheckList>> select(int parentId) async {
    print("CheckList Select() parent_id=$parentId");
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<CheckList> checkLists =
        queryRes.map((e) => CheckList.fromJson(e)).toList();
    return checkLists;
  }

  /// Select all CheckLists with is_base = true
  static Future<List<CheckList>> selectBase() async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "is_base = 'true'",
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<CheckList> checkLists =
        queryRes.map((e) => CheckList.fromJson(e)).toList();
    return checkLists;
  }

  /// Select all CheckLists with is_base = true
  static Future<List<CheckList>> selectNotBase(int parentId) async {
    if (parentId == null) return [];
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        where: "is_base != 'true' and parent_id = ?", whereArgs: [parentId]);
    if (queryRes == null || queryRes.length == 0) return [];
    List<CheckList> checkLists =
        queryRes.map((e) => CheckList.fromJson(e)).toList();
    return checkLists;
  }

  /// Select all CheckLists templates
  static Future<List<CheckList>> selectTemplates(int parentId) async {
    List hasResult = await selectBase();
    List<int> excludeResult =
        (await selectNotBase(parentId)).map((e) => e.base_id).toList();
    return List<CheckList>.from(
        hasResult.where((element) => !excludeResult.contains(element.id)));
  }

  static Future<List<CheckList>> selectByParentId(int parentId) async {
    if (parentId == null) return null;

    // [{id: 1}, {}...]
    // var ids = await DBProvider.db.executeQuery(
    //     "SELECT A.id from (SELECT id from check_list where is_base = 'true') as A LEFT JOIN (SELECT base_id from check_list where is_base = 'false' and parent_id =$parentId) as B ON A.id = B.base_id where B.base_id is NULL");

    List<CheckList> templates = await selectTemplates(parentId);
    // print(ids);
    var ids = templates.map((element) => {'id': element.id}).toList();

    print("Ids $ids");
    if (ids.length > 0) {
      for (var item in ids) {
        // item[id] is used for searching assigned questions for reinserting them as not base
        var checkList = await CheckListController.selectById(item["id"]);

        checkList.is_base = false;
        checkList.parent_id = parentId;
        checkList.base_id = item["id"];

        // New id for work check list
        var createResp =
            await CheckListController.create(checkList, dontSync: true);
        if (createResp["code"] > 0) {
          var checkListId = createResp["id"];
          var questions =
              await CheckListItemController.getCheckListItemsByParentId(
                  item["id"]);
          if (questions.length > 0) {
            for (var originalQuestion in questions) {
              CheckListItem copyItem = new CheckListItem();

              copyItem.odoo_id = null;
              copyItem.base_id = originalQuestion.id;
              copyItem.parent_id = checkListId;
              copyItem.name = originalQuestion.name;
              copyItem.question = originalQuestion.question;
              copyItem.result = originalQuestion.result;
              copyItem.description = originalQuestion.description;
              copyItem.active = true;

              await CheckListItemController.create(copyItem, dontSync: true);
            }
          }
        }
      }
      SynController.syncTask(noLoadFromOdoo: true);
    }

    var dataToFront = await CheckListController.select(parentId);

    return dataToFront;
  }

  // Update the whole object in db
  static Future<Map<String, dynamic>> update(CheckList checkList) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Update() CheckList!");
    print(checkList);
    Future<int> odooId = selectOdooId(checkList.id);
    var checkListJson = checkList.prepareForUpdate();
    checkListJson.remove('odoo_id');
    await DBProvider.db
        .update(_tableName, checkListJson)
        .then((rowsAffected) async {
      res['code'] = 1;
      res['id'] = checkList.id;

      return SynController.edit(_tableName, checkList.id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res["code"] = -3;
      res["message"] = "Error updating $_tableName";
    });

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  // Set for records of checkLists which comes in ids active = True; ids - [1, 3, 5]
  // By parent id (id of plan) we find all checklists, for id in ids we set active = True, for others active = False;
  static Future<Map<String, dynamic>> setIsActiveTrue(
      List<int> ids, int parentId) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    if (ids.length == 0) {
      return {
        "code": -1,
        "message": "Не заданы id для обновления статуса!",
        "id": null
      };
    }

    var allCheckLists = await CheckListController.select(parentId);

    if (allCheckLists.length == 0) {
      res["code"] = -1;
      res["message"] = "Не были найдены записи!";
      res["id"] = null;

      return res;
    }

    try {
      var skipIdList = [];
      for (var id in ids) {
        for (var cList in allCheckLists) {
          var json = cList.toJson();
          var recordId = json["id"];
          Future<int> odooId = selectOdooId(recordId);
          if (skipIdList.contains(json["id"])) {
            continue;
          } else {
            if (id == json["id"]) {
              await DBProvider.db.executeQuery(
                  "UPDATE $_tableName SET is_active='true' WHERE id=$recordId");
              // Update is_active in Odoo
            } else {
              await DBProvider.db.executeQuery(
                  "UPDATE $_tableName SET is_active='false' WHERE id=$recordId");
              // Update is_active in Odoo
            }
            await SynController.edit(_tableName, recordId, await odooId)
                .catchError((err) {
              res['code'] = -2;
              res['message'] = 'Error updating syn';
            });
          }
        }
        skipIdList.add(id);
      }

      res['code'] = 1;
      res['message'] = 'Успешно изменен статус чек-листа!';

      print("RES Set is active! checkList $res");
    } catch (e) {
      print("setIsActiveTrue() Error: $e");
      res["code"] = -3;
      res["message"] = "Error updating table $_tableName, err: $e";
      res["id"] = null;
    }
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> delete(int checkListId) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Delete() CheckList");
    await DBProvider.db.update(
        _tableName, {'id': checkListId, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      res['id'] = value;
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });

    var assignedItems = await CheckListItemController.select(checkListId);
    if (assignedItems.length == 0) {
      print(
          "Delete CheckList(). Not found assigned checkListItems! ID: $checkListId");
      // res = {
      //   'code': -1,
      //   'message': 'Не найдены связанные вопросы к чек листу id: $checkListId',
      //   'id': null,
      // };

      // return res;
    }
    try {
      print("Try to delete assigned checkListsItems");
      for (var q in assignedItems) {
        var json = q.toJson();
        var itemId = json["id"];
        await CheckListItemController.delete(itemId);
        res['code'] = 1;
        res['message'] = 'Связанный вопрос с чек-листом успешно удален!';
        // await DBProvider.db
        // .update('check_list_item', {'id': itemId, 'active': 'false'});
      }
    } catch (e) {
      print("Delete of assignedItems to CheckList ID: $checkListId. Error: $e");
      res = {
        'code': -3,
        'message': 'Error deleting from checkListItems',
        'id': null,
      };
    }

    // res = {
    //   'code': 1,
    //   'message': 'Успешно удалено',
    //   'id': 0,
    // };

    return res;
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static Future<CheckList> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return CheckList.fromJson(json[0]);
  }

  static Future<List<int>> loadFromOdoo(
      {bool clean: false, List<int> parentIds = const []}) async {
    const List<String> fields = [
      'is_base',
      'base_id',
      'name',
      'is_active',
      'type',
      'active',
      'parent_id',
      'write_date',
    ];
    List domain = [];
    if (clean) {
      domain += [
        ['parent_id', 'in', parentIds]
      ];
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
      int checkListId = (await selectByOdooId(e['id']))?.id;
      int parentId = (await CheckPlanItemController.selectByOdooId(
              unpackListId(e['parent_id'])['id']))
          ?.id;
      Map<String, dynamic> res = {
        ...e,
        'odoo_id': e['id'],
        'parent_id': parentId,
        'active': e['active'] ? 'true' : 'false',
      };
      if (checkListId != null) {
        res['id'] = checkListId;
        await DBProvider.db
            .update(_tableName, CheckList.fromJson(res).toJson());
      } else {
        res['odoo_id'] = e['id'];
        await DBProvider.db
            .insert(_tableName, CheckList.fromJson(res).toJson());
      }
    });
    print('loaded ${json.length} records of $_tableName');
    await setLatestWriteDate(_tableName, json);
    return json.map((e) => e['id'] as int).toList();
  }

  static firstLoadFromOdoo([bool loadRelated = false]) async {
    List<String> fields;
    List<List> domain = [];
    if (loadRelated) {
      fields = ['write_date', 'parent_id'];
    } else {
      await DBProvider.db
          .executeQuery("DELETE FROM $_tableName WHERE is_base = 'false'");
      fields = [
        'is_base',
        'base_id',
        'name',
        'is_active',
        'type',
        'active',
      ];
    }

    // Get only work check list not templates!
    domain.add(['is_base', '=', false]);

    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'context': {'create_or_update': true}
    });

    await Future.forEach(json, (e) async {
      // base_id from odoo is like [3, _unknown, 3]
      if (e['base_id'] is List) {
        e['base_id'] = e['base_id'][0];
      }

      if (loadRelated) {
        CheckList checkList = await selectByOdooId(e['id']);
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckPlanItem checkPlanItem =
              await CheckPlanItemController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          if (checkPlanItem == null) return null;
          res['id'] = checkList.id;
          res['parent_id'] = checkPlanItem.id;
        }

        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        Map<String, dynamic> res = {
          ...e,
          'id': null,
          'odoo_id': e['id'],
          'active': 'true',
        };
        CheckList json = CheckList.fromJson(res);
        return CheckListController.create(json, saveOdooId: true);
      }
    });
    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');

    if (loadRelated) await setLatestWriteDate(_tableName, json);
  }

  static loadChangesFromOdoo([bool loadRelated = false]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['write_date', 'parent_id'];
    else
      fields = [
        'is_base',
        'base_id',
        'name',
        'is_active',
        'type',
        'active',
      ];

    List domain = await getLastSyncDateDomain(_tableName);

    // Get only work check list not templates!
    domain.add(['is_base', '=', false]);
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'context': {'create_or_update': true}
    });

    print("CheckList. Load changes from odoo! $json");

    await Future.forEach(json, (e) async {
      if (e['base_id'] is List) {
        e['base_id'] = e['base_id'][0];
      }
      CheckList checkList = await selectByOdooId(e['id']);
      if (loadRelated) {
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckPlanItem checkPlanItem =
              await CheckPlanItemController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          if (checkPlanItem == null) return null;
          res['id'] = checkList.id;
          res['parent_id'] = checkPlanItem.id;
        }
        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        if (checkList == null) {
          Map<String, dynamic> res = CheckList.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
            'is_active': e['is_active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = CheckList.fromJson({
          ...e,
          'id': checkList.id,
          'odoo_id': checkList.odoo_id,
          'active': e['active'] ? 'true' : 'false',
          'is_active': e['is_active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');

    if (loadRelated) await setLatestWriteDate(_tableName, json);
  }
}
