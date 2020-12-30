import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'package:ek_asu_opb_mobile/models/chat.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class ChatMessageController extends Controllers {
  static const String _tableName = "chat_message";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  /// Get count of new messages of specified `Chat`.
  static Future<int> getNewMessagesCount(
      dynamic chat, int userId, DateTime lastRead) async {
    if (chat is Chat) chat = chat.id;
    if (chat == null) return null;
    List queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['id'] + (lastRead == null ? [] : ['create_date']),
      where: 'parent_id = ? and create_uid != ?',
      whereArgs: [chat, userId],
    );
    if (lastRead != null) {
      queryRes = queryRes.where((element) {
        if (element['create_date'] != null) {
          return stringToDateTime(element['create_date']).isAfter(lastRead);
        } else
          return true;
      }).toList();
    }
    return queryRes.length;
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<ChatMessage> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return ChatMessage.fromJson(json);
  }

  static Future<ChatMessage> selectByOdooId(int odooId) async {
    if (odooId == null) return null;
    var json = await DBProvider.db
        .select(_tableName, where: "odoo_id = ?", whereArgs: [odooId]);
    if (json == null || json.isEmpty) return null;
    return ChatMessage.fromJson(json[0]);
  }

  static Future<int> selectOdooId(int id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(_tableName,
        columns: ['odoo_id'], where: "id = ?", whereArgs: [id]);
    if (queryRes == null || queryRes.length == 0)
      throw 'No record of table $_tableName with id=$id exist.';
    return queryRes[0]['odoo_id'];
  }

  /// Select all messages of specified `Chat` (can be `int`).
  ///
  /// If `fromLastRead` is true,
  /// records only after `chat`'s `last_read` are returned.
  /// Else all records of specified chat are returned.
  static Future<List<ChatMessage>> select(dynamic chat) async {
    if (chat is int) chat = ChatController.selectById(chat);
    if (chat == null || chat.id == null) {
      return [];
    }
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ?",
      whereArgs: [chat.id],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<ChatMessage> chatMessages =
        queryRes.map((e) => ChatMessage.fromJson(e)).toList();
    return chatMessages;
  }

  static loadFromOdoo({bool clean: false, int limit, int offset}) async {
    List<String> fields = [
      'parent_id',
      'msg',
      'create_date',
      'create_uid',
      'write_date',
    ];
    List domain;
    if (clean) {
      domain = [];
      await DBProvider.db.deleteAll(_tableName);
    } else {
      domain = await getLastSyncDateDomain(_tableName, excludeActive: true);
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
    await Future.forEach(json, (e) async {
      ChatMessage chatMessage = await selectByOdooId(e['id']);
      int parentId = (await ChatController.selectByOdooId(
              unpackListId(e['parent_id'])['id']))
          ?.id;
      Map<String, dynamic> res = {
        ...e,
        'odoo_id': e['id'],
        'parent_id': parentId,
      };
      if (chatMessage?.id != null) {
        res['id'] = chatMessage.id;
        await DBProvider.db
            .update(_tableName, ChatMessage.fromJson(res).toJson());
      } else {
        res['odoo_id'] = e['id'];
        await DBProvider.db
            .insert(_tableName, ChatMessage.fromJson(res).toJson());
      }
    });
    print('loaded ${json.length} records of $_tableName');
    await setLatestWriteDate(_tableName, json);
  }

  static Future<Map<String, dynamic>> insert(ChatMessage chatMessage,
      [bool saveOdooId = false]) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> json = chatMessage.toJson(!saveOdooId);
    if (saveOdooId) json.remove('id');
    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
      if (!saveOdooId)
        return SynController.create(_tableName, resId).catchError((err) {
          res['code'] = -2;
          res['message'] = 'Error updating syn';
        });
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error inserting into $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> update(ChatMessage chatMessage) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Future<int> odooId = selectOdooId(chatMessage.id);
    var chatMessageJson = chatMessage.toJson();
    chatMessageJson.remove('odoo_id');
    await DBProvider.db
        .update(_tableName, chatMessageJson)
        .then((rowsAffected) async {
      res['code'] = 1;
      res['id'] = chatMessage.id;
      return SynController.edit(_tableName, chatMessage.id, await odooId)
          .catchError((err) {
        res['code'] = -2;
        res['message'] = 'Error updating syn';
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
