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
  String inn;
  String ogrn;
  String okpo;
  String addr;
  String director_fio;
  String director_email;
  String director_phone;
  String deputy_fio;
  String deputy_email;
  String deputy_phone;

  Department(
      {this.id,
      this.name,
      this.short_name,
      this.railway_id,
      this.parent_id,
      this.active,
      this.inn,
      this.okpo,
      this.ogrn,
      this.addr,
      this.director_fio,
      this.director_email,
      this.director_phone,
      this.deputy_fio,
      this.deputy_email,
      this.deputy_phone});

  factory Department.fromJson(Map<String, dynamic> json) => new Department(
      id: json["id"],
      name: getStr(json["name"]),
      short_name: getStr(json["short_name"]),
      railway_id: json["rel_railway_id"] != null
          ? getIdFromList(json["rel_railway_id"])
          : json["railway_id"],
      parent_id: getIdFromList(json["parent_id"]),
      active: (json["active"].toString() == 'true'),
      inn: getObj(json["inn"]),
      ogrn: getObj(json["ogrn"]),
      okpo: getObj(json["okpo"]),
      addr: getObj(json["addr"]),
      director_fio: getObj(json["director_fio"]),
      director_email: getObj(json["director_email"]),
      director_phone: getObj(json["director_phone"]),
      deputy_fio: getObj(json["deputy_fio"]),
      deputy_email: getObj(json["deputy_email"]),
      deputy_phone: getObj(json["deputy_phone"]));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': short_name,
      'railway_id': railway_id,
      'parent_id': parent_id,
      'active': (active == null || !active) ? 'false' : 'true',
      'inn': inn,
      'ogrn': ogrn,
      'okpo': okpo,
      'addr': addr,
      'director_fio': director_fio,
      'director_email': director_email,
      'director_phone': director_phone,
      'deputy_fio': deputy_fio,
      'deputy_email': deputy_email,
      'deputy_phone': deputy_phone,
      'search_field':
          name.trim().toLowerCase() + ' ' + short_name.trim().toLowerCase()
    };
  }

  @override
  String toString() {
    return 'Department{id: $id, name: $name, short_name: $short_name, addr: $addr, inn: $inn, ogrn: $ogrn, okpo: $okpo, director_fio: $director_fio, director_phone: $director_phone, director_email: $director_email, deputy_fio: $deputy_fio, deputy_phone: $deputy_phone, deputy_email: $deputy_email }';
  }
}
