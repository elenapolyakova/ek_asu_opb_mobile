import "dart:convert";

Sector inspectionFromJson(String str) {
  final jsonData = json.decode(str);
  return Sector.fromJson(jsonData);
}

String inspectionToJson(Sector data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Sector {
  final int sector_id;
  final String name;
  final String vname;

  Sector({this.sector_id, this.name, this.vname});

  factory Sector.fromJson(Map<String, dynamic> json) => new Sector(
        sector_id: json["sector_id"],
        name: json["name"],
        vname: json["vname"],
      );

  Map<String, dynamic> toJson() {
    return {
      'sector_id': sector_id,
      'name': name,
      'vname': vname,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Sector{sector_id: $sector_id, name: $name, vname: $vname }';
  }
}
