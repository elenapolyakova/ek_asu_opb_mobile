import "package:ek_asu_opb_mobile/controllers/controllers.dart";
import "package:ek_asu_opb_mobile/models/models.dart";
import "package:ek_asu_opb_mobile/src/exchangeData.dart";

class PlanController extends Controllers {
  static String _tableName = "plan";
  static Future<dynamic> insert(Map<String, dynamic> json) async {
    Plan plan = Plan.fromJson(json); //нужно, чтобы преобразовать одоо rel в id
    return await DBProvider.db.insert(_tableName, plan.toJson());
  }

  static Future<List<int>> selectIDs() async {
    List<Map<String, dynamic>> maps =
        await DBProvider.db.select(_tableName, distinct: true, columns: ["id"]);

    if (maps.isEmpty) return null;
    return List.generate(maps.length, (index) => maps[index]["id"]);
  }

  static Future<List<Map<String, dynamic>>> selectAll() async {
    return await DBProvider.db.selectAll(_tableName);
  }

  static loadFromOdoo([limit]) async {
    List<dynamic> json =
        await getDataWithAttemp('mob.main.plan', 'search_read', [
      [],
      [
        'type',
        'name',
        'railway_id',
        'year',
        'date_set',
        'user_set_id',
        'state',
      ]
    ], {
      'limit': limit
    });
    DBProvider.db.deleteAll(_tableName);
    json
        .map((e) => {
              ...e,
              'id': null,
              'odoo_id': e.id,
            })
        .forEach((e) => insert(e));
  }

  static Future<Plan> add(Map<String, dynamic> json) async {
    Plan plan = Plan.fromJson(json);
    int newItemId = await getDataWithAttemp(_tableName, 'create', [
      {
        'type': plan.type,
        'name': plan.name,
        'railway_id': plan.railwayId,
        'year': plan.year,
        'date_set': plan.dateSet,
        'user_set_id': plan.userSetId,
        'state': plan.state,
      }
    ], {});
    plan.odooId = newItemId;
    await DBProvider.db.insert(_tableName, plan.toJson());
    return plan;
  }

  static Future<Plan> edit(Plan plan) async {
    if (plan.odooId != null)
      getDataWithAttemp(_tableName, 'write', [
        [plan.odooId],
        plan.toJson(true)
      ], {});
    await DBProvider.db.update(_tableName, plan.toJson());
    return plan;
  }

  static Future<Plan> delete(Plan plan) async {
    if (plan.odooId != null)
      getDataWithAttemp(_tableName, 'unlink', [
        [plan.odooId],
      ], {});
    await DBProvider.db.delete(_tableName, plan.id);
    return plan;
  }
}
