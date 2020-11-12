import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class UserInfoController extends Controllers {
  static String _tableName = "userInfo";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    UserInfo user = UserInfo.fromJson(json);
    return await DBProvider.db.insert(_tableName, user.toJson());
  }

  static Future<void> deleteAll() async {
    return await DBProvider.db.deleteAll(_tableName);
  }

  static Future<UserInfo> selectUserInfo() async {
    List<Map<String, dynamic>> userInfoFromDb =
        await DBProvider.db.selectAll(_tableName);
    if (userInfoFromDb == null || userInfoFromDb.length == 0) return null;
    return UserInfo.fromJson(userInfoFromDb[0]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
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
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    json.forEach((e) => insert(e));
  }
}
