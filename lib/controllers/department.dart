import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart" as model;
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class Department extends Controllers {
  static String _tableName = "department";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    model.Department department = model.Department.fromJson(
        json); //нужно, чтобы преобразовать одоо rel в id
    return await DBProvider.db.insert(_tableName, department.toJson());
  }

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return null;
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static loadFromOdoo({limit = 0}) async {
    List<dynamic> json = await getDataWithAttemp(
        'eco.department',
        'search_read',
        [
          [],
          [
            'name',
            'short_name',
            'rel_railway_id',
            'active',
          ]
        ],
        limit ? {'limit': limit} : {});
    DBProvider.db.deleteAll(_tableName);
    json.forEach((e) => insert(e));
  }
}
