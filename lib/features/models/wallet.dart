class Wallet {
  final String? id;
  final String artisanId;
  final int pendingBalance;
  final int availableBalance;
  final int totalEarned;
  final int totalWithdrawn;
  final String? paystackTransferCode;
  final String? paystackRecipientCode;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final bool isVerified;
  final String? createdAt;
  final String? updatedAt;

  Wallet({
    this.id,
    required this.artisanId,
    this.pendingBalance = 0,
    this.availableBalance = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
    this.paystackTransferCode,
    this.paystackRecipientCode,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id']?.toString(),
      artisanId: json['artisan_id'] ?? '',
      pendingBalance: _parseInt(json['pending_balance']),
      availableBalance: _parseInt(json['available_balance']),
      totalEarned: _parseInt(json['total_earned']),
      totalWithdrawn: _parseInt(json['total_withdrawn']),
      paystackTransferCode: json['paystack_transfer_code'],
      paystackRecipientCode: json['paystack_recipient_code'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      accountName: json['account_name'],
      isVerified: _parseBool(json['is_verified']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artisan_id': artisanId,
      'pending_balance': pendingBalance,
      'available_balance': availableBalance,
      'total_earned': totalEarned,
      'total_withdrawn': totalWithdrawn,
      'paystack_transfer_code': paystackTransferCode,
      'paystack_recipient_code': paystackRecipientCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'is_verified': isVerified,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class PaymentTransaction {
  final String? id;
  final String reference;
  final String? jobReference;
  final String? artisanId;
  final String? customerEmail;
  final int amount;
  final int fee;
  final int netAmount;
  final String type;
  final String status;
  final Map<String, dynamic>? paystackResponse;
  final String? failureReason;
  final String? createdAt;
  final String? updatedAt;

  PaymentTransaction({
    this.id,
    required this.reference,
    this.jobReference,
    this.artisanId,
    this.customerEmail,
    required this.amount,
    this.fee = 0,
    required this.netAmount,
    required this.type,
    this.status = 'pending',
    this.paystackResponse,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  
  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id']?.toString(),
      reference: json['reference'] ?? '',
      jobReference: json['job_reference'],
      artisanId: json['artisan_id']?.toString(),
      customerEmail: json['customer_email'],
      amount: _parseInt(json['amount']),
      fee: _parseInt(json['fee']),
      netAmount: _parseInt(json['net_amount']),
      type: json['type'] ?? '',
      status: json['status'] ?? 'pending',
      paystackResponse: json['paystack_response'] as Map<String, dynamic>?,
      failureReason: json['failure_reason'],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'job_reference': jobReference,
      'artisan_id': artisanId,
      'customer_email': customerEmail,
      'amount': amount,
      'fee': fee,
      'net_amount': netAmount,
      'type': type,
      'status': status,
      'paystack_response': paystackResponse,
      'failure_reason': failureReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
