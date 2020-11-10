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

  static Future<List<model.User>> selectAll() async {
    List<Map<String, dynamic>> userList =
        await DBProvider.db.selectAll(_tableName);
    if (userList != null)
      return List.generate(
          userList.length, (index) => model.User.fromJson(userList[index]));
  }

  static Future<model.User> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return model.User.fromJson(json);
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
