import "dart:convert";
import 'package:ek_asu_opb_mobile/utils/convert.dart';


Department departmentFromJson(String str) {
  final jsonData = json.decode(str);
  return Department.fromJson(jsonData);
}

String departmantToJson(Department data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Department {
  final int id;
  final String name;
  final String short_name;
  final int railway_id;

  Department({this.id, this.name, this.short_name, this.railway_id});

  factory Department.fromJson(Map<String, dynamic> json) => 
     new Department(
      id: json["id"],
      name: getStr(json["name"]),
      short_name: getStr(json["short_name"]),
      railway_id: getIdFromList(json["rel_railway_id"])
    );
  

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': short_name,
      'railway_id': railway_id
    };
  }

  @override
  String toString() {
    return 'Department{id: $id, name: $name, short_name: $short_name }';
  }
}
