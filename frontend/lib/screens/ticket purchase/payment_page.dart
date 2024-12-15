import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'dart:async';
import 'package:frontend/models/order.dart';
import 'package:frontend/services/user_api/flight_api_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentPage extends StatelessWidget {
  final Order order;

  const PaymentPage({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("支付订单"),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderSummary(),
            SizedBox(height: 16),
            _buildPaymentOptions(),
            Spacer(),
            _buildPayButton(context),
          ],
        ),
      ),
    );
  }

  // 订单总结卡片
  Widget _buildOrderSummary() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "订单确认",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            Divider(thickness: 1, color: Colors.grey[300]),
            SizedBox(height: 10),
            _buildDetailRow("订单号", "${order.orderId}"),
            SizedBox(height: 8),
            _buildDetailRow("支付金额", "￥${order.totalPrice.toStringAsFixed(2)}",
                isHighlight: true),
            SizedBox(height: 8),
            _buildDetailRow("支付状态", "待支付"),
          ],
        ),
      ),
    );
  }

  // 支付选项区域
  Widget _buildPaymentOptions() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "选择支付方式",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            _buildPaymentOption(
              icon: Icons.credit_card,
              title: "信用卡/借记卡",
              subtitle: "支持Visa, MasterCard, 银联等",
            ),
            SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.account_balance_wallet,
              title: "支付宝",
              subtitle: "推荐使用支付宝进行快速支付",
            ),
            SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.payment,
              title: "微信支付",
              subtitle: "支持微信扫码支付",
            ),
          ],
        ),
      ),
    );
  }

  // 支付按钮，调用支付操作
  Widget _buildPayButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        onPressed: () async {
          _simulatePayment(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          "立即支付",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 模拟支付操作，弹出支付成功窗口，倒计时返回主页
  Future<void> _simulatePayment(BuildContext context) async {
    // 显示加载状态
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Center(
          child: CircularProgressIndicator(color: Colors.teal),
        );
      },
    );

    try {
      String? token = TokenManager.getToken();
      if (token == null) throw Exception("用户未登录，未获取到Token");

      // 调用确认订单接口
      await FlightAPI().confirmOrder(token, order.orderId);

      // 关闭加载状态
      Navigator.of(context, rootNavigator: true).pop();

      // 显示支付成功弹窗
      _showPaymentSuccessDialog(context);
    } catch (e) {
      // 关闭加载状态
      Navigator.of(context, rootNavigator: true).pop();

      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("支付失败: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 支付成功弹窗
  void _showPaymentSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("支付成功"),
          content: Text("您的订单已支付成功！即将返回主页。"),
        );
      },
    );

    // 自动倒计时后返回主页
    Future.delayed(Duration(seconds: 3), () {
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  // 构建单个支付选项
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 32),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        Spacer(),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ],
    );
  }

  // 构建订单详情行
  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? Colors.orange : Colors.black87,
          ),
        ),
      ],
    );
  }
}
