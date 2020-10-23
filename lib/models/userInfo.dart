import "dart:convert";

UserInfo userInfoFromJson(String str) {
  final jsonData = json.decode(str);
  return UserInfo.fromJson(jsonData);
}

String userInfoToJson(UserInfo data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class UserInfo {
  final int uid;
  final String login;
  String password;
  final int role_id;
  final int pred_id;
  final String userFullName;


  UserInfo({this.uid, this.login, this.password, this.role_id, this.pred_id,  this.userFullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) => new UserInfo(
        uid: json["uid"],
        login: json["login"],
        password: json["password"],
        role_id: json["role_id"],
        pred_id: json["pred_id"],
        userFullName: json["userFullName"],
      );

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'login': login,
      'password': password,
      'role_id': role_id,
      'pred_id': pred_id,
      'userFullName': userFullName,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'userInfo{uid: $uid, login: $login, password: $password, '+  
    ' role_id: $role_id, pred_id: $pred_id, userFullName: $userFullName, }';
  }
}
