import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/faultItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/controllers/syn.dart";

class FaultItemController extends Controllers {
  static String _tableName = "fault_item";

  static Future<Map<String, dynamic>> create(FaultItem faultItem,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Create() FaultItem");
    print("Fault data $faultItem");

    Map<String, dynamic> json = faultItem.toJson();
    if (saveOdooId) json.remove("id");

    // json.remove("id");
    // // Warning only for local db!!!
    // // When enable loading from odoo, delete this code
    // json["odooId"] = null;

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      res['message'] = "Фото создано";
      if (!saveOdooId) {
        return SynController.create(_tableName, resId).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
      }
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

    // Future<int> odooId = selectOdooId(faultItemId);
    print("Delete() FaultItem");
    // Set file_data = null for removing base64 photo data
    await DBProvider.db.update(_tableName, {
      'id': faultItemId,
      'active': 'false',
      'file_data': null
    }).then((value) async {
      res['code'] = 1;
      res['id'] = value;
      // Commented because of documents not deleted in odoo!
      // await SynController.delete(_tableName, faultItemId, await odooId)
      //     .catchError((err) {
      //   res['code'] = -2;
      //   res['message'] = 'Error updating syn';
      // });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });

    return res;
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }
}
