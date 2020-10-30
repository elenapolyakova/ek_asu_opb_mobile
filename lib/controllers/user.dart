import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart" as model;
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class User extends Controllers {
  static String _tableName = "user";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    model.User user = model.User.fromJson(json);
    return await DBProvider.db.insert(_tableName, user.toJson());
  }

  static Future<void> deleteAll() async {
    return await DBProvider.db.deleteAll(_tableName);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<String> getName(id) async {
    Map<String, String> res = await DBProvider.db.selectById(_tableName, id);
    if (res != null) return res['login'];
    return null;
  }

  static loadFromOdoo([limit]) async {
    List<dynamic> json = await getDataWithAttemp('res.users', 'search_read', [
      [],
      [
        'login',
        'f_user_role_txt',
        'display_name',
        'department_id',
        'railway_id',
        'email',
        'phone',
        'active',
        'function',
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    json.forEach((e) => insert(e));
  }
}
