// import "package:ek_asu_opb_mobile/controllers/controllers.dart";
// import 'package:ek_asu_opb_mobile/models/checkListTemplate.dart';
// import "package:ek_asu_opb_mobile/models/models.dart";
// import "package:ek_asu_opb_mobile/src/exchangeData.dart";
// import "package:ek_asu_opb_mobile/utils/convert.dart";
// import "package:ek_asu_opb_mobile/controllers/syn.dart";

// class CListTemplateController extends Controllers {
//   static String _tableName = "clist_template";
//   static Future<dynamic> insert(Map<String, dynamic> json) async {
//     CListTemplate clist = CListTemplate.fromJson(json);

//     return await DBProvider.db.insert(_tableName, clist.toJson());
//   }

//   static Future<List<Map<String, dynamic>>> selectAll() async {
//     return await DBProvider.db.selectAll(_tableName);
//   }
// }
// //
