import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/controllers/faultItem.dart";
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

  static Future<Map<String, dynamic>> create(Fault fault) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Create() Fault");
    print("Fault data $fault");
    print(fault.toJson());
    Map<String, dynamic> json = fault.toJson();

    json.remove("id");

    // From this copy we will create db records in fault_item table
    var faultCopy = Map.from(json);

    json.remove('create');
    json.remove('delete');

    // Warning only for local db!!!
    // When enable loading from odoo, delete this code
    json["odooId"] = null;

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;

      // Using res id for create assigned fault_item with parent_id = resId
      // TO DO
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create Fault into $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
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
    print("Fault Select()");
    print(faults);
    return faults;
  }

  // Update the whole object in db
  static Future<Map<String, dynamic>> update(Fault fault) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

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
    var assignedItems = await FaultItemController.select(faultId);
    if (assignedItems.length == 0) {
      // Some logging
      print("Delete() Fault");
      print("Not found assigned FaultItems to fault with id: $faultId");
    }
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

  static Future<int> getFaultsCount(int parentId) async {
    if (parentId == null) return null;

    var response = await DBProvider.db.executeQuery(
        "SELECT COUNT(id) FROM $_tableName WHERE parent_id=$parentId and active='true'");

    int count = response[0]["COUNT(id)"];
    return count;
  }
}
