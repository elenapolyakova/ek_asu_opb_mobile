import "dart:convert";
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

/*Department departmentFromJson(String str) {
  final jsonData = json.decode(str);
  return Department.fromJson(jsonData);
}

String departmantToJson(Department data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}*/

class Department extends Models {
  int id;
  String name;
  String short_name;
  int railway_id;
  int parent_id;
  bool active;

  Department(
      {this.id,
      this.name,
      this.short_name,
      this.railway_id,
      this.parent_id,
      this.active});

  factory Department.fromJson(Map<String, dynamic> json) => new Department(
      id: json["id"],
      name: getStr(json["name"]),
      short_name: getStr(json["short_name"]),
      railway_id: json["rel_railway_id"] != null ? getIdFromList(json["rel_railway_id"]) : json["railway_id"],
      parent_id: getIdFromList(json["parent_id"]),
      active: (json["active"].toString() == 'true'));

 

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': short_name,
      'railway_id': railway_id,
      'parent_id': parent_id,
      'active':  (active == null || !active) ? 'false' : 'true',
      'search_field':
          name.trim().toLowerCase() +' '+ short_name.trim().toLowerCase()
    };
  }

  @override
  String toString() {
    return 'Department{id: $id, name: $name, short_name: $short_name }';
  }
}
