Map<String, Object> _config = {
  "ServiceRootUrl": "http://msk3tis2.vniizht.lan",
  "addressForPing": "msk3tis2.vniizht.lan",
  "port": 8069,
  "password": "09051945",
  "db": "ecodb_2020-07-01",
/*  "ServiceRootUrl": "http://ekasuopb.svrw.oao.rzd",
  "db":	"ek_asu_opb2",
  "password": "1", */

  "cbtRole": "cbt",
  "ncopRole": "ncop",
  "attemptCount": 5,
  "limitRecord": 80,
  
  "clientId": "fd9dd42e-f50e-4d15-be78-f3c76ad4bb95",
  "sessionExpire": 10*60, //через какое время запрашиваем ПИН-код, секунд
};

dynamic getItem(String item) {
  return _config[item] != null ?  _config[item] : "";
}
