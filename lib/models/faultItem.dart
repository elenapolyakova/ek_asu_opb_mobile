import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class FaultItem extends Models {
  int id;
  String name = nowStr();
  int type = 2;
  int odoo_id;
  // id of Fault
  int parent_id;
  // Will paths to file in internal device memory
  String image;
  bool active;

  FaultItem({
    this.id,
    this.odoo_id,
    this.name,
    this.type,
    this.parent_id,
    this.image,
    this.active,
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
        name: json["name"],
        type: json["type"],
        parent_id: json["parent_id"],
        image: getStr(json["image"]),
        active: (json["active"].toString() == 'true'),
      );

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odoo_id,
      'name': name,
      'type': type,
      'parent_id': parent_id,
      'image': image,
      'active': (active == null || !active) ? 'false' : 'true',
    };
    if (omitId) {
      res.remove("id");
      res.remove("odoo_id");
    }
    return res;
  }

  @override
  String toString() {
    return 'FaultItem {id: $id, odooId: $odoo_id, name: $name, type: $type, parent_id: $parent_id, image: $image, active: $active}';
  }
}
