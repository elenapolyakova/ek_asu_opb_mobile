import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkListItem.dart";

class CheckListItemController extends Controllers {
  static String _tableName = "check_list_item";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListItem checkListItem = CheckListItem.fromJson(json);
    print("Check list item from json $checkListItem");
    print("Check list item toJson()");
    print(checkListItem.toJson());
    return await DBProvider.db.insert(_tableName, checkListItem.toJson());
  }
}
