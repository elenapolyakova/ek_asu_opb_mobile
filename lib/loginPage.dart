import 'package:ek_asu_opb_mobile/controllers/department.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/authenticate.dart' as auth;

class LoginPage extends StatefulWidget {
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

  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);
  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);
  final formKey = new GlobalKey<FormState>();
  final pinFormKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        body: new Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/background.jpg"),
                  fit: BoxFit.fill)),
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
                          color: Theme.of(context).primaryColorLight,
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
                              color: Theme.of(context).primaryColorLight),
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
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
                              color: Theme.of(context).primaryColorLight),
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
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
                        color: Theme.of(context).buttonColor,
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
    bool isSet = false;
    if (isAuthorize) {
     // Department.loadFromOdoo();
      isSet = await auth.setUserData();
    }

    setState(() {
      if (!isAuthorize)
        _errorMessage = "Неверное имя пользователя или пароль";
      else if (!isSet)
        _errorMessage = "Ошибка при получении данных о пользователе";
      else
        _errorMessage = "";
    });
    if (isSet && isAuthorize) {
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
