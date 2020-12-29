Map<String, Object> _config = {
   /*ВНИИЖТ - dev*/
 "ServiceRootUrl": "http://msk3tis2.vniizht.lan:8069",
  "addressForPing": "msk3tis2.vniizht.lan",
  "db": "ecodb_2020-07-01",
 
  
  /*РЖД - prod*/
  /*"ServiceRootUrl": "http://ekasuopb.svrw.oao.rzd:8069",
  "addressForPing": "ekasuopb.svrw.oao.rzd",
  "db": "ek_asu_opb2",*/
  "MapAddr": "http://ekasuopb.svrw.oao.rzd",

  /*РЖД - test*/
  /* 
  "ServiceRootUrl": "http://10.247.1.133",
  "addressForPing": "10.247.1.133",
  "db": "ek_asu_opb_db"*/
  "password": "09051945",
  "cbtRole": "ЦБТ",
  "ncopRole": "НЦОП",
  "attemptCount": 50,
  "limitRecord": 80,
  "sessionExpire": 10 * 60, //через какое время запрашиваем ПИН-код, секунд
  "refreshMessenger": 10, //как часто обновляем сообщения в мессенджере, секунд
  "refreshCountMessenger":
      60, //как часто обновляем количество сообщений в иконке чат, секунд
  //"MapAddr": "http://172.22.3.173",
};

dynamic getItem(String item) {
  return _config[item] != null ? _config[item] : "";
}

dynamic setItem(String key, String item) {
  return _config[key] = item;
}
