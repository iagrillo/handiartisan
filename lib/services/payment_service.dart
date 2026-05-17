
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../features/models/job.dart';
import '../features/models/wallet.dart';

class PaymentService {

  /// Withdraw funds from wallet by calling a Supabase Edge Function
  static Future<bool> withdrawFromWallet({
    required String artisanId,
    required int amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'withdrawFunds',
        body: {
          'artisanId': artisanId,
          'amount': amount,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountName': accountName,
        },
      );
      // Check response.data for success
      return response.data != null && (response.data['success'] == true || response.data['status'] == 'success');
    } catch (e) {
      debugPrint('withdrawFromWallet error: $e');
      return false;
    }
  }

    /// Deposit funds to a wallet using Edge Function with Authorization header
    static Future<bool> depositToWallet(String artisanId, int amount) async {
      if (amount <= 0) return false;
      try {
        final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
        if (accessToken == null) {
          throw Exception('User not authenticated');
        }
        final response = await http.post(
          Uri.parse('https://awbqkptzknhlvxfboklf.supabase.co/functions/v1/depositFunds'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'artisanId': artisanId,
            'amount': amount,
          }),
        );
        debugPrint('depositToWallet response: \\${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['success'] == true;
        }
        return false;
      } catch (e) {
        debugPrint('depositToWallet error: $e');
        return false;
      }
    }

    /// Transfer funds from one wallet to another (demo: just decreases sender, increases receiver)
    static Future<bool> transferFromWallet({
      required String fromArtisanId,
      required String toArtisanId,
      required int amount,
    }) async {
      if (amount <= 0) return false;
      try {
        final fromWallet = await getWallet(fromArtisanId);
        final toWallet = await getWallet(toArtisanId);
        if (fromWallet == null || toWallet == null) return false;
        if (fromWallet.availableBalance < amount) return false;
        await _client.from('wallets').update({
          'available_balance': fromWallet.availableBalance - amount,
          'total_withdrawn': fromWallet.totalWithdrawn + amount,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('artisan_id', fromArtisanId);
        await _client.from('wallets').update({
          'available_balance': toWallet.availableBalance + amount,
          'total_earned': toWallet.totalEarned + amount,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('artisan_id', toArtisanId);
        return true;
      } catch (e) {
        debugPrint('transferFromWallet error: $e');
        return false;
      }
    }
  static SupabaseClient get _client => Supabase.instance.client;
  static String? _walletAuthEmail;
  static String? _walletAuthPhone;
  static String? _walletAuthPassword;
  static String? _walletAuthArtisanId;
  static DateTime? _walletAccessDisabledUntil;
  static bool _walletAccessFailureLogged = false;

  static void setWalletAccessCredentials({
    required String email,
    required String phone,
    required String password,
    required String artisanId,
  }) {
    _walletAuthEmail = email;
    _walletAuthPhone = phone;
    _walletAuthPassword = password;
    _walletAuthArtisanId = artisanId;
    _walletAccessDisabledUntil = null;
    _walletAccessFailureLogged = false;
  }

  static void clearWalletAccessCredentials() {
    _walletAuthEmail = null;
    _walletAuthPhone = null;
    _walletAuthPassword = null;
    _walletAuthArtisanId = null;
    _walletAccessDisabledUntil = null;
    _walletAccessFailureLogged = false;
  }

  static Future<String?> getArtisanIdForCurrentUser({String? email}) async {
    final currentEmail = (email ?? _client.auth.currentUser?.email)?.trim();
    if (currentEmail == null || currentEmail.isEmpty) return null;

    try {
      final response = await _client
          .from('artisans')
          .select('id')
          .eq('email', currentEmail)
          .limit(1);

      final rows = response as List;
      if (rows.isEmpty) return null;

      final artisanId = rows.first['id']?.toString();
      if (artisanId != null && artisanId.isNotEmpty) {
        await _ensureWalletRecord(artisanId);
      }
      return artisanId;
    } catch (e) {
      debugPrint('getArtisanIdForCurrentUser error: $e');
      return null;
    }
  }

  static bool get _hasWalletAccessCredentials =>
      _walletAuthEmail != null &&
      _walletAuthPhone != null &&
      _walletAuthPassword != null;

  static bool get _walletAccessTemporarilyDisabled =>
      _walletAccessDisabledUntil != null &&
      DateTime.now().isBefore(_walletAccessDisabledUntil!);

  static void _temporarilyDisableWalletAccess(Object error) {
    final alreadyDisabled = _walletAccessTemporarilyDisabled;
    _walletAccessDisabledUntil = DateTime.now().add(const Duration(minutes: 5));

    if (!alreadyDisabled || !_walletAccessFailureLogged) {
      debugPrint(
        'walletAccess unavailable; falling back to direct wallet queries for '
        '5 minutes: $error',
      );
      _walletAccessFailureLogged = true;
    }
  }

  static Future<Map<String, dynamic>?> _invokeWalletAccess({
    required String action,
    String? artisanId,
    String? bankName,
    String? accountNumber,
    String? accountName,
  }) async {
    if (!_hasWalletAccessCredentials || _walletAccessTemporarilyDisabled) {
      return null;
    }

    try {
      final response = await _client.functions.invoke(
        'walletAccess',
        body: {
          'action': action,
          'artisanId': artisanId ?? _walletAuthArtisanId,
          'email': _walletAuthEmail,
          'phone': _walletAuthPhone,
          'password': _walletAuthPassword,
          if (bankName != null) 'bankName': bankName,
          if (accountNumber != null) 'accountNumber': accountNumber,
          if (accountName != null) 'accountName': accountName,
        },
      );

      _walletAccessDisabledUntil = null;
      _walletAccessFailureLogged = false;

      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (_isWalletAccessMissingError(e) ||
          msg.contains('failed to fetch') ||
          msg.contains('clientexception')) {
        _temporarilyDisableWalletAccess(e);
        return null;
      }

      debugPrint('walletAccess invoke failed for action=$action: $e');
      return null;
    }
  }

  static bool _isWalletAccessMissingError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('status: 404') ||
        msg.contains('not_found') ||
        msg.contains('requested function was not found') ||
        msg.contains('walletaccess');
  }

  static Future<Wallet?> _ensureWalletRecord(String artisanId) async {
    try {
      final existing = await _client
          .from('wallets')
          .select()
          .eq('artisan_id', artisanId)
          .maybeSingle();

      if (existing != null) {
        return Wallet.fromJson(Map<String, dynamic>.from(existing));
      }

      final created = await _client
          .from('wallets')
          .insert({
            'artisan_id': artisanId,
            'pending_balance': 0,
            'available_balance': 0,
            'total_earned': 0,
            'total_withdrawn': 0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();

      return created != null
          ? Wallet.fromJson(Map<String, dynamic>.from(created))
          : null;
    } catch (e) {
      debugPrint('ensureWalletRecord error: $e');
      return null;
    }
  }

  static Future<WalletBundleResult> _legacyWalletLoginBundle({
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final artisans = await _client
          .from('artisans')
          .select('id,email,phone')
          .eq('phone', phone)
          .eq('email', email)
          .eq('password', password)
          .limit(1);

      if ((artisans as List).isEmpty) {
        return WalletBundleResult(success: false, error: 'Invalid credentials');
      }

      final artisan = artisans.first;
      final artisanId = artisan['id']?.toString();
      if (artisanId == null || artisanId.isEmpty) {
        return WalletBundleResult(
            success: false, error: 'Invalid artisan response');
      }

      setWalletAccessCredentials(
        email: email,
        phone: phone,
        password: password,
        artisanId: artisanId,
      );

      final wallet = await getWallet(artisanId);
      final jobs = await getJobsForArtisan(artisanId);
      final transactions = await getTransactions(artisanId);

      return WalletBundleResult(
        success: true,
        artisanId: artisanId,
        wallet: wallet,
        jobs: jobs,
        transactions: transactions,
      );
    } catch (e) {
      debugPrint('legacy wallet login fallback failed: $e');
      return WalletBundleResult(
          success: false, error: 'Wallet login failed: $e');
    }
  }

  static bool _needsPaymentConfirmation(Job job) {
    final status = (job.status ?? '').toLowerCase();
    final hasPaymentReference = job.paymentReference?.isNotEmpty ?? false;
    return hasPaymentReference &&
        (status == 'pending' ||
            status == 'accepted' ||
            status == 'estimate_accepted');
  }

  static bool _jobsDiffer(List<Job> original, List<Job> updated) {
    if (original.length != updated.length) return true;
    for (var i = 0; i < original.length; i++) {
      final before = original[i];
      final after = updated[i];
      if (before.status != after.status ||
          before.amountPaid != after.amountPaid ||
          before.escrowAmount != after.escrowAmount ||
          before.commissionAmount != after.commissionAmount) {
        return true;
      }
    }
    return false;
  }

  static Future<List<Job>> _syncPaidJobsIfNeeded(
    List<Job> jobs, {
    bool allowDebugFallback = false,
  }) async {
    if (jobs.isEmpty) return jobs;

    final refreshedJobs = <Job>[];
    for (final job in jobs) {
      if (!_needsPaymentConfirmation(job)) {
        refreshedJobs.add(job);
        continue;
      }

      final refreshed = await confirmPaymentForJob(
        job.jobReference,
        allowDebugFallback: allowDebugFallback,
      );
      refreshedJobs.add(refreshed ?? job);
    }

    return refreshedJobs;
  }

  // ============================================
  // Job Methods
  // ============================================

  static Future<List<Job>> getJobsForArtisan(String artisanId) async {
    try {
      final response = await _client
          .from('jobs')
          .select()
          .eq('artisan_id', artisanId)
          .order('created_at', ascending: false);
      final list = response as List;
      final jobs = list
          .map((json) => Job.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      return _syncPaidJobsIfNeeded(jobs);
    } catch (e) {
      debugPrint('getJobsForArtisan error: $e');
      return [];
    }
  }

  static Future<List<Job>> getJobsForCustomer(String customerId) async {
    try {
      final response = await _client
          .from('jobs')
          .select()
          .eq('customer_email', customerId)
          .order('created_at', ascending: false);
      final list = response as List;
      final jobs = list
          .map((json) => Job.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      return _syncPaidJobsIfNeeded(jobs);
    } catch (e) {
      debugPrint('getJobsForCustomer error: $e');
      return [];
    }
  }

  static Future<Job?> getJobByReference(String jobReference) async {
    try {
      final response = await _client
          .from('jobs')
          .select()
          .eq('job_reference', jobReference)
          .maybeSingle();
      return response != null
          ? Job.fromJson(Map<String, dynamic>.from(response))
          : null;
    } catch (e) {
      debugPrint('getJobByReference error: $e');
      return null;
    }
  }

  static Future<bool> updateJobStatus(String jobId, String status) async {
    try {
      final response = await _client
          .from('jobs')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', jobId)
          .select('id')
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('updateJobStatus error: $e');
      return false;
    }
  }

  static Future<Job?> createJobDirect({
    required String artisanId,
    required String customerEmail,
    String? customerName,
    String? customerPhone,
    String? serviceType,
    String? description,
    String? address,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final jobReference = 'HH_JOB_$timestamp';

      final jobData = {
        'job_reference': jobReference,
        'artisan_id': artisanId,
        'customer_email': customerEmail,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'service_type': serviceType,
        'description': description,
        'address': address,
        'amount_paid': 0,
        'escrow_amount': 0,
        'commission_amount': 0,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _client.from('jobs').insert(jobData).select().maybeSingle();

      return response != null
          ? Job.fromJson(Map<String, dynamic>.from(response))
          : null;
    } catch (e) {
      debugPrint('createJobDirect error: $e');
      return null;
    }
  }

  static Future<PaymentInitializeResult> initializePayment({
    required String artisanId,
    required String customerEmail,
    String? customerName,
    String? customerPhone,
    String? serviceType,
    String? description,
    String? jobReference,
    String? address,
    int amount = 3000,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final paymentReference = 'HH_PAY_$timestamp';

      if (amount <= 0) {
        return PaymentInitializeResult(
          success: false,
          message: 'Invalid payment amount',
        );
      }

      // Call Supabase edge function
      final response =
          await _client.functions.invoke('initializeTransaction', body: {
        'artisanId': artisanId,
        'customerEmail': customerEmail,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'serviceType': serviceType,
        'description': description,
        'jobReference': jobReference,
        'address': address,
        'amount': amount,
        'paymentReference': paymentReference,
      });

      debugPrint('Payment init response: \\n${response.data}');
      debugPrint('Payment init full response: \\n$response');

      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('Payment init parsed data: \\n$data');
        if (data['success'] == true || data['authorization_url'] != null) {
          debugPrint('Payment init authorization_url: \\n${data['authorization_url'] ?? data['authorizationUrl']}');
          return PaymentInitializeResult(
            success: true,
            authorizationUrl:
                data['authorization_url'] ?? data['authorizationUrl'],
            paymentReference: data['reference'] ?? data['paymentReference'],
            jobReference: data['job_reference'] ?? data['jobReference'],
            message: data['message'] ?? 'Payment initialized',
          );
        } else {
          debugPrint('Payment init error: \\n${data['error'] ?? data['message'] ?? 'Failed to initialize payment'}');
          return PaymentInitializeResult(
            success: false,
            message: data['error'] ??
                data['message'] ??
                'Failed to initialize payment',
          );
        }
      } else {
        debugPrint('Payment init error: No response data');
        return PaymentInitializeResult(
          success: false,
          message: 'Failed to initialize payment - no response data',
        );
      }
    } catch (e) {
      debugPrint('initializePayment error: $e');
      return PaymentInitializeResult(
        success: false,
        message: 'Payment initialization failed: $e',
      );
    }
  }

  static Future<Job?> confirmPaymentForJob(
    String jobReference, {
    bool allowDebugFallback = false,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'verifyTransaction',
        body: {'jobReference': jobReference},
      );

      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map['success'] == true) {
          final jobJson = map['job'];
          if (jobJson is Map) {
            return Job.fromJson(Map<String, dynamic>.from(jobJson));
          }
          final refreshed = await getJobByReference(jobReference);
          if (refreshed != null) return refreshed;
        }

        debugPrint(
          'confirmPaymentForJob Paystack verification is still pending for '
          '$jobReference: ${map['message'] ?? map['error'] ?? 'unknown response'}',
        );
      }
    } catch (e) {
      debugPrint('confirmPaymentForJob verifyTransaction error: $e');
    }

    if (allowDebugFallback) {
      debugPrint(
        'Debug fallback ignored for $jobReference. '
        'Successful Paystack confirmation is required before wallet credit.',
      );
    }

    return getJobByReference(jobReference);
  }

  static Future<Job?> verifyPaymentAndUpdateJob(String jobReference) async {
    debugPrint(
      'verifyPaymentAndUpdateJob is disabled for $jobReference. '
      'Wallet credit now requires successful Paystack verification.',
    );
    return getJobByReference(jobReference);
  }

  static Future<bool> markJobAsPaid(String jobId, {int amount = 3000}) async {
    try {
      final response = await _client
          .from('jobs')
          .update({
            'status': 'paid',
            'amount_paid': amount,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', jobId)
          .select('id')
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('markJobAsPaid error: $e');
      return false;
    }
  }

  static Future<bool> generateArrivalOtp(String jobId) async {
    try {
      final otp =
          (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      final expiry =
          DateTime.now().add(const Duration(minutes: 10)).toIso8601String();

      final response = await _client
          .from('jobs')
          .update({
            'arrival_otp': otp,
            'arrival_otp_expiry': expiry,
            'artisan_arrived': true,
            'artisan_arrived_at': DateTime.now().toIso8601String(),
          })
          .eq('id', jobId)
          .select('id')
          .maybeSingle();
      debugPrint('Generated OTP: $otp for job: $jobId');
      return response != null;
    } catch (e) {
      debugPrint('generateArrivalOtp error: $e');
      return false;
    }
  }

  // ============================================
  // Job Completion OTP Methods
  // ============================================

  /// Artisan calls this when they tap "Finish Job".
  /// Calls the generate_job_completion_otp DB function and returns the OTP
  /// so the artisan can read it to the customer.
  static Future<JobCompletionOtpResult> generateJobCompletionOtp({
    required String jobReference,
    required String artisanId,
  }) async {
    try {
      final response =
          await _client.rpc('generate_job_completion_otp', params: {
        'job_ref': jobReference,
        'artisan_id_param': artisanId,
      });

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] == true) {
        return JobCompletionOtpResult(
          success: true,
          message: data['message'] ?? 'OTP sent to customer',
        );
      }
      return JobCompletionOtpResult(
        success: false,
        message: data['error'] ?? 'Failed to generate OTP',
      );
    } catch (e) {
      debugPrint('generateJobCompletionOtp error: $e');
      return JobCompletionOtpResult(success: false, message: 'Error: $e');
    }
  }

  /// Customer calls this when they enter the OTP shown by the artisan.
  /// Sets customer_verified = true in the DB.
  static Future<JobCompletionOtpResult> verifyCustomerCompletion({
    required String jobReference,
    required String otpCode,
  }) async {
    try {
      final response = await _client.rpc('verify_customer_completion', params: {
        'job_ref': jobReference,
        'otp_code': otpCode,
      });

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] == true) {
        return JobCompletionOtpResult(
          success: true,
          message: data['message'] ?? 'Verified',
        );
      }
      return JobCompletionOtpResult(
        success: false,
        message: data['error'] ?? 'Verification failed',
      );
    } catch (e) {
      debugPrint('verifyCustomerCompletion error: $e');
      return JobCompletionOtpResult(success: false, message: 'Error: $e');
    }
  }

  /// Artisan calls this after customer has verified — enters the same OTP
  /// to release labor from pending to available balance.
  static Future<LaborReleaseResult> verifyAndReleaseLabor({
    required String jobReference,
    required String artisanId,
    required String customerOtp,
  }) async {
    try {
      final response = await _client.rpc('verify_job_completion_otp', params: {
        'job_ref': jobReference,
        'artisan_id_param': artisanId,
        'otp_code': customerOtp,
      });

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] == true) {
        return LaborReleaseResult(
          success: true,
          message: data['message'] ?? 'Labor released',
          amountReleased: (data['amountReleased'] as num?)?.toDouble() ?? 0,
        );
      }
      return LaborReleaseResult(
        success: false,
        message: data['error'] ?? 'Failed to release labor',
        amountReleased: 0,
      );
    } catch (e) {
      debugPrint('verifyAndReleaseLabor error: $e');
      return LaborReleaseResult(
          success: false, message: 'Error: $e', amountReleased: 0);
    }
  }

  // ============================================
  // Wallet Methods
  // ============================================

  static Future<WalletBundleResult> walletLoginBundle({
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _client.functions.invoke('walletAccess', body: {
        'action': 'login',
        'email': email,
        'phone': phone,
        'password': password,
      });

      if (response.data == null) {
        return WalletBundleResult(
            success: false, error: 'No response from wallet service');
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['success'] != true) {
        return WalletBundleResult(
            success: false, error: data['error']?.toString() ?? 'Login failed');
      }

      final artisanMap = Map<String, dynamic>.from(data['artisan'] as Map);
      final artisanId = artisanMap['id']?.toString();
      if (artisanId == null || artisanId.isEmpty) {
        return WalletBundleResult(
            success: false, error: 'Invalid artisan response');
      }

      setWalletAccessCredentials(
        email: email,
        phone: phone,
        password: password,
        artisanId: artisanId,
      );

      final walletJson = data['wallet'];
      final jobsJson = (data['jobs'] as List?) ?? const [];
      final txJson = (data['transactions'] as List?) ?? const [];

      var wallet = walletJson == null
          ? null
          : Wallet.fromJson(Map<String, dynamic>.from(walletJson as Map));
      var jobs = jobsJson
          .map((j) => Job.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      var transactions = txJson
          .map((t) =>
              PaymentTransaction.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList();

      final syncedJobs = await _syncPaidJobsIfNeeded(jobs);
      if (_jobsDiffer(jobs, syncedJobs)) {
        jobs = syncedJobs;
        final refreshedWallet = await getWallet(artisanId);
        if (refreshedWallet != null) {
          wallet = refreshedWallet;
        }
        transactions = await getTransactions(artisanId);
      }

      return WalletBundleResult(
        success: true,
        artisanId: artisanId,
        wallet: wallet,
        jobs: jobs,
        transactions: transactions,
      );
    } catch (e) {
      if (_isWalletAccessMissingError(e)) {
        debugPrint(
            'walletAccess missing, falling back to legacy wallet login flow');
        return _legacyWalletLoginBundle(
          email: email,
          phone: phone,
          password: password,
        );
      }
      debugPrint('walletLoginBundle error: $e');
      return WalletBundleResult(
          success: false, error: 'Wallet login failed: $e');
    }
  }

  static Future<WalletBundleResult> getWalletBundle(String artisanId) async {
    try {
      final data =
          await _invokeWalletAccess(action: 'bundle', artisanId: artisanId);
      if (data == null || data['success'] != true) {
        final wallet = await getWallet(artisanId);
        final jobs = await getJobsForArtisan(artisanId);
        final transactions = await getTransactions(artisanId);

        return WalletBundleResult(
          success: true,
          artisanId: artisanId,
          wallet: wallet,
          jobs: jobs,
          transactions: transactions,
        );
      }

      final walletJson = data['wallet'];
      final jobsJson = (data['jobs'] as List?) ?? const [];
      final txJson = (data['transactions'] as List?) ?? const [];

      var wallet = walletJson == null
          ? null
          : Wallet.fromJson(Map<String, dynamic>.from(walletJson as Map));
      var jobs = jobsJson
          .map((j) => Job.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      var transactions = txJson
          .map((t) =>
              PaymentTransaction.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList();

      final syncedJobs = await _syncPaidJobsIfNeeded(jobs);
      if (_jobsDiffer(jobs, syncedJobs)) {
        jobs = syncedJobs;
        final refreshedWallet = await getWallet(artisanId);
        if (refreshedWallet != null) {
          wallet = refreshedWallet;
        }
        transactions = await getTransactions(artisanId);
      }

      return WalletBundleResult(
        success: true,
        artisanId: artisanId,
        wallet: wallet,
        jobs: jobs,
        transactions: transactions,
      );
    } catch (e) {
      debugPrint('getWalletBundle error: $e');
      return WalletBundleResult(
          success: false, error: 'Bundle load failed: $e');
    }
  }

  static Future<Wallet?> getWallet(String artisanId) async {
    try {
      final trusted =
          await _invokeWalletAccess(action: 'bundle', artisanId: artisanId);
      if (trusted != null &&
          trusted['success'] == true &&
          trusted['wallet'] != null) {
        return Wallet.fromJson(
            Map<String, dynamic>.from(trusted['wallet'] as Map));
      }

      final response = await _client
          .from('wallets')
          .select()
          .eq('artisan_id', artisanId)
          .maybeSingle();
      if (response != null) {
        return Wallet.fromJson(Map<String, dynamic>.from(response));
      }

      return _ensureWalletRecord(artisanId);
    } catch (e) {
      debugPrint('getWallet error: $e');
      return null;
    }
  }

  static Future<List<PaymentTransaction>> getTransactions(
      String artisanId) async {
    try {
      final trusted =
          await _invokeWalletAccess(action: 'bundle', artisanId: artisanId);
      if (trusted != null && trusted['success'] == true) {
        final txJson = (trusted['transactions'] as List?) ?? const [];
        return txJson
            .map((json) => PaymentTransaction.fromJson(
                Map<String, dynamic>.from(json as Map)))
            .toList();
      }

      final response = await _client
          .from('transactions')
          .select()
          .eq('artisan_id', artisanId)
          .order('created_at', ascending: false);
      final list = response as List;
      return list
          .map((json) =>
              PaymentTransaction.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('getTransactions error: $e');
      return [];
    }
  }

  static Future<bool> verifyWallet(String artisanId) async {
    try {
      final trusted = await _invokeWalletAccess(
          action: 'verifyWallet', artisanId: artisanId);
      if (trusted != null && trusted['success'] == true) {
        return true;
      }

      final wallet = await getWallet(artisanId);
      if (wallet == null) {
        debugPrint('verifyWallet: No wallet found');
        return false;
      }

      if (wallet.bankName == null ||
          wallet.accountNumber == null ||
          wallet.accountName == null) {
        debugPrint('verifyWallet: Missing bank details');
        return false;
      }

      try {
        final response = await _client.functions.invoke('verifyWallet', body: {
          'artisanId': artisanId,
          'bankName': wallet.bankName,
          'accountNumber': wallet.accountNumber,
          'accountName': wallet.accountName,
        });

        if (response.data is Map) {
          final data = Map<String, dynamic>.from(response.data as Map);
          if (data['success'] == true) {
            return true;
          }
          debugPrint(
              'verifyWallet function returned: ${data['error'] ?? data['message']}');
        }
      } catch (e) {
        debugPrint('verifyWallet function invoke failed: $e');
      }

      final ensuredWallet = await _ensureWalletRecord(artisanId);
      if (ensuredWallet?.id == null) {
        return false;
      }

      final response = await _client
          .from('wallets')
          .update({
            'is_verified': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ensuredWallet!.id!)
          .select('id');

      final updatedRows = response as List;
      debugPrint(
          'verifyWallet: is_verified set to true, result: ${updatedRows.isNotEmpty}');
      return updatedRows.isNotEmpty;
    } catch (e) {
      debugPrint('verifyWallet error: $e');
      return false;
    }
  }

  static Future<bool> saveBankDetails({
    required String artisanId,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final trusted = await _invokeWalletAccess(
        action: 'saveBankDetails',
        artisanId: artisanId,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
      );
      if (trusted != null) {
        if (trusted['success'] == true) {
          return true;
        }
        debugPrint(
          'saveBankDetails walletAccess returned: '
          '${trusted['error'] ?? trusted['message'] ?? 'unknown error'}',
        );
      }

      try {
        final response = await _client.functions.invoke('verifyWallet', body: {
          'artisanId': artisanId,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountName': accountName,
        });

        if (response.data is Map) {
          final data = Map<String, dynamic>.from(response.data as Map);
          if (data['success'] == true) {
            return true;
          }
          debugPrint(
              'saveBankDetails verifyWallet fallback returned: ${data['error'] ?? data['message']}');
        }
      } catch (e) {
        debugPrint('saveBankDetails verifyWallet fallback error: $e');
      }

      final wallet = await _ensureWalletRecord(artisanId);
      if (wallet?.id == null) {
        return false;
      }

      final response = await _client
          .from('wallets')
          .update({
            'bank_name': bankName,
            'account_number': accountNumber,
            'account_name': accountName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet!.id!)
          .select('id');

      final updatedRows = response as List;
      return updatedRows.isNotEmpty;
    } catch (e) {
      debugPrint('saveBankDetails error: $e');
      return false;
    }
  }

  static Future<ReleaseFundsResult> releaseFunds(
      {required String artisanId, int? amount}) async {
    try {
      final response = await _client.functions.invoke('transferPayout', body: {
        'artisanId': artisanId,
        'amount': amount,
      });

      if (response.data != null && response.data['success'] == true) {
        return ReleaseFundsResult(
          success: true,
          message: response.data['message'] ?? 'Funds released successfully',
          amount: response.data['amount'],
        );
      } else {
        return ReleaseFundsResult(
          success: false,
          message: response.data?['error'] ?? 'Failed to release funds',
        );
      }
    } catch (e) {
      debugPrint('releaseFunds error: $e');
      return ReleaseFundsResult(
        success: false,
        message: 'Failed to release funds: $e',
      );
    }
  }

  // ============================================
  // Realtime Subscriptions
  // Returns channel - caller must call .subscribe() on it
  // ============================================

  static Stream<List<dynamic>> walletStream(String artisanId) {
    if (_hasWalletAccessCredentials && !_walletAccessTemporarilyDisabled) {
      return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
        final data =
            await _invokeWalletAccess(action: 'bundle', artisanId: artisanId);
        if (data != null && data['success'] == true && data['wallet'] != null) {
          return [data['wallet']];
        }
        return <dynamic>[];
      });
    }

    return _client
        .from('wallets')
        .stream(primaryKey: ['id']).eq('artisan_id', artisanId);
  }

  static Stream<List<dynamic>> jobsStream(String artisanId) {
    return _client
        .from('jobs')
        .stream(primaryKey: ['id'])
        .eq('artisan_id', artisanId)
        .order('created_at', ascending: false);
  }
}

// ============================================
// Result Classes
// ============================================

class PaymentInitializeResult {
  final bool success;
  final String? authorizationUrl;
  final String? paymentReference;
  final String? jobReference;
  final String message;
  final String? error;

  PaymentInitializeResult({
    required this.success,
    this.authorizationUrl,
    this.paymentReference,
    this.jobReference,
    required this.message,
    this.error,
  });
}

class WalletBundleResult {
  final bool success;
  final String? artisanId;
  final Wallet? wallet;
  final List<Job> jobs;
  final List<PaymentTransaction> transactions;
  final String? error;

  WalletBundleResult({
    required this.success,
    this.artisanId,
    this.wallet,
    this.jobs = const [],
    this.transactions = const [],
    this.error,
  });
}

class ReleaseFundsResult {
  final bool success;
  final String message;
  final int? amount;
  final int? releasedAmount;
  final String? error;

  ReleaseFundsResult({
    required this.success,
    required this.message,
    this.amount,
    this.releasedAmount,
    this.error,
  });
}

class JobCompletionOtpResult {
  final bool success;
  final String message;

  JobCompletionOtpResult({
    required this.success,
    required this.message,
  });
}

class LaborReleaseResult {
  final bool success;
  final String message;
  final double amountReleased;

  LaborReleaseResult({
    required this.success,
    required this.message,
    required this.amountReleased,
  });
}
