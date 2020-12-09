import 'dart:io';

import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";
import 'package:ek_asu_opb_mobile/models/departmentDocument.dart';
import 'package:ek_asu_opb_mobile/src/fileStorage.dart';
import "dart:convert";
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;

import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/utils/network.dart';
import 'package:path_provider/path_provider.dart';

class DepartmentDocumentController extends Controllers {
  static final String baseURL =
      '${config.getItem('ServiceRootUrl')}:${config.getItem('port')}';
  static const String _tableName = "department_document";

  static Future firstLoadFromOdoo([int limit]) async {
    List<int> departmentIds = await DepartmentController.selectIDs();
    List queryRes = await getDataWithAttemp('eco.department', 'search_read', [
      [
        ['id', 'in', departmentIds]
      ],
      [
        'f_docs_data_json',
      ]
    ], {});
    if (queryRes.length == 0) return null;
    var result = await Future.forEach(await getDocuments(queryRes), (doc) {
      return insert(doc);
    });
    print("loaded ${queryRes.length} records of $_tableName");
    return result;
  }

  static Future<List<Document>> getDocuments(List queryRes) async {
    List<Document> documents = [];
    await Future.forEach(queryRes, (department) async {
      await Future.forEach(
          (json.decode(department['f_docs_data_json'])).entries,
          (section) async {
        await Future.forEach(section.value.entries, (model) async {
          Map<String, dynamic> docData = {};
          await Future.forEach(model.value[model.value['fn_data']], (dataItem) {
            docData['section'] = section.key;
            docData['model'] = model.key;
            docData['file_name'] = dataItem[0];
            docData['file_id'] = dataItem[1];
            docData['department_id'] = department['id'];
          });
          documents.add(Document.fromJson(docData));
        });
      });
    });
    return documents;
  }

  static Future<File> getLocalDocument(Document document) async {
    String path = document.filePath;
    if (path == null || !(await File(path).exists())) {
      Map<String, dynamic> record = await downloadDocument(document);
      String appPath = (await getApplicationDocumentsDirectory()).path;
      String newPath =
          "$appPath/depDocs/${DateTime.now().toUtc().millisecondsSinceEpoch}/${record['file_name']}";
      while (await File(newPath).exists()) {
        newPath =
            "$appPath/depDocs/${DateTime.now().toUtc().millisecondsSinceEpoch}/${record['file_name']}";
      }
      path = newPath;
      await DBProvider.db
          .update(_tableName, {'id': document.id, 'file_path': path});
      await File(path).create(recursive: true);
      return base64ToFile(
        record['data'],
        path: path,
      );
    }
    return File(path);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static Future<Map<String, dynamic>> downloadDocument(
      Document document) async {
    // String url =
    //     "$baseURL/web/content?model=${document.model}&field=data&id=${document.fileId}&filename_field=file_name&download=true";
    // var client = (await OdooProxy.odooClient.client).httpClient;
    // var session = await OdooProxy.odooClient.session;
    // final response =
    //     await client.get(url, headers: {'Cookie': 'session_id=' + session.id});
    // return response.bodyBytes;
    final response = await getDataWithAttemp(document.model, 'search_read', [
      [
        ['id', '=', document.fileId]
      ],
      [
        'data',
        'file_name',
      ]
    ], {});
    return response[0];
  }

  static Future<List<Document>> select(
    int departmentId, {
    String section,
    bool fromServer = false,
  }) async {
    List<Document> res = [];
    if (departmentId == null) return res;

    if (fromServer && await ping()) {
      List queryRes = await getDataWithAttemp('eco.department', 'search_read', [
        [
          ['id', '=', departmentId]
        ],
        [
          'f_docs_data_json',
        ]
      ], {});
      if (queryRes.length == 0) return [];
      await update(await getDocuments(queryRes), departmentId);
      return select(departmentId, section: section);
    }

    if (section == null) {
      List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
        _tableName,
        where: "department_id = ?",
        whereArgs: [departmentId],
      );
      res = queryRes.map((e) => Document.fromJson(e)).toList();
    } else {
      List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
        _tableName,
        where: "department_id = ? and section = ?",
        whereArgs: [departmentId, section],
      );
      res = queryRes.map((e) => Document.fromJson(e)).toList();
    }
    return res;
  }

  static Future<List<String>> getSectionList(int departmentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['section'],
      where: "department_id = ?",
      whereArgs: [departmentId],
    );
    return queryRes.map((e) => e['section'] as String).toList();
  }

  static Future<Map<String, dynamic>> insert(Document document) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    Map<String, dynamic> json = document.toJson(true);
    await DBProvider.db.insert(_tableName, json).then((resId) {
      res['code'] = 1;
      res['id'] = resId;
    }).catchError((err) {
      res['code'] = -3;
      res['message'] = 'Error inserting into $_tableName';
    });
    DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> update(
      List<Document> documents, int departmentId) async {
    Map<String, dynamic> res = {
      'code': null,
      'message': null,
      'id': null,
    };
    List<Document> newDocuments = List<Document>.from(documents);
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      columns: ['id', 'section', 'model', 'file_name', 'file_id'],
      where: "department_id = ?",
      whereArgs: [departmentId],
    );
    List<int> toDelete = [];
    // добавляем ID элементов, которые надо удалить
    queryRes.forEach((queryItem) {
      if (!newDocuments.any((newDoc) {
        return queryItem['section'] == newDoc.section &&
            queryItem['model'] == newDoc.model &&
            queryItem['file_name'] == newDoc.fileName &&
            queryItem['file_id'] == newDoc.fileId;
      })) {
        toDelete.add(queryItem['id']);
      }
    });
    // удаляем из нового списка документов элементы, которые уже есть в БД
    newDocuments.removeWhere((newDoc) => queryRes.any((queryItem) =>
        queryItem['section'] == newDoc.section &&
        queryItem['model'] == newDoc.model &&
        queryItem['file_name'] == newDoc.fileName &&
        queryItem['file_id'] == newDoc.fileId));
    await Future.forEach(toDelete, (int toDeleteId) {
      return DBProvider.db.delete(_tableName, toDeleteId);
    });
    await Future.forEach(newDocuments, (Document docToInsert) {
      return insert(docToInsert);
    });
    // await DBProvider.db
    //     .update(_tableName, document.toJson())
    //     .then((resId) async {
    //   res['code'] = 1;
    //   res['id'] = resId;
    // }).catchError((err) {
    //   res['code'] = -3;
    //   res['message'] = 'Error updating $_tableName';
    // });
    // DBProvider.db.insert('log', {'date': nowStr(), 'message': res.toString()});
    return res;
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    //   Map<String, dynamic> res = {
    //     'code': null,
    //     'message': null,
    //     'id': null,
    //   };
    //   Future<int> odooId = selectOdooId(id);
    //   await DBProvider.db
    //       .update(_tableName, {'id': id, 'active': 'false'}).then((value) async {
    //     res['code'] = 1;
    //     return SynController.delete(_tableName, id, await odooId)
    //         .catchError((err) {
    //       res['code'] = -2;
    //       res['message'] = 'Error updating syn';
    //     });
    //   }).catchError((err) {
    //     res['code'] = -3;
    //     res['message'] = 'Error deleting from $_tableName';
    //   });
    //   return res;
  }
}
