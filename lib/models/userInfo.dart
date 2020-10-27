import "dart:convert";
import 'package:ek_asu_opb_mobile/utils/convert.dart';

UserInfo userInfoFromJson(String str) {
  final jsonData = json.decode(str);
  return UserInfo.fromJson(jsonData);
}

String userInfoToJson(UserInfo data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}



class UserInfo {
  int id;
  String login;
  final String f_user_role_txt;
  final String display_name;
  final int department_id;
  final int railway_id;
  final String email;
  final String phone;

  UserInfo(
      {this.id,
      this.login,
      this.f_user_role_txt,
      this.display_name,
      this.department_id,
      this.railway_id,
      this.email,
      this.phone});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return new UserInfo(
        id: json["id"],
        login: json["login"],
        f_user_role_txt: getStr(json["f_user_role_txt"]),
        display_name: getStr(json["display_name"]),
        department_id: getIdFromList(json["department_id"]),
        railway_id: getIdFromList(json["rel_railway_id"]),
        email: getStr(json["email"]),
        phone: getStr(json["phone"]));
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
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'userInfo{uid: $id, login: $login, ' +
        ' role_id: $f_user_role_txt, display_name: $display_name, }';
  }
}
