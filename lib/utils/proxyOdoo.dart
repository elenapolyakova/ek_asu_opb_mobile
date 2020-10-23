
import 'dart:convert';
import 'dart:typed_data';
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'config.dart' as config;
import 'package:ek_asu_opb_mobile/models/userInfo.dart';
import 'authenticate.dart' as auth;

var _serviceRootUrl = config.getItem('ServiceRootUrl');
var _port = config.getItem('port');

String _getUrl(String urlPart) => '$_serviceRootUrl:$_port$urlPart';

Future<int> getAdminUID() async {
  var _url = _getUrl('/xmlrpc/2/common');
  var _db = config.getItem('db');
  var _username = config.getItem('login');
  var _password = config.getItem('password');

//params [db, username, password, {}]
  List<Object> params = [_db, _username, _password, new Map<String, dynamic>()];
  var uid = await xml_rpc.call(_url, "authenticate", params);
  return int.tryParse(uid.toString());
}

Future<int> authorize(String login, String password,
    {String dbName = ""}) async {
  var _url = _getUrl('/xmlrpc/2/common');
  var _db = config.getItem('db');
  var _username = login;
  var _password = password;

//params [db, username, password, {}]
  List<Object> params = [_db, _username, _password, new Map<String, dynamic>()];
  var uid = await xml_rpc.call(_url, "authenticate", params);
  return int.tryParse(uid.toString());
}

Future<UserInfo> getUserData(int uid) async {
  List<Object> domain = [
    [
      ['id', '=', uid.toString()]
    ]
  ];
  // Map<String, dynamic>param = {"limit": 1};
  //search -> modelName, search, domain
  //read -> modelName, read, ids

  dynamic result = await execute('res.users', 'read', [uid], null);
  if (result != null) {
    Map<String, dynamic> resultJson = result as Map<String, dynamic>;
    var roleName = toUTF8(resultJson["f_user_role_txt"]);
    print(roleName);
    UserInfo tempUserInfo = new UserInfo(
      login: "test", pred_id: 1, role_id: 1, userFullName: 'Иванов');

    return tempUserInfo;
  }
  return null;
}


Future<dynamic> execute(String modelName, String methodName,
    List<Object> domain, Map<String, dynamic> param) async {
  //"res.partner", "search", [['company_id', '=', '1']],
  var _url = _getUrl('/xmlrpc/2/object');
  var _db = config.getItem('db');
  var _adminUid = await auth.getAdminUid();
  var _password = config.getItem('password');
  //params [db, uid, password, modelName, methodName, domain, param]
  List<Object> params = [
    _db,
    _adminUid,
    _password,
    modelName,
    methodName,
    domain
  ];

  if (param != null) params.add(param);
  return await xml_rpc.call(_url, "execute_kw", params);
}

String toUTF8(String latin1String)
{
  if (latin1String == "" || latin1String == null) return "";
  Uint8List latin1Bytes = latin1.encode(latin1String);
  return utf8.decode(latin1Bytes);
}
