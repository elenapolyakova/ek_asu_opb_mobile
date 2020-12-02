import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'package:ek_asu_opb_mobile/models/chat.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class ChatController extends Controllers {
  static String _tableName = "chat";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<Chat> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return Chat.fromJson(json);
  }

  static Future<List<Chat>> selectByIds(List<int> ids) async {
    if (ids == null || ids.length == 0) return [];
    List<Map<String, dynamic>> json = await DBProvider.db.select(
      _tableName,
      where: "id in (${ids.map((e) => "?").join(',')})",
      whereArgs: ids,
    );
    return json.map((e) => Chat.fromJson(e)).toList();
  }

  static Future<Chat> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return Chat.fromJson(json[0]);
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  static loadFromOdoo({bool clean: false, int limit, int offset}) async {
    await ComGroupController.loadChangesFromOdoo();
    await ComGroupController.loadChangesFromOdoo(true);

    List<String> fields = [
      'name',
      'group_id',
      'type',
      'user_ids',
    ];
    List domain;
    if (clean) {
      domain = [];
      await DBProvider.db.deleteAll(_tableName);
    } else {
      domain = await getLastSyncDateDomain(_tableName);
      domain.removeLast();
    }
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'offset': offset,
      'context': {'create_or_update': true}
    });
    var result = await Future.forEach(json, (e) async {
      int chatId = (await selectByOdooId(e['id']))?.id;
      int groupId = (await ComGroupController.selectByOdooId(
              unpackListId(e['group_id'])['id']))
          ?.id;
      List userIds = e.remove('user_ids');
      Map<String, dynamic> res = {
        ...e,
        'group_id': groupId,
      };
      if (chatId != null) {
        res['id'] = chatId;
        await DBProvider.db.update(_tableName, Chat.fromJson(res).toJson());
      } else {
        res['odoo_id'] = e['id'];
        chatId =
            await DBProvider.db.insert(_tableName, Chat.fromJson(res).toJson());
      }
      await RelChatUserController.updateChatUsers(
        chatId,
        List<int>.from(
            userIds.map((userId) => unpackListId(userId)['id'] as int)),
      );
    });
    print('loaded ${json.length} records of $_tableName');
    await setLastSyncDateForDomain(_tableName, DateTime.now());
    return result;
  }

  // static firstLoadFromOdoo([bool loadRelated = false, int limit]) async {
  //   List<String> fields;
  //   List<List> domain = [];
  //   if (loadRelated) {
  //     fields = [
  //       'group_id',
  //       'user_ids',
  //     ];
  //   } else {
  //     await DBProvider.db.deleteAll(_tableName);
  //     fields = [
  //       'name',
  //       'type',
  //     ];
  //   }
  //   List<dynamic> json = await getDataWithAttemp(
  //       SynController.localRemoteTableNameMap[_tableName], 'search_read', [
  //     domain,
  //     fields
  //   ], {
  //     'limit': limit,
  //     'context': {'create_or_update': true}
  //   });
  //   var result = await Future.forEach(json, (e) async {
  //     if (loadRelated) {
  //       ComGroup comGroup = await ComGroupController.selectByOdooId(
  //           unpackListId(e['group_id'])['id']);
  //       Chat chat = await selectByOdooId(e['id']);
  //       if (comGroup != null) {
  //         Map<String, dynamic> res = {
  //           'id': chat.id,
  //           'group_id': comGroup.id,
  //         };
  //         await DBProvider.db.update(_tableName, res);
  //       }
  //       return RelChatUserController.updateChatUsers(chat.id,
  //           List<int>.from(e['user_ids'].map((userId) => userId as int)));
  //     } else {
  //       Map<String, dynamic> res = {
  //         ...e,
  //         'odoo_id': e['id'],
  //       };
  //       return insert(Chat.fromJson(res), [], true);
  //     }
  //   });
  //   print(
  //       'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');
  //   return result;
  // }

  // static loadChangesFromOdoo([bool loadRelated = false, int limit]) async {
  //   List<String> fields;
  //   if (loadRelated)
  //     fields = [
  //       'group_id',
  //       'user_ids',
  //     ];
  //   else
  //     fields = [
  //       'name',
  //       'type',
  //     ];
  //   List domain = await getLastSyncDateDomain(_tableName);
  //   List<dynamic> json = await getDataWithAttemp(
  //       SynController.localRemoteTableNameMap[_tableName], 'search_read', [
  //     domain,
  //     fields
  //   ], {
  //     'limit': limit,
  //     'context': {'create_or_update': true}
  //   });
  //   var result = await Future.forEach(json, (e) async {
  //     Chat chat = await selectByOdooId(e['id']);
  //     if (loadRelated) {
  //       ComGroup comGroup = await ComGroupController.selectByOdooId(
  //           unpackListId(e['group_id'])['id']);
  //       if (comGroup != null) {
  //         Map<String, dynamic> res = {
  //           'id': chat.id,
  //           'group_id': comGroup.id,
  //         };
  //         await DBProvider.db.update(_tableName, res);
  //       }
  //       return RelChatUserController.updateChatUsers(chat.id,
  //           List<int>.from(e['user_ids'].map((userId) => userId as int)));
  //     } else {
  //       if (chat == null) {
  //         Map<String, dynamic> res = Chat.fromJson(e).toJson(true);
  //         res['odoo_id'] = e['id'];
  //         return DBProvider.db.insert(_tableName, res);
  //       }
  //       Map<String, dynamic> res = Chat.fromJson({
  //         ...e,
  //         'id': chat.id,
  //         'odoo_id': chat.odooId,
  //       }).toJson();
  //       return DBProvider.db.update(_tableName, res);
  //     }
  //   });
  //   print(
  //       'loaded ${json.length} ${loadRelated ? '' : 'un'}related records of $_tableName');
  //   return result;
  // }

  // static Future finishSync(dateTime) {
  //   return setLastSyncDateForDomain(_tableName, dateTime);
  // }

  /// Select all records by provided parameters.
  /// Without any parameters return all records.
  /// Returns a List of records.
  static Future<List<Chat>> select({int groupId, int id}) async {
    if (groupId != null && id != null) {
      throw 'Need to specify at most one parameter';
    }
    if (groupId == null && id == null) {
      List<Map<String, dynamic>> queryRes = await selectAll();
      List<Chat> chats = queryRes.map((e) => Chat.fromJson(e)).toList();
      return chats;
    }
    if (id == null) {
      List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
        _tableName,
        where: "group_id = ?",
        whereArgs: [groupId],
      );
      if (queryRes == null || queryRes.length == 0) return [];
      List<Chat> chats = queryRes.map((e) => Chat.fromJson(e)).toList();
      return chats;
    } else {
      return [await selectById(id)];
    }
  }

  static Future<Map<String, dynamic>> insert(Chat chat,
      [List<int> userIds = const [], bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> json = chat.toJson(!saveOdooId);
    if (saveOdooId) json.remove('id');
    await DBProvider.db.insert(_tableName, json).then((resId) {
      return RelChatUserController.insertByChatId(resId, userIds).then((value) {
        res['code'] = 1;
        res['id'] = resId;
        if (!saveOdooId)
          return SynController.create(_tableName, resId).catchError((err) {
            res['code'] = -2;
            res['message'] = 'Error updating syn';
          });
      }).catchError((err) {
        res['code'] = -3;
        res['message'] = 'Error inserting into rel_chat_user';
      });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error inserting into $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> update(Chat chat,
      [List<int> userIds = const []]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(chat.id);
    await DBProvider.db.update(_tableName, chat.toJson()).then((resId) async {
      return RelChatUserController.updateChatUsers(chat.id, userIds)
          .then((value) async {
        res['code'] = 1;
        res['id'] = chat.id;
        return SynController.edit(_tableName, chat.id, await odooId)
            .catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
      }).catchError((err) {
        res['code'] = -3;
        res['message'] = 'Error updating rel_chat_user';
      });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error updating $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  ///No deleting yet
  static Future<Map<String, dynamic>> _delete(int id) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(id);
    await DBProvider.db
        .update(_tableName, {'id': id, 'active': 'false'}).then((value) async {
      res['code'] = 1;
      return SynController.delete(_tableName, id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
      });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error deleting from $_tableName';
    });
    return res;
  }
}
