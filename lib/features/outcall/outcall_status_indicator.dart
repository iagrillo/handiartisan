import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

/// Artisan-side status indicator showing outcall verification status
class OutcallStatusIndicator extends StatelessWidget {
  final String status;
  final String? jobReference;

  const OutcallStatusIndicator({
    super.key,
    required this.status,
    this.jobReference,
  });

  // Map status to display data
  StatusData get _statusData {
    switch (status) {
      case 'arrival_confirmed':
      case 'outcall_confirmed':
        return StatusData(
          icon: Icons.check_circle,
          color: AppTheme.success,
          label: 'Arrival Confirmed',
          description: 'Artisan has arrived and verified',
        );
      case 'verified':
      case 'estimate_pending':
        return StatusData(
          icon: Icons.check_circle,
          color: AppTheme.success,
          label: 'Outcall Verified',
          description: 'You can now submit an estimate',
        );
      case 'estimate_submitted':
        return StatusData(
          icon: Icons.pending,
          color: AppTheme.warning,
          label: 'Estimate Submitted',
          description: 'Waiting for customer approval',
        );
      case 'accepted':
        return StatusData(
          icon: Icons.task_alt,
          color: AppTheme.success,
          label: 'Estimate Accepted',
          description: 'Contract created with escrow',
        );
      case 'declined':
      case 'estimate_declined':
        return StatusData(
          icon: Icons.cancel,
          color: AppTheme.error,
          label: 'Estimate Declined',
          description: 'Customer declined the estimate',
        );
      default:
        return StatusData(
          icon: Icons.schedule,
          color: AppTheme.textTertiary,
          label: 'Pending Verification',
          description: 'Waiting for customer to confirm arrival',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _statusData;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: data.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spaceBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTheme.titleMedium.copyWith(
                    color: data.color,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Text(
                  data.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (jobReference != null && status != 'pending') ...[
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Ref: $jobReference',
                    style: AppTheme.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusData {
  final IconData icon;
  final Color color;
  final String label;
  final String description;

  StatusData({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
  });
}
