import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/nci.dart';

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
}
