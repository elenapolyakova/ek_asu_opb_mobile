import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:ek_asu_opb_mobile/models/faultItem.dart';
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import "package:ek_asu_opb_mobile/src/fileStorage.dart";

class FaultItemController extends Controllers {
  static const String _tableName = "fault_item";

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

    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      res['message'] = "Фото создано";
      if (!saveOdooId) {
        var file = fileToBase64(json["image"]);
        return SynController.create(_tableName, resId, beforeUpload: (record) {
          record["file_data"] = file;
          return record;
        }).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
      }
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error create FaultItem into $_tableName';
    });

    print("FAULT_ITEM Res $res");

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

  // param image stay for path
  static Future<List<FaultItem>> selectItemByPath(String filePath) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "image = ? and active = 'true'",
      whereArgs: [filePath],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<FaultItem> faultItems =
        queryRes.map((e) => FaultItem.fromJson(e)).toList();
    print("FaultItems SelectItemByPath()");
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

  static Future<FaultItem> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return FaultItem.fromJson(json[0]);
  }

  static firstLoadFromOdoo([bool loadRelated = false, int limit]) async {
    List<String> fields;
    List<List> domain = [];
    if (loadRelated) {
      fields = ['write_date', 'parent_id'];
    } else {
      await DBProvider.db.deleteAll(_tableName);
      fields = [
        'name',
        'type',
        'file_name',
        'file_data',
        'coord_n',
        'coord_e',
      ];
    }
    domain.add(['parent2_id', '=', null]);
    domain.add(['parent3_id', '=', null]);

    List<dynamic> json;
    int page = 0;
    do {
      json = await getDataWithAttemp(
          SynController.localRemoteTableNameMap[_tableName], 'search_read', [
        domain,
        fields
      ], {
        'limit': 10,
        'offset': 10 * page++,
        'context': {'create_or_update': true}
      });

      await Future.forEach(json, (e) async {
        if (loadRelated) {
          FaultItem faultItem = await selectByOdooId(e['id']);
          Map<String, dynamic> res = {};
          if (e['parent_id'] is List) {
            Fault parentFault = await FaultController.selectByOdooId(
                unpackListId(e['parent_id'])['id']);
            if (parentFault == null) return null;
            res['id'] = faultItem.id;
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
          // Skip records where file_data is false from odoo as
          // Data for this records is not defined!
          if (e["file_data"] is bool) {
          } else {
            if (e["coord_n"] is bool) {
              e["coord_n"] = null;
            }
            if (e["coord_e"] is bool) {
              e["coord_e"] = null;
            }

            print("firstLoadFromOdoo() FaultItem insert! $res");
            FaultItem json = FaultItem.fromJson(res);

            // Create local file
            var file = await base64ToFile(json.file_data);
            print("Path ");
            print(file.path);

            json.image = file.path;
            // Set file_data null because of issues with db
            json.file_data = null;
            return FaultItemController.create(json, true);
          }
        }
      });
    } while (json is List && json.length == 10);
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
        'type',
        'file_name',
        'file_data',
        'coord_n',
        'coord_e',
      ];

    List domain = await getLastSyncDateDomain(_tableName, excludeActive: true);
    // Get only photos for fault! By this
    domain.add(['parent2_id', '=', null]);
    domain.add(['parent3_id', '=', null]);

    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'context': {'create_or_update': true}
    });

    print("FaultItem, Load changes from odoo! $json");
    print("Domain $domain");

    await Future.forEach(json, (e) async {
      FaultItem faultItem = await selectByOdooId(e['id']);
      if (loadRelated) {
        if (faultItem != null) {
          Map<String, dynamic> res = {};
          if (e['parent_id'] is List) {
            Fault parentFault = await FaultController.selectByOdooId(
                unpackListId(e['parent_id'])['id']);
            if (parentFault == null) return null;
            res['id'] = faultItem.id;
            res['parent_id'] = parentFault.id;
          }
          if (res['id'] != null) return DBProvider.db.update(_tableName, res);
          return null;
        }
      } else {
        if (faultItem == null) {
          // Skip records where file_data is false from odoo!
          if (e["file_data"] is bool) {
          } else {
            // Firstly create file!
            var file = await base64ToFile(e["file_data"]);
            // Set path
            e["image"] = file.path;
            // Check if coords from odoo is bool
            if (e["coord_n"] is bool) {
              e["coord_n"] = null;
            }
            if (e["coord_e"] is bool) {
              e["coord_e"] = null;
            }

            // set file_data = null because of issues with db
            e["file_data"] = null;
            Map<String, dynamic> res =
                FaultItem.fromJson({...e, 'active': 'true'}).toJson(true);
            res['odoo_id'] = e['id'];
            return DBProvider.db.insert(_tableName, res);
          }
        }
        // Map<String, dynamic> res = FaultItem.fromJson({
        //   ...e,
        //   'id': faultItem.id,
        //   'odoo_id': faultItem.odoo_id,
        //   'active': 'true',
        // }).toJson();
        // return DBProvider.db.update(_tableName, res);
      }
    });
    print(
        'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');

    if (loadRelated) await setLatestWriteDate(_tableName, json);
  }
}
