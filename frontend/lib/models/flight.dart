class Flight {
  final int flightId;
  final String departureTime;
  final String arrivalTime;
  final String departureAirport;
  final String arrivalAirport;
  final String planeModel;

  double minPrice; // 新增最低票价
  String seatType; // 新增座位类型

  Flight({
    required this.flightId,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.planeModel,
    this.minPrice = 0.0,
    this.seatType = '',
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      flightId: json['flight_id'],
      departureTime: json['departure_time'],
      arrivalTime: json['arrival_time'],
      departureAirport: json['departure_airport'],
      arrivalAirport: json['arrival_airport'],
      planeModel: json['plane_model'],
    );
  }
}
