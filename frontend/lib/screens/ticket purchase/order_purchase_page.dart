import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/ticket%20purchase/payment_page.dart';
import 'package:frontend/screens/ticket%20purchase/select_passenger_page.dart';
import '../../services/user_api/flight_api_server.dart';
import '../../../models/passenger.dart';
import '../../../models/document.dart';

class OrderPurchasePage extends StatefulWidget {
  final int flightId;
  final int ticketId;
  final String departureTime;
  final String arrivalTime;
  final String departureAirport;
  final String arrivalAirport;
  final String seatType;
  final double price;

  const OrderPurchasePage({
    Key? key,
    required this.flightId,
    required this.ticketId,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.seatType,
    required this.price,
  }) : super(key: key);

  @override
  _OrderPurchasePageState createState() => _OrderPurchasePageState();
}

class _OrderPurchasePageState extends State<OrderPurchasePage> {
  Passenger? _selectedPassenger;
  Document? _selectedDocument;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("确认订单", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFlightInfoCard(),
          SizedBox(height: 12),
          _buildPassengerSection(),
          Spacer(),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildFlightInfoCard() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeSection(
                    widget.departureTime, widget.departureAirport),
                Icon(Icons.flight_takeoff, color: Colors.teal, size: 36),
                _buildTimeSection(widget.arrivalTime, widget.arrivalAirport),
              ],
            ),
            SizedBox(height: 12),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "航班号: ${widget.flightId}",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                Text(
                  "￥${widget.price.toStringAsFixed(0)} | ${_convertSeatType(widget.seatType)}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("出行旅客",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          if (_selectedPassenger != null && _selectedDocument != null)
            Row(
              children: [
                Icon(Icons.account_circle, size: 32, color: Colors.teal),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPassenger!.name,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${_selectedDocument!.type}: ${_selectedDocument!.number}",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Text("请选择乘客信息",
                style: TextStyle(fontSize: 16, color: Colors.black54)),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SelectPassengerPage()),
                );
                if (result != null && result is Map) {
                  setState(() {
                    _selectedPassenger = result["passenger"];
                    _selectedDocument = result["document"];
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _selectedPassenger == null ? "添加乘客" : "更改乘客",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _handleOrderConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: Size(double.infinity, 50),
        ),
        child: Text(
          "提交订单",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleOrderConfirmation() async {
    if (_selectedPassenger == null || _selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("请先选择乘客信息")),
      );
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("正在创建订单...")));

    try {
      String? token = TokenManager.getToken();
      if (token == null) throw Exception("用户未登录");

      final order = await FlightAPI()
          .purchaseTicket(token, _selectedPassenger!.id, widget.ticketId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentPage(order: order)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("订单创建失败: $e")));
    }
  }

  Widget _buildTimeSection(String time, String airport) {
    return Column(
      children: [
        Text(
          DateFormat('HH:mm').format(DateTime.parse(time)),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(airport, style: TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
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
}
