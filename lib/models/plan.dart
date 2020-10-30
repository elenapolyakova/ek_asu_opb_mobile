import "dart:convert";
import 'package:ek_asu_opb_mobile/controllers/railway.dart'
    as railwayController;
import 'package:ek_asu_opb_mobile/controllers/user.dart' as userController;
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class Plan extends Models {
  int id;
  int odooId;
  String type; //Принадлежность
  String name; //Наименование
  int railwayId; //Дорога
  String _railwayName; //Дорога
  int year; //Год
  String dateSet; //Дата утверждения
  int userSetId; //Подписант
  String _userSetName; //Подписант
  String state; //Состояние

  static Map<String, String> typeSelection = {
    'cbt': 'ЦБТ',
    'ncop': 'НЦОП',
  };

  static Map<String, String> stateSelection = {
    'draft': 'Черновик',
    'approved': 'Утверждено',
  };

  String get railwayName {
    if (_railwayName == null)
      railwayController.Railway.getName(railwayId)
          .then((name) => {_railwayName = name});
    return _railwayName;
  }

  String get userSetName {
    if (_userSetName == null)
      userController.User.getName(railwayId)
          .then((name) => {_userSetName = name});
    return _userSetName;
  }

  String get typeDisplay {
    if (type != null && typeSelection.containsKey(type))
      return typeSelection[type];
    return type;
  }

  String get stateDisplay {
    if (state != null && stateSelection.containsKey(state))
      return stateSelection[state];
    return state;
  }

  Plan(
      {this.odooId,
      this.id,
      this.type,
      this.year,
      this.dateSet,
      this.name,
      this.railwayId,
      this.userSetId,
      this.state});

  factory Plan.fromJson(Map<String, dynamic> json) {
    Plan res = new Plan(
      odooId: json["odoo_id"],
      id: json["id"],
      type: getObj(json["type"]),
      name: getObj(json["name"]),
      railwayId: unpackListId(json["railway_id"])['id'],
      year: json["year"],
      dateSet: getObj(json["date_set"]),
      userSetId: unpackListId(json["user_set_id"])['id'],
      state: getObj(json["state"]),
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map res = {
      'id': id,
      'odoo_id': odooId,
      'type': type,
      'name': name,
      'railway_id': railwayId,
      'year': year,
      'date_set': dateSet,
      'user_set_id': userSetId,
      'state': state,
    };
    if (omitId) {
      res.remove('id');
      res.remove('odoo_id');
    }
    return res;
  }

  @override
  String toString() {
    return 'Plan{odooId: $odooId, id: $id, name: $name}';
  }
}
