import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

class CheckListScreen extends StatefulWidget {
  @override
  State<CheckListScreen> createState() => _CheckListScreen();
}

class _CheckListScreen extends State<CheckListScreen> {
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

  @override
  Widget build(BuildContext context) {
    return new Text("Здесь будут чек-листы");
  }
}
