import "dart:convert";
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

/*Railway railwayFromJson(String str) {
  final jsonData = json.decode(str);
  return Railway.fromJson(jsonData);
}

String railwayToJson(Railway data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}*/

class Railway extends Models {
   int id;
   String name;
   String short_name;

  Railway({this.id, this.name, this.short_name});

  factory Railway.fromJson(Map<String, dynamic> json) => new Railway(
        id: json["id"],
        name: getStr(json["name"]),
        short_name: getStr(json["short_name"]),
      );

  Railway fromJson(Map<String, dynamic> json) {
    return Railway.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': short_name,
    };
  }

  @override
  String toString() {
    return 'Railway{id: $id, name: $name, short_name: $short_name }';
  }
}
