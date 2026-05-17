import 'dart:convert';
import 'dart:io';

/// Service for handling outcall verification and estimate workflows
class OutcallService {
  static String get _supabaseUrl => const String.fromEnvironment(
    'SUPABASE_URL', 
    defaultValue: 'https://awbqkptzknhlvxfboklf.supabase.co'
  );
  static String get _anonKey => const String.fromEnvironment(
    'SUPABASE_ANON_KEY', 
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnFrcHR6a25obHZ4ZmJva2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1ODQyMDEsImV4cCI6MjA4NTE2MDIwMX0.eyH9HAXyhDguzRVz9urxDviD7fBZ6azOsSh8K03PVeU'
  );

  static Future<Map<String, dynamic>> _postRequest(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$_supabaseUrl/functions/v1/$endpoint');
      final response = await _makeHttpRequest(uri, 'POST', body);
      return response;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _makeHttpRequest(Uri uri, String method, Map<String, dynamic>? body) async {
    // Using runtime HttpClient
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Bearer $_anonKey');
      request.headers.set('apikey', _anonKey);
      
      if (body != null) {
        request.write(jsonEncode(body));
      }
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(responseBody);
        return {'success': false, 'error': errorData['error'] ?? 'Request failed'};
      }
    } finally {
      client.close();
    }
  }

  /// Generate OTP when artisan arrives at location
  static Future<GenerateOtpResult> generateArrivalOtp({
    required String jobReference,
    required String artisanId,
  }) async {
    final body = {
      'jobReference': jobReference,
      'artisanId': artisanId,
    };

    final data = await _postRequest('generateArrivalOtp', body);
    
    if (data['success'] == true) {
      return GenerateOtpResult(
        success: true,
        message: data['message'] ?? 'OTP sent to customer',
        otp: data['otp'],
        otpExpiry: data['otpExpiry'],
        smsSent: data['smsSent'] ?? false,
      );
    } else {
      return GenerateOtpResult(
        success: false,
        message: data['error'] ?? 'Failed to generate OTP',
      );
    }
  }

  /// Get current OTP for a job (for customer to view)
  static Future<GetOtpResult> getJobOtp({
    required String jobReference,
  }) async {
    final body = {
      'jobReference': jobReference,
    };

    final data = await _postRequest('getJobOtp', body);
    
    if (data['success'] == true) {
      return GetOtpResult(
        success: true,
        otp: data['otp'],
        otpExpiry: data['otpExpiry'],
        artisanArrived: data['artisanArrived'] ?? false,
      );
    } else {
      return GetOtpResult(
        success: false,
        message: data['error'] ?? 'Failed to get OTP',
      );
    }
  }

  /// Verify outcall visit - called when artisan arrives
  static Future<OutcallVerifyResult> verifyOutcallVisit({
    required String jobReference,
    required String artisanId,
    required String customerId,
    required String verificationMethod,
    String? otp,
    double? artisanLatitude,
    double? artisanLongitude,
  }) async {
    final body = {
      'jobReference': jobReference,
      'artisanId': artisanId,
      'customerId': customerId,
      'verificationMethod': verificationMethod,
      if (otp != null) 'otp': otp,
      if (artisanLatitude != null) 'artisanLatitude': artisanLatitude,
      if (artisanLongitude != null) 'artisanLongitude': artisanLongitude,
    };

    final data = await _postRequest('verifyOutcallVisit', body);
    
    if (data['success'] == true) {
      return OutcallVerifyResult(
        success: true,
        message: data['message'] ?? 'Outcall verified successfully',
        jobReference: data['jobReference'],
        artisanId: data['artisanId'],
        amountReleased: data['amountReleased'] ?? 2000,
      );
    } else {
      return OutcallVerifyResult(
        success: false,
        message: data['error'] ?? 'Verification failed',
      );
    }
  }

  /// Submit estimate - called by artisan after verification
  static Future<SubmitEstimateResult> submitEstimate({
    required String jobReference,
    required String artisanId,
    required List<EstimateMaterial> materials,
    required double laborCost,
    required String timeline,
    String? notes,
  }) async {
    final body = {
      'jobReference': jobReference,
      'artisanId': artisanId,
      'materials': materials.map((m) => m.toJson()).toList(),
      'laborCost': laborCost,
      'timeline': timeline,
      if (notes != null) 'notes': notes,
    };

    final data = await _postRequest('submitEstimate', body);
    
    if (data['success'] == true) {
      return SubmitEstimateResult(
        success: true,
        message: data['message'] ?? 'Estimate submitted successfully',
        jobReference: data['jobReference'],
        totalEstimate: (data['estimate']?['totalEstimate'] ?? 0).toDouble(),
      );
    } else {
      return SubmitEstimateResult(
        success: false,
        message: data['error'] ?? 'Failed to submit estimate',
      );
    }
  }

  /// Respond to estimate - called by customer to accept or decline
  static Future<RespondEstimateResult> respondToEstimate({
    required String jobReference,
    required String customerId,
    required String response,
  }) async {
    final body = {
      'jobReference': jobReference,
      'customerId': customerId,
      'response': response,
    };

    final data = await _postRequest('respondToEstimate', body);
    
    if (data['success'] == true) {
      return RespondEstimateResult(
        success: true,
        message: data['message'] ?? 'Response recorded',
        response: data['response'],
        contractReference: data['contract']?['contractReference'],
        totalAmount: (data['contract']?['totalAmount'] ?? 0).toDouble(),
      );
    } else {
      return RespondEstimateResult(
        success: false,
        message: data['error'] ?? 'Failed to respond to estimate',
      );
    }
  }

  /// Accept estimate - creates contract with escrow
  static Future<AcceptEstimateResult> acceptEstimate({
    required String jobReference,
    required String customerId,
  }) async {
    final body = {
      'jobReference': jobReference,
      'customerId': customerId,
    };

    final data = await _postRequest('acceptEstimate', body);
    
    if (data['success'] == true) {
      return AcceptEstimateResult(
        success: true,
        message: data['message'] ?? 'Estimate accepted',
        jobReference: data['jobReference'],
        contractReference: data['contractReference'],
        escrowAmount: (data['escrowAmount'] ?? 0).toDouble(),
      );
    } else {
      return AcceptEstimateResult(
        success: false,
        message: data['error'] ?? 'Failed to accept estimate',
      );
    }
  }

  /// Decline estimate - closes job, artisan keeps outcall fee
  static Future<DeclineEstimateResult> declineEstimate({
    required String jobReference,
    required String customerId,
  }) async {
    final body = {
      'jobReference': jobReference,
      'customerId': customerId,
    };

    final data = await _postRequest('declineEstimate', body);
    
    if (data['success'] == true) {
      return DeclineEstimateResult(
        success: true,
        message: data['message'] ?? 'Estimate declined',
        jobReference: data['jobReference'],
      );
    } else {
      return DeclineEstimateResult(
        success: false,
        message: data['error'] ?? 'Failed to decline estimate',
      );
    }
  }

  /// Generate completion OTP when artisan finishes job
  static Future<GenerateCompletionOtpResult> generateJobCompletionOtp({
    required String jobReference,
    required String artisanId,
  }) async {
    final body = {
      'jobReference': jobReference,
      'artisanId': artisanId,
    };

    final data = await _postRequest('generateJobCompletionOtp', body);
    
    if (data['success'] == true) {
      return GenerateCompletionOtpResult(
        success: true,
        message: data['message'] ?? 'Completion OTP generated',
        otp: data['otp'],
        otpExpiry: data['otpExpiry'],
        customerNotified: data['customerNotified'] ?? false,
      );
    } else {
      return GenerateCompletionOtpResult(
        success: false,
        message: data['error'] ?? 'Failed to generate completion OTP',
      );
    }
  }

  /// Verify and release labor cost to wallet
  static Future<ReleaseLaborResult> verifyAndReleaseLabor({
    required String jobReference,
    required String artisanId,
    String? customerOtp,
  }) async {
    final body = {
      'jobReference': jobReference,
      'artisanId': artisanId,
      if (customerOtp != null) 'customerOtp': customerOtp,
    };

    final data = await _postRequest('verifyAndReleaseLabor', body);
    
    if (data['success'] == true) {
      return ReleaseLaborResult(
        success: true,
        message: data['message'] ?? 'Labor released',
        amountReleased: (data['amountReleased'] ?? 0).toDouble(),
        transactionRef: data['transactionRef'],
      );
    } else {
      return ReleaseLaborResult(
        success: false,
        message: data['error'] ?? 'Failed to release labor',
      );
    }
  }
}

