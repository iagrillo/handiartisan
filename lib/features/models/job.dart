class Job {
  final String? id;
  final String jobReference;
  final String? artisanId;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerName;
  final String? serviceType;
  final String? description;
  final String? address;
  final int amountPaid;
  final int escrowAmount;
  final int commissionAmount;
  final String? status;
  final String? paymentReference;
  final String? transferReference;
  final String? refundReference;
  final String? scheduledDate;
  final String? completedDate;
  final String? createdAt;
  final String? updatedAt;

  // Estimate fields
  final String? estimateMaterials;
  final double? estimateMaterialsCost;
  final double? estimateLaborCost;
  final double? estimateTotal;
  final String? estimateTimeline;
  final String? estimateNotes;
  final String? estimateStatus;
  final String? estimateSubmittedAt;
  final String? estimateRespondedAt;

  // Tracking fields
  final String? declinedBy;
  final bool? customerRequestedNewEstimate;
  final String? arrivalOtp;
  final String? arrivalOtpExpiry;
  final String? customerOtp;
  final bool? artisanArrived;

  // Completion OTP fields
  final String? completionOtp;
  final String? completionOtpExpiry;
  final bool? laborCostReleased;
  final String? laborCostReleasedAt;
  final bool? customerVerified;
  final String? customerVerifiedAt;

  Job({
    this.id,
    required this.jobReference,
    this.artisanId,
    this.customerEmail,
    this.customerPhone,
    this.customerName,
    this.serviceType,
    this.description,
    this.address,
    this.amountPaid = 0,
    this.escrowAmount = 0,
    this.commissionAmount = 0,
    this.status,
    this.paymentReference,
    this.transferReference,
    this.refundReference,
    this.scheduledDate,
    this.completedDate,
    this.createdAt,
    this.updatedAt,
    this.estimateMaterials,
    this.estimateMaterialsCost,
    this.estimateLaborCost,
    this.estimateTotal,
    this.estimateTimeline,
    this.estimateNotes,
    this.estimateStatus,
    this.estimateSubmittedAt,
    this.estimateRespondedAt,
    this.declinedBy,
    this.customerRequestedNewEstimate,
    this.arrivalOtp,
    this.arrivalOtpExpiry,
    this.customerOtp,
    this.artisanArrived,
    this.completionOtp,
    this.completionOtpExpiry,
    this.laborCostReleased,
    this.laborCostReleasedAt,
    this.customerVerified,
    this.customerVerifiedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id']?.toString(),
      jobReference: json['job_reference'] ?? '',
      artisanId: json['artisan_id']?.toString(),
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      customerName: json['customer_name'],
      serviceType: json['service_type'],
      description: json['description'],
      address: json['address'],
      amountPaid: json['amount_paid'] ?? 0,
      escrowAmount: json['escrow_amount'] ?? 0,
      commissionAmount: json['commission_amount'] ?? 0,
      status: json['status'] ?? 'pending',
      paymentReference: json['payment_reference'],
      transferReference: json['transfer_reference'],
      refundReference: json['refund_reference'],
      scheduledDate: json['scheduled_date'],
      completedDate: json['completed_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      estimateMaterials: json['estimate_materials'],
      estimateMaterialsCost: json['estimate_materials_cost']?.toDouble(),
      estimateLaborCost: json['estimate_labor_cost']?.toDouble(),
      estimateTotal: json['estimate_total']?.toDouble(),
      estimateTimeline: json['estimate_timeline'],
      estimateNotes: json['estimate_notes'],
      estimateStatus: json['estimate_status'],
      estimateSubmittedAt: json['estimate_submitted_at'],
      estimateRespondedAt: json['estimate_responded_at'],
      declinedBy: json['declined_by'],
      customerRequestedNewEstimate: json['customer_requested_new_estimate'],
      arrivalOtp: json['arrival_otp'] ?? json['artisan_arrival_otp'],
      arrivalOtpExpiry: json['arrival_otp_expiry'],
      customerOtp: json['customer_otp'],
      artisanArrived: json['artisan_arrived'] ?? json['artisan_arrived'],
      completionOtp: json['completion_otp'],
      completionOtpExpiry: json['completion_otp_expiry'],
      laborCostReleased: json['labor_cost_released'],
      laborCostReleasedAt: json['labor_cost_released_at'],
      customerVerified: json['customer_verified'],
      customerVerifiedAt: json['customer_verified_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_reference': jobReference,
      'artisan_id': artisanId,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_name': customerName,
      'service_type': serviceType,
      'description': description,
      'address': address,
      'amount_paid': amountPaid,
      'escrow_amount': escrowAmount,
      'commission_amount': commissionAmount,
      'status': status,
      'payment_reference': paymentReference,
      'transfer_reference': transferReference,
      'refund_reference': refundReference,
      'scheduled_date': scheduledDate,
      'completed_date': completedDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'estimate_materials': estimateMaterials,
      'estimate_materials_cost': estimateMaterialsCost,
      'estimate_labor_cost': estimateLaborCost,
      'estimate_total': estimateTotal,
      'estimate_timeline': estimateTimeline,
      'estimate_notes': estimateNotes,
      'estimate_status': estimateStatus,
      'estimate_submitted_at': estimateSubmittedAt,
      'estimate_responded_at': estimateRespondedAt,
      'declined_by': declinedBy,
      'customer_requested_new_estimate': customerRequestedNewEstimate,
      'artisan_arrival_otp': arrivalOtp,
      'arrival_otp_expiry': arrivalOtpExpiry,
      'customer_otp': customerOtp,
      'artisan_arrived': artisanArrived,
      'completion_otp': completionOtp,
      'completion_otp_expiry': completionOtpExpiry,
      'labor_cost_released': laborCostReleased,
      'labor_cost_released_at': laborCostReleasedAt,
      'customer_verified': customerVerified,
      'customer_verified_at': customerVerifiedAt,
    };
  }
}