import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart" as model;

class Railway extends Controllers {
  static String _tableName = "railway";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    model.Railway railway = model.Railway.fromJson(json);
    return await DBProvider.db.insert(_tableName, railway.toJson());
  }
  static Future<List<Map<String, dynamic>>> selectAll() async  {
     return await DBProvider.db.selectAll(_tableName);
  }
}
