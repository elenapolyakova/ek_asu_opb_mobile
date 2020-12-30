import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:ek_asu_opb_mobile/controllers/faultFixItem.dart';
import 'package:ek_asu_opb_mobile/models/faultFix.dart';
import 'package:ek_asu_opb_mobile/models/faultFixItem.dart';
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'dart:io';
import 'package:uuid/uuid.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class FaultFixController extends Controllers {
  static const String _tableName = "fault_fix";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    FaultFix faultFix = FaultFix.fromJson(json);

    print("FaultFix Insert() to DB");
    print(faultFix.toJson());
    return await DBProvider.db.insert(_tableName, faultFix.toJson());
  }

  // faultItems is a List of json data FaultItem
  // delete paths of files to delete arra of string
  static Future<Map<String, dynamic>> create(FaultFix faultFix,
      List<Map<String, dynamic>> faultItems, List<String> delete,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Create() FaultFix");
    print("FaultFix $faultFix; faultItems $faultItems");

    Map<String, dynamic> json = faultFix.toJson();
    //
    if (saveOdooId) json.remove("id");

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      res['message'] = "Запись контроля нарушений создана";
      if (!saveOdooId) {
        return SynController.create(_tableName, resId).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
      }
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create FaultFix into $_tableName';
    });

    print("Create() FaultFix response $res");

    // Main faultFix db record created, so we can create faultFixItems records
    if (res["code"] == 1) {
      if (faultItems != null && faultItems.length > 0) {
        for (var fItem in faultItems) {
          try {
            FaultFixItem item = new FaultFixItem();
            // Set properties
            item.active = true;
            item.coord_e = fItem["coord_e"];
            item.coord_n = fItem["coord_n"];
            item.parent3_id = res["id"];
            item.file_data = fItem["path"];
            item.type = 2;
            item.name = Uuid().v1();
            item.file_name = item.name + ".jpg";

            var insertResp = await FaultFixItemController.create(item);
            print("FaultFixItem insert response $insertResp");
          } catch (e) {
            print(
                "Create() FaultFix Error! Error while creating faultFixItems: $e");
            res["code"] = -3;
            res["message"] = "Ошибка при создании нарушения и св. фотографий";
          }
        }
      }
    }

    var deletedFaultItemsIds = [];
    // Delete assigned photos to FaultFix
    if (delete.length > 0) {
      try {
        for (var path in delete) {
          // Find necessary item
          List<FaultFixItem> itemsList =
              await FaultFixItemController.selectItemByPath(path);
          print("FaultFixItems to delete $itemsList");
          // if not null, delete from db and internal memory
          if (itemsList != null && itemsList.length > 0) {
            for (var item in itemsList) {
              var deleteResp = await FaultFixItemController.delete(item.id);
              print("print delete resp $deleteResp");
              if (deleteResp["code"] > 0) {
                deletedFaultItemsIds.add(deleteResp["id"]);
                await File(item.file_data).delete();
              }
            }
          }
        }
      } catch (e) {
        print(
            "FaultFix Create() Error! Error while deleting existing faultFixItem: $e");
        res["code"] = -3;
        res["message"] = "Ошибка при удалении ранее сохраненных  фото";
      }
    }
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<FaultFix> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return FaultFix.fromJson(json);
  }

  // Select all FaultFix by parent_id( ID)
  // Returns found records or null.
  static Future<List<FaultFix>> select(int parentId) async {
    if (parentId == null) return [];
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ? and active = 'true'",
      whereArgs: [parentId],
    );

    if (queryRes == null || queryRes.length == 0) return [];
    List<FaultFix> faultFixs =
        queryRes.map((e) => FaultFix.fromJson(e)).toList();
    return faultFixs;
  }

  // Update faultFix also allows to add or delete photos
  // faultFixItems - list with data as photoPath coord_e coord_n and etc.
  // delete - list ids of photos(faultFixItems) to delete
  static Future<Map<String, dynamic>> update(FaultFix faultFix,
      List<Map<String, dynamic>> faultFixItems, List<String> delete) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Update() FaultFix faultFixItems: $faultFixItems, delete: $delete");
    var createdFaultItemsIds = [];
    var deletedFaultItemsIds = [];

    // Get odooId
    Future<int> odooId = selectOdooId(faultFix.id);

    // Mainly update faultFix record
    await DBProvider.db
        .update(_tableName, faultFix.prepareForUpdate())
        .then((rowsAffected) async {
      res['code'] = 1;
      res['id'] = faultFix.id;
      await SynController.edit(_tableName, faultFix.id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res["code"] = -3;
      res["message"] = "Error updating $_tableName";
    });

    // Creating new FaultItems For existing FaultFix!
    if (faultFixItems.length > 0) {
      for (var fItem in faultFixItems) {
        try {
          FaultFixItem item = new FaultFixItem();
          // Set properties
          item.active = true;
          item.coord_e = fItem["coord_e"];
          item.coord_n = fItem["coord_n"];
          item.parent3_id = faultFix.id;
          item.file_data = fItem["path"];

          item.type = 2;
          item.name = Uuid().v1();
          item.file_name = item.name + ".jpg";

          var createResp = await FaultFixItemController.create(item);
          print("faultItem create resp $createResp");
          if (createResp["code"] > 0)
            createdFaultItemsIds.add(createResp["id"]);
        } catch (e) {
          print(
              "FaultFix Update() Error! Error while creating new faultItem: $e");
          res["code"] = -3;
          res["message"] = "Ошибка при добавлении новых фото";
        }
      }
    }

    // Delete assigned photos to Fault
    if (delete.length > 0) {
      try {
        for (var path in delete) {
          // Find necessary item
          List<FaultFixItem> itemsList =
              await FaultFixItemController.selectItemByPath(path);
          print("FaultFixItems to delete $itemsList");
          // if not null, delete from db and internal memory
          if (itemsList != null && itemsList.length > 0) {
            for (var item in itemsList) {
              var deleteResp = await FaultFixItemController.delete(item.id);
              print("print delete resp $deleteResp");
              if (deleteResp["code"] > 0) {
                deletedFaultItemsIds.add(deleteResp["id"]);
                await File(item.file_data).delete();
              }
            }
          }
        }
      } catch (e) {
        print(
            "FaultFix Update() Error! Error while deleting existing faultFixItem: $e");
        res["code"] = -3;
        res["message"] = "Ошибка при удалении ранее сохраненных  фото";
      }
    }

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> delete(int faultFixId) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Delete() FaultFix");
    Future<int> odooId = selectOdooId(faultFixId);

    await DBProvider.db.update(
        _tableName, {'id': faultFixId, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      res['id'] = value;
      await SynController.delete(_tableName, faultFixId, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });

    var assignedItems = await FaultFixItemController.select(faultFixId);
    // if not found print about it
    if (assignedItems.length == 0) {
      // Some logging
      print(
          "Not found assigned FaulFixtItems to FaultFiz with id: $faultFixId");
    }

    // If found, delete from db and internal memory assigned photos
    var deletedFotosIds = [];
    if (assignedItems.length > 0) {
      try {
        print("Try to delete assigned FaultItems");
        for (var fItem in assignedItems) {
          var json = fItem.toJson();
          var itemId = json["id"];

          await FaultFixItemController.delete(itemId);
          await File(fItem.file_data).delete();
          deletedFotosIds.add(itemId);
        }
      } catch (e) {
        print("Delete of assignedItems to FaultFix ID: $faultFixId. Error: $e");
        res = {
          'code': -3,
          'message': 'Error deleting from faultFixItems',
          'id': null,
        };
      }
    }
    print("Deleted photos ids $deletedFotosIds");
    res = {
      'code': 1,
      'message': 'Успешно удалено',
      'id': 0,
    };

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  // Получить кол-во нарушений для устранения, для
  static Future<int> getFaultsFixCount(int parentId) async {
    if (parentId == null) return null;

    var response = await DBProvider.db.executeQuery(
        "SELECT COUNT(id) FROM $_tableName WHERE parent_id=$parentId and active='true'");

    int count = response[0]["COUNT(id)"];
    return count;
  }

  static Future<DateTime> getMaxFixDate(int parentId) async {
    if (parentId == null) return null;

    var queryRes = await DBProvider.db.executeQuery(
        "SELECT MAX(date) as date from $_tableName where parent_id=$parentId");
    if (queryRes.length == 0) return null;

    DateTime date = stringToDateTime(queryRes[0]["date"], forceUtc: false);

    return date;
  }

  // Get odooId by db id
  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static Future<FaultFix> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return FaultFix.fromJson(json[0]);
  }

  static firstLoadFromOdoo([bool loadRelated = false]) async {
    List<String> fields;
    List<List> domain = [];
    if (loadRelated) {
      fields = ['write_date', 'parent_id'];
    } else {
      await DBProvider.db.deleteAll(_tableName);
      fields = [
        'desc',
        'date',
        'is_finished',
        'active',
      ];
    }

    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'context': {'create_or_update': true}
    });

    await Future.forEach(json, (e) async {
      if (e['date'] is bool) {
        e['date'] = null;
      }
      if (loadRelated) {
        FaultFix fault = await selectByOdooId(e['id']);
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          Fault parentFault = await FaultController.selectByOdooId(
              unpackListId(e['parent_id'])['id']);
          if (parentFault == null) return null;
          res['id'] = fault.id;
          res['parent_id'] = parentFault.id;
        }
        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        Map<String, dynamic> res = {
          ...e,
          'id': null,
          'odoo_id': e['id'],
          'active': 'true',
        };

        print("firstLoadFromOdoo() FaultFix insert! $res");
        FaultFix json = FaultFix.fromJson(res);
        // second and third params needs for creation faultFixItems as photos
        // In this case we don't need to create the from here
        // They will be created in faultFixItemController!
        return FaultFixController.create(json, [], [], true);
      }
    });

    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');

    if (loadRelated) await setLatestWriteDate(_tableName, json);
  }

  static loadChangesFromOdoo([bool loadRelated = false]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['write_date', 'parent_id'];
    else
      fields = [
        'desc',
        'date',
        'is_finished',
        'active',
      ];

    List domain = await getLastSyncDateDomain(_tableName);

    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'context': {'create_or_update': true}
    });

    print("FaultFix, Load changes from odoo! $json");

    await Future.forEach(json, (e) async {
      if (e['date'] is bool) {
        e['date'] = null;
      }

      FaultFix faultFix = await selectByOdooId(e['id']);
      if (loadRelated) {
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          Fault parentFault = await FaultController.selectByOdooId(
              unpackListId(e['parent_id'])['id']);
          if (parentFault == null) return null;
          res['id'] = faultFix.id;
          res['parent_id'] = parentFault.id;
        }
        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        if (faultFix == null) {
          Map<String, dynamic> res = FaultFix.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = FaultFix.fromJson({
          ...e,
          'id': faultFix.id,
          'odoo_id': faultFix.odoo_id,
          'active': e['active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');

    if (loadRelated) await setLatestWriteDate(_tableName, json);
  }
}
