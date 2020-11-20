import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkList.dart";
import 'package:ek_asu_opb_mobile/utils/network.dart';

class CheckListController extends Controllers {
  static String _tableName = "check_list";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListWork checkList = CheckListWork.fromJson(json);
    print("Data 1 check list $checkList");
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

  static Future<List<Map<String, dynamic>>> selectByParentId(
      int parentId) async {
    if (parentId == null) return null;

    // [{id: 1}, {}...]
    var ids = await DBProvider.db.executeQuery(
        "SELECT A.id from (SELECT id from check_list where is_base = 'true') as A LEFT JOIN (SELECT base_id from check_list where is_base = 'false' and parent_id =$parentId) as B ON A.id = B.base_id where B.base_id is NULL");

    if (ids.length > 0) {
      for (var item in ids) {
        // item[id] is used for searching assigned questions for reinserting them as not base
        var response = await CheckListController.selectById(item["id"]);
        var checkList = response.toJson();
        print(response);

        checkList.remove("id");

        checkList["odooId"] = null;
        checkList["is_base"] = false;
        checkList["parent_id"] = parentId;
        checkList["base_id"] = item["id"];
        checkList["child_ids"] = "";
        print("after processing $checkList");

        var workCheckLstId = await CheckListController.insert(checkList);

        break;
      }
    }
  }
}
