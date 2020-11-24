import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:http/http.dart';

class Fault extends Models {
  int id;
  int odooId;
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
  // GEO
  double lat;
  double lon;
  //
  DateTime plan_fix_date;
  // create list of paths
  List<String> create;
  // List of ids to delete
  List<int> delete;

  Fault({
    this.id,
    this.odooId,
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
    this.lat,
    this.lon,
    this.plan_fix_date,
    this.create,
    this.delete,
  });

  factory Fault.fromJson(Map<String, dynamic> json) => new Fault(
        id: json["id"],
        odooId: json["odooId"],
        parent_id: json["parent_id"],
        name: getStr(json["name"]),
        desc: getStr(json["desc"]),
        fine: getObj(json["fine"]),
        fine_desc: getStr(json["fine_desc"]),
        koap_id: getObj(json["koap_id"]),
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
        date_done: json["date_done"] == null
            ? null
            : DateTime.parse(json["date_done"]),
        desc_done: getStr(json["desc_done"]),
        active: (json["active"].toString() == 'true'),
        lat: getObj(json["lat"]),
        lon: getObj(json["lon"]),
        plan_fix_date: json["plan_fix_date"] == null
            ? null
            : DateTime.parse(json["plan_fix_date"]),
        create: getObj(json["create"]),
        delete: getObj(json["delete"]),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odooId': odooId,
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
      'lat': lat,
      'lon': lon,
      'plan_fix_date': dateTimeToString(plan_fix_date),
    };
  }

  // String name; //Наименование
  // String desc; //Описание
  // DateTime date; //Дата фиксации
  // String fine_desc; //Штраф. Описание
  // int fine; //Штраф. Сумма
  // int koap_id; //cтатья КОАП

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
      'plan_fix_date': dateTimeToString(plan_fix_date),
    };
  }

  @override
  String toString() {
    return 'Fault {id: $id, odooId: $odooId, parent_id: $parent_id, name: $name, desc: $desc, fine: $fine, koap_id: $koap_id}';
  }
}