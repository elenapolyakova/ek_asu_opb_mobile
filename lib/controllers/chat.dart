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
    List<int> groupIds = (await ComGroupController.selectAll())
        .map((e) => e['odoo_id'] as int)
        .toList();

    List<String> fields = [
      'name',
      'group_id',
      'type',
      'user_ids',
      'write_date',
    ];
    List domain;
    if (clean) {
      domain = [];
      await DBProvider.db.deleteAll(_tableName);
    } else {
      domain = await getLastSyncDateDomain(_tableName, excludeActive: true);
    }
    domain += [
      '|',
      ['group_id', 'in', groupIds],
      ['group_id', '=', false],
    ];
    List<dynamic> json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName], 'search_read', [
      domain,
      fields
    ], {
      'limit': limit,
      'offset': offset,
      'context': {'create_or_update': true}
    });
    await Future.forEach(json, (e) async {
      Chat chat = await selectByOdooId(e['id']);
      int groupId = (await ComGroupController.selectByOdooId(
              unpackListId(e['group_id'])['id']))
          ?.id;
      List userIds = e.remove('user_ids');
      Map<String, dynamic> res = {
        ...e,
        'odoo_id': e['id'],
        'group_id': groupId,
      };
      if (chat != null) {
        res['id'] = chat.id;
        res['last_read'] = dateTimeToString(chat.lastRead, true);
        await DBProvider.db.update(_tableName, Chat.fromJson(res).toJson());
      } else {
        chat = Chat(
            id: await DBProvider.db
                .insert(_tableName, Chat.fromJson(res).toJson()));
      }
      await RelChatUserController.updateChatUsers(
        chat.id,
        List<int>.from(
            userIds.map((userId) => unpackListId(userId)['id'] as int)),
      );
    });
    print('loaded ${json.length} records of $_tableName');
    await setLatestWriteDate(_tableName, json);
  }

  ///Download **new** `Chat`s and `Message`s.
  ///
  ///Return Map of **every** Chat and its **new** messages' count,
  ///excluding specified user's messages.
  static Future<Map<Chat, int>> getNewMessages(int userId) async {
    await loadFromOdoo();
    await ChatMessageController.loadFromOdoo();
    List<Chat> chats = await select();
    Map<Chat, int> res = {};
    await Future.forEach(chats, (Chat chat) async {
      res[chat] = await ChatMessageController.getNewMessagesCount(
        chat.id,
        userId,
        chat.lastRead,
      );
    });
    return res;
  }

  /// Select all records by provided parameters.
  /// Without any parameters return all records.
  /// Returns a List of records.
  static Future<List<Chat>> select({int groupId, int id}) async {
    // if (chat is int) chat = await ChatController.selectById(chat);
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
