import 'package:ek_asu_opb_mobile/controllers/checkListItem.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkList.dart";
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/utils/network.dart';

class CheckListController extends Controllers {
  static String _tableName = "check_list";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListWork checkList = CheckListWork.fromJson(json);

    print("CheckList Insert() to DB");
    print(checkList.toJson());

    return await DBProvider.db.insert(_tableName, checkList.toJson());
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

    if (ids.length > 0) {
      for (var item in ids) {
        // item[id] is used for searching assigned questions for reinserting them as not base
        var response = await CheckListController.selectById(item["id"]);
        var checkList = response.toJson();

        checkList.remove("id");

        checkList["odooId"] = null;
        checkList["is_base"] = false;
        checkList["parent_id"] = parentId;
        checkList["base_id"] = item["id"];
        checkList["child_ids"] = "";

        // New id for work check list
        var workCheckLstId = await CheckListController.insert(checkList);

        var questions =
            await CheckListItemController.getCheckListItemsByParentId(
                item["id"]);

        if (questions.length > 0) {
          for (var q in questions) {
            var qJson = q.toJson();

            Map<String, dynamic> copy = Map.from(qJson);

            copy.remove("id");
            copy["odooId"] = null;
            copy["base_id"] = qJson["id"];
            copy["parent_id"] = workCheckLstId;

            var checkListItemId = await CheckListItemController.insert(copy);
          }
        }
      }
    }

    var dataToFront = await CheckListController.select(parentId);

    return dataToFront;
  }

  static Future<Map<String, dynamic>> setIsActiveTrue(
      List ids, int parentId) async {
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
        print("Id $id");
        for (var cList in allCheckLists) {
          var json = cList.toJson();
          var recordId = json["id"];

          if (skipIdList.contains(json["id"])) {
            continue;
          } else {
            if (id == json["id"]) {
              await DBProvider.db.executeQuery(
                  "UPDATE $_tableName SET is_active='true' WHERE id=$recordId");
            } else {
              await DBProvider.db.executeQuery(
                  "UPDATE $_tableName SET is_active='false' WHERE id=$recordId");
            }
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

      return res;
    }
  }
}
