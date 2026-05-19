import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/outcall_service.dart';
import '../../services/payment_service.dart';
import '../../services/paystack_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../widgets/escrow_badge.dart';
import '../ui/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Customer-facing screen to review artisan's estimate
class EstimateReviewScreen extends StatefulWidget {
  final String jobReference;
  final String customerId;
  final Map<String, dynamic> jobData;

  const EstimateReviewScreen({
    super.key,
    required this.jobReference,
    required this.customerId,
    required this.jobData,
  });

  @override
  State<EstimateReviewScreen> createState() => _EstimateReviewScreenState();
}

class _EstimateReviewScreenState extends State<EstimateReviewScreen> {
  bool _isLoading = false;
  String? _selectedResponse;
  Map<String, dynamic>? _freshJobData;

  @override
  void initState() {
    super.initState();
    _loadFreshJobData();
    // Auto-refresh every 5 seconds
    Future.delayed(const Duration(seconds: 5), _autoRefresh);
  }

  void _autoRefresh() {
    if (mounted) {
      _loadFreshJobData();
      Future.delayed(const Duration(seconds: 5), _autoRefresh);
    }
  }

  Future<void> _loadFreshJobData() async {
    try {
      final job = await PaymentService.getJobByReference(widget.jobReference);
      debugPrint('Loaded job: $job');
      debugPrint('Job status: ${job?.status}');
      debugPrint('Job arrival_otp: ${job?.arrivalOtp}');
      debugPrint('Job artisan_arrived: ${job?.artisanArrived}');
      if (job != null && mounted) {
        setState(() {
          _freshJobData = job.toJson();
          debugPrint('Fresh job data: $_freshJobData');
        });
      }
    } catch (e) {
      debugPrint('Error loading fresh job data: $e');
    }
  }

  // Get effective job data (fresh if available, otherwise from widget)
  Map<String, dynamic> get _effectiveJobData => _freshJobData ?? widget.jobData;

  // Get estimate data from jobData
  List<dynamic> get _materials {
    final materialsJson = _effectiveJobData['estimate_materials'];
    if (materialsJson is String) {
      try {
        return jsonDecode(materialsJson) as List<dynamic>;
      } catch (_) {
        return [];
      }
    }
    return materialsJson as List<dynamic>? ?? [];
  }

