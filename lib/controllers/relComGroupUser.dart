import 'package:ek_asu_opb_mobile/controllers/comGroup.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/comGroup.dart';
import 'package:ek_asu_opb_mobile/models/models.dart';

class RelComGroupUserController extends Controllers {
  static const String _tableName = "rel_com_group_user";

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

  /// Select ComGroup records by provided userId.
  /// Returns selected records or an empty list.
  static Future<List<ComGroup>> selectByUserId(int userId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['com_group_id'],
      where: "user_id = ?", // and active = 'true'",
      whereArgs: [userId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    return ComGroupController.selectByIds(
        queryRes.map((e) => e['com_group_id']).toList());
  }

  /// Select User records by provided comGroupId.
  /// Returns selected records or an empty list.
  static Future<List<User>> selectByComGroupId(int comGroupId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['user_id'],
      where: "com_group_id = ?", // and active = 'true'",
      whereArgs: [comGroupId],
    );
    if (queryRes == null || queryRes.length == 0) return [];
    var res = await UserController.selectByIds(
        queryRes.map((e) => e['user_id'] as int).toList());
    return res;
  }

  static Future insertByComGroupId(int comGroupId, List<int> userIds) async {
    var batch = await DBProvider.db.batch;
    userIds.forEach((int userId) {
      batch.insert(_tableName, {
        'user_id': userId,
        'com_group_id': comGroupId,
      });
    });
    return batch.commit(noResult: true);
  }

  /// Find a ComGroup record with provided comGroupId.
  /// Update its users with provided newUserIds.
  static Future updateComGroupUsers(
      int comGroupId, List<int> newUserIds) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['user_id', 'id'],
      where: "com_group_id = ?",
      whereArgs: [comGroupId],
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
        'com_group_id': comGroupId,
      });
    });
    return batch.commit(noResult: true);
  }
}
