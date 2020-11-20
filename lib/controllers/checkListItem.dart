import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkListItem.dart";

class CheckListItemController extends Controllers {
  static String _tableName = "check_list_item";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListItem checkListItem = CheckListItem.fromJson(json);
    print("CheckListItem Insert() to db");
    print(checkListItem.toJson());

    return await DBProvider.db.insert(_tableName, checkListItem.toJson());
  }

  static Future<List<CheckListItem>> getQuestionsByParentId(
      int parent_id) async {
    var result = await DBProvider.db.executeQuery(
        "SELECT * from check_list_item WHERE parent_id=$parent_id");
    List<CheckListItem> response = [];

    for (var item in result) {
      var newItem = CheckListItem.fromJson(item);
      response.add(newItem);
    }
    print("getQuestionsByParentId() response $response");
    return response;
  }
}
