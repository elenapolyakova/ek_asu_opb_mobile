import "package:ek_asu_opb_mobile/models/models.dart";

class Syn extends Models {
  int id;
  int recordId;
  String localTableName;
  String method;
  String error;

  Syn({this.id, this.recordId, this.localTableName, this.method, this.error});

  factory Syn.fromJson(Map<String, dynamic> json) {
    Syn res = new Syn(
      id: json["id"],
      recordId: json["record_id"],
      localTableName: json["local_table_name"],
      method: json["method"],
      error: json["error"],
    );
    return res;
  }

  Map<String, dynamic> toJson() {
    Map res = {
      'id': id,
      'record_id': recordId,
      'local_table_name': localTableName,
      'method': method,
      'error': error,
    };
    return res;
  }

  @override
  String toString() {
    return 'Syn{record_id: $recordId, local_table_name: $localTableName, method: $method${error != null ? (", error: " + error) : ""}}';
  }
}
