import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckList extends Models {
  int id;
  int odoo_id;
  // Plan id which uses this check list
  int parent_id;
  bool is_base;
  String name;
  int type;
  bool active;
  // Status of check list, true in work, false not used now
  bool is_active;
  int base_id;

  CheckList({
    this.id,
    this.odoo_id,
    this.parent_id,
    this.base_id,
    this.is_base,
    this.name,
    this.is_active,
    this.type,
    this.active = true,
  });

  static Map<int, String> typeSelection = {
    1: 'Воздух',
    2: 'Вода',
    3: 'Отходы',
    4: 'Почва',
    5: 'Шум',
    6: 'Гос.органы',
    7: 'Эко-менеджмент',
    8: 'Эко-риски'
  };

  String get getTypeName {
    if (type != null && typeSelection.containsKey(type)) {
      return typeSelection[type];
    }
    return type.toString();
  }

  factory CheckList.fromJson(Map<String, dynamic> json) => new CheckList(
        id: json["id"],
        odoo_id: json["odoo_id"],
        parent_id: unpackListId(json["parent_id"])['id'],
        is_base: json["is_base"].toString() == 'true',
        name: getStr(json["name"]),
        is_active: json["is_active"].toString() == 'true',
        type: getObj(json["type"]),
        base_id: unpackListId(json["base_id"])['id'],
        active: json["active"].toString() == 'true',
      );

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odoo_id,
      'parent_id': parent_id,
      'base_id': base_id,
      'name': name,
      'type': type,
      'active': (active == null || !active) ? 'false' : 'true',
      'is_base': (is_base == null || !is_base) ? 'false' : 'true',
      'is_active': (is_active == null || !is_active) ? 'false' : 'true',
    };

    if (omitId) {
      res.remove("id");
      res.remove("odoo_id");
    }

    return res;
  }

  Map<String, dynamic> prepareForUpdate() {
    return {
      'id': id,
      'is_active': is_active,
    };
  }

  @override
  String toString() {
    return 'CheckList{id: $id, odooId: $odoo_id, parent_id: $parent_id, name: $name, type: $type, active: $active, is_base: $is_base, is_active: $is_active }';
  }
}