  double _parseEstimateValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      return double.tryParse(normalized) ?? 0;
    }
    return 0;
  }

  double get _materialsCost =>
      _parseEstimateValue(_effectiveJobData['estimate_materials_cost']);

  double get _laborCost =>
      _parseEstimateValue(_effectiveJobData['estimate_labor_cost']);

  double get _totalEstimate {
    final estimateTotal =
        _parseEstimateValue(_effectiveJobData['estimate_total']);
    if (estimateTotal > 0) return estimateTotal;
    return _materialsCost + _laborCost;
  }

  bool get _hasEstimate => _totalEstimate > 0 || _materials.isNotEmpty;

  double get _depositAmount {
    final isInitialOutcallBooking =
        (_effectiveJobData['service_type']?.toString().toLowerCase() ==
                'outcall') &&
            !_hasEstimate;
    if (isInitialOutcallBooking) return 2000;

    final escrowAmount =
        _parseEstimateValue(_effectiveJobData['escrow_amount']);
    if (escrowAmount > 0) return escrowAmount;

    final amountPaid = _parseEstimateValue(_effectiveJobData['amount_paid']);
    if (amountPaid > 0) return amountPaid;

    return _totalEstimate;
  }

  String get _depositLabel =>
      _hasEstimate ? 'Estimate Deposit' : 'Outcall Deposit';

  String get _timeline =>
      _effectiveJobData['estimate_timeline'] ?? 'Not specified';

  String get _notes => _effectiveJobData['estimate_notes'] ?? '';

  Future<void> _respondToEstimate(String response) async {
    // If accepting, show payment method selection first
    if (response == 'accept') {
      _showPaymentMethodDialog();
      return;
    }

    // For decline, show options: Request New Estimate or Close Job
    _showDeclineOptionsDialog();
  }

  void _showDeclineOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cancel, color: AppTheme.error),
            const SizedBox(width: AppTheme.spaceSM),
            const Text('Decline Estimate'),
          ],
        ),
        content: Text(
          'What would you like to do?',
          style: AppTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _processDeclineWithAction('request_new');
            },
            icon: const Icon(Icons.replay),
            label: const Text('Request New Estimate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _processDeclineWithAction('close_job');
            },
            icon: const Icon(Icons.close),
            label: const Text('Close Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processDeclineWithAction(String action) async {
    setState(() {
      setState(() => _isLoading = true);
      try {
        // Calculate total amount with 10% service fee
        final estimateAmount = _totalEstimate;
        if (estimateAmount <= 0) {
          _showErrorSnackBar('Unable to initialize payment. Estimate amount is invalid.');
          return;
        }
        final serviceFee = estimateAmount * 0.10;
        final totalAmountWithFee = (estimateAmount + serviceFee).round();

        final publicKey = dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? 'NULL';
        debugPrint('Paystack public key at runtime: ' + publicKey);
        await PaystackService.checkout(
          context: context,
          publicKey: publicKey,
          amount: totalAmountWithFee,
          email: _effectiveJobData['customer_email']?.toString() ?? '',
          reference: widget.jobReference,
          onSuccess: () {
            if (!mounted) return;
            _showPaymentConfirmationDialog();
          },
          onClosed: () {
            if (!mounted) return;
            _showErrorSnackBar('Payment failed or cancelled.');
          },
        );
      } catch (e) {
        _showErrorSnackBar('Payment failed: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      if (!mounted) return;
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedResponse = null;
        });
      }
    }
  }

  void _showResultDialog(RespondEstimateResult result, String response) {
    final isAccepted = response == 'accept';
    final isCloseJob = response == 'close_job';
    final isRequestNew = response == 'request_new';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isAccepted ? Icons.check_circle : Icons.cancel,
              color: isAccepted ? AppTheme.success : AppTheme.error,
              size: 28,
            ),
            const SizedBox(width: AppTheme.spaceSM),
            Text(isAccepted ? 'Estimate Accepted' : 'Estimate Declined'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAccepted) ...[
              Text(
                'You have accepted the estimate.',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              if (result.contractReference != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contract Created',
                        style: AppTheme.labelLarge,
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Contract Ref: ${result.contractReference}',
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(
                        'Escrow Amount',
                        style: AppTheme.bodySmall
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      EscrowBadge(
                        amount: _formatCurrency(result.totalAmount),
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (isCloseJob) ...[
              Text(
                'You have declined the estimate.',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'The job has been closed.',
                style: AppTheme.bodySmall,
              ),
            ] else if (isRequestNew) ...[
              Text(
                'You requested a new estimate.',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'The artisan can now submit a new estimate.',
                style: AppTheme.bodySmall,
              ),
            ] else ...[
              Text(
                'You have declined the estimate.',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'The job has been closed.',
                style: AppTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Choose Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How would you like to pay for this job?',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceLG),
            // Pay into Wallet (Paystack)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processPaymentViaWallet();
              },
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Pay into Wallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spaceBase),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            // Pay Cash/Transfer
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processPaymentCashOrTransfer();
              },
              icon: const Icon(Icons.money),
              label: const Text('Pay Cash/Transfer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.success,
                side: const BorderSide(color: AppTheme.success),
                padding:
                    const EdgeInsets.symmetric(vertical: AppTheme.spaceBase),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPaymentViaWallet() async {
    setState(() => _isLoading = true);

    try {
      // Calculate total amount with 10% service fee
      final estimateAmount = _totalEstimate;
      if (estimateAmount <= 0) {
        _showErrorSnackBar(
            'Unable to initialize payment. Estimate amount is invalid.');
        return;
      }
      final serviceFee = estimateAmount * 0.10;
      final totalAmountWithFee = (estimateAmount + serviceFee).round();

      // Initialize Paystack payment
      final paymentResult = await PaymentService.initializePayment(
        artisanId: _effectiveJobData['artisan_id']?.toString() ?? '',
        customerEmail: _effectiveJobData['customer_email']?.toString() ?? '',
        amount: totalAmountWithFee.toInt(),
        jobReference: widget.jobReference,
        serviceType: _effectiveJobData['service_type']?.toString() ?? '',
        customerName: _effectiveJobData['customer_name']?.toString() ?? '',
        customerPhone: _effectiveJobData['customer_phone']?.toString() ?? '',
        description: 'Payment for job ${widget.jobReference}',
        address: _effectiveJobData['address']?.toString(),
      );

      if (!mounted) return;

      if (paymentResult.success &&
          paymentResult.authorizationUrl != null &&
          paymentResult.authorizationUrl!.isNotEmpty) {
        // Launch Paystack payment URL
        final uri = Uri.parse(paymentResult.authorizationUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!mounted) return;
          _showPaymentConfirmationDialog();
        } else {
          _showErrorSnackBar('Could not open payment page');
        }
      } else {
        _showErrorSnackBar(
            paymentResult.error ?? 'Payment initialization failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.payment, color: AppTheme.primary, size: 28),
            SizedBox(width: AppTheme.spaceSM),
            Text('Confirm Transaction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please complete the Paystack payment, then tap Check Status. The estimate will only be accepted after successful verification.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Job Reference: ${widget.jobReference}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                final updatedJob = await PaymentService.confirmPaymentForJob(
                  widget.jobReference,
                );
                if (!mounted) return;

                if (updatedJob != null && updatedJob.status == 'paid') {
                  await _loadFreshJobData();
                  _showSuccessDialog(
                    'Payment Confirmed',
                    'Your payment has been verified successfully. The estimate is now accepted.',
                  );
                } else {
                  _showErrorSnackBar(
                    'Payment is still pending confirmation. If you completed the checkout, wait a few seconds and tap again.',
                  );
                }
              } catch (e) {
                if (!mounted) return;
                _showErrorSnackBar('Error checking payment status: $e');
              } finally {
                setState(() => _isLoading = true);
                try {
                  // Calculate total amount with 10% service fee
                  final estimateAmount = _totalEstimate;
                  if (estimateAmount <= 0) {
                    _showErrorSnackBar('Unable to initialize payment. Estimate amount is invalid.');
                    return;
                  }
                  final serviceFee = estimateAmount * 0.10;
                  final totalAmountWithFee = (estimateAmount + serviceFee).round();

                  final publicKey = dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? 'NULL';
                  debugPrint('Paystack public key at runtime: $publicKey');
                  await PaystackService.checkout(
                    context: context,
                    publicKey: publicKey,
                    amount: totalAmountWithFee,
                    email: _effectiveJobData['customer_email']?.toString() ?? '',
                    reference: widget.jobReference,
                    onSuccess: () {
                      if (!mounted) return;
                      _showPaymentConfirmationDialog();
                    },
                    onClosed: () {
                      if (!mounted) return;
                      _showErrorSnackBar('Payment failed or cancelled.');
                    },
                  );
                } catch (e) {
                  _showErrorSnackBar('Payment failed: $e');
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Review Estimate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFreshJobData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              decoration: BoxDecoration(
                gradient: AppTheme.subtleGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceSM),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        child: const Icon(Icons.receipt_long,
                            color: AppTheme.primary),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Job Reference',
                                style: AppTheme.caption
                                    .copyWith(color: AppTheme.textSecondary)),
                            const SizedBox(height: 2),
                            Text(widget.jobReference,
                                style: AppTheme.titleMedium),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceSM,
                          vertical: AppTheme.spaceXXS + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.statusColor(
                                  _effectiveJobData['status']?.toString() ??
                                      'pending')
                              .withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          AppTheme.statusLabel(
                              _effectiveJobData['status']?.toString() ??
                                  'pending'),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.statusColor(
                                _effectiveJobData['status']?.toString() ??
                                    'pending'),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceBase),
                  EscrowBadge(
                    label: _depositLabel,
                    amount: _formatCurrency(_depositAmount),
                    compact: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceBase),

            // OTP Section - Show if artisan has arrived (or if OTP exists)
            if (_effectiveJobData['artisan_arrived'] == true ||
                _effectiveJobData['arrival_otp'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spaceBase),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: AppTheme.success.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppTheme.success),
                        const SizedBox(width: AppTheme.spaceSM),
                        Text(
                          'Artisan Has Arrived!',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMD),
                    Text(
                      'Give this code to the artisan:',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceXL,
                            vertical: AppTheme.spaceMD),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(color: AppTheme.success, width: 2),
                        ),
                        child: Text(
                          _effectiveJobData['arrival_otp'] ??
                              _effectiveJobData['artisan_arrival_otp'] ??
                              '------',
                          style: AppTheme.headline1.copyWith(
                            letterSpacing: 4,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spaceXL),

            // Materials Section
            Text(
              'Materials',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            if (_materials.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spaceBase),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: AppTheme.divider),
                ),
                child:
                    Text('No materials specified', style: AppTheme.bodyMedium),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: AppTheme.divider),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _materials.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final material = _materials[index];
                    final name = material['name'] ?? '';
                    final cost = (material['cost'] ?? 0).toDouble();
                    final qty = material['quantity'] ?? 1;

                    return ListTile(
                      title: Text(name, style: AppTheme.bodyMedium),
                      subtitle: Text('Qty: $qty', style: AppTheme.bodySmall),
                      trailing: Text(
                        _formatCurrency(cost * qty),
                        style: AppTheme.labelLarge
                            .copyWith(color: AppTheme.primary),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: AppTheme.spaceXL),

            // Labor Cost
            Text(
              'Labor Cost',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.divider),
              ),
              child: ListTile(
                title: Text('Service Charge', style: AppTheme.bodyMedium),
                trailing: Text(
                  _formatCurrency(_laborCost),
                  style: AppTheme.titleMedium,
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceXL),

            // Timeline
            Text(
              'Timeline',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.divider),
              ),
              child: ListTile(
                leading: const Icon(Icons.schedule, color: AppTheme.primary),
                title: Text('Estimated Completion', style: AppTheme.bodyMedium),
                subtitle: Text(_timeline, style: AppTheme.bodySmall),
              ),
            ),

            // Notes
            if (_notes.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceXL),
              Text(
                'Notes',
                style: AppTheme.headline3,
              ),
              const SizedBox(height: AppTheme.spaceMD),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spaceBase),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Text(_notes, style: AppTheme.bodyMedium),
              ),
            ],

            const SizedBox(height: AppTheme.spaceXL),

            // Total
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Estimate',
                    style: AppTheme.headline3,
                  ),
                  Text(
                    _formatCurrency(_totalEstimate),
                    style: AppTheme.headline2.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space2XL),

            // Show message if no estimate yet
            if (!_hasEstimate) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spaceBase),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.hourglass_empty,
                        color: AppTheme.warning, size: 48),
                    const SizedBox(height: AppTheme.spaceMD),
                    Text(
                      'Waiting for Estimate',
                      style: AppTheme.headline3.copyWith(
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      'The artisan will submit an estimate shortly.',
                      style: AppTheme.bodyMedium
                          .copyWith(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceBase),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _respondToEstimate('decline'),
                          icon: _selectedResponse == 'decline' && _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.close),
                          label: const Text('Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMD),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceBase),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _respondToEstimate('accept'),
                          icon: _selectedResponse == 'accept' && _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMD),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.spaceBase),
          ],
        ),
      ),
    );
  }
}
