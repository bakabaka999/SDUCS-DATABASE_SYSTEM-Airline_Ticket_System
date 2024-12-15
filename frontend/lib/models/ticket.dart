// 机票模型
class Ticket {
  final int ticketId;
  final String ticketType;
  final String seatType;
  final double price;
  final double baggageAllowance;
  final int remainingSeats;

  Ticket({
    required this.ticketId,
    required this.ticketType,
    required this.seatType,
    required this.price,
    required this.baggageAllowance,
    required this.remainingSeats,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      ticketId: json['ticket_id'],
      ticketType: json['ticket_type'],
      seatType: json['seat_type'],
      price: json['price'],
      baggageAllowance: json['baggage_allowance'],
      remainingSeats: json['remaining_seats'],
    );
  }
}
