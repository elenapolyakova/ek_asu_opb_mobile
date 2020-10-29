import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart" as model;

class UserInfo extends Controllers {
  //tableName пока для таблиц user и userInfo одна модель и один контроллер,
  // нужно имя передавать в параметры
  static Future<dynamic> insert(
      String tableName, Map<String, dynamic> json) async {
    model.UserInfo user = model.UserInfo.fromJson(json);
    return await DBProvider.db.insert(tableName, user.toJson());
  }

  static Future<void> deleteAll(String tableName) async {
    return await DBProvider.db.deleteAll(tableName);
  }

  static Future<model.UserInfo> selectUserInfo() async {

     List<Map<String, dynamic>> userInfoFromDb = await DBProvider.db.selectAll('userInfo');
  if (userInfoFromDb == null || userInfoFromDb.length == 0) return null;
  return model.UserInfo.fromJson(userInfoFromDb[0]);
  }

   static Future<List<Map<String, dynamic>>> selectAll(String tableName) async  {
     return await DBProvider.db.selectAll(tableName);
  }
}
