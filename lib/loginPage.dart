import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/homeScreen.dart';
import 'package:ek_asu_opb_mobile/testScreen.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  String _email;
  String _password;
  bool _errorUser = false;
  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);
  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);
  final formKey = new GlobalKey<FormState>();
  BuildContext _context;

  @override
  Widget build(BuildContext context) {
    _context = context;

    return new MaterialApp(
      home: new Scaffold(
        body: new Container(
          color: Theme.of(context).backgroundColor,
          child: new Center(
            child: new Form(
                key: formKey,
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Container(
                        child: new Text(
                      "Авторизация",
                      style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 35.0,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    )),
                    new Container(
                      decoration: new BoxDecoration(
                        border: Border.all(
                            color: Colors.white, //Theme.of(context).accentColor,
                             width: 1.5),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      margin: EdgeInsets.all(10),
                      child: new TextFormField(
                        decoration: new InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline,
                              color: Theme.of(context).accentColor),
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                              
                          //helperText: ''
                        ),
                        keyboardType: TextInputType.emailAddress,
                        maxLines: 1,
                        cursorColor: Theme.of(context).cursorColor,
                        style: _sizeTextBlack,
                        onSaved: (val) => _email = val,
                        onTap: () => setState(() {
                          _errorUser = false;
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
                            color: Colors.white, //Theme.of(context).accentColor,
                             width: 1.5),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      margin: EdgeInsets.all(10),
                      child: new TextFormField(
                        decoration: new InputDecoration(
                          prefixIcon: Icon(Icons.vpn_key,
                              color: Theme.of(context).accentColor),
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                        ),
                        obscureText: true,
                        maxLines: 1,
                       // cursorColor: Theme.of(context).cursorColor,
                        style: _sizeTextBlack,
                        onSaved: (val) => _password = val,
                        onTap: () => setState(() {
                          _errorUser = false;
                        }),
                        validator: (val) => val.length < 1
                            ? "Пароль не может быть пустым"
                            : null,
                        // validator: (val) =>
                        //     !val.contains("@") ? 'Not a valid email.' : null,
                      ),
                      width: 400.0,
                    ),
                    new Container(
                        padding: new EdgeInsets.all(10.0),
                        child: new Text(
                          _errorUser
                              ? "Неверное имя пользователя или пароль"
                              : '',
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 17),
                          textAlign: TextAlign.left,
                        )),
                    new Container(
                      width: 400,
                      height: 50.0,
                      margin: new EdgeInsets.only(top: 15.0),
                      decoration: new BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Theme.of(context).accentColor,
                      ),
                      child: new MaterialButton(
                        onPressed: submit,
                        /*color: Theme.of(context).accentColor,
                      height: 50.0,
                      minWidth: 400.0,*/
                        child: new Text(
                          "ВОЙТИ",
                          style: _sizeTextWhite,
                        ),
                      ),
                    )
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
      signIn();
    }
  }

  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  signIn() async {
    final storage = new FlutterSecureStorage();
    var _roleId = 0, _predId = 0;
    Map data = {'email': _email, 'password': _password};
    /* var jsonResponse = null;
    var response = await http.post("http://192.168.0.104:8000/api/v1/auth_token/token/login/", body: data);
    if(response.statusCode == 200) {
      jsonResponse = json.decode(response.body);
      if(jsonResponse != null) {*/
    switch (_email.toUpperCase()) {
      case 'ЦБТ':
      case 'CBT':
        _roleId = 1;
        _predId = 1;
        break;
      case 'НЦОП':
      case 'NCOP':
        _roleId = 2;
        _predId = 2;
        break;
    }
    if (_roleId == 0) {
      setState(() {
        _errorUser = true;
      });
      return;
    }

    setState(() {});
    var user_info = {
      'role_id': _roleId,
      'pred_id': _predId,
      'username': _email
    };

    await storage.write(key: "user_info", value: jsonEncode(user_info));
    await storage.write(key: "auth_token", value: 'auth_token');
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => //TestScreen()
              HomeScreen()),
    );

    /*  }
    }
    else {
      setState(() {

      });
      print(response.body);
    }*/
  }
}
