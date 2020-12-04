import 'dart:async';
import 'dart:io';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/models/ispDocument.dart';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:ek_asu_opb_mobile/src/exchangeData.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ek_asu_opb_mobile/src/fileStorage.dart';

class ISPDocumentController extends Controllers {
  static String _tableName = "isp_document";

  static final String baseURL =
      '${config.getItem('ServiceRootUrl')}:${config.getItem('port')}';
  static String documentModel = 'mob.document';

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

    List<ISPDocument> ispDocs =
        queryRes.map((e) => ISPDocument.fromJson(e)).toList();

    var res = await setIsNewFalse(parent2Id);
    print("Updates is_new state $res");

    return ispDocs;
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

  static Future<Map<String, dynamic>> downloadDocument(
      ISPDocument document) async {
    final response = await getDataWithAttemp(documentModel, 'search_read', [
      [
        ['id', '=', document.id]
      ],
      [
        'file_data',
        'file_name',
      ]
    ], {});
    return response[0];
  }

  static Future<File> getLocalDocument(ISPDocument document) async {
    String path = document.file_path;
    if (path == null || !(await File(path).exists())) {
      Map<String, dynamic> record = await downloadDocument(document);
      String appPath = (await getApplicationDocumentsDirectory()).path;
      String newPath =
          "$appPath/ispDocs/${DateTime.now().toUtc().millisecondsSinceEpoch}/${record['file_name']}";
      while (await File(newPath).exists()) {
        newPath =
            "$appPath/ispDocs/${DateTime.now().toUtc().millisecondsSinceEpoch}/${record['file_name']}";
      }
      path = newPath;
      await DBProvider.db
          .update(_tableName, {'id': document.id, 'file_path': path});
      await File(path).create(recursive: true);
      return base64ToFile(
        record['file_data'],
        path: path,
      );
    }
    return File(path);
  }
}
