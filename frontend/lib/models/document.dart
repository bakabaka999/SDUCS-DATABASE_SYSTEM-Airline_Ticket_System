/// 证件数据模型
/// 用于表示与乘机人关联的证件信息，包括证件类型、证件号码等。
class Document {
  final int id; // 证件ID
  final String type; // 证件类型，例如身份证、护照等
  final String number; // 证件号码
  final int passengerId; // 关联的乘机人ID

  // 构造函数，用于初始化证件对象
  Document({
    required this.id,
    required this.type,
    required this.number,
    required this.passengerId,
  });

  /// 将从后端获取到的JSON数据转换为Document对象
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['document_id'], // 证件ID
      type: json['document_type'], // 证件类型
      number: json['document_number'], // 证件号码
      passengerId: json['passenger_id'], // 关联的乘机人ID
    );
  }

  /// 将Document对象转换为JSON数据，便于发送给后端
  Map<String, dynamic> toJson() {
    return {
      'document_id': id, // 证件ID
      'document_type': type, // 证件类型
      'document_number': number, // 证件号码
      'passenger_id': passengerId, // 关联的乘机人ID
    };
  }
}
