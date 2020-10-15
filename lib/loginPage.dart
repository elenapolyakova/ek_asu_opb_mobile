import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/homeScreen.dart';

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
        body: new Center(
          child: new Form(
              key: formKey,
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Container(
                    child: new TextFormField(
                      decoration: new InputDecoration(labelText: "Логин"),
                      keyboardType: TextInputType.emailAddress,
                      maxLines: 1,
                      style: _sizeTextBlack,
                      onSaved: (val) => _email = val,
                      onTap: () => setState(() {
                        _errorUser = false;
                      }),
                      validator: (val) => val.length < 1
                          ? "Имя пользователя не может быть пустым"
                          : null,
                      // validator: (val) =>
                      //     !val.contains("@") ? 'Not a valid email.' : null,
                    ),
                    width: 400.0,
                  ),
                  new Container(
                    child: new TextFormField(
                      decoration: new InputDecoration(labelText: "Пароль"),
                      obscureText: true,
                      maxLines: 1,
                      validator: (val) =>
                          val.length < 1 ? "Пароль не может быть пустым" : null,
                      onSaved: (val) => _password = val,
                      onTap: () => setState(() {
                        _errorUser = false;
                      }),
                      style: _sizeTextBlack,
                    ),
                    width: 400.0,
                    padding: new EdgeInsets.only(top: 10.0),
                  ),
                  new Padding(
                      padding: new EdgeInsets.only(top: 15.0, left: 5.0),
                      child: new Align(
                          alignment: Alignment.topLeft,
                          child: new Text(
                              _errorUser ? "Неверный логин или пароль" : '',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 12)))),
                  new Padding(
                    padding: new EdgeInsets.only(top: 25.0),
                    child: new MaterialButton(
                      onPressed: submit,
                      color: Theme.of(context).accentColor,
                      height: 50.0,
                      minWidth: 150.0,
                      child: new Text(
                        "ВХОД",
                        style: _sizeTextWhite,
                      ),
                    ),
                  )
                ],
              )),
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

  void performLogin() {
    hideKeyboard();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
 
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
    var user_info = {'role_id': _roleId, 'pred_id': _predId, 'username': _email};
    
    await storage.write(key: "user_info", value: jsonEncode(user_info));
    await storage.write(key: "auth_token", value: 'auth_token');
    Navigator.of(_context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => HomeScreen()),
        (Route<dynamic> route) => false);
    /*  }
    }
    else {
      setState(() {

      });
      print(response.body);
    }*/
  }
}
