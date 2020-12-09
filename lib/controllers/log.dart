import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class LogController extends Controllers {
  static const String _tableName = "log";
  static Future<dynamic> insert(String message) async {
    DBProvider.db.insert(_tableName, {'date': nowStr(), 'message': message});
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<void> deleteAll() async {
    return await DBProvider.db.deleteAll(_tableName);
  }
}
