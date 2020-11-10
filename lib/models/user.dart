import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class User extends Models {
  int id;
  String login;
  String f_user_role_txt;
  String display_name;
  int department_id;
  int railway_id;
  String email;
  String phone;
  bool active;
  String function;
  String user_role;

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
      this.function, 
      this.user_role});

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
        railway_id: (json["rel_railway_id"] != null) ? getIdFromList(json["rel_railway_id"]) : json["railway_id"],
        email: getStr(json["email"]),
        phone: getStr(json["phone"]),
        active:  (json["active"].toString() == 'true'),
        function: getStr(json["function"]),
        user_role: getStr(json["user_role"]),);
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
      'active':  (active == null || !active) ? 'false' : 'true',
      'function': function,
      'search_field': display_name.trim().toLowerCase(),
      'user_role': user_role
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'user{uid: $id, login: $login, ' +
        ' f_user_role_txt: $f_user_role_txt, display_name: $display_name, }';
  }
}
