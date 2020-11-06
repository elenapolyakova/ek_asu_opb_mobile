import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:ek_asu_opb_mobile/screens/planScreen.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class Plan extends Models {
  int id;
  int odooId;
  String type; //Принадлежность
  String name; //Наименование
  Railway _railway; //Дорога
  int railwayId; //Дорога
  int year; //Год
  DateTime dateSet; //Дата утверждения
  String signerName; //Подписант имя
  String signerPost; //Подписант должность
  String numSet; //Номер плана
  bool active; //Действует
  String state; //Состояние

  static Map<String, String> typeSelection = {
    'cbt': 'ЦБТ',
    'ncop': 'НЦОП',
  };

  static Map<String, String> stateSelection = {
    'draft': 'Черновик',
    'approved': 'Утверждено',
  };

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

  List<PlanItem> get items {
    //mob.main.plan.item
    return [];
  }

  Future<Railway> get railway async {
    if (_railway == null)
      _railway = await controllers.Railway.selectById(railwayId);
    return _railway;
  }

  Plan({
    this.odooId,
    this.id,
    this.type,
    this.year,
    this.dateSet,
    this.name,
    this.railwayId,
    this.signerName,
    this.signerPost,
    this.numSet,
    this.active,
    this.state,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    Plan res = new Plan(
      odooId: json["odoo_id"],
      id: json["id"],
      type: getObj(json["type"]),
      name: getObj(json["name"]),
      railwayId: (json["railway_id"] is List)
          ? unpackListId(json["railway_id"])['id']
          : json["railway_id"],
      year: json["year"],
      dateSet:
          json["date_set"] == null ? null : DateTime.parse(json["date_set"]),
      signerName: getObj(json["signer_name"]),
      signerPost: getObj(json["signer_post"]),
      numSet: getObj(json["num_set"]),
      active: json["active"] == 'true',
      state: getObj(json["state"]),
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'odoo_id': odooId,
      'type': type,
      'name': name,
      'railway_id': _railway.id,
      'year': year,
      'date_set': dateSet.toIso8601String().split(':')[0],
      'signer_name': signerName,
      'signer_post': signerPost,
      'num_set': numSet,
      'active': (active == null || !active) ? 'false' : 'true',
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
