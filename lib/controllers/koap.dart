import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/koap.dart';

class KoapController extends Controllers {
  static const String _tableName = "koap";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Koap koap = Koap.fromJson(json);
    return await DBProvider.db.insert(_tableName, koap.toJson());
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<Koap> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return Koap.fromJson(json);
  }

  static Future<List<Koap>> select(String template) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "search_field like ?",
      whereArgs: ['%$template%'],
    );
    if (queryRes.isEmpty) return [];
    List<Koap> result = List.generate(
        queryRes.length, (index) => Koap.fromJson(queryRes[index]));

    return result;
  }
}
