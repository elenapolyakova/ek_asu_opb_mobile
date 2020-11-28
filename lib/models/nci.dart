import "package:ek_asu_opb_mobile/models/models.dart";

class DocumentList extends Models {
  int id;
  String name;
  int parent_id;

  // NCI is a list of documents!
  DocumentList({
    this.id,
    this.name,
    // if item has parent_id , it's a Вложение, которое так же может иметь доки
    this.parent_id,
  });

  factory DocumentList.fromJson(Map<String, dynamic> json) => new DocumentList(
        id: json["id"],
        name: json["name"],
        parent_id: json["parent_id"],
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parent_id,
    };
  }

  @override
  String toString() {
    return 'DocumentList{id: $id, parent_id: $parent_id, name: $name }';
  }
}
