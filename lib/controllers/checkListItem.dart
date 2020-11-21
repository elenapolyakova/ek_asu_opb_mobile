import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkListItem.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckListItemController extends Controllers {
  static String _tableName = "check_list_item";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListItem checkListItem = CheckListItem.fromJson(json);
    print("CheckListItem Insert() to db");
    print(checkListItem.toJson());

    return await DBProvider.db.insert(_tableName, checkListItem.toJson());
  }

  // Used for creation work copy of CheckList templates and its assigned Questions
  static Future<List<CheckListItem>> getCheckListItemsByParentId(
      int parent_id) async {
    if (parent_id == null) return [];

    var result = await DBProvider.db.executeQuery(
        "SELECT * from check_list_item WHERE parent_id=$parent_id and active='true'");
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

  // Update the whole object in db
  static Future<Map<String, dynamic>> update(
      CheckListItem checkListItem) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Update() CheckListItem");
    await DBProvider.db
        .update(_tableName, checkListItem.prepareForUpdate())
        .then((resId) async {
      print("RES ID $resId");
      res['code'] = 1;
      res['id'] = resId;
    }).catchError((err) {
      res["code"] = -3;
      res["message"] = "Error updating $_tableName";
    });

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    print("Delete() CheckListItem");
    await DBProvider.db
        .update(_tableName, {'id': id, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      res["id"] = value;
      print("Delete value $value");
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });
    return res;
  }
}
