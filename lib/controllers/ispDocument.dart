import 'dart:async';

import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/ispDocument.dart';

class ISPDocumentController extends Controllers {
  static String _tableName = "isp_document";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    ISPDocument nciDocument = ISPDocument.fromJson(json);

    print("NCIDocument Insert() to DB");
    print(nciDocument.toJson());
    return await DBProvider.db.insert(_tableName, nciDocument.toJson());
  }

  static Future<List<ISPDocument>> select(int parent2Id) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent2_id = ?",
      whereArgs: [parent2Id],
    );

    if (queryRes == null || queryRes.length == 0) return [];

    List<ISPDocument> nciDocs =
        queryRes.map((e) => ISPDocument.fromJson(e)).toList();

    var res = await setIsNewFalse(parent2Id);
    print("Updates is_new state $res");

    return nciDocs;
  }

  static Future<Map<String, dynamic>> setIsNewFalse(int parent2Id) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };

    try {
      await DBProvider.db.executeQuery(
          "UPDATE $_tableName SET is_new = 'false' WHERE parent2_id=$parent2Id");

      res['code'] = 1;
    } catch (e) {
      print("setIsNewFalse Error: $e");
      res['code'] = -3;
      res['message'] = 'Ошибка при обновлении статуса документа';
      res['id'] = null;
    }

    return res;
  }
}
