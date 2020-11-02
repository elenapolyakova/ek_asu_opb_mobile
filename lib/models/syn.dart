import "dart:convert";
import 'package:ek_asu_opb_mobile/controllers/railway.dart'
    as railwayController;
import 'package:ek_asu_opb_mobile/controllers/user.dart' as userController;
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class Syn extends Models {
  int id;
  int recordId;
  String localTableName;
  String method;

  Syn({this.id, this.recordId, this.localTableName, this.method});

  factory Syn.fromJson(Map<String, dynamic> json) {
    Syn res = new Syn(
      id: json["id"],
      recordId: json["record_id"],
      localTableName: json["local_table_name"],
      method: json["method"],
    );
    return res;
  }

  Map<String, dynamic> toJson() {
    Map res = {
      'id': id,
      'record_id': recordId,
      'local_table_name': localTableName,
      'method': method,
    };
    return res;
  }

  @override
  String toString() {
    return 'Syn{record_id: $recordId, local_table_name: $localTableName, method: $method}';
  }
}
