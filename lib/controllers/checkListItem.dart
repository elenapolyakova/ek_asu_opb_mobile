import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import "package:ek_asu_opb_mobile/models/checkListItem.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/controllers/syn.dart";

class CheckListItemController extends Controllers {
  static String _tableName = "check_list_item";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    CheckListItem checkListItem = CheckListItem.fromJson(json);

    return await DBProvider.db.insert(_tableName, checkListItem.toJson());
  }

  // Used for creation of new checkListItem
  static Future<Map<String, dynamic>> create(CheckListItem checkListItem,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Create() CheckListItem");
    print(checkListItem);
    Map<String, dynamic> json = checkListItem.toJson(!saveOdooId);
    if (saveOdooId) json.remove("id");

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      if (!saveOdooId) {
        return SynController.create(_tableName, resId).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
      }
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create checkListItem into $_tableName';
    });

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  // Used for creation work copy of CheckList templates and its assigned Questions
  static Future<List<CheckListItem>> getCheckListItemsByParentId(
      int parent_id) async {
    if (parent_id == null) return [];

    var result = await DBProvider.db.executeQuery(
        "SELECT * from check_list_item WHERE parent_id=$parent_id and active='true'");
    List<CheckListItem> response = [];

    for (var item in result) {
      var newItem = CheckListItem.fromJson(item);
      response.add(newItem);
    }
    print("getQuestionsByParentId() response $response");
    return response;
  }

  /// Select all CheckListItems with matching parentId (Parent id stays for check_list)
  /// Returns found records or null.
  static Future<List<CheckListItem>> select(int parentId) async {
    if (parentId == null) return [];

    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<CheckListItem> checkListItems =
        queryRes.map((e) => CheckListItem.fromJson(e)).toList();
    return checkListItems;
  }

  // Update the whole object in db
  static Future<Map<String, dynamic>> update(
      CheckListItem checkListItem) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Update() CheckListItem!");
    print(checkListItem);
    Future<int> odooId = selectOdooId(checkListItem.id);
    await DBProvider.db
        .update(_tableName, checkListItem.prepareForUpdate())
        .then((resId) async {
      res['code'] = 1;
      res['id'] = resId;

      return SynController.edit(_tableName, checkListItem.id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res["code"] = -3;
      res["message"] = "Error updating $_tableName";
    });

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    print("Delete() CheckListItem");

    Future<int> odooId = selectOdooId(id);
    await DBProvider.db
        .update(_tableName, {'id': id, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      res["id"] = value;
      return SynController.delete(_tableName, id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });

    var assignedFaults = await FaultController.select(id);
    print("Assigned faults to checkList $assignedFaults");

    if (assignedFaults.length > 0) {
      for (var fault in assignedFaults) {
        try {
          var deleteResp = await FaultController.delete(fault.id);
          print("Delete Resp $deleteResp");
        } catch (e) {
          print(
              "Delete() Fault. Error while deleting assigned fault to CheckListItem id: $id");
          res['code'] = -3;
          res['message'] =
              'Ошибка при удалении связанных нарушений к чек-листу';

          return res;
        }
      }
    }
    // Make success response
    res['code'] = 1;
    res['message'] = 'Данные успешно удалены';
    res['id'] = 0;

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});

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
