import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class CheckListItem extends Models {
  int id;
  int base_id;
  int odoo_id;
  // Id of check list
  int parent_id;
  // Name for question
  String name;
  // The question value itself
  String question;
  String result;
  String description;
  bool active;

  CheckListItem({
    this.id,
    this.odoo_id,
    this.parent_id,
    this.base_id,
    this.name,
    this.question,
    this.result,
    this.description,
    this.active = true,
  });

  Future<int> get getFaultsCounts async {
    if (id != null) {
      return await FaultController.getFaultsCount(id);
    }
    return null;
  }

  factory CheckListItem.fromJson(Map<String, dynamic> json) =>
      new CheckListItem(
          id: json["id"],
          odoo_id: json["odoo_id"],
          parent_id: unpackListId(json["parent_id"])['id'],
          base_id: unpackListId(json["base_id"])['id'],
          name: getStr(json["name"]),
          question: getStr(json["question"]),
          active: json["active"].toString() == 'true',
          result: getStr(json["result"]),
          description: getStr(json["description"]));

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odoo_id,
      'parent_id': parent_id,
      'base_id': base_id,
      'name': name,
      'question': question,
      'active': (active == null || !active) ? 'false' : 'true',
      'description': description,
      'result': result,
    };

    if (omitId) {
      res.remove("id");
      res.remove("odoo_id");
    }

    return res;
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
    return 'CheckListItem{id: $id, odooId: $odoo_id, : $name, active: $active, question: $question, parent_id: $parent_id}';
  }
}
