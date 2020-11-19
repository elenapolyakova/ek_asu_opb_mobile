// import "package:ek_asu_opb_mobile/models/models.dart";
// import 'package:ek_asu_opb_mobile/utils/convert.dart';

// class CListTemplate extends Models {
//   int id;
//   int type;
//   bool active = true;
//   bool is_base;
//   String name;
//   String questions;

//   CListTemplate(
//       {this.id,
//       this.type,
//       this.active,
//       this.name,
//       this.questions,
//       this.is_base});

//   factory CListTemplate.fromJson(Map<String, dynamic> json) =>
//       new CListTemplate(
//           id: json["id"],
//           name: getStr(json["name"]),
//           type: getObj(json["type"]),
//           active: (json["active"].toString() == 'true'),
//           is_base: getObj(json["is_base"]),
//           questions: getStr(json["questions"]));

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'type': type,
//       'active': (active == null || !active) ? 'false' : 'true',
//       'is_base': (is_base == null || !is_base) ? 'false' : 'true',
//       'questions': questions
//     };
//   }

//   @override
//   String toString() {
//     return 'CListTemplate{id: $id, name: $name, active: $active, is_base: $is_base, questions: $questions}';
//   }
// }
