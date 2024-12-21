import 'package:flutter/material.dart';
import 'package:frontend/models/order.dart';

class OrderDetailPage extends StatelessWidget {
  final Order orderDetail;

  const OrderDetailPage({Key? key, required this.orderDetail})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final flight = orderDetail.ticket?['flight'];
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("订单详情"),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle("订单信息"),
              _buildOrderInfoCard(),
              SizedBox(height: 16),
              _buildSectionTitle("乘客信息"),
              _buildPassengerInfoCard(),
              SizedBox(height: 16),
              _buildSectionTitle("航班信息"),
              _buildFlightInfoCard(flight),
              SizedBox(height: 16),
              _buildSectionTitle("票务信息"),
              _buildTicketInfoCard(),
              SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // 分区标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }

  // 订单信息卡片
  Widget _buildOrderInfoCard() {
    return _buildInfoCard([
      _buildRow("订单号", "${orderDetail.orderId}"),
      _buildRow("状态", "${orderDetail.status}"),
      _buildRow("下单时间", "${orderDetail.purchaseTime}"),
      _buildRow("总价", "￥${orderDetail.totalPrice}", highlight: true),
    ]);
  }

  // 乘客信息卡片
  Widget _buildPassengerInfoCard() {
    final passenger = orderDetail.passenger;
    return _buildInfoCard([
      _buildRow("姓名", passenger?['name'] ?? ""),
      _buildRow("性别", passenger?['gender'] ?? ""),
      _buildRow("电话", passenger?['phone_number'] ?? ""),
      _buildRow("邮箱", passenger?['email'] ?? ""),
    ]);
  }

  // 航班信息卡片
  Widget _buildFlightInfoCard(Map<String, dynamic>? flight) {
    return _buildInfoCard([
      _buildRow("起飞机场", flight?['departure_airport'] ?? "未知"),
      _buildRow("到达机场", flight?['arrival_airport'] ?? "未知"),
      _buildRow("起飞时间", flight?['departure_time'] ?? "未知"),
      _buildRow("到达时间", flight?['arrival_time'] ?? "未知"),
    ]);
  }

  // 票务信息卡片
  Widget _buildTicketInfoCard() {
    final ticket = orderDetail.ticket;
    return _buildInfoCard([
      _buildRow("座位类型", _convertSeatType(ticket?['seat_type'])),
      _buildRow("票价", "￥${ticket?['price'] ?? "未知"}"),
      _buildRow("行李额度", "${ticket?['baggage_allowance'] ?? '无'}"),
    ]);
  }

  // 构建信息卡片
  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // 构建行
  Widget _buildRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.orange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // 转换座位类型为中文
  String _convertSeatType(String? seatType) {
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

  // 操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text("返回", style: TextStyle(color: Colors.white)),
        ),
        // ElevatedButton(
        //   onPressed: () {
        //     print("取消订单: ${orderDetail.orderId}");
        //   },
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.red,
        //     padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        //   ),
        //   child: Text("取消订单", style: TextStyle(color: Colors.white)),
        // ),
      ],
    );
  }
}
