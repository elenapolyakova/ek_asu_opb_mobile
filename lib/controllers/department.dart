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

  static Future<model.Department> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return model.Department.fromJson(json);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<List<model.Department>> select(String template, int railwayId) async {
    String railwayWhere =
        railwayId != null ? 'railway_id = ?' :'railway_id IS NULL';
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: 'search_field like ? and $railwayWhere',
      whereArgs: ['%${template}%', railwayId],
    );
    if (queryRes.isEmpty) return null;
    List<model.Department> result = List.generate(
        queryRes.length, (index) => model.Department.fromJson(queryRes[index]));

    return result;
  }

  static loadFromOdoo([limit]) async {
    List<dynamic> json =
        await getDataWithAttemp('eco.department', 'search_read', [
      [],
      [
        'name',
        'short_name',
        'rel_railway_id',
        'active',
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    json.forEach((e) => print(e));
  }
}
