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

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
        
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
          leading: null,
          title: TextIcon(
              icon: Icons.account_circle_rounded,
              text: '${_userInfo != null ? _userInfo.display_name : ""}',
              onTap: null,
              color: Theme.of(context).primaryColorLight),
          automaticallyImplyLeading: false,
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
     

      body: Text("Здесь будет информационно-справочная подсистема"), //getBodyContent(),
    );
  }
}
