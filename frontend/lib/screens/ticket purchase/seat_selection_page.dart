import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/user_api/flight_api_server.dart';
import '../../../models/ticket.dart';
import 'order_purchase_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final int flightId;
  final String departureTime;
  final String arrivalTime;
  final String departureAirport;
  final String arrivalAirport;

  const SeatSelectionPage({
    Key? key,
    required this.flightId,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.arrivalAirport,
  }) : super(key: key);

  @override
  _SeatSelectionPageState createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage>
    with SingleTickerProviderStateMixin {
  List<Ticket> tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
  }

  Future<void> _fetchTickets() async {
    setState(() => _isLoading = true);
    try {
      String? token = TokenManager.getToken();
      if (token == null) throw Exception("用户未登录");

      tickets = await FlightAPI().fetchFlightTickets(token, widget.flightId);
    } catch (e) {
      setState(() => _errorMessage = "获取舱位信息失败，请稍后重试。");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNextDay = _isNextDay(widget.departureTime, widget.arrivalTime);

    return Scaffold(
      appBar: AppBar(
        title: Text("选择舱位", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: TextStyle(color: Colors.redAccent)))
              : Column(
                  children: [
                    _buildFlightInfoHeader(isNextDay),
                    Expanded(child: _buildSeatList()),
                  ],
                ),
    );
  }

  Widget _buildFlightInfoHeader(bool isNextDay) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn(widget.departureTime, widget.departureAirport),
              Icon(Icons.flight_takeoff, color: Colors.teal, size: 36),
              _buildTimeColumn(widget.arrivalTime, widget.arrivalAirport,
                  isNextDay: isNextDay),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "航班号: ${widget.flightId}  |  Airbus A380",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String time, String airport,
      {bool isNextDay = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _formatTime(time),
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        if (isNextDay)
          Text("+1 天", style: TextStyle(fontSize: 14, color: Colors.red)),
        SizedBox(height: 4),
        Text(
          airport,
          style: TextStyle(fontSize: 16, color: Colors.teal.shade700),
        ),
      ],
    );
  }

  Widget _buildSeatList() {
    Map<String, List<Ticket>> groupedTickets = _groupTicketsBySeatType();

    return ListView(
      children: groupedTickets.entries.map((entry) {
        return _buildSeatTypeCard(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildSeatTypeCard(String seatType, List<Ticket> tickets) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              _convertSeatType(seatType),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            leading: Icon(Icons.airline_seat_recline_extra, color: Colors.teal),
          ),
          Divider(),
          ...tickets.map((ticket) => _buildTicketRow(ticket)).toList(),
        ],
      ),
    );
  }

  Widget _buildTicketRow(Ticket ticket) {
    return ListTile(
      leading: Icon(Icons.airplane_ticket_outlined, color: Colors.blueAccent),
      title: Text(
        "${_convertTicketType(ticket.ticketType)} - ￥${ticket.price.toStringAsFixed(0)}",
        style: TextStyle(fontSize: 16),
      ),
      subtitle: Text("行李额：${ticket.baggageAllowance} Kg"),
      trailing: ElevatedButton(
        onPressed: () => _navigateToOrder(ticket),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text("订票", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _navigateToOrder(Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPurchasePage(
          flightId: widget.flightId,
          ticketId: ticket.ticketId,
          departureTime: widget.departureTime,
          arrivalTime: widget.arrivalTime,
          departureAirport: widget.departureAirport,
          arrivalAirport: widget.arrivalAirport,
          seatType: ticket.seatType,
          price: ticket.price,
        ),
      ),
    );
  }

  Map<String, List<Ticket>> _groupTicketsBySeatType() {
    Map<String, List<Ticket>> groupedTickets = {};
    for (var ticket in tickets) {
      groupedTickets.putIfAbsent(ticket.seatType, () => []).add(ticket);
    }
    return groupedTickets;
  }

  String _convertSeatType(String seatType) {
    switch (seatType) {
      case 'economy':
        return "经济舱";
      case 'business':
        return "商务舱";
      case 'first_class':
        return "头等舱";
      default:
        return "未知舱位";
    }
  }

  String _convertTicketType(String ticketType) {
    switch (ticketType) {
      case 'adult':
        return "成人票";
      case 'student':
        return "学生票";
      case 'teacher':
        return "教师票";
      case 'senior':
        return "老年票";
      default:
        return "未知票型";
    }
  }

  bool _isNextDay(String departure, String arrival) {
    final depTime = DateTime.parse(departure);
    final arrTime = DateTime.parse(arrival);
    return arrTime.day > depTime.day;
  }

  String _formatTime(String dateTimeStr) {
    return DateFormat('HH:mm').format(DateTime.parse(dateTimeStr));
  }
}
