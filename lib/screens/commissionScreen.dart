import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/components/search.dart';

class CommissionScreen extends StatefulWidget {
  @override
  State<CommissionScreen> createState() => _CommissionScreen();
}

class _CommissionScreen extends State<CommissionScreen> {
  UserInfo _userInfo;

  final _list = const [
    'Igor Minar',
    'Brad Green',
    'Dave Geddes',
    'Naomi Black',
    'Greg Weber',
    'Dean Sofer',
    'Wes Alvaro',
    'John Scott',
    'Daniel Nadasi',
  ];

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
    return new MaterialSearchInput<String>(
      placeholder: 'ФИО участника', //placeholder of the search bar text input

     
      //or
      results: _list
          .map((name) => new MaterialSearchResult<String>(
                value: name, //The value must be of type <String>
                text: name, //String that will be show in the list
              //  icon: Icons.person,
              ))
          .toList(),
      filter: (dynamic value, String criteria) {
                        return value.toLowerCase().trim()
                          .contains(new RegExp(r'' + criteria.toLowerCase().trim() + ''));
                      },

      //callback when some value is selected, optional.
      onSelect: (String selected) {
        print(selected);
      },
      //callback when the value is submitted, optional.
    //  leading: null,
    );
  }
}
