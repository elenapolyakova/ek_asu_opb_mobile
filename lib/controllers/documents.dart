import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class DocumentsController extends Controllers {
  static Future<Map<String, dynamic>> getJson(int departmentId) async {
    if (departmentId == null) return null;
    List<dynamic> json =
        await getDataWithAttemp('eco.department', 'search_read', [
      [
        ['id', '=', departmentId]
      ],
      [
        'f_docs_data_json',
      ]
    ], {});
    if (json.length == 0) return null;
    print(json.single);
    return json.single as Map<String, dynamic>;
  }
}
