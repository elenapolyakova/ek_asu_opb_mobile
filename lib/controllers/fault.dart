import 'package:ek_asu_opb_mobile/controllers/checkListItem.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/controllers/faultItem.dart";
import 'package:ek_asu_opb_mobile/models/checkListItem.dart';
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:ek_asu_opb_mobile/models/faultItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'dart:io';
import 'package:ek_asu_opb_mobile/src/fileStorage.dart';
import 'package:uuid/uuid.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class FaultController extends Controllers {
  static const String _tableName = "fault";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Fault fault = Fault.fromJson(json);

    print("Fault Insert() to DB");
    print(fault.toJson());
    return await DBProvider.db.insert(_tableName, fault.toJson());
  }

  // faultItems is a List of json data FaultItem
  // delete paths
  static Future<Map<String, dynamic>> create(
      Fault fault, List<Map<String, dynamic>> faultItems, List<String> delete,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    // Set date_done as plan_fix_date for uploading data to odoo!
    fault.date_done = fault.plan_fix_date;

    print("Create() Fault");
    print("Fault $fault; faultItems $faultItems");

    Map<String, dynamic> json = fault.toJson();
    //
    if (saveOdooId) json.remove("id");

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      res['message'] = "Нарушение создано";
      if (!saveOdooId) {
        return SynController.create(_tableName, resId).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
      }
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create Fault into $_tableName';
    });

    print("Create() Fault response $res");

    // Main fault db record created, so we can create faultItems records
    if (res["code"] == 1) {
      if (faultItems != null && faultItems.length > 0) {
        for (var fItem in faultItems) {
          try {
            FaultItem item = new FaultItem();
            // Set properties
            item.active = true;
            item.image = fItem["path"];
            item.coord_e = fItem["coord_e"];
            item.coord_n = fItem["coord_n"];
            item.parent_id = res["id"];
            item.file_data = null;
            item.type = 2;
            item.name = Uuid().v1();
            item.file_name = item.name + ".jpg";

            var insertResp = await FaultItemController.create(item);
            print("Fault item insert response $insertResp");
          } catch (e) {
            print("Create() Fault Error! Error while creating faultItems: $e");
            res["code"] = -3;
            res["message"] = "Ошибка при создании нарушения и св. фотографий";
          }
        }
      }
    }

    var deletedFaultItemsIds = [];
    // Delete assigned photos to Fault
    if (delete.length > 0) {
      try {
        for (var path in delete) {
          // Find necessary item
          List<FaultItem> itemsList =
              await FaultItemController.selectItemByPath(path);
          print("FaultItems to delete $itemsList");
          // if not null, delete from db and internal memory
          if (itemsList != null && itemsList.length > 0) {
            for (var item in itemsList) {
              var deleteResp = await FaultItemController.delete(item.id);
              print("print delete resp $deleteResp");
              if (deleteResp["code"] > 0) {
                deletedFaultItemsIds.add(deleteResp["id"]);
                await File(item.image).delete();
              }
            }
          }
        }
      } catch (e) {
        print(
            "Fault Create() Error! Error while deleting existing faultItem: $e");
        res["code"] = -3;
        res["message"] = "Ошибка при удалении ранее сохраненных  фото";
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
    return faults;
  }

  // Get all faults by ID плана проверки
  static Future<List<Fault>> getFaultsByCheckPlanId(int planId) async {
    if (planId == null) return [];

    try {
      var checkListIdsResp = await DBProvider.db.executeQuery(
          "SELECT id from check_list where parent_id=$planId and active='true' and is_active='true' and is_base='false'");

      // We not found checkLists assigned to plan, return []
      if (checkListIdsResp.length == 0) return [];
      var ids = [];
      checkListIdsResp.forEach((e) {
        ids.add(e["id"]);
      });

      var checkListItemResp = await DBProvider.db.executeQuery(
          "SELECT id from check_list_item where parent_id IN (${ids.join(',')}) and active='true'");
      // Not found assigned questions to checkList, faults are []
      if (checkListItemResp.length == 0) return [];

      // print('check list  item resp $checkListItemResp');
      var checkListItemIds = [];
      // Coupling ids from db resp
      checkListItemResp.forEach((e) {
        checkListItemIds.add(e["id"]);
      });

      var faults = await DBProvider.db.executeQuery(
          "SELECT * FROM fault WHERE parent_id IN (${checkListItemIds.join(', ')}) and active='true'");

      if (faults.length == 0) return [];

      List<Fault> faultsByPlanId =
          faults.map((e) => Fault.fromJson(e)).toList();

      return faultsByPlanId;
    } catch (e) {
      print(
          "getFaultsByCheckPlanId(), Error while getting faults by checkPlanItemID: $e");
      return [];
    }
  }

  // Get all faults by department_id
  static Future<List<Fault>> getFaultsByDepartment(int depId) async {
    if (depId == null) return [];

    try {
      // Планы проверки по предприятию, id
      var checkPlanItemResp = await DBProvider.db.executeQuery(
          "SELECT id from plan_item_check_item WHERE department_id=$depId and active='true'");
      // checkPlanItems not found return []
      if (checkPlanItemResp.length == 0) return [];

      var checkPlanIds = [];
      // coupling ids
      checkPlanItemResp.forEach((e) {
        checkPlanIds.add(e["id"]);
      });

      var checkListIdsResp = await DBProvider.db.executeQuery(
          "SELECT id from check_list where parent_id IN (${checkPlanIds.join(', ')}) and active='true' and is_active='true' and is_base='false'");

      // We not found checkLists assigned to plan, return []
      if (checkListIdsResp.length == 0) return [];
      var ids = [];
      checkListIdsResp.forEach((e) {
        ids.add(e["id"]);
      });

      var checkListItemResp = await DBProvider.db.executeQuery(
          "SELECT id from check_list_item where parent_id IN (${ids.join(',')}) and active='true'");
      // Not found assigned questions to checkList, faults are []
      if (checkListItemResp.length == 0) return [];

      // print('check list  item resp $checkListItemResp');
      var checkListItemIds = [];
      // Coupling ids from db resp
      checkListItemResp.forEach((e) {
        checkListItemIds.add(e["id"]);
      });

      var faults = await DBProvider.db.executeQuery(
          "SELECT * FROM fault WHERE parent_id IN (${checkListItemIds.join(', ')}) and active='true'");

      if (faults.length == 0) return [];

      List<Fault> faultsByPlanId =
          faults.map((e) => Fault.fromJson(e)).toList();

      return faultsByPlanId;
    } catch (e) {
      print(
          "getFaultsByCheckPlanId(), Error while getting faults by checkPlanItemID: $e");
      return [];
    }
  }

  // Update fault also allows to add or delete photos for 1 Fault
  // faultItems - list with data as photoPath coord_e coord_n and etc.
  // delete - list ids of photos(faultItems) to delete
  static Future<Map<String, dynamic>> update(Fault fault,
      List<Map<String, dynamic>> faultItems, List<String> delete) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    // Set date_done as plan fix date for uploading to odoo!
    fault.date_done = fault.plan_fix_date;

    print("Update() FAULT faultItems: $faultItems, delete: $delete");
    var createdFaultItemsIds = [];
    var deletedFaultItemsIds = [];

    // Get odooId
    Future<int> odooId = selectOdooId(fault.id);

    // Mainly update fault record
    await DBProvider.db
        .update(_tableName, fault.prepareForUpdate())
        .then((resId) async {
      res['code'] = 1;
      res['id'] = resId;
      await SynController.edit(_tableName, fault.id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res["code"] = -3;
      res["message"] = "Error updating $_tableName";
    });

    // Creating new FaultItems For existing Fault!
    if (faultItems.length > 0) {
      for (var fItem in faultItems) {
        try {
          FaultItem item = new FaultItem();
          // Set properties
          item.active = true;
          item.image = fItem["path"];
          item.coord_e = fItem["coord_e"];
          item.coord_n = fItem["coord_n"];
          item.parent_id = fault.id;
          item.file_data = null;

          item.type = 2;
          item.name = Uuid().v1();
          item.file_name = item.name + ".jpg";

          var createResp = await FaultItemController.create(item);
          print("faultItem create resp $createResp");
          if (createResp["code"] > 0)
            createdFaultItemsIds.add(createResp["id"]);
        } catch (e) {
          print("Fault Update() Error! Error while creating new faultItem: $e");
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
          List<FaultItem> itemsList =
              await FaultItemController.selectItemByPath(path);
          print("FaultItems to delete $itemsList");
          // if not null, delete from db and internal memory
          if (itemsList != null && itemsList.length > 0) {
            for (var item in itemsList) {
              var deleteResp = await FaultItemController.delete(item.id);
              print("print delete resp $deleteResp");
              if (deleteResp["code"] > 0) {
                deletedFaultItemsIds.add(deleteResp["id"]);
                await File(item.image).delete();
              }
            }
          }
        }
      } catch (e) {
        print(
            "Fault Update() Error! Error while deleting existing faultItem: $e");
        res["code"] = -3;
        res["message"] = "Ошибка при удалении ранее сохраненных  фото";
      }
    }

    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> delete(int faultId) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    print("Delete() Fault");
    Future<int> odooId = selectOdooId(faultId);

    await DBProvider.db.update(
        _tableName, {'id': faultId, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      res['id'] = value;
      await SynController.delete(_tableName, faultId, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
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

          await FaultItemController.delete(itemId);
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

  static Future<int> getFaultsCount(int parentId) async {
    if (parentId == null) return null;

    var response = await DBProvider.db.executeQuery(
        "SELECT COUNT(id) FROM $_tableName WHERE parent_id=$parentId and active='true'");

    int count = response[0]["COUNT(id)"];
    return count;
  }

  // Get odooId by db id
  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static Future<Fault> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return Fault.fromJson(json[0]);
  }

  static firstLoadFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    List<List> domain = [];
    if (loadRelated) {
      fields = ['write_date', 'parent_id'];
      // List<Map<String, dynamic>> queryRes =
      //     await DBProvider.db.select(_tableName, columns: ['odoo_id']);
      // domain = [
      //   ['id', 'in', queryRes.map((e) => e['odoo_id'] as int).toList()]
      // ];
    } else {
      await DBProvider.db.deleteAll(_tableName);
      // List<List> toAdd = [];
      // await Future.forEach(
      //     SynController.tableMany2oneFieldsMap[_tableName].entries,
      //     (element) async {
      //   List<Map<String, dynamic>> queryRes =
      //       await DBProvider.db.select(element.value, columns: ['odoo_id']);
      //   toAdd.add([
      //     element.key,
      //     'in',
      //     queryRes.map((e) => e['odoo_id'] as int).toList()
      //   ]);
      // });
      // domain += toAdd;
      fields = [
        'name',
        'desc',
        'fine_desc',
        'fine',
        'koap_id',
        'date',
        'date_done',
        'active',
      ];
    }

    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });

    await Future.forEach(json, (e) async {
      // koap_id from odoo is like []
      if (e['koap_id'] is List) {
        e['koap_id'] = e['koap_id'][0];
      }
      // If date done not set, save empty string
      if (e['date_done'] is bool) {
        e['date_done'] = null;
      }
      if (e['date'] is bool) {
        e['date'] = null;
      }

      // Set plan_fix_date as it's name in odoo date_done
      e['plan_fix_date'] = e['date_done'];

      if (loadRelated) {
        Fault fault = await selectByOdooId(e['id']);
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckListItem parentCheckListItem =
              await CheckListItemController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          if (parentCheckListItem == null) return null;
          // assert(parentCheckListItem != null,
          //     "Model check_list_item has to be loaded before $_tableName");
          res['id'] = fault.id;
          res['parent_id'] = parentCheckListItem.id;
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

        print("firstLoadFromOdoo() Fault insert! $res");
        Fault json = Fault.fromJson(res);
        // second and third params needs for creation faultItems as photos
        // In this case we don't need to create the from here
        // They will be created in faultItemController!
        return FaultController.create(json, [], [], true);
      }
    });

    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');

    if (loadRelated) await setLatestWriteDate(_tableName, json);
  }

  static loadChangesFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['write_date', 'parent_id'];
    else
      fields = [
        'name',
        'desc',
        'fine_desc',
        'fine',
        'koap_id',
        'date',
        'date_done',
        'active',
      ];

    List domain = await getLastSyncDateDomain(_tableName);

    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });

    print("Fault, Load changes from odoo! $json");

    await Future.forEach(json, (e) async {
      if (e['koap_id'] is List) {
        e['koap_id'] = e['koap_id'][0];
      }
      // If date done not set, save empty string
      if (e['date_done'] is bool) {
        e['date_done'] = null;
      }
      if (e['date'] is bool) {
        e['date'] = null;
      }
      // Set plan_fix_date as date_done property in odoo!
      e['plan_fix_date'] = e['date_done'];

      Fault fault = await selectByOdooId(e['id']);
      if (loadRelated) {
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckListItem parentCheckListItem =
              await CheckListItemController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          if (parentCheckListItem == null) return null;
          // assert(parentCheckListItem != null,
          //     "Model check_list_item has to be loaded before $_tableName");
          res['id'] = fault.id;
          res['parent_id'] = parentCheckListItem.id;
        }
        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        if (fault == null) {
          Map<String, dynamic> res = Fault.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = Fault.fromJson({
          ...e,
          'id': fault.id,
          'odoo_id': fault.odoo_id,
          'active': e['active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');

    if (loadRelated) await setLatestWriteDate(_tableName, json);
  }

  static Future finishSync(dateTime) {
    return setLastSyncDateForDomain(_tableName, dateTime);
  }
}
