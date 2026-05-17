import 'package:flutter/material.dart';
import '../../services/outcall_service.dart';
import '../../services/payment_service.dart';
import '../ui/app_theme.dart';

/// Customer-facing button to confirm artisan arrival
class ConfirmArrivalButton extends StatefulWidget {
  final String jobReference;
  final String artisanId;
  final String customerId;
  final VoidCallback? onSuccess;

  const ConfirmArrivalButton({
    super.key,
    required this.jobReference,
    required this.artisanId,
    required this.customerId,
    this.onSuccess,
  });

  @override
  State<ConfirmArrivalButton> createState() => _ConfirmArrivalButtonState();
}

class _ConfirmArrivalButtonState extends State<ConfirmArrivalButton> {
  bool _isLoading = false;

  Future<void> _confirmArrival() async {
    setState(() => _isLoading = true);

    try {
      final result = await OutcallService.verifyOutcallVisit(
        jobReference: widget.jobReference,
        artisanId: widget.artisanId,
        customerId: widget.customerId,
        verificationMethod: 'customerConfirm',
      );

      if (!mounted) return;

      if (result.success) {
        // Update job status to arrival_confirmed
        try {
          final job = await PaymentService.getJobByReference(widget.jobReference);
          if (job != null && job.id != null) {
            final updated = await PaymentService.updateJobStatus(job.id!, 'arrival_confirmed');
            debugPrint('Status update result for ${widget.jobReference}: $updated');
          } else {
            debugPrint('Job not found for reference: ${widget.jobReference}');
          }
        } catch (e) {
          debugPrint('Error updating job status: $e');
        }

        // Show success message
        _showSuccessDialog(result.amountReleased);
        widget.onSuccess?.call();
      } else {
        // Show error message
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(int amountReleased) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
            const SizedBox(width: AppTheme.spaceSM),
            const Text('Arrival Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have confirmed the artisan\'s arrival.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.success.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppTheme.success),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(
                    child: Text(
                      '₦${amountReleased.toString()} fee released to artisan',
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'The artisan will now submit an estimate for your review.',
              style: AppTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSM),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirm arrival', style: AppTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Tap once the artisan is physically at your location.',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceBase),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _confirmArrival,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _isLoading ? 'Confirming...' : 'Confirm Artisan Arrival',
                style: AppTheme.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
