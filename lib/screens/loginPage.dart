import 'dart:ui';

import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/controllers/department.dart';
import 'package:ek_asu_opb_mobile/src/odooClient.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import '../utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:package_info/package_info.dart';
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = FlutterSecureStorage();

class LoginPage extends StatefulWidget {
  BuildContext context;

  @override
  LoginPage({this.context});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  String _email;
  String _password;
  String _pin;
  //bool _showErrorUser = false;
  String _errorMessage = "";
  bool _showErrorPin = false;
  bool isLoginProccess = false;
  final settingFormKey = new GlobalKey<FormState>();
  String _ip = "";
  String _db = "";
  String _passwordAdmin = "";
  String version = "";
  String _settingError = "";

  final _sizeTextBlack =
      const TextStyle(fontSize: 20.0, color: Color(0xFF252A0E));
  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);
  final formKey = new GlobalKey<FormState>();
  final pinFormKey = new GlobalKey<FormState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getBaseUrl();
    getVersion();
  }

  void getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    setState(() {});
  }

  Future<void> getBaseUrl() async {
    _ip = await auth.getBaseUrl();
    _db = await auth.getDB();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        body: new Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/LoginScreenBack.png"),
                  fit: BoxFit.cover)),
          child: new Container(
            child: new Form(
                key: formKey,
                child: new Column(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: Text(''),
                        ),
                        Container(
                            padding: EdgeInsets.only(top: 24, right: 24),
                            child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxHeight: 24, maxWidth: 24),
                                child: IconButton(
                                    iconSize: 24,
                                    padding: EdgeInsets.all(0),
                                    icon: Icon(Icons.settings), //Icons.logout),
                                    color: Theme.of(context).buttonColor,
                                    onPressed: () {
                                      return showSetting(setState);
                                    })))
                      ],
                    ),
                    Expanded(
                        child: Center(
                            child: SingleChildScrollView(
                                child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        new Container(
                            child: new Text(
                          "Авторизация",
                          style: TextStyle(
                              color: Theme.of(context).primaryColorLight,
                              fontSize: 35.0,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        )),
                        new Container(
                          decoration: new BoxDecoration(
                            border: Border.all(
                                color: Colors
                                    .white, //Theme.of(context).accentColor,
                                width: 1.5),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Colors.white,
                          ),
                          // padding: EdgeInsets.symmetric(horizontal: 10.0),
                          margin: EdgeInsets.all(10),
                          child: new TextFormField(
                            decoration: new InputDecoration(
                              prefixIcon: Icon(Icons.mail_outline,
                                  color: Theme.of(context).primaryColorLight),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            maxLines: 1,
                            cursorColor: Theme.of(context).cursorColor,
                            style: _sizeTextBlack,
                            onSaved: (val) => _email = val,
                            onTap: () => setState(() {
                              _errorMessage = "";
                            }),
                            /* validator: (val) => val.length < 1
                          ? "Имя пользователя не может быть пустым"
                          : null,*/
                          ),
                          width: 400.0,
                        ),
                        new Container(
                          decoration: new BoxDecoration(
                            border: Border.all(
                                color: Colors
                                    .white, //Theme.of(context).accentColor,
                                width: 1.5),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Colors.white,
                          ),
                          // padding: EdgeInsets.symmetric(horizontal: 10.0),
                          margin: EdgeInsets.only(top: 10),
                          child: new TextFormField(
                            decoration: new InputDecoration(
                              prefixIcon: Icon(Icons.vpn_key,
                                  color: Theme.of(context).primaryColorLight),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                            ),
                            obscureText: true,
                            maxLines: 1,
                            cursorColor: Theme.of(context).cursorColor,
                            style: _sizeTextBlack,
                            onSaved: (val) => _password = val,
                            onTap: () => setState(() {
                              _errorMessage = "";
                            }),
                            /* validator: (val) => val.length < 1
                            ? "Пароль не может быть пустым"
                            : null,*/
                          ),
                          width: 400.0,
                        ),
                        new Container(
                            padding: new EdgeInsets.all(10.0),
                            child: new Text(
                              _errorMessage,
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 17),
                              textAlign: TextAlign.left,
                            )),
                        new Container(
                          width: 400,
                          height: 50.0,
                          margin: new EdgeInsets.only(top: 0.0),
                          decoration: new BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Theme.of(context).buttonColor,
                          ),
                          child: new MaterialButton(
                            onPressed: !isLoginProccess ? submit : null,
                            /*color: Theme.of(context).accentColor,
                      height: 50.0,
                      minWidth: 400.0,*/
                            child: !isLoginProccess
                                ? new Text(
                                    "ВОЙТИ",
                                    style: _sizeTextWhite,
                                  )
                                : CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColorLight),
                                  ),
                          ),
                        )
                      ],
                    )))),
                    Container(child: Text(''))
                  ],
                )),
          ),
        ),
      ),
    );
  }

  void submit() {
    final form = formKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      setState(() {
        isLoginProccess = true;
      });
      signIn();
    }
  }

  showSetting(StateSetter setState) {
    showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              // title: Text("Настройки подключения"),
              backgroundColor: Theme.of(context).primaryColor,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              content: new Form(
                  key: settingFormKey,
                  child: new Container(
                      height: 320,
                      width: 500,
                      child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              child: Text('Адрес сервера'),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.symmetric(vertical: 5),
                            ),
                            new Container(
                              decoration: new BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).primaryColorLight,
                                    width: 1.5),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Colors.white,
                              ),
                              height: 40,
                              child: new TextFormField(
                                initialValue: (_ip),
                                decoration: new InputDecoration(
                                  prefixIcon: Icon(
                                      Icons.settings_input_component,
                                      color:
                                          Theme.of(context).primaryColorLight),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                ),
                                maxLines: 1,
                                cursorColor: Theme.of(context).cursorColor,
                                style: _sizeTextBlack,
                                onSaved: (val) => _ip = val,
                                onTap: () => setState(() {
                                  _settingError = "";
                                }),
                              ),
                            ),
                            Container(
                              child: Text('Имя базы данных'),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.symmetric(vertical: 5),
                            ),
                            new Container(
                              decoration: new BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).primaryColorLight,
                                    width: 1.5),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Colors.white,
                              ),
                              height: 40,
                              child: new TextFormField(
                                initialValue: (_db),
                                decoration: new InputDecoration(
                                  prefixIcon: Icon(Icons.storage,
                                      color:
                                          Theme.of(context).primaryColorLight),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                ),
                                maxLines: 1,
                                cursorColor: Theme.of(context).cursorColor,
                                style: _sizeTextBlack,
                                onSaved: (val) => _db = val,
                                onTap: () => setState(() {
                                  _settingError = "";
                                }),
                              ),
                            ),
                            Container(
                              child: Text('Пароль администратора'),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.symmetric(vertical: 5),
                            ),
                            new Container(
                              decoration: new BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).primaryColorLight,
                                    width: 1.5),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Colors.white,
                              ),
                              height: 40,
                              child: new TextFormField(
                                decoration: new InputDecoration(
                                  contentPadding: EdgeInsets.all(0),
                                  prefixIcon: Icon(Icons.vpn_key,
                                      color:
                                          Theme.of(context).primaryColorLight),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                ),
                                maxLines: 1,
                                obscureText: true,
                                cursorColor: Theme.of(context).cursorColor,
                                style: _sizeTextBlack,
                                onSaved: (val) => _passwordAdmin = val,
                                onTap: () => setState(() {
                                  _settingError = "";
                                }),
                              ),
                            ),
                            new Container(
                              width: 200,
                              height: 35.0,
                              margin: new EdgeInsets.only(top: 15.0),
                              decoration: new BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Theme.of(context).buttonColor,
                              ),
                              child: new MaterialButton(
                                onPressed: () => settingConfirm(setState),
                                child: new Text(
                                  "Принять",
                                  style: _sizeTextWhite,
                                ),
                              ),
                            ),
                            new Container(
                                alignment: Alignment.centerLeft,
                                padding: new EdgeInsets.only(top: 5.0),
                                child: new Text(
                                  _settingError,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 14),
                                  textAlign: TextAlign.left,
                                )),
                            Container(
                              margin: EdgeInsets.only(top: 5),
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Версия: $version',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).primaryColorDark),
                              ),
                            )
                          ]))),
            );
          });
        });
  }

  Future<void> settingConfirm(setState) async {
    final form = settingFormKey.currentState;

    form.save();

    String pswd = config.getItem('password') ?? '09051945';
    if (pswd != _passwordAdmin) {
      setState(() {
        _settingError = 'Неверный пароль';
      });
      return;
    }

    if (_ip == '') {
      setState(() {
        _settingError = 'Адрес не может быть пустым';
      });
      return;
    }
    if (!RegExp(r'^https?://(.*)$', multiLine: false, caseSensitive: false)
        .hasMatch(_ip)) {
      setState(() {
        _settingError = 'Адрес должен начинаться с http(-s)://';
      });
      return;
    }

    if (_db == '') {
      setState(() {
        _settingError = 'Имя БД не может быть пустым';
      });
      return;
    }

    String lastUrl = await auth.getBaseUrl();
    String lastDB = await auth.getDB();

    if (_ip != lastUrl || _db != lastDB) {
      await DBProvider.db.reCreateDB();
      await auth.resetAllStorageData();
      await auth.setBaseUrl(_ip);
      await auth.setDB(_db);
    }
    //OdooClient client = await OdooProxy.odooClient.client;
    // if (client != null) client.close();

    Navigator.pop(context, null);
  }

  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  signIn() async {
    bool isAuthorize = await auth.authorize(_email.trim(), _password);
    bool isSet = false;
    bool isValidRole = false;
    List<String> roleList = [];
    roleList.add(config.getItem('cbtRole'));
    roleList.add(config.getItem('ncopRole'));
    if (isAuthorize) {
      // Department.loadFromOdoo(1);
      isSet = await auth.setUserData();
      if (isSet) {
        String userRole = (await auth.getUserInfo()).f_user_role_txt;
        isValidRole = (roleList.indexOf(userRole) > -1);
      }
    }

    setState(() {
      setState(() {
        isLoginProccess = false;
      });
      if (!isAuthorize)
        _errorMessage = "Неверное имя пользователя или пароль";
      else if (!isSet)
        _errorMessage = "Ошибка при получении данных о пользователе";
      else if (!isValidRole)
        _errorMessage =
            "Пользователь с данной ролью не может работать в приложении";
      else
        _errorMessage = "";
    });
    if (_errorMessage == "") {
      //(isSet && isAuthorize) {
      showSetPinDialog(); // возможно проверять pin в storage? если есть не запрашивать заново? но если пользователь его забыл...
    }
  }

  pinConfirm(setState) async {
    final form = pinFormKey.currentState;

    form.save();

    setState(() {
      _showErrorPin = _pin.length != 5;
    });
    if (_showErrorPin) return;

    await auth.setPinCode(_pin);
    Navigator.pop(context, true); //для скрытия диалога с установкой ПИН-кода

    if (auth.isSameUser() && Navigator.canPop(context)) {
      //на случай, если закончилась odoo сессия и зашли под тем же пользователем, - перенаправляем на последнюю страницу
      //возможно нужно будет сохранять state куда-то, чтобы восстановить последние введенные данные пользователя
      Navigator.pop(context);
    } else
      Navigator.pushNamed(context, "/home");
  }

  showSetPinDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (_) {
          return AlertDialog(
            title: Text("Установите ПИН-код для входа в приложение"),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            backgroundColor: Theme.of(context).primaryColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            content: StatefulBuilder(builder: (context, StateSetter setState) {
              return new Form(
                  key: pinFormKey,
                  child: new Container(
                      height: 150,
                      child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Container(
                                decoration: new BoxDecoration(
                                  border: Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 1.5),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  color: Colors.white,
                                ),
                                height: 56,
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                margin: EdgeInsets.all(10),
                                child: new TextFormField(
                                  decoration: new InputDecoration(
                                    prefixIcon: Icon(Icons.vpn_key,
                                        color: Theme.of(context)
                                            .primaryColorLight),
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide.none),
                                  ),
                                  // inputFormatters: [widget._amountValidator],
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                  ], // Only numbers can be entered
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  maxLines: 1,
                                  maxLength: 5,
                                  cursorColor: Theme.of(context).cursorColor,
                                  style: _sizeTextBlack,
                                  obscureText: true,
                                  onSaved: (val) => _pin = val,
                                  onTap: () => setState(() {
                                    _showErrorPin = false;
                                  }),
                                )),
                            new Expanded(
                                child: new Container(
                                    padding: new EdgeInsets.all(5.0),
                                    child: new Text(
                                      _showErrorPin
                                          ? "ПИН-код должен содержать 5 цифр"
                                          : '',
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 15),
                                      textAlign: TextAlign.left,
                                    ))),
                            new Container(
                              width: 200,
                              height: 50.0,
                              margin: new EdgeInsets.only(top: 15.0),
                              decoration: new BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Theme.of(context).buttonColor,
                              ),
                              child: new MaterialButton(
                                onPressed: () => pinConfirm(setState),
                                child: new Text(
                                  "OK",
                                  style: _sizeTextWhite,
                                ),
                              ),
                            )
                          ])));
            }),
          );
        });
  }
}
