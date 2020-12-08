import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class UserController extends Controllers {
  static String _tableName = "user";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    User user = User.fromJson(json);
    return await DBProvider.db.insert(_tableName, user.toJson());
  }

  static Future<void> deleteAll() async {
    return await DBProvider.db.deleteAll(_tableName);
  }

  static Future<List<User>> selectAll() async {
    List<Map<String, dynamic>> userList =
        await DBProvider.db.selectAll(_tableName);
    if (userList != null)
      return List.generate(
          userList.length, (index) => User.fromJson(userList[index]));
    return [];
  }

  static Future<List<User>> selectByRailway(int railwayId) async {

    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: railwayId != null ? 'railway_id = ? ' : null,
      whereArgs:  railwayId != null ? [railwayId] : null,
     
    );
    if (queryRes.isEmpty) return [];
    List<User> result = List.generate(
        queryRes.length, (index) => User.fromJson(queryRes[index]));

    return result;

  }

  static Future<User> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return User.fromJson(json);
  }

  static Future<List<User>> selectByIds(List<int> ids) async {
    if (ids == null || ids.length == 0) return [];
    List<Map<String, dynamic>> json = await DBProvider.db.select(
      _tableName,
      where: "id in (${ids.map((e) => "?").join(',')})",
      whereArgs: ids,
    );
    var res = json.map((e) => User.fromJson(e)).toList();
    return res;
  }

  static loadFromOdoo([int limit]) async {
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
