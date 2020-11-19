import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkList.dart";

class CheckListController extends Controllers {
  static String _tableName = "check_list";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListWork checkList = CheckListWork.fromJson(json);
    print("Data 1 check list $checkList");
    print(checkList.toJson());

    return await DBProvider.db.insert(_tableName, checkList.toJson());
  }
}