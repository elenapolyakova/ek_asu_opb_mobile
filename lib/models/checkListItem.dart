import 'dart:convert';

import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckListItem extends Models {
  int id;
  int base_id;
  int odooId;
  // Id of check list
  int parent_id;
  // Name for question
  String name;
  // The question value itself
  String question;
  String result;
  String description;
  bool active = true;

  CheckListItem({
    this.id,
    this.odooId,
    this.parent_id,
    this.base_id,
    this.name,
    this.question,
    this.result,
    this.description,
    this.active,
  });

  factory CheckListItem.fromJson(Map<String, dynamic> json) =>
      new CheckListItem(
          id: json["id"],
          odooId: json["odooId"],
          parent_id: json["parent_id"],
          base_id: getObj(json["base_id"]),
          name: getStr(json["name"]),
          question: getStr(json["question"]),
          active: (json["active"].toString() == 'true'),
          result: getStr(json["result"]),
          description: getStr(json["description"]));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odooId': odooId,
      'parent_id': parent_id,
      'base_id': base_id,
      'name': name,
      'question': question,
      'active': (active == null || !active) ? 'false' : 'true',
      'description': description,
      'result': result,
    };
  }

  // Make json suitable for update() in local DB;
  // Set only params that can be updated
  // Params can be extended!
  Map<String, dynamic> prepareForUpdate() {
    return {
      'id': id,
      'name': name,
      'question': question,
      'description': description,
      'result': result,
    };
  }

  @override
  String toString() {
    return 'CheckListItem{id: $id, odooId: $odooId, : $name, active: $active, question: $question, parent_id: $parent_id}';
  }
}