/// Result class for generateArrivalOtp
class GenerateOtpResult {
  final bool success;
  final String message;
  final String? otp;
  final String? otpExpiry;
  final bool smsSent;

  GenerateOtpResult({
    required this.success,
    required this.message,
    this.otp,
    this.otpExpiry,
    this.smsSent = false,
  });
}

/// Result class for getJobOtp
class GetOtpResult {
  final bool success;
  final String? otp;
  final String? otpExpiry;
  final bool artisanArrived;
  final String? message;

  GetOtpResult({
    required this.success,
    this.otp,
    this.otpExpiry,
    this.artisanArrived = false,
    this.message,
  });
}

/// Result class for verifyOutcallVisit
class OutcallVerifyResult {
  final bool success;
  final String message;
  final String? jobReference;
  final String? artisanId;
  final int amountReleased;

  OutcallVerifyResult({
    required this.success,
    required this.message,
    this.jobReference,
    this.artisanId,
    this.amountReleased = 0,
  });
}

/// Material item for estimate
class EstimateMaterial {
  final String name;
  final double cost;
  final int quantity;

  EstimateMaterial({
    required this.name,
    required this.cost,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cost': cost,
      'quantity': quantity,
    };
  }
}

/// Result class for submitEstimate
class SubmitEstimateResult {
  final bool success;
  final String message;
  final String? jobReference;
  final double totalEstimate;

