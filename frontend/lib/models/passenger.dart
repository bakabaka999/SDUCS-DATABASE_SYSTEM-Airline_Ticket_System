class Passenger {
  final int id;
  final String name;
  final bool gender;
  final String phoneNumber;
  final String email;
  final String personType;
  final String birthDate;

  Passenger({
    required this.id,
    required this.name,
    required this.gender,
    required this.phoneNumber,
    required this.email,
    required this.personType,
    required this.birthDate,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      personType: json['person_type'],
      birthDate: json['birth_date'],
    );
  }
}
