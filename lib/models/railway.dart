import "dart:convert";

Railway inspectionFromJson(String str) {
  final jsonData = json.decode(str);
  return Railway.fromJson(jsonData);
}

String inspectionToJson(Railway data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Railway {
  final int railway_id;
  final String name;
  final String vname;

  Railway({this.railway_id, this.name, this.vname});

  factory Railway.fromJson(Map<String, dynamic> json) => new Railway(
        railway_id: json["railway_id"],
        name: json["name"],
        vname: json["vname"],
      );

  Map<String, dynamic> toJson() {
    return {
      'railway_id': railway_id,
      'name': name,
      'vname': vname,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Railway{railway_id: $railway_id, name: $name, vname: $vname }';
  }
}
