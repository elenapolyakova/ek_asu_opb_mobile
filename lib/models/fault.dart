import 'package:ek_asu_opb_mobile/controllers/faultFix.dart';
import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class Fault extends Models {
  int id;
  int odoo_id;
  // Id of checkListItem
  int parent_id;
  String name;
  String desc;
  String fine_desc;
  int fine;
  int koap_id;
  DateTime date;
  DateTime date_done;
  String desc_done;
  // used or not
  bool active;
  // // GEO
  // double lat;
  // double lon;
  // //
  DateTime plan_fix_date;

  Fault({
    this.id,
    this.odoo_id,
    this.parent_id,
    this.name,
    this.desc,
    this.fine_desc,
    this.fine,
    this.koap_id,
    this.date,
    this.date_done,
    this.desc_done,
    this.active,
    // this.lat,
    // this.lon,
    this.plan_fix_date,
  });

  Future<DateTime> get getLastFixDate async {
    if (id != null) {
      return FaultFixController.getMaxFixDate(id);
    }
    return null;
  }

  factory Fault.fromJson(Map<String, dynamic> json) => new Fault(
        id: json["id"],
        odoo_id: json["odoo_id"],
        parent_id: unpackListId(json["parent_id"])['id'],
        name: getObj(json["name"]),
        desc: getObj(json["desc"]),
        fine: getObj(json["fine"]),
        fine_desc: getObj(json["fine_desc"]),
        koap_id: getObj(json["koap_id"]),
        date: stringToDateTime(json["date"], forceUtc: false),
        date_done: stringToDateTime(json["date_done"], forceUtc: false),
        desc_done: getObj(json["desc_done"]),
        active: json["active"].toString() == 'true',
        plan_fix_date: stringToDateTime(json["plan_fix_date"], forceUtc: false),
      );

  Map<String, dynamic> toJson([omitId = false]) {
    return {
      'id': id,
      'odoo_id': odoo_id,
      'parent_id': parent_id,
      'name': name,
      'desc': desc,
      'fine': fine,
      'fine_desc': fine_desc,
      'koap_id': koap_id,
      'date': dateTimeToString(date),
      'date_done': dateTimeToString(date_done),
      'desc_done': desc_done,
      'active': (active == null || !active) ? 'false' : 'true',
      'plan_fix_date': dateTimeToString(plan_fix_date),
    };
  }

  // Make json suitable for update() in local DB;
  // Set only params that can be updated
  // Params can be extended!
  Map<String, dynamic> prepareForUpdate() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'date': dateTimeToString(date),
      'fine_desc': fine_desc,
      'fine': fine,
      'koap_id': koap_id,
      'date_done': dateTimeToString(date_done),
      'plan_fix_date': dateTimeToString(plan_fix_date),
    };
  }

  @override
  String toString() {
    return 'Fault {id: $id, odooId: $odoo_id, parent_id: $parent_id, name: $name, desc: $desc, fine: $fine, fine_desc: $fine_desc, koap_id: $koap_id, plan_fix_date:$plan_fix_date}';
  }
}
