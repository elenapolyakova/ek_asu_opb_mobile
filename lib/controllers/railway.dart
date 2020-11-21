import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class RailwayController extends Controllers {
  static String _tableName = "railway";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Railway railway = Railway.fromJson(json);
    return await DBProvider.db.insert(_tableName, railway.toJson());
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<Railway> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return Railway.fromJson(json);
  }

  static loadFromOdoo([int limit]) async {
    List<dynamic> json = await getDataWithAttemp('eco.railway', 'search_read', [
      [],
      [
        'name',
        'short_name',
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    json.forEach((e) => insert(e));
  }
}
