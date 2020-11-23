import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/checkList.dart";
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class FaultController extends Controllers {
  static String _tableName = "fault";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Fault fault = Fault.fromJson(json);

    print("Fault Insert() to DB");
    print(fault.toJson());
    return await DBProvider.db.insert(_tableName, fault.toJson());
  }

  static Future<Fault> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return Fault.fromJson(json);
  }

  // Select all faults by parent_id(CheckListItem ID)
  // Returns found records or null.
  static Future<List<Fault>> select(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<Fault> faults = queryRes.map((e) => Fault.fromJson(e)).toList();
    return faults;
  }

  // Update the whole object in db
  static Future<Map<String, dynamic>> update(Fault fault) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Update() Fault");
    await DBProvider.db
        .update(_tableName, fault.prepareForUpdate())
        .then((resId) async {
      res['code'] = 1;
      res['id'] = resId;
    }).catchError((err) {
      res["code"] = -3;
      res["message"] = "Error updating $_tableName";
    });

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  // Important! Set active false now only to fault, not assigned photos and etc.
  // Rework after making controllers for faultItem
  static Future<Map<String, dynamic>> delete(int faultId) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Delete() Fault");
    await DBProvider.db.update(
        _tableName, {'id': faultId, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      res['id'] = value;
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });

    // TO DO ASSIGNED ITEMS
    // var assignedItems = await FaultItemController.select(faultId);
    // if (assignedItems.length == 0) {
    //   res = {
    //     'code': -1,
    //     'message': 'Не найдены связанные фотографии к нарушению id: $faultId',
    //     'id': null,
    //   };

    //   return res;
    // }
    // try {
    //   print("Try to delete assigned FaultItems");
    //   for (var q in assignedItems) {
    //     var json = q.toJson();
    //     var itemId = json["id"];
    //     await DBProvider.db
    //         .update('fault_item', {'id': itemId, 'active': 'false'});
    //   }
    // } catch (e) {
    //   print("Delete of assignedItems to Fault ID: $faultId. Error: $e");
    //   res = {
    //     'code': -3,
    //     'message': 'Error deleting from faultItems',
    //     'id': null,
    //   };
    //   return res;
    // }

    res = {
      'code': 1,
      'message': 'Успешно удалено',
      'id': 0,
    };

    return res;
  }
}
