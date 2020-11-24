import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/faultItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class FaultItemController extends Controllers {
  static String _tableName = "fault_item";

  static Future<Map<String, dynamic>> create(FaultItem faultItem) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Create() FaultItem");
    print("Fault data $faultItem");

    Map<String, dynamic> json = faultItem.toJson();

    json.remove("id");
    // Warning only for local db!!!
    // When enable loading from odoo, delete this code
    json["odooId"] = null;

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create FaultItem into $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  // Select all fault items by parent_id(by fault Id)
  // Returns found records or null.
  static Future<List<FaultItem>> select(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );

    if (queryRes == null || queryRes.length == 0) return [];
    List<FaultItem> faultItems =
        queryRes.map((e) => FaultItem.fromJson(e)).toList();
    print("FaultItems Select()");
    print(faultItems);
    return faultItems;
  }

  static Future<FaultItem> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return FaultItem.fromJson(json);
  }

  static Future<Map<String, dynamic>> delete(int faultItemId) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Delete() FaultItem");
    await DBProvider.db.update(
        _tableName, {'id': faultItemId, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      res['id'] = value;
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });

    res = {
      'code': 1,
      'message': 'Успешно удалено',
      'id': 0,
    };

    return res;
  }
}
