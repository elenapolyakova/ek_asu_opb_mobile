Map<String, dynamic> _config = {
  "ServiceRootUrl": "http://ekasuopb.svrw.oao.rzd/",
  "clientId": "fd9dd42e-f50e-4d15-be78-f3c76ad4bb95"
};

String getItem(String item) {
  return _config[item] != null ?  _config[item] : "";
}
