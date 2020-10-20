import 'package:http/http.dart' as http;
import 'package:flutter_xmlrpc/client.dart' as xmlRpcClient;
import 'config.dart' as config;
import 'package:ek_asu_opb_mobile/models/models.dart';

var _serviceRootUrl = config.getItem('ServiceRootUrl');
var _port = config.getItem('port');

String _getUrl(String urlPart) => '$_serviceRootUrl:$_port$urlPart';

//void loadData() {


//  xmlRpcClient.call(_getUrl('/web'), methodName, params);

//}

 Future<bool> authorize (LoginData loginData, String dbName) async{
   var client = http.Client();

  var url = _getUrl('/web');
  var response = await http.get(url);
  //var response = await http.post(url, body: {'name': 'doodle', 'color': 'blue'});
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
  return true;
 }

