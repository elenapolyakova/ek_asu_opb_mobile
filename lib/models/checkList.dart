import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckListWork extends Models {
  int id;
  int odooId;
  // Plan id which uses this check list
  int parent_id;
  bool is_base;
  String name;
  int type;
  bool active = true;
  // Status of check list, true in work, false not used now
  bool is_active;
  int base_id;

  CheckListWork({
    this.id,
    this.odooId,
    this.parent_id,
    this.base_id,
    this.is_base,
    this.name,
    this.is_active,
    this.type,
    this.active,
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

  factory CheckListWork.fromJson(Map<String, dynamic> json) =>
      new CheckListWork(
        id: json["id"],
        odooId: json["odooId"],
        parent_id: json["parent_id"] is List ? null : getObj(json["parent_id"]),
        is_base: (json["is_base"].toString() == 'true'),
        name: getStr(json["name"]),
        is_active: (json["is_active"].toString() == 'true'),
        type: getObj(json["type"]),
        base_id: getObj(json["base_id"]),
        active: (json["active"].toString() == 'true'),
      );

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odooId': odooId,
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
      res.remove("odooId");
    }

    return res;
  }

  @override
  String toString() {
    return 'CheckListWork{id: $id, odooId: $odooId, parent_id: $parent_id, name: $name, type: $type, active: $active, is_base: $is_base, is_active: $is_active }';
  }
}
