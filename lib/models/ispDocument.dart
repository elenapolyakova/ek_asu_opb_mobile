import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class NCIDocument extends Models {
  int id;
  // id of parent DocumentList
  int parent2_id;
  String name;
  DateTime date;
  String number;
  String description;
  String file_name;
  String file_data;
  int type;
  bool is_new;

  NCIDocument({
    this.id,
    this.parent2_id,
    this.name,
    this.date,
    this.number,
    this.description,
    this.file_name,
    this.file_data,
    this.type,
    this.is_new,
  });

  factory NCIDocument.fromJson(Map<String, dynamic> json) => new NCIDocument(
        id: json["id"],
        parent2_id: json["parent2_id"],
        name: getObj(json["name"]),
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
        number: getObj(json["number"]),
        description: getObj(json["description"]),
        file_name: getObj(json["file_name"]),
        file_data: getObj(json["file_data"]),
        type: getObj(json["type"]),
        is_new: (json["is_new"].toString() == 'true'),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent2_id': parent2_id,
      'name': name,
      'date': date,
      'number': number,
      'description': description,
      'file_name': file_name,
      'file_data': file_data,
      'type': type,
      'is_new': (is_new == null || !is_new) ? 'false' : 'true',
    };
  }

  @override
  String toString() {
    return 'NCIDocument {id: $id, parent2_id: $parent2_id, name: $name, file_name: $file_name, is_new: $is_new, file_data: $file_data}';
  }
}
