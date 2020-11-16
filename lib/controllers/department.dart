import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class DepartmentController extends Controllers {
  static String _tableName = "department";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Department department = Department.fromJson(json);
    print('Departments json');
    print(department); //нужно, чтобы преобразовать одоо rel в id
    return await DBProvider.db.insert(_tableName, department.toJson());
  }

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<Department> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return Department.fromJson(json);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<List<Department>> select(String template, int railwayId) async {
    Map<String, dynamic> where =
        Controllers.getNullSafeWhere({'railway_id': railwayId});
    // String railwayWhere =
    //     railwayId != null ? 'railway_id = ?' : 'railway_id IS NULL';
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: where['where'] + " and search_field like ?",
      whereArgs: where['whereArgs'] + ['%$template%'],
      //where: 'search_field like ? and $railwayWhere',
      //whereArgs: ['%$template%', railwayId],
    );
    if (queryRes.isEmpty) return [];
    List<Department> result = List.generate(
        queryRes.length, (index) => Department.fromJson(queryRes[index]));

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
        'inn',
        'ogrn',
        'okpo',
        'addr',
        'director_fio',
        'director_email',
        'director_phone',
        'deputy_fio',
        'deputy_phone',
        'deputy_email',
        'active',
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    print("Load from odoo!");
    print(json);
    json.forEach((e) => print(e));
  }
}
