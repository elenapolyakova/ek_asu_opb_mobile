import 'package:ek_asu_opb_mobile/controllers/checkListItem.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkList.dart";
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
            qJson.remove("id");
            qJson["odooId"] = null;
            qJson["base_id"] = qJson["id"];
            qJson["parent_id"] = workCheckLstId;

            var checkListItemId = await CheckListItemController.insert(qJson);
          }
        }
      }
    }

    var dataToFront = await CheckListController.select(parentId);

    return dataToFront;
  }
}
