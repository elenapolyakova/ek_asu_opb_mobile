import 'dart:io';

import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/src/fileStorage.dart';
import 'package:path_provider/path_provider.dart';

class ReportController extends Controllers {
  /// Скачать предустановленный на сервере отчёт.
  ///
  /// Параметры
  /// --------
  /// `recordOdooId`: odooId записи, для которой нужно скачать отчёт.
  /// Можно использовать `XXXXController.selectOdooId(localDbId)`.
  ///
  /// `reportXmlId`: Строка `XXXXController.XXXReportXmlId`
  static Future downloadReport(int recordOdooId, String reportXmlId) async {
    String appPath = (await getApplicationDocumentsDirectory()).path;
    final response = await getData(
        SynController.localRemoteTableNameMap['plan'], 'download_report', [
      [recordOdooId],
      reportXmlId,
    ], {});
    try {
      Map reportData = response['report_data'];
      String newPath =
          "$appPath/reports/${DateTime.now().toUtc().millisecondsSinceEpoch}/${reportData['file_name']}";
      while (await File(newPath).exists()) {
        newPath =
            "$appPath/reports/${DateTime.now().toUtc().millisecondsSinceEpoch}/${reportData['file_name']}";
      }
      await File(newPath).create(recursive: true);
      File file = await base64ToFile(
        reportData['file_data'].replaceAll("\n", ''),
        path: newPath,
      );
      return file;
    } catch (e) {
      print("While downloading report, Exception was thrown: $e");
      return null;
    }
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
