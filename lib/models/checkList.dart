import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckList extends Models {
  int id;
  int odooId;
  // Plan id which uses this check list
  int parent_id;
  bool is_base = false;
  String name;
  List child_ids;
  int type;
  bool active = true;
  // Status of check list, true in work, false not used now
  bool is_active = false;

  CheckList({
    this.id,
    this.odooId,
    this.parent_id,
    this.is_base,
    this.name,
    this.is_active,
    this.child_ids,
    this.type,
    this.active,
  });

  factory CheckList.fromJson(Map<String, dynamic> json) => new CheckList(
        id: json["id"],
        odooId: json["odooId"],
        parent_id: json["parent_id"],
        is_base: json["is_base"],
        name: getStr(json["name"]),
        is_active: getObj(json["is_active"]),
        type: getObj(json["type"]),
        child_ids: getObj(json["child_ids"]),
        active: (json["active"].toString() == 'true'),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odooId': odooId,
      'parent_id': parent_id,
      'name': name,
      'type': type,
      'active': (active == null || !active) ? 'false' : 'true',
      'is_base': (is_base == null || !is_base) ? 'false' : 'true',
      'child_ids': child_ids,
      'is_active': (is_active == null || !is_active) ? 'false' : 'true',
    };
  }
}
