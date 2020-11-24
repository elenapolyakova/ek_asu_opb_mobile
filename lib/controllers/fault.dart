import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/controllers/faultItem.dart";
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:ek_asu_opb_mobile/models/faultItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'dart:io';

class FaultController extends Controllers {
  static String _tableName = "fault";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Fault fault = Fault.fromJson(json);

    print("Fault Insert() to DB");
    print(fault.toJson());
    return await DBProvider.db.insert(_tableName, fault.toJson());
  }

// path to files means path to photos of Faults storing in internal memory
  static Future<Map<String, dynamic>> create(
      Fault fault, List<String> pathsToFiles) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    print("Create() Fault");
    print("Fault $fault; pathToFiles $pathsToFiles");

    Map<String, dynamic> json = fault.toJson();
    json.remove("id");

    // Warning only for local db!!!
    // When enable loading from odoo, delete this code
    json["odooId"] = null;

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      res['message'] = "Нарушение создано";
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create Fault into $_tableName';
    });

    print("Create() Fault response $res");

    // Main fault db record created, so we can create faultItems records
    if (res["code"] == 1) {
      if (pathsToFiles != null && pathsToFiles.length > 0) {
        for (var photoPath in pathsToFiles) {
          try {
            FaultItem item = new FaultItem();
            item.active = true;
            item.image = photoPath;
            item.parent_id = res["id"];

            var insertResp = await FaultItemController.create(item);
            print("Fault item insert response $insertResp");
          } catch (e) {
            print("Create() Fault Error! Error while creating faultItems: $e");
            res["code"] = -3;
            res["message"] = "Ошибка при создании нарушения и св. фотографий";
            return res;
          }
        }
      }
    }
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

  // Update fault also allows to add or delete photos for 1 Fault
  // create - list with paths to photos in internal memory
  // delete - list ids of photos(faultItems) to delete
  static Future<Map<String, dynamic>> update(
      Fault fault, List<String> create, List<int> delete) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Update() Fault: $fault, create: $create, delete: $delete");
    var createdFaultItemsIds = [];
    var deletedFaultItemsIds = [];

    // Mainly update fault record
    await DBProvider.db
        .update(_tableName, fault.prepareForUpdate())
        .then((resId) async {
      res['code'] = 1;
      res['id'] = resId;
    }).catchError((err) {
      res["code"] = -3;
      res["message"] = "Error updating $_tableName";
    });

    // Creating new FaultItems For existing Fault!
    if (create.length > 0) {
      for (var path in create) {
        try {
          FaultItem faultItem = new FaultItem();
          faultItem.active = true;
          faultItem.image = path;
          // set id of parent
          faultItem.parent_id = fault.id;

          var createResp = await FaultItemController.create(faultItem);
          if (createResp["code"] > 0)
            createdFaultItemsIds.add(createResp["id"]);
        } catch (e) {
          print("Fault Update() Error! Error while creating new faultItem: $e");
          res["code"] = -3;
          res["message"] = "Ошибка при добавлении новых фото";
          return res;
        }
      }
    }

    // Delete assigned photos to Fault
    if (delete.length > 0) {
      try {
        for (var faultItemId in delete) {
          // Find necessary item
          FaultItem item = await FaultItemController.selectById(faultItemId);
          print("FaultItem to delete $item");
          // if not null, delete from db and internal memory
          if (item != null) {
            var deleteResp = await FaultItemController.delete(faultItemId);
            print("print delete resp $deleteResp");
            if (deleteResp["code"] > 0) {
              deletedFaultItemsIds.add(deleteResp["id"]);
              await File(item.image).delete();
            }
          }
        }
      } catch (e) {
        print(
            "Fault Update() Error! Error while deleting existing faultItem: $e");
        res["code"] = -3;
        res["message"] = "Ошибка при удалении ранее сохраненных  фото";
        return res;
      }
    }

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

    var assignedItems = await FaultItemController.select(faultId);
    // if not found print about it
    if (assignedItems.length == 0) {
      // Some logging
      print("Not found assigned FaultItems to fault with id: $faultId");
    }

    // If found, delete from db and internal memory assigned photos
    var deletedFotosIds = [];
    if (assignedItems.length > 0) {
      try {
        print("Try to delete assigned FaultItems");
        for (var fItem in assignedItems) {
          var json = fItem.toJson();
          var itemId = json["id"];

          await DBProvider.db
              .update('fault_item', {'id': itemId, 'active': 'false'});
          await File(fItem.image).delete();
          deletedFotosIds.add(itemId);
        }
      } catch (e) {
        print("Delete of assignedItems to Fault ID: $faultId. Error: $e");
        res = {
          'code': -3,
          'message': 'Error deleting from faultItems',
          'id': null,
        };
        return res;
      }
    }

    res = {
      'code': 1,
      'message': 'Успешно удалено',
      'id': 0,
    };

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
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
