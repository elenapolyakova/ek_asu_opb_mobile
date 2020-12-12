import 'dart:io';

import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/controllers/planItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class Plan extends Models {
  int id;
  int odooId;

  ///Ключ принадлежности
  String type;

  ///Наименование
  String name;

  /// Id дороги
  int railwayId;
  Railway _railway;

  ///Год
  int year;

  ///Дата утверждения
  DateTime dateSet;

  ///Подписант имя
  String signerName;

  ///Подписант должность
  String signerPost;

  ///Номер плана
  String numSet;

  ///Действует
  bool active;

  ///Ключ состояния
  String state;

  ///Варианты выбора для принадлежности
  static Map<String, String> typeSelection = {
    'cbt': 'ЦБТ',
    'ncop': 'НЦОП',
  };

  ///Варианты выбора для состояния
  static Map<String, String> stateSelection = {
    'draft': 'Черновик',
    'approved': 'Утверждено',
  };

  ///Значение принадлежности
  String get typeDisplay {
    if (type != null && typeSelection.containsKey(type))
      return typeSelection[type];
    return type;
  }

  ///Значение состояния
  String get stateDisplay {
    if (state != null && stateSelection.containsKey(state))
      return stateSelection[state];
    return state;
  }

  ///Пункты плана
  Future<List<PlanItem>> get items async {
    return await PlanItemController.select(id);
  }

  ///Дорога
  Future<Railway> get railway async {
    if (_railway == null)
      _railway = await RailwayController.selectById(railwayId);
    return _railway;
  }

  Future<File> get pdfReport {
    if (odooId == null) return null;
    return PlanController.downloadPdfReport(odooId);
  }

  Future<File> get xlsReport {
    if (odooId == null) return null;
    return PlanController.downloadXlsReport(odooId);
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
    this.active = true,
    this.state = 'draft',
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    Plan res = new Plan(
      id: json["id"],
      odooId: json["odoo_id"],
      type: getObj(json["type"]),
      name: getObj(json["name"]),
      railwayId: unpackListId(json["rw_id"])['id'],
      year: getObj(json["year"]),
      dateSet: stringToDateTime(json["date_set"], forceUtc: false),
      signerName: getObj(json["signer_name"]),
      signerPost: getObj(json["signer_post"]),
      numSet: getObj(json["num_set"]),
      active: json["active"].toString() == 'true',
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
      'rw_id': railwayId,
      'year': year,
      'date_set': dateTimeToString(dateSet),
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
