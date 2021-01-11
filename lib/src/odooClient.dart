import 'dart:async';
import 'dart:convert';
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:ek_asu_opb_mobile/models/userInfo.dart' as user;
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class SessionExpired implements Exception {}

class OdooProxy {
  OdooProxy._();
  static final OdooProxy odooClient = OdooProxy._();
  static OdooClient _client;
  OdooSession _session;
  var subscription;
  String _baseUrl = "";
  String _db = "";

  String get baseURL {
    if (_baseUrl != "") return _baseUrl;
    _baseUrl = '${config.getItem('ServiceRootUrl')}';
    return _baseUrl;
  }

  set baseURL(String value) => _baseUrl = '$value';

  String get db {
    if (_db != "") return _db;
    _db = config.getItem('db');
    return _db;
  }

  set db(String value) => _db = value;

  Future<OdooSession> get session async {
    if (_session != null) return _session;
    _session = await auth.getSession();
    return _session;
  }

  Future<OdooClient> get client async {
    if (_client != null) return _client;
    try {
      _client = await initClient();
    } catch (e) {}

    return _client;
  }

  Future<OdooClient> initClient() async {
    final OdooSession odooSession = await session;
    if (odooSession != null) return OdooClient(baseURL, odooSession);
    return OdooClient(baseURL);
  }

  Future<void> destroySession() async {
    final OdooClient odooClient = await client;
    subscription = null;
    _session = null;
    return odooClient.destroySession();
  }

  void close() async {
    final OdooClient odooClient = await client;
    odooClient.close();
    _client = null;
  }

  Future<dynamic> checkSession() async {
    final OdooClient odooClient = await client;
    return odooClient.checkSession();
  }

  Future<StreamSubscription<OdooSession>> sessionListen(
      Function(OdooSession) sessionChanged) async {
    if (subscription == null) {
      final OdooClient odooClient = await client;
      if (odooClient != null)
        subscription = odooClient.sessionStream.listen(sessionChanged);
    }
  }

  Future<OdooSession> authorize(String login, String password,
      {String dbName}) async {
    dbName = dbName ?? db;
    final OdooClient odooClient = await client;
    if (odooClient == null) return null;
    try {
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message': '----------------------------------------'
      });
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message': 'Try authenticate($dbName, $login, $password)'
      });
      OdooSession session =
          await odooClient.authenticate(dbName, login, password);
      DBProvider.db.insert('log', {'date': nowStr(), 'message': 'success'});
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message': '----------------------------------------'
      });
      return session;
    } on OdooException catch (e) {
      print(e);
      DBProvider.db
          .insert('log', {'date': nowStr(), 'message': 'error: ${e.message}'});
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message': '----------------------------------------'
      });
      return null;
    }
  }

  Future<dynamic> callKw(String model, String method, dynamic args,
      Map<String, dynamic> kwargs) async {
    Map<String, dynamic> param = {
      'model': model,
      'method': method,
      'args': args ?? [],
      'kwargs': kwargs ?? {}
    };

    DBProvider.db.insert(
        'log', {'date': nowStr(), 'message': 'callKw(${json.encode(param)})'});

    final OdooClient odooClient = await client;
    try {
      return await odooClient.callKw(param);
    } on OdooSessionExpiredException catch (e) {
      print(e);
      throw new SessionExpired();
    } on OdooException catch (e) {
      print(e);
      DBProvider.db
          .insert('log', {'date': nowStr(), 'message': 'error: ${e.message}'});

      return null;
    } catch (e) {
      if (e.message != "Connection closed while receiving data")
        throw new SessionExpired();
      print(e);
      auth.LogOut(null); //return null;
    }
  }

  Future<user.UserInfo> getUserData(int uid) async {
    if (uid == null) return null;
    DBProvider.db.insert('log', {
      'date': nowStr(),
      'message': 'Get userInfo for uid=${uid.toString()}'
    });
    final OdooClient odooClient = await client;
    Map<String, dynamic> param = {
      'model': 'res.users',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [
          ['id', '=', uid.toString()]
        ],
        'fields': [
          'id',
          'login',
          'f_user_role_txt',
          'display_name',
          'department_id',
          'rel_railway_id',
          'email',
          'phone' /*,'f_all_subord_dep_ids'*/
        ]
      }
    };

    try {
      DBProvider.db.insert('log',
          {'date': nowStr(), 'message': 'callKw(${json.encode(param)})'});
      List<dynamic> result = await odooClient.callKw(param);

      if (result != null) {
        Map<String, dynamic> resultJson = result[0] as Map<String, dynamic>;
        user.UserInfo userInfo = user.UserInfo.fromJson(resultJson);

        DBProvider.db.insert('log', {'date': nowStr(), 'message': 'success'});
        DBProvider.db.insert('log', {
          'date': nowStr(),
          'message': '----------------------------------------'
        });
        return userInfo;
      }
    } on OdooException catch (e) {
      print(e);
      DBProvider.db
          .insert('log', {'date': nowStr(), 'message': 'error: ${e.message}'});
      DBProvider.db.insert('log', {
        'date': nowStr(),
        'message': '----------------------------------------'
      });
      return null;
      //throw e;
    } catch (e) {
      print(e);
      return null;
      //throw e;
    }

    return null;
  }
}
