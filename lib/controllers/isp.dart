import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/isp.dart';

class DocumentListController extends Controllers {
  static String _tableName = "document_list";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    DocumentList documentList = DocumentList.fromJson(json);

    print("DocumentList Insert() to DB");
    print(documentList.toJson());
    return await DBProvider.db.insert(_tableName, documentList.toJson());
  }

  static Future<DocumentList> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return DocumentList.fromJson(json);
  }

  // Get all primary documents lists. Root elements in tree!
  static Future<List<DocumentList>> getAllRoot() async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db.select(
      _tableName,
      where: "parent_id IS NULL",
    );

    if (queryRes == null || queryRes.length == 0) return [];

    List<DocumentList> documentLists =
        queryRes.map((e) => DocumentList.fromJson(e)).toList();

    return documentLists;
  }

  // Get child documentList
  static Future<List<DocumentList>> select(int parentId) async {
    List<Map<String, dynamic>> queryRes = await DBProvider.db
        .select(_tableName, where: "parent_id = ?", whereArgs: [parentId]);

    if (queryRes == null || queryRes.length == 0) return [];

    List<DocumentList> documentLists =
        queryRes.map((e) => DocumentList.fromJson(e)).toList();

    return documentLists;
  }
}
