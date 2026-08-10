class Pet {
  final int id;
  final String name;
  final String species;
  final String breed;
  final String? birthday;
  final String? gotchaDate;
  final int? age;
  final String allergies;
  final String existingConditions;
  final String? photoUrl;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    this.birthday,
    this.gotchaDate,
    this.age,
    required this.allergies,
    required this.existingConditions,
    this.photoUrl,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      breed: json['breed'] ?? '',
      birthday: json['birthday'],
      gotchaDate: json['gotcha_date'],
      age: json['age'],
      allergies: json['allergies'] ?? '',
      existingConditions: json['existing_conditions'] ?? '',
      photoUrl: json['photo'],
    );
  }
}
