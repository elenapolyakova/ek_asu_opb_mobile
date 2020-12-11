import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class FaultFixItem extends Models {
  int id;
  // item name in odoo
  String name;
  // See typeSelection below
  int type;
  int odoo_id;
  // id of FaultFix
  int parent3_id;
  bool active;
  // File name in odoo
  String file_name;
  // File data base64
  String file_data;

  // GEO
  double coord_n;
  double coord_e;

  FaultFixItem({
    this.id,
    this.odoo_id,
    this.name,
    this.type,
    this.parent3_id,
    this.active,
    this.file_data,
    this.file_name,
    this.coord_n,
    this.coord_e,
  });

  static Map<int, String> typeSelection = {
    1: 'Документ',
    2: 'Фотография',
    3: 'Схема',
  };

  String get getTypeName {
    if (type != null && typeSelection.containsKey(type)) {
      return typeSelection[type];
    }
    return type.toString();
  }

  factory FaultFixItem.fromJson(Map<String, dynamic> json) => new FaultFixItem(
        id: json["id"],
        odoo_id: json["odoo_id"],
        name: getStr(json["name"]),
        type: json["type"],
        parent3_id: json["parent3_id"],
        active: (json["active"].toString() == 'true'),
        file_data: getStr(json["file_data"]),
        file_name: getStr(json["file_name"]),
        coord_e: json["coord_e"],
        coord_n: json["coord_n"],
      );

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odoo_id,
      'name': name,
      'type': type,
      'parent3_id': parent3_id,
      'active': (active == null || !active) ? 'false' : 'true',
      'file_data': file_data,
      'file_name': file_name,
      'coord_n': coord_n,
      'coord_e': coord_e,
    };
    if (omitId) {
      res.remove("id");
      res.remove("odoo_id");
    }
    return res;
  }

  @override
  String toString() {
    return 'FaultFixItem {id: $id, odooId: $odoo_id, name: $name, type: $type, parent3_id: $parent3_id, active: $active, file_data: $file_data, file_name: $file_name, coord_n: $coord_n, coord_e: $coord_e}';
  }
}
