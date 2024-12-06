class Invoice {
  final String type; // 发票类型，如 '个人' 或 '公司'
  final String name; // 发票名称
  final String identificationNumber; // 识别号（如果是公司类型，必填）
  final String companyAddress; // 公司地址（如果是公司类型，必填）
  final String phoneNumber; // 电话号码
  final String bankName; // 开户银行名称
  final String bankAccount; // 开户银行账号

  // 构造函数
  Invoice({
    required this.type,
    required this.name,
    required this.identificationNumber,
    required this.companyAddress,
    required this.phoneNumber,
    required this.bankName,
    required this.bankAccount,
  });

  // 通过 JSON 数据构造 Invoice 实例
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      type: json['type'],
      name: json['name'],
      identificationNumber: json['identification_number'] ?? '',
      companyAddress: json['company_address'] ?? '',
      phoneNumber: json['phone_number'],
      bankName: json['bank_name'],
      bankAccount: json['bank_account'],
    );
  }

  // 将 Invoice 实例转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'identification_number': identificationNumber,
      'company_address': companyAddress,
      'phone_number': phoneNumber,
      'bank_name': bankName,
      'bank_account': bankAccount,
    };
  }
}
