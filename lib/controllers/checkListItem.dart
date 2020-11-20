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

  static Future<List<CheckListItem>> getCheckListItemsByParentId(
      int parent_id) async {
    if (parent_id == null) return [];

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

  /// Select all CheckListItems with matching parentId (Parent id stays for check_list)
  /// Returns found records or null.
  static Future<List<CheckListItem>> select(int parentId) async {
    if (parentId == null) return [];

    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<CheckListItem> checkListItems =
        queryRes.map((e) => CheckListItem.fromJson(e)).toList();
    return checkListItems;
  }
}
