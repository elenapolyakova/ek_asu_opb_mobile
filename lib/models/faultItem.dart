import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class FaultItem extends Models {
  int id;
  // item name in odoo
  String name;
  // See typeSelection below
  int type;
  int odoo_id;
  // id of Fault
  int parent_id;
  bool active;
  // File name in odoo
  String file_name;
  // File data base64
  String file_data;

  // GEO
  double coord_n;
  double coord_e;

  FaultItem({
    this.id,
    this.odoo_id,
    this.name,
    this.type,
    this.parent_id,
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

  factory FaultItem.fromJson(Map<String, dynamic> json) => new FaultItem(
        id: json["id"],
        odoo_id: json["odoo_id"],
        name: getStr(json["name"]),
        type: getObj(json["type"]),
        parent_id: unpackListId(json["parent_id"])['id'],
        active: json["active"].toString() == 'true',
        file_data: getStr(json["file_data"]),
        file_name: getStr(json["file_name"]),
        coord_e: getObj(json["coord_e"]),
        coord_n: getObj(json["coord_n"]),
      );

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odoo_id,
      'name': name,
      'type': type,
      'parent_id': parent_id,
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
    return 'FaultItem {id: $id, odooId: $odoo_id, name: $name, type: $type, parent_id: $parent_id, active: $active, file_data: $file_data, file_name: $file_name, coord_n: $coord_n, coord_e: $coord_e}';
  }
}
