
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class User extends Models {
  int id;
  String login;
  final String f_user_role_txt;
  final String display_name;
  final int department_id;
  final int railway_id;
  final String email;
  final String phone;
  final String active;
  final String function;

  User(
      {this.id,
      this.login,
      this.f_user_role_txt,
      this.display_name,
      this.department_id,
      this.railway_id,
      this.email,
      this.phone,
      this.active,
      this.function});

  User fromJson(Map<String, dynamic> json) {
    return User.fromJson(json);
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return new User(
        id: json["id"],
        login: json["login"],
        f_user_role_txt: getStr(json["f_user_role_txt"]),
        display_name: getStr(json["display_name"]),
        department_id: getIdFromList(json["department_id"]),
        railway_id: getIdFromList(json["rel_railway_id"]),
        email: getStr(json["email"]),
        phone: getStr(json["phone"]),
        active: (json["active"] == true).toString(),
        function:  getStr(json["function"]));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'f_user_role_txt': f_user_role_txt,
      'display_name': display_name,
      'department_id': department_id,
      'railway_id': railway_id,
      'email': email,
      'phone': phone,
      'active': active,
      'function': function
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'user{uid: $id, login: $login, ' +
        ' role_id: $f_user_role_txt, display_name: $display_name, }';
  }
}
