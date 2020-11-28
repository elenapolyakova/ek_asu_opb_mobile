import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import 'package:ek_asu_opb_mobile/models/nciDocument.dart';

class DocumentListController extends Controllers {
  static String _tableName = "nci_document";

  static Future<dynamic> insert(Map<String, dynamic> json) async {
    NCIDocument nciDocument = NCIDocument.fromJson(json);

    print("NCIDocument Insert() to DB");
    print(nciDocument.toJson());
    return await DBProvider.db.insert(_tableName, nciDocument.toJson());
  }

  static Future<NCIDocument> selectById(int id) async {
    if (id == null) return null;
    var json = await DBProvider.db.selectById(_tableName, id);
    return NCIDocument.fromJson(json);
  }
}
