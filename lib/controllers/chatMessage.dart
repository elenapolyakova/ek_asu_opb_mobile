import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/controllers/syn.dart";
import 'package:ek_asu_opb_mobile/models/chat.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class ChatMessageController extends Controllers {
  static String _tableName = "chat_message";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
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

  static Future finishSync(dateTime) {
    return setLastSyncDateForDomain(_tableName, dateTime);
  }

  /// Select all messages with matching chatId.
  /// Returns a List of records.
  static Future<List<ChatMessage>> select(int chatId) async {
    if (chatId == null) {
      return [];
    }
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ?",
      whereArgs: [chatId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    List<ChatMessage> chatMessages =
        queryRes.map((e) => ChatMessage.fromJson(e)).toList();
    return chatMessages;
  }

  ///Load message count of a chat from server.
  ///This will update chat's lastUpdate.
  ///Chat can be either int or Chat.
  ///Returns message count or null.
  static Future<int> newMessagesFromOdooCount(dynamic chat) async {
    if (chat is int) chat = await ChatController.selectById(chat);
    if (chat == null || chat.id == null) return null;
    List domain = [
      ['parent_id', '=', chat.id],
    ];
    String datetime = dateTimeToString(toServerTime(chat.lastUpdate), true);
    if (datetime != null) {
      domain.add(['write_date', '>', datetime]);
    }
    await DBProvider.db.update('chat',
        {'id': chat.id, 'last_update': dateTimeToString(DateTime.now(), true)});
    // chat.lastUpdate = DateTime.now();
    // ChatController.update(chat);
    var json = await getDataWithAttemp(
        SynController.localRemoteTableNameMap[_tableName],
        'search_count',
        [domain],
        {});
    return int.tryParse(json.toString());
  }

  ///Load message count of a chat.
  ///This will update chat's lastRead.
  ///Chat can be either int or Chat.
  ///Returns message count or null.
  static Future<int> newMessagesCount(dynamic chat, int userId) async {
    if (chat is int) chat = await ChatController.selectById(chat);
    if (chat == null || chat.id == null) return null;
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['id'] + (chat.lastRead != null ? ['create_date'] : []),
      where: "parent_id = ? and create_uid != ?",
      whereArgs: [chat.id, userId],
    );
    if (chat.lastRead != null) {
      queryRes = queryRes
          .where((element) =>
              stringToDateTime(element['create_date']).isAfter(chat.lastRead))
          .toList();
    }
    await DBProvider.db.update('chat',
        {'id': chat.id, 'last_read': dateTimeToString(DateTime.now(), true)});
    // chat.lastRead = DateTime.now();
    // await ChatController.update(chat);
    return queryRes.length;
  }

  ///Load messages of a chat from specified date.
  ///Chat can be either int or Chat.
  ///If count is false (default) returns List<ChatMessage>.
  ///If count is true, returns message count.
  static Future newMessagesFromDate(dynamic chat, int userId, DateTime dateTime,
      {bool count: false}) async {
    if (chat is int) chat = await ChatController.selectById(chat);
    if (chat == null || chat.id == null) return null;
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id = ?" + (count ? ' and create_uid != ?' : ''),
      whereArgs: [chat.id] + (count ? [userId] : []),
    );
    if (dateTime != null) {
      queryRes = queryRes
          .where((element) =>
              stringToDateTime(element['create_date']).isAfter(dateTime))
          .toList();
    }
    // chat.lastRead = DateTime.now();
    // await ChatController.update(chat);
    if (count)
      return queryRes.length;
    else
      return queryRes.map((e) => ChatMessage.fromJson(e)).toList();
  }

  static loadFromOdoo({bool clean: false, int limit, int offset}) async {
    List<String> fields = [
      'parent_id',
      'msg',
      'create_date',
      'create_uid',
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
      int chatMessageId = (await selectByOdooId(e['id']))?.id;
      int parentId = (await ChatController.selectByOdooId(
              unpackListId(e['parent_id'])['id']))
          ?.id;
      Map<String, dynamic> res = {
        ...e,
        'parent_id': parentId,
      };
      if (chatMessageId != null) {
        res['id'] = chatMessageId;
        await DBProvider.db
            .update(_tableName, ChatMessage.fromJson(res).toJson());
      } else {
        res['odoo_id'] = e['id'];
        await DBProvider.db
            .insert(_tableName, ChatMessage.fromJson(res).toJson());
      }
    });
    print('loaded ${json.length} records of $_tableName');
    await setLastSyncDateForDomain(_tableName, DateTime.now());
    return result;
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
    await DBProvider.db
        .update(_tableName, chatMessage.toJson())
        .then((resId) async {
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
