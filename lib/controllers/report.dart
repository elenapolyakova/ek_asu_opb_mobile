import 'dart:io';

import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/models/departmentDocument.dart';
import 'package:ek_asu_opb_mobile/src/fileStorage.dart';
import "dart:convert";
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;

import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/utils/network.dart';
import 'package:path_provider/path_provider.dart';

class ReportController extends Controllers {
  // static Future<File> getLocalDocument(Document document) async {
  //   String path = document.filePath;
  //   if (path == null || !(await File(path).exists())) {
  //     Map<String, dynamic> record = await downloadDocument(document);
  //     String appPath = (await getApplicationDocumentsDirectory()).path;
  //     String newPath =
  //         "$appPath/depDocs/${DateTime.now().toUtc().millisecondsSinceEpoch}/${record['file_name']}";
  //     while (await File(newPath).exists()) {
  //       newPath =
  //           "$appPath/depDocs/${DateTime.now().toUtc().millisecondsSinceEpoch}/${record['file_name']}";
  //     }
  //     path = newPath;
  //     await DBProvider.db
  //         .update(_tableName, {'id': document.id, 'file_path': path});
  //     await File(path).create(recursive: true);
  //     return base64ToFile(
  //       record['data'],
  //       path: path,
  //     );
  //   }
  //   return File(path);
  // }

  static Future<List> downloadDocument() async {
    // String url =
    //     "$baseURL/web/content?model=${document.model}&field=data&id=${document.fileId}&filename_field=file_name&download=true";
    // var client = (await OdooProxy.odooClient.client).httpClient;
    // var session = await OdooProxy.odooClient.session;
    // final response =
    //     await client.get(url, headers: {'Cookie': 'session_id=' + session.id});
    // return response.bodyBytes;
    final List response =
        await getDataWithAttemp('ir.actions.report.xml', 'search_read', [
      [
        ['model', '=', SynController.localRemoteTableNameMap['plan']]
      ],
      ['name', 'report_name']
    ], {});
    return response;
  }

  // static Future<List<String>> getSectionList(int departmentId) async {
  //   List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
  //     _tableName,
  //     columns: ['section'],
  //     where: "department_id = ?",
  //     whereArgs: [departmentId],
  //   );
  //   return queryRes.map((e) => e['section'] as String).toList();
  // }
}