  SubmitEstimateResult({
    required this.success,
    required this.message,
    this.jobReference,
    this.totalEstimate = 0,
  });
}

/// Result class for respondToEstimate
class RespondEstimateResult {
  final bool success;
  final String message;
  final String? response;
  final String? contractReference;
  final double totalAmount;

  RespondEstimateResult({
    required this.success,
    required this.message,
    this.response,
    this.contractReference,
    this.totalAmount = 0,
  });
}

/// Result class for acceptEstimate
class AcceptEstimateResult {
  final bool success;
  final String message;
  final String? jobReference;
  final String? contractReference;
  final double escrowAmount;

  AcceptEstimateResult({
    required this.success,
    required this.message,
    this.jobReference,
    this.contractReference,
    this.escrowAmount = 0,
  });
}

/// Result class for declineEstimate
class DeclineEstimateResult {
  final bool success;
  final String message;
  final String? jobReference;

  DeclineEstimateResult({
    required this.success,
    required this.message,
    this.jobReference,
  });
}

/// Result class for generateJobCompletionOtp
class GenerateCompletionOtpResult {
  final bool success;
  final String message;
  final String? otp;
  final String? otpExpiry;
  final bool customerNotified;

  GenerateCompletionOtpResult({
    required this.success,
    required this.message,
    this.otp,
    this.otpExpiry,
    this.customerNotified = false,
  });
}

/// Result class for verifyAndReleaseLabor
class ReleaseLaborResult {
  final bool success;
  final String message;
  final double amountReleased;
  final String? transactionRef;

  ReleaseLaborResult({
    required this.success,
    required this.message,
    this.amountReleased = 0,
    this.transactionRef,
  });
}
