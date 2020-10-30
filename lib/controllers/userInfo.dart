import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart" as model;

class UserInfo extends Controllers {
static String _tableName = "userInfo";
  static Future<dynamic> insert(
      Map<String, dynamic> json) async {
    model.UserInfo user = model.UserInfo.fromJson(json);
    return await DBProvider.db.insert(_tableName, user.toJson());
  }

  static Future<void> deleteAll() async {
    return await DBProvider.db.deleteAll(_tableName);
  }

  static Future<model.UserInfo> selectUserInfo() async {

     List<Map<String, dynamic>> userInfoFromDb = await DBProvider.db.selectAll(_tableName);
  if (userInfoFromDb == null || userInfoFromDb.length == 0) return null;
  return model.UserInfo.fromJson(userInfoFromDb[0]);
  }

   static Future<List<Map<String, dynamic>>> selectAll() async  {
     return await DBProvider.db.selectAll(_tableName);
  }
}
