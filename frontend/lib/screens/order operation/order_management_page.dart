import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:frontend/models/order.dart';
import 'package:frontend/services/user_api/flight_api_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail_page.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

  @override
  _OrderManagementPageState createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _currentStatus = ''; // 当前筛选状态
  late String _token;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // 加载订单数据
  Future<void> _loadOrders({String? status}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      _token = TokenManager.getToken();

      final orders = await FlightAPI().fetchUserOrders(_token, status: status);
      setState(() {
        _orders = orders;
        _currentStatus = status ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("加载订单失败: $e")));
    }
  }

  // 取消订单
  Future<void> _cancelOrder(int orderId) async {
    try {
      await FlightAPI().cancelOrder(_token, orderId);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("订单取消成功")));
      _loadOrders(status: _currentStatus); // 重新加载当前状态订单列表
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("取消订单失败: $e")));
    }
  }

  // 订单项组件（美化版）
  Widget _buildOrderItem(Order order) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行：订单号和状态
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "订单号: ${order.orderId}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(
                  label: Text(
                    order.status == "pending"
                        ? "待支付"
                        : order.status == "confirmed"
                            ? "已确认"
                            : order.status == "canceled"
                                ? "已取消"
                                : "已退款",
                  ),
                  backgroundColor: order.status == "pending"
                      ? Colors.orange.shade100
                      : order.status == "confirmed"
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                ),
              ],
            ),
            Divider(),
            // 航班信息和支付金额
            Row(
              children: [
                Icon(Icons.flight_takeoff, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "航班: ${order.flight?['departure_airport']} → ${order.flight?['arrival_airport']}",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      "起飞时间: ${order.flight?['departure_time']}",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  "￥${order.totalPrice.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final detail = await FlightAPI()
                        .fetchOrderDetail(_token, order.orderId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailPage(orderDetail: detail),
                      ),
                    );
                  },
                  child: Text("查看详情"),
                ),
                SizedBox(width: 8),
                if (order.status == 'pending' || order.status == 'confirmed')
                  ElevatedButton(
                    onPressed: () => _cancelOrder(order.orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("取消订单"),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 筛选按钮组件
  Widget _buildFilterButton(String label, String? status) {
    final isSelected = _currentStatus == (status ?? '');
    return ElevatedButton(
      onPressed: () => _loadOrders(status: status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("订单管理"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 筛选按钮
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton("全部", null),
                _buildFilterButton("待支付", "pending"),
                _buildFilterButton("已确认", "confirmed"),
                _buildFilterButton("已取消", "canceled"),
                _buildFilterButton("已退款", "refunded"),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(child: Text("没有订单"))
                    : ListView.builder(
                        itemCount: _orders.length,
                        itemBuilder: (context, index) =>
                            _buildOrderItem(_orders[index]),
                      ),
          ),
        ],
      ),
    );
  }
}
