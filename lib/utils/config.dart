Map<String, Object> _config = {
  //"ServiceRootUrl": "http://ekasuopb.svrw.oao.rzd",
  "ServiceRootUrl": "http://msk3tis2.vniizht.lan",
  "port": "8069",
  "db": "ecodb_2020-07-01",
  "login": "admin",
  "password": "09051945",
  "clientId": "fd9dd42e-f50e-4d15-be78-f3c76ad4bb95",
  "sessionExpire": 10*60, //через какое время запрашиваем ПИН-код, секунд
};

dynamic getItem(String item) {
  return _config[item] != null ?  _config[item] : "";
}
