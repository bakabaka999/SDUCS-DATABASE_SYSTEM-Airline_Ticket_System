// 用户订单模型
class Order {
  final int orderId;
  final String status;
  final double totalPrice;
  final String purchaseTime;
  final String? refundTime;
  final double? refundAmount;
  final Map<String, dynamic>? flight; // 航班信息
  final Map<String, dynamic>? ticket; // 机票信息
  final Map<String, dynamic>? passenger; // 乘客信息

  Order({
    required this.orderId,
    required this.status,
    required this.totalPrice,
    required this.purchaseTime,
    this.refundTime,
    this.refundAmount,
    this.flight,
    this.ticket,
    this.passenger,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      status: json['status'],
      totalPrice: json['total_price'],
      purchaseTime: json['purchase_time'],
      refundTime: json['refund_time'],
      refundAmount: json['refund_amount'],
      flight: json['flight_info'],
      ticket: json['ticket'], // 解析机票信息
      passenger: json['passenger'], // 解析乘客信息
    );
  }
}
