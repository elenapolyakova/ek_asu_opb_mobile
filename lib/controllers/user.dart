import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart" as model;

class User extends Controllers {

      static String _tableName = "user";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    model.User user = model.User.fromJson(json);
    return await DBProvider.db.insert(_tableName, user.toJson());
  }

  static Future<void> deleteAll() async {
    return await DBProvider.db.deleteAll(_tableName);
  }

   static Future<List<Map<String, dynamic>>> selectAll() async  {
     return await DBProvider.db.selectAll(_tableName);
  }
}
