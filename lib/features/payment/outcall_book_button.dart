import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/payment_service.dart';
import '../../widgets/escrow_badge.dart';
import '../models/artisan.dart';
import '../ui/app_theme.dart';

class OutcallBookButton extends StatefulWidget {
  final Artisan artisan;
  final String? customerEmail;
  final String? customerName;
  final String? customerPhone;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentFailure;

  const OutcallBookButton({
    required this.artisan,
    this.customerEmail,
    this.customerName,
    this.customerPhone,
    this.onPaymentSuccess,
    this.onPaymentFailure,
    Key? key,
  }) : super(key: key);

  @override
  State<OutcallBookButton> createState() => _OutcallBookButtonState();
}

class _OutcallBookButtonState extends State<OutcallBookButton> {
  bool _isLoading = false;
  String? _error;

  static const int jobAmount = 3000;
  static const int escrowAmount = 2000;
  static const int commissionAmount = 1000;

  Future<void> _sendWhatsAppToArtisan() async {
    final whatsapp = widget.artisan.whatsapp ?? widget.artisan.phone;
    if (whatsapp.isEmpty) return;
    final cleanNumber = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final message =
        'An outcall has been booked. Please login to Jobs to see details.';
    final uri = Uri.parse(
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSuccessfulTransactionFeedback(String jobReference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: AppTheme.success),
            SizedBox(width: AppTheme.spaceSM),
            Text('Transaction Successful'),
          ],
        ),
        content: Text(
          'Your outcall booking was successful.\n\nJob Ref: $jobReference\n\nYou will be redirected to Jobs to login and view details.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onPaymentSuccess?.call();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/jobs', (route) => false);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL)),
        boxShadow: AppTheme.shadowLG,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriceBreakdown(),
            const SizedBox(height: AppTheme.spaceBase),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: AppTheme.spaceSM),
                          Text(
                            'Book Outcall - ₦3,000',
                            style: AppTheme.labelLarge
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTheme.spaceMD),
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMD),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error),
                    const SizedBox(width: AppTheme.spaceSM),
                    Expanded(
                      child: Text(_error!,
                          style: AppTheme.bodyMedium
                              .copyWith(color: AppTheme.error)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.spaceXS),
                Text('Secured by Paystack',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Breakdown', style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spaceMD),
          _buildPriceRow('Total Amount', '₦$jobAmount', isTotal: true),
          const Divider(height: AppTheme.spaceBase),
          EscrowBadge(
            label: 'To Artisan',
            amount: '₦$escrowAmount',
            compact: true,
          ),
          const SizedBox(height: AppTheme.spaceXS),
          _buildPriceRow('Platform Commission', '₦$commissionAmount',
              color: AppTheme.warning),
          const SizedBox(height: AppTheme.spaceSM),
          Text('Funds held in escrow until job is completed',
              style: AppTheme.caption.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount,
      {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: isTotal
                ? AppTheme.labelLarge
                : AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
        Text(amount,
            style: isTotal
                ? AppTheme.titleMedium
                : AppTheme.bodySmall
                    .copyWith(color: color ?? AppTheme.textSecondary)),
      ],
    );
  }

  Future<void> _handleBooking() async {
    final email = widget.customerEmail;
    if (email == null || email.isEmpty) {
      setState(() => _error = 'Please provide your email address to continue');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await PaymentService.initializePayment(
        artisanId: widget.artisan.id ?? '',
        customerEmail: email,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        serviceType: 'outcall',
        description: 'Outcall service by ${widget.artisan.fullName}',
      );

      if (!mounted) return;

      if (result.success &&
          result.authorizationUrl != null &&
          result.jobReference != null) {
        final uri = Uri.parse(result.authorizationUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }

        if (!mounted) return;

        final updatedJob =
            await PaymentService.getJobByReference(result.jobReference!);

        if (updatedJob != null && updatedJob.status == 'paid') {
          await _sendWhatsAppToArtisan();
          _showSuccessfulTransactionFeedback(result.jobReference!);
        } else {
          _showPaymentPendingDialog(result.jobReference!);
        }
      } else {
        setState(() => _error = result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentPendingDialog(String jobReference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.hourglass_empty, color: AppTheme.primary),
          const SizedBox(width: AppTheme.spaceSM),
          const Text('Payment Pending'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please complete your payment in the Paystack checkout.',
                style: AppTheme.bodyMedium),
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                  color: AppTheme.inputFill,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Reference:',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary)),
                  Text(jobReference,
                      style: AppTheme.labelLarge
                          .copyWith(fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Once payment is successful, your job will be confirmed automatically. If you are using Paystack test mode, tap Check Status after completing checkout.',
              style: AppTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPaymentFailure?.call();
              },
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPaymentStatus(jobReference, userInitiated: true);
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus(String jobReference,
      {bool userInitiated = false}) async {
    setState(() => _isLoading = true);
    try {
      final job = await PaymentService.confirmPaymentForJob(
        jobReference,
      );
      if (!mounted) return;

      if (job != null && job.status == 'paid') {
        await _sendWhatsAppToArtisan();
        _showSuccessfulTransactionFeedback(jobReference);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userInitiated
                  ? 'Payment is still pending confirmation. If you completed the Paystack payment, wait a few seconds and tap again.'
                  : 'Payment not yet completed. Please try again.',
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error checking status: $e'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class OutcallBookButtonSimple extends StatelessWidget {
  final Artisan artisan;
  final String? customerEmail;
  final VoidCallback? onPressed;
  final VoidCallback? onPaymentSuccess;

  const OutcallBookButtonSimple({
    required this.artisan,
    this.customerEmail,
    this.onPressed,
    this.onPaymentSuccess,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () => _showBookingDialog(context),
      icon: const Icon(Icons.calendar_today, size: 18),
      label: const Text('Book Outcall'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceBase, vertical: AppTheme.spaceMD),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BookingBottomSheet(
        artisan: artisan,
        customerEmail: customerEmail,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }
}

class _BookingBottomSheet extends StatefulWidget {
  final Artisan artisan;
  final String? customerEmail;
  final VoidCallback? onPaymentSuccess;

  const _BookingBottomSheet(
      {required this.artisan, this.customerEmail, this.onPaymentSuccess});

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  Future<void> _sendWhatsAppToArtisan() async {
    final whatsapp = widget.artisan.whatsapp ?? widget.artisan.phone;
    if (whatsapp.isEmpty) return;
    final cleanNumber = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final message =
        'An outcall has been booked. Please login to Jobs to see details.';
    final url =
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.customerEmail);
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceLG,
        right: AppTheme.spaceLG,
        top: AppTheme.spaceLG,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLG,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    widget.artisan.fullName.isNotEmpty
                        ? widget.artisan.fullName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.artisan.fullName,
                          style: AppTheme.titleMedium),
                      Text(widget.artisan.category,
                          style: AppTheme.bodySmall
                              .copyWith(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMD,
                      vertical: AppTheme.spaceXS + 2),
                  decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                  child: Text('₦3,000',
                      style: AppTheme.labelLarge
                          .copyWith(color: AppTheme.success)),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLG),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              decoration: BoxDecoration(
                gradient: AppTheme.subtleGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outcall booking', style: AppTheme.titleSmall),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Pay securely to reserve this artisan for an on-site visit. ₦2,000 is held in escrow until the job is completed.',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Your Name',
                    prefixIcon: Icon(Icons.person_outlined))),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Service Address',
                    prefixIcon: Icon(Icons.location_on_outlined))),
            const SizedBox(height: AppTheme.spaceLG),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: AppTheme.spaceSM),
                      Text('Payment summary',
                          style: AppTheme.labelLarge
                              .copyWith(color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  _SummaryRow(label: 'Visit booking', value: '₦3,000'),
                  const SizedBox(height: AppTheme.spaceXS),
                  EscrowBadge(
                    label: 'Held in escrow',
                    amount: '₦${_OutcallBookButtonState.escrowAmount}',
                    compact: true,
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  _SummaryRow(label: 'Platform fee', value: '₦1,000'),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleBook,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMD))),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 18),
                          const SizedBox(width: AppTheme.spaceSM),
                          Text('Pay & Book',
                              style: AppTheme.labelLarge
                                  .copyWith(color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBook() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final job = await PaymentService.createJobDirect(
        artisanId: widget.artisan.id ?? '',
        customerEmail: _emailController.text,
        customerName:
            _nameController.text.isNotEmpty ? _nameController.text : null,
        customerPhone:
            _phoneController.text.isNotEmpty ? _phoneController.text : null,
        serviceType: 'outcall',
        description: 'Outcall service by ${widget.artisan.fullName}',
        address:
            _addressController.text.isNotEmpty ? _addressController.text : null,
      );

      if (!mounted) return;

      if (job == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to create job'),
            backgroundColor: AppTheme.error));
        setState(() => _isLoading = false);
        return;
      }

      final result = await PaymentService.initializePayment(
        artisanId: widget.artisan.id ?? '',
        customerEmail: _emailController.text,
        customerName:
            _nameController.text.isNotEmpty ? _nameController.text : null,
        customerPhone:
            _phoneController.text.isNotEmpty ? _phoneController.text : null,
        serviceType: 'outcall',
        description: 'Outcall service by ${widget.artisan.fullName}',
        jobReference: job.jobReference,
      );

      if (!mounted) return;

      if (result.success && result.authorizationUrl != null) {
        final jobRef = job.jobReference;

        final uri = Uri.parse(result.authorizationUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        // Keep this sheet alive so the user sees the payment confirmation flow
        // immediately after returning from Paystack.
        if (mounted) {
          _showPaymentConfirmationDialog(jobRef);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.error ?? 'Failed to initialize payment'),
            backgroundColor: AppTheme.error));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentConfirmationDialog(String jobReference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: AppTheme.success),
            const SizedBox(width: AppTheme.spaceSM),
            const Text('Confirm Transaction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Please confirm your payment. We will verify transaction success before continuing.',
                style: AppTheme.bodyMedium),
            const SizedBox(height: AppTheme.spaceMD),
            Text('Job Reference: $jobReference',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                final updatedJob = await PaymentService.confirmPaymentForJob(
                  jobReference,
                );
                if (!mounted) return;

                if (updatedJob != null && updatedJob.status == 'paid') {
                  await _sendWhatsAppToArtisan();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: const [
                          Icon(Icons.check_circle, color: AppTheme.success),
                          SizedBox(width: AppTheme.spaceSM),
                          Text('Transaction Successful'),
                        ],
                      ),
                      content: Text(
                        'Outcall booked successfully.\n\nYou will now be redirected to Jobs to login and view details.',
                        style: AppTheme.bodyMedium,
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onPaymentSuccess?.call();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                '/jobs', (route) => false);
                          },
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Payment is still pending confirmation. If you completed the Paystack payment, wait a few seconds and tap again.'),
                      backgroundColor: AppTheme.warning,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error checking status: $e'),
                      backgroundColor: AppTheme.error),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('I Have Paid'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
        Text(value,
            style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }
}
