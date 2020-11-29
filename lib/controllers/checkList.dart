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
  static String _tableName = "check_list";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListWork checkList = CheckListWork.fromJson(json);

    print("CheckList Insert() to DB");
    print(checkList);

    return await DBProvider.db.insert(_tableName, checkList.toJson());
  }

  static Future<Map<String, dynamic>> create(CheckListWork checkList,
      [bool saveOdooId = false]) async {
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
      if (!saveOdooId) {
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

  static Future<CheckListWork> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return CheckListWork.fromJson(json);
  }

  /// Select all CheckLists with matching parentId
  /// Returns found records or null.
  static Future<List<CheckListWork>> select(int parentId) async {
    print("CheckList Select() parent_id=$parentId");
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<CheckListWork> checkLists =
        queryRes.map((e) => CheckListWork.fromJson(e)).toList();
    return checkLists;
  }

  static Future<List<CheckListWork>> selectByParentId(int parentId) async {
    if (parentId == null) return null;

    // [{id: 1}, {}...]
    var ids = await DBProvider.db.executeQuery(
        "SELECT A.id from (SELECT id from check_list where is_base = 'true') as A LEFT JOIN (SELECT base_id from check_list where is_base = 'false' and parent_id =$parentId) as B ON A.id = B.base_id where B.base_id is NULL");

    print("Ids $ids");
    if (ids.length > 0) {
      for (var item in ids) {
        // item[id] is used for searching assigned questions for reinserting them as not base
        var checkList = await CheckListController.selectById(item["id"]);
        // var checkList = response.toJson();

        // checkList.remove("id");
        // checkList["odooId"] = null;
        checkList.is_base = false;
        checkList.parent_id = parentId;
        checkList.base_id = item["id"];

        // New id for work check list
        var createResp = await CheckListController.create(checkList);
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

              await CheckListItemController.create(copyItem);
            }
          }
        }
      }
    }

    var dataToFront = await CheckListController.select(parentId);

    return dataToFront;
  }

  // Update the whole object in db
  static Future<Map<String, dynamic>> update(CheckListWork checkList) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Update() CheckList!");
    print(checkList);
    Future<int> odooId = selectOdooId(checkList.id);
    await DBProvider.db
        .update(_tableName, checkList.prepareForUpdate())
        .then((resId) async {
      res['code'] = 1;
      res['id'] = resId;

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

      return {
        "code": 1,
        "message": "Successfully updates",
        "id": 0,
      };
    } catch (e) {
      print("setIsActiveTrue() Error: $e");
      res["code"] = -3;
      res["message"] = "Error updating table $_tableName, err: $e";
      res["id"] = null;

      DBProvider.db
          .insert('log', {'date': nowStr(), 'message': res.toString()});

      return res;
    }
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
      res = {
        'code': -1,
        'message': 'Не найдены связанные вопросы к чек листу id: $checkListId',
        'id': null,
      };

      return res;
    }
    try {
      print("Try to delete assigned checkListsItems");
      for (var q in assignedItems) {
        var json = q.toJson();
        var itemId = json["id"];
        await DBProvider.db
            .update('check_list_item', {'id': itemId, 'active': 'false'});
      }
    } catch (e) {
      print("Delete of assignedItems to CheckList ID: $checkListId. Error: $e");
      res = {
        'code': -3,
        'message': 'Error deleting from checkListItems',
        'id': null,
      };
      return res;
    }

    res = {
      'code': 1,
      'message': 'Успешно удалено',
      'id': 0,
    };

    return res;
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static Future<CheckListWork> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return CheckListWork.fromJson(json[0]);
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
    } else
      fields = [
        'is_base',
        'base_id',
        'name',
        'is_active',
        'type',
        'active',
      ];

    // Get only work check list not templates!
    domain.add(['is_base', '=', false]);

    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });

    print("First load json $json");
    // We don't need to delete templates !!!!
    if (!loadRelated)
      await DBProvider.db
          .executeQuery("DELETE FROM $_tableName WHERE is_base = 'false'");

    return Future.forEach(json, (e) async {
      // base_id from odoo is like [3, _unknown, 3]
      if (e['base_id'] is List) {
        e['base_id'] = e['base_id'][0];
      }

      if (loadRelated) {
        CheckListWork checkList = await selectByOdooId(e['id']);
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckPlanItem checkPlanItem =
              await CheckPlanItemController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          assert(checkPlanItem != null,
              "Model plan_item has to be loaded before $_tableName");
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

        print("firstLoadFromOdoo() CheckListTo insert! $res");
        CheckListWork json = CheckListWork.fromJson(res);
        return CheckListController.create(json, true);
      }
    });
  }

  static loadChangesFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['parent_id'];
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
    print("domain $domain");

    // Get only work check list not templates!
    domain.add(['is_base', '=', false]);
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });

    print("Load changes from odoo! $json");

    return Future.forEach(json, (e) async {
      if (e['base_id'] is List) {
        e['base_id'] = e['base_id'][0];
      }
      CheckListWork checkList = await selectByOdooId(e['id']);
      if (loadRelated) {
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckPlanItem checkPlanItem =
              await CheckPlanItemController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          assert(checkPlanItem != null,
              "Model checkPlanItem has to be loaded before $_tableName");
          res['id'] = checkList.id;
          res['parent_id'] = checkPlanItem.id;
        }
        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        if (checkList == null) {
          Map<String, dynamic> res = CheckListWork.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
            'is_active': e['is_active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = CheckListWork.fromJson({
          ...e,
          'id': checkList.id,
          'odoo_id': checkList.odoo_id,
          'active': e['active'] ? 'true' : 'false',
          'is_active': e['is_active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
  }

  static Future finishSync(dateTime) {
    return setLastSyncDateForDomain(_tableName, dateTime);
  }
}
