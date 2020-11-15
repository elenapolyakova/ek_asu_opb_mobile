import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

class ISPScreen extends StatefulWidget {
  @override
  State<ISPScreen> createState() => _ISPScreen();
}

class _ISPScreen extends State<ISPScreen> {
  UserInfo _userInfo;
  bool showLoading = true;

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          showLoading = false;
          setState(() {});
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  void LogOut() {
    auth.LogOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
            title: Container(
                child: Row(children: [
              Container(
                child: TextIcon(
                    icon: Icons.account_circle_rounded,
                    text: '${_userInfo != null ? _userInfo.display_name : ""}',
                    onTap: null,
                    color: Theme.of(context).primaryColorLight),
              ),
              Expanded(child: Center(child: HomeIcon()))
            ])),
            backgroundColor: Theme.of(context).primaryColorDark,
            actions: <Widget>[
              Padding(
                  padding: EdgeInsets.only(right: 26),
                  child: TextIcon(
                      icon: Icons.exit_to_app,
                      text: 'Выход',
                      onTap: LogOut,
                      color: Theme.of(context).buttonColor)),
            ]),
        body:  Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/frameScreen.png"),
                        fit: BoxFit.fitWidth)),
                child: showLoading
                    ? Text("")
                    : Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(children: [
                          Expanded(
                              child: ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                Text("Информационно-справочная подсистема")
                              ]))
                        ]))) //getBodyContent(),
        );
  }
}
