import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/models.dart';

class RelChatUserController extends Controllers {
  static String _tableName = "rel_chat_user";

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return [];
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<Map<String, dynamic>> selectById(int id) async {
    if (id == null) return null;
    Map<String, dynamic> json = await DBProvider.db.selectById(_tableName, id);
    return json;
  }

  /// Select Chat records by provided userId.
  /// Returns selected records or an empty list.
  static Future<List<Chat>> selectByUserId(int userId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['chat_id'],
      where: "user_id = ?", // and active = 'true'",
      whereArgs: [userId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    return ChatController.selectByIds(
        queryRes.map((e) => e['chat_id']).toList());
  }

  /// Select User records by provided chatId.
  /// Returns selected records or an empty list.
  static Future<List<User>> selectByChatId(int chatId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['user_id'],
      where: "chat_id = ?", // and active = 'true'",
      whereArgs: [chatId],
    );
    var a = await DBProvider.db.selectAll(_tableName);
    if (queryRes == null || queryRes.length == 0) return [];
    return UserController.selectByIds(
        queryRes.map((e) => e['user_id'] as int).toList());
  }

  static Future insertByChatId(int chatId, List<int> userIds) async {
    var batch = await DBProvider.db.batch;
    userIds.forEach((int userId) {
      batch.insert(_tableName, {
        'user_id': userId,
        'chat_id': chatId,
      });
    });
    return batch.commit(noResult: true);
  }

  /// Find a Chat record with provided chatId.
  /// Update its users with provided newUserIds.
  static Future updateChatUsers(int chatId, List<int> newUserIds) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['user_id', 'id'],
      where: "chat_id = ?",
      whereArgs: [chatId],
    );
    List<int> toDelete = [];
    List<int> toInsert = [];

    queryRes.forEach((element) {
      if (!newUserIds.contains(element['user_id'])) {
        toDelete.add(element['id']);
      }
    });
    List<int> oldUserIds = queryRes.map((e) => e['user_id'] as int).toList();
    newUserIds.forEach((element) {
      if (!oldUserIds.contains(element)) {
        toInsert.add(element);
      }
    });
    var batch = await DBProvider.db.batch;
    toDelete.forEach((int userId) {
      batch.delete(
        _tableName,
        where: "id = ?",
        whereArgs: [userId],
      );
    });
    toInsert.forEach((int userId) {
      batch.insert(_tableName, {
        'user_id': userId,
        'chat_id': chatId,
      });
    });
    return batch.commit(noResult: true);
  }
}
