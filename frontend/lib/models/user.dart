/// 用户数据模型
/// 用于表示用户信息，包括用户的基本信息、账户信息等。
/// 这个模型会用于从后端获取用户数据和向后端发送数据。
library;

class User {
  final int id; // 用户ID
  final String name; // 用户名
  final String email; // 用户邮箱
  final String phoneNumber; // 用户手机号
  final double accumulatedMiles; // 用户累计里程
  final int ticketCount; // 用户购票次数

  // 构造函数，用于初始化用户对象
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber = '',
    this.accumulatedMiles = 0,
    this.ticketCount = 0,
  });

  /// 将从后端获取到的JSON数据转换为User对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'], // 用户ID
      name: json['name'], // 用户名
      email: json['email'], // 用户邮箱
      phoneNumber: json['phone_number'] ?? '', // 用户手机号（可能为空）
      accumulatedMiles: json['accumulated_miles'] ?? 0.0, // 累计里程
      ticketCount: json['ticked_count'] ?? 0, // 购票次数
    );
  }

  /// 将User对象转换为JSON数据，便于发送给后端
  Map<String, dynamic> toJson() {
    return {
      'id': id, // 用户ID
      'name': name, // 用户名
      'email': email, // 用户邮箱
      'phone_number': phoneNumber, // 用户手机号
      'accumulated_miles': accumulatedMiles, // 累计里程
      'ticked_count': ticketCount, // 购票次数
    };
  }
}
