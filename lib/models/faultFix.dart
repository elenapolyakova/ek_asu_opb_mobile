import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class FaultFix extends Models {
  // Model for control of execution of
  int id;
  int odoo_id;
  // id of Fault
  int parent_id;
  // fault fix text description
  String desc;
  DateTime date;
  // state
  bool is_finished;
  bool active;

  FaultFix({
    this.id,
    this.odoo_id,
    this.parent_id,
    this.date,
    this.desc,
    this.active,
    this.is_finished,
  });

  factory FaultFix.fromJson(Map<String, dynamic> json) => new FaultFix(
      id: json["id"],
      odoo_id: json["odoo_id"],
      parent_id: json["parent_id"],
      active: (json["active"].toString() == 'true'),
      is_finished: (json["is_finished"].toString() == 'true'),
      date: json["date"] == null ? null : DateTime.parse(json["date"]),
      desc: json["desc"]);

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odoo_id,
      'parent_id': parent_id,
      'active': (active == null || !active) ? 'false' : 'true',
      'is_finished': (is_finished == null || !is_finished) ? 'false' : 'true',
      'desc': desc,
      'date': dateTimeToString(date),
    };
    if (omitId) {
      res.remove("id");
      res.remove("odoo_id");
    }
    return res;
  }

  // Make json suitable for update() in local DB;
  // Set only params that can be updated
  // Params can be extended!
  Map<String, dynamic> prepareForUpdate() {
    return {
      'id': id,
      'desc': desc,
      'date': dateTimeToString(date),
      'is_finished': (is_finished == null || !is_finished) ? 'false' : 'true',
    };
  }

  @override
  String toString() {
    return 'FaultFix {id: $id, odooId: $odoo_id, parent_id: $parent_id, active: $active }';
  }
}
