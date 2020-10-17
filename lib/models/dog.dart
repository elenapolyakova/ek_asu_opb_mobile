import "dart:convert";

Dog dogFromJson(String str) {
  final jsonData = json.decode(str);
  return Dog.fromJson(jsonData);
}

String dogToJson(Dog data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Dog {
  final int id;
  final String name;
  final int age;

  Dog({this.id, this.name, this.age});

  factory Dog.fromJson(Map<String, dynamic> json) => new Dog(
        id: json["id"],
        name: json["name"],
        age: json["age"],
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Dog{id: $id, name: $name, age: $age}';
  }
}
