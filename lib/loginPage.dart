import 'package:ek_asu_opb_mobile/main.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/homeScreen.dart';
import 'package:ek_asu_opb_mobile/testScreen.dart';
import 'utils/authenticate.dart' as auth;

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  String _email;
  String _password;
  String _pin;
  bool _showErrorUser = false;
  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);
  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);
  final formKey = new GlobalKey<FormState>();
  final pinFormKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

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
                            color:
                                Colors.white, //Theme.of(context).accentColor,
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
                          _showErrorUser = false;
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
                            color:
                                Colors.white, //Theme.of(context).accentColor,
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
                        cursorColor: Theme.of(context).cursorColor,
                        style: _sizeTextBlack,
                        onSaved: (val) => _password = val,
                        onTap: () => setState(() {
                          _showErrorUser = false;
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
                          _showErrorUser
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
    bool isAuthorize = await auth.authorize(_email, _password);

    if (!isAuthorize) {
      setState(() {
        _showErrorUser = true;
      });
      return;
    }
    showSetPinDialog();
  }

  pinConfirm() async {
    final form = pinFormKey.currentState;
    if (form.validate()) {
      form.save();
      await auth.setPinCode(_pin);

      //loadData
      bool result = await auth.setUserData(_email, _password);

      Navigator.pushNamed(context, "/home");
    }
  }

  showSetPinDialog() {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text("Установите ПИН-код для входа в приложение"),
            content: new Form(
                key: pinFormKey,
                child: new Container(
                  height: 100,
                  color: Colors.white,
                  child: new TextFormField(
                      // inputFormatters: [widget._amountValidator],
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ], // Only numbers can be entered
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      maxLines: 1,
                      maxLength: 5,
                      cursorColor: Theme.of(context).cursorColor,
                      style: _sizeTextBlack,
                      onSaved: (val) => _pin = val,
                      validator: (val) => val.length < 5
                          ? "ПИН-код должен состоять из 5 цифр"
                          : null),
                )),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    pinConfirm();
                  },
                  child: Text("OK"))
            ],
          );
        });
  }
}
