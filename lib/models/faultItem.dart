import "package:ek_asu_opb_mobile/models/models.dart";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class FaultItem extends Models {
  int id;
  int odooId;
  // id of Fault
  int parent_id;
  // Will paths to file in internal device memory
  String image;
  bool active;

  FaultItem({
    this.id,
    this.odooId,
    this.parent_id,
    this.image,
    this.active,
  });

  factory FaultItem.fromJson(Map<String, dynamic> json) => new FaultItem(
        id: json["id"],
        odooId: json["odooId"],
        parent_id: json["parent_id"],
        image: getStr(json["image"]),
        active: (json["active"].toString() == 'true'),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'odooId': odooId,
      'parent_id': parent_id,
      'image': image,
      'active': (active == null || !active) ? 'false' : 'true',
    };
  }
}
