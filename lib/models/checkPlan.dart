import 'dart:io';

import 'package:ek_asu_opb_mobile/controllers/checkPlan.dart';
import 'package:ek_asu_opb_mobile/controllers/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/controllers/comGroup.dart';
import 'package:ek_asu_opb_mobile/controllers/planItem.dart';
import 'package:ek_asu_opb_mobile/controllers/railway.dart';
import 'package:ek_asu_opb_mobile/models/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/models/comGroup.dart';
import 'package:ek_asu_opb_mobile/models/planItem.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class CheckPlan extends Models {
  int id;
  int odooId;

  ///Id плана проверки
  int parentId;
  PlanItem _parent;

  ///Наименование
  String name;

  ///Дорога
  int railwayId;
  Railway _railway;

  ///Начало проверки
  DateTime dateFrom;

  ///Окончание проверки
  DateTime dateTo;

  ///Дата утверждения
  DateTime dateSet;

  ///Ключ состояния
  String state = 'draft';

  ///Подписант. Имя
  String signerName;

  ///Подписант. Должность
  String signerPost;

  ///Кто утвердил. Имя
  String appName;

  ///Кто утвердил. Должность
  String appPost;

  ///Номер
  String numSet;

  ///Действует
  bool active;

  ///Id комиссии
  int mainComGroupId;
  ComGroup _mainComGroup;

  ///Варианты состояния
  static Map<String, String> stateSelection = {
    'draft': 'Черновик',
    'approved': 'Утверждено',
  };

  ///Значение состояния
  String get stateDisplay {
    if (state != null && stateSelection.containsKey(state))
      return stateSelection[state];
    return state;
  }

  ///Пункты плана
  Future<List<CheckPlanItem>> get items async {
    return await CheckPlanItemController.select(id);
  }

  ///Рабочие группы
  Future<List<ComGroup>> get comGroups async {
    return await ComGroupController.selectWorkGroups(id);
  }

  ///Комиссия
  Future<ComGroup> get mainComGroup async {
    if (_mainComGroup == null) {
      _mainComGroup = await ComGroupController.selectMainGroup(id);
      mainComGroupId = _mainComGroup.id;
    }
    return _mainComGroup;
  }

  ///Все группы данного плана
  Future<List<ComGroup>> get allComGroups async {
    return await ComGroupController.selectAllGroups(id);
  }

  ///Председатель комиссии
  Future<User> get mainComGroupHead async {
    if (await mainComGroup == null) return null;
    return await (await mainComGroup).head;
  }

  ///Члены комиссии
  Future<List<User>> get mainComGroupUsers async {
    if (await mainComGroup == null) return null;
    return await (await mainComGroup).comUsers;
  }

  ///Дорога
  Future<Railway> get railway async {
    if (_railway == null)
      _railway = await RailwayController.selectById(railwayId);
    return _railway;
  }

  ///Пункт плана
  Future<PlanItem> get parent async {
    if (_parent == null)
      _parent = await PlanItemController.selectById(parentId);
    return _parent;
  }

  Future<File> get pdfReport {
    if (odooId == null) return null;
    return CheckPlanController.downloadPdfReport(odooId);
  }

  Future<File> get xlsReport {
    if (odooId == null) return null;
    return CheckPlanController.downloadXlsReport(odooId);
  }

  CheckPlan({
    this.id,
    this.odooId,
    this.parentId,
    this.name,
    this.railwayId,
    this.dateFrom,
    this.dateTo,
    this.dateSet,
    this.state,
    this.signerName,
    this.signerPost,
    this.appName,
    this.appPost,
    this.numSet,
    this.active = true,
  });

  factory CheckPlan.fromJson(Map<String, dynamic> json) {
    CheckPlan res = new CheckPlan(
      id: json["id"],
      odooId: json["odoo_id"],
      parentId: unpackListId(json["parent_id"])['id'],
      name: getObj(json["name"]),
      railwayId: unpackListId(json["rw_id"])['id'],
      dateFrom: stringToDateTime(json["date_from"], forceUtc: false),
      dateTo: stringToDateTime(json["date_to"], forceUtc: false),
      dateSet: stringToDateTime(json["date_set"], forceUtc: false),
      state: getObj(json["state"]),
      signerName: getObj(json["signer_name"]),
      signerPost: getObj(json["signer_post"]),
      appName: getObj(json["app_name"]),
      appPost: getObj(json["app_post"]),
      numSet: getObj(json["num_set"]),
      active: json["active"].toString() == 'true',
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'odoo_id': odooId,
      'id': id,
      'parent_id': parentId,
      'name': name,
      'rw_id': railwayId,
      'date_from': dateTimeToString(dateFrom),
      'date_to': dateTimeToString(dateTo),
      'date_set': dateTimeToString(dateSet),
      'state': state,
      'signer_name': signerName,
      'signer_post': signerPost,
      'app_name': appName,
      'app_post': appPost,
      'num_set': numSet,
      'active': (active == null || !active) ? 'false' : 'true',
    };
    if (omitId) {
      res.remove('id');
      res.remove('odoo_id');
    }
    return res;
  }

  @override
  String toString() {
    return 'CheckPlan{odooId: $odooId, id: $id, name: $name}';
  }
}
