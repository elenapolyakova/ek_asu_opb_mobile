import "dart:convert";
import 'dart:ffi';
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
  String f_inn;
  String f_ogrn;
  String f_okpo;
  String f_addr;
  String director_fio;
  String director_email;
  String director_phone;
  String deputy_fio;
  String deputy_email;
  String deputy_phone;
  int rel_sector_id;
  String rel_sector_name;
  double f_coord_n;
  double f_coord_e;

  Department(
      {this.id,
      this.name,
      this.short_name,
      this.railway_id,
      this.parent_id,
      this.active,
      this.f_inn,
      this.f_okpo,
      this.f_addr,
      this.f_ogrn,
      this.director_fio,
      this.director_email,
      this.director_phone,
      this.deputy_fio,
      this.deputy_email,
      this.deputy_phone,
      this.rel_sector_id,
      this.rel_sector_name,
      this.f_coord_e,
      this.f_coord_n});

  factory Department.fromJson(Map<String, dynamic> json) => new Department(
      id: json["id"],
      name: getStr(json["name"]),
      short_name: getStr(json["short_name"]),
      railway_id: unpackListId(json["rel_railway_id"])['id'] ??
          unpackListId(json["railway_id"])['id'],
      parent_id: unpackListId(json["parent_id"])['id'],
      active: json["active"].toString() == 'true',
      f_inn: getObj(json["f_inn"]),
      f_ogrn: getObj(json["f_ogrn"]),
      f_okpo: getObj(json["f_okpo"]),
      f_addr: getObj(json["f_addr"]),
      director_fio: getObj(json["director_fio"]),
      director_email: getObj(json["director_email"]),
      director_phone: getObj(json["director_phone"]),
      deputy_fio: getObj(json["deputy_fio"]),
      deputy_email: getObj(json["deputy_email"]),
      deputy_phone: getObj(json["deputy_phone"]),
      rel_sector_id: unpackListId(json["rel_sector_id"])['id'],
      rel_sector_name: unpackListId(json["rel_sector_id"])['name'],
      f_coord_e: getObj(json["f_coord_e"]),
      f_coord_n: getObj(json["f_coord_n"]));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': short_name,
      'railway_id': railway_id,
      'parent_id': parent_id,
      'active': (active == null || !active) ? 'false' : 'true',
      'f_inn': f_inn,
      'f_ogrn': f_ogrn,
      'f_okpo': f_okpo,
      'f_addr': f_addr,
      'director_fio': director_fio,
      'director_email': director_email,
      'director_phone': director_phone,
      'deputy_fio': deputy_fio,
      'deputy_email': deputy_email,
      'deputy_phone': deputy_phone,
      'rel_sector_id': rel_sector_id,
      'rel_sector_name': rel_sector_name,
      'f_coord_e': f_coord_e,
      'f_coord_n': f_coord_n,
      'search_field':
          name.trim().toLowerCase() + ' ' + short_name.trim().toLowerCase()
    };
  }

  // Make json suitable for update() in local DB
  Map<String, dynamic> prepareForUpdate() {
    return {
      'id': id,
      'f_inn': f_inn,
      'f_ogrn': f_ogrn,
      'f_okpo': f_okpo,
      'director_fio': director_fio,
      'director_email': director_email,
      'director_phone': director_phone,
      'deputy_fio': deputy_fio,
      'deputy_email': deputy_email,
      'deputy_phone': deputy_phone,
    };
  }

  @override
  String toString() {
    return 'Department{id: $id, name: $name, short_name: $short_name, addr: $f_addr, inn: $f_inn, ogrn: $f_ogrn, okpo: $f_okpo, director_fio: $director_fio}';
  }
}
