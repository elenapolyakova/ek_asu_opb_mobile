import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:ek_asu_opb_mobile/controllers/checkList.dart';
import 'package:ek_asu_opb_mobile/models/checkList.dart';
import "package:ek_asu_opb_mobile/models/checkListItem.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

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

  static Future<CheckListItem> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return CheckListItem.fromJson(json[0]);
  }

  static firstLoadFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    List<List> domain = [];
    if (loadRelated) {
      fields = ['parent_id'];
      List<Map<String, dynamic>> queryRes =
          await DBProvider.db.select(_tableName, columns: ['odoo_id']);
      domain = [
        ['id', 'in', queryRes.map((e) => e['odoo_id'] as int).toList()]
      ];
    } else {
      List<List> toAdd = [];
      await Future.forEach(
          SynController.tableMany2oneFieldsMap[_tableName].entries,
          (element) async {
        List<Map<String, dynamic>> queryRes =
            await DBProvider.db.select(element.value, columns: ['odoo_id']);
        toAdd.add([
          element.key,
          'in',
          queryRes.map((e) => e['odoo_id'] as int).toList()
        ]);
      });
      domain += toAdd;
      fields = [
        'base_id',
        'name',
        'question',
        'active',
        'result',
        'description',
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

    print("CheckListItem firstLoad $json");
    // Before we delete all data for collisions escape
    if (!loadRelated) await DBProvider.db.deleteAll(_tableName);

    return Future.forEach(json, (e) async {
      // base_id from odoo is like [3, _unknown, 3]
      if (e['base_id'] is List) {
        e['base_id'] = e['base_id'][0];
      }

      if (loadRelated) {
        CheckListItem checkListItem = await selectByOdooId(e['id']);
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckListWork parentCheckList =
              await CheckListController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          assert(parentCheckList != null,
              "Model check_list has to be loaded before $_tableName");
          res['id'] = checkListItem.id;
          res['parent_id'] = parentCheckList.id;
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

        print("firstLoadFromOdoo() CheckListItem insert! $res");
        CheckListItem json = CheckListItem.fromJson(res);
        return CheckListItemController.create(json, true);
      }
    });
  }

  static loadChangesFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    if (loadRelated)
      fields = ['parent_id'];
    else
      fields = [
        'base_id',
        'name',
        'question',
        'active',
        'result',
        'description',
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

    print("CheckListItem, Load changes from odoo! $json");
    print("Domain $domain");

    return Future.forEach(json, (e) async {
      if (e['base_id'] is List) {
        e['base_id'] = e['base_id'][0];
      }
      CheckListItem checkListItem = await selectByOdooId(e['id']);
      if (loadRelated) {
        Map<String, dynamic> res = {};
        if (e['parent_id'] is List) {
          CheckListWork parentCheckList =
              await CheckListController.selectByOdooId(
                  unpackListId(e['parent_id'])['id']);
          assert(parentCheckList != null,
              "Model check_list has to be loaded before $_tableName");
          res['id'] = checkListItem.id;
          res['parent_id'] = parentCheckList.id;
        }
        if (res['id'] != null) return DBProvider.db.update(_tableName, res);
        return null;
      } else {
        if (checkListItem == null) {
          Map<String, dynamic> res = CheckListItem.fromJson({
            ...e,
            'active': e['active'] ? 'true' : 'false',
          }).toJson(true);
          res['odoo_id'] = e['id'];
          return DBProvider.db.insert(_tableName, res);
        }
        Map<String, dynamic> res = CheckListItem.fromJson({
          ...e,
          'id': checkListItem.id,
          'odoo_id': checkListItem.odoo_id,
          'active': e['active'] ? 'true' : 'false',
        }).toJson();
        return DBProvider.db.update(_tableName, res);
      }
    });
  }

  static Future finishSync(dateTime) {
    return setLastSyncDateForDomain(_tableName, dateTime);
  }
}
