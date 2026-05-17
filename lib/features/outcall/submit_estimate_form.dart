import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/outcall_service.dart';
import '../ui/app_theme.dart';

/// Artisan form to submit job estimates
class SubmitEstimateForm extends StatefulWidget {
  final String jobReference;
  final String artisanId;
  final VoidCallback? onSuccess;

  const SubmitEstimateForm({
    super.key,
    required this.jobReference,
    required this.artisanId,
    this.onSuccess,
  });

  @override
  State<SubmitEstimateForm> createState() => _SubmitEstimateFormState();
}

class _SubmitEstimateFormState extends State<SubmitEstimateForm> {
  final _formKey = GlobalKey<FormState>();
  final _timelineController = TextEditingController();
  final _notesController = TextEditingController();
  final _laborCostController = TextEditingController();

  List<_MaterialItem> _materials = [];
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  double get _totalMaterials {
    return _materials.fold(0.0, (sum, item) => sum + (item.cost * item.quantity));
  }

  double get _totalEstimate {
    final laborCost = double.tryParse(_laborCostController.text) ?? 0;
    return _totalMaterials + laborCost;
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  Widget _buildAmountSummaryCard({
    required String label,
    required String value,
    bool emphasized = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: emphasized ? AppTheme.primary.withOpacity(0.1) : AppTheme.inputFill,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: emphasized ? Border.all(color: AppTheme.primary.withOpacity(0.24)) : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final valueText = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: (emphasized ? AppTheme.headline2 : AppTheme.titleMedium).copyWith(
                color: emphasized ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          );

          final useColumn = constraints.maxWidth < 340;
          if (useColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.headline3),
                const SizedBox(height: AppTheme.spaceXS),
                Align(alignment: Alignment.centerRight, child: valueText),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: Text(label, style: AppTheme.headline3)),
              const SizedBox(width: AppTheme.spaceSM),
              Flexible(child: valueText),
            ],
          );
        },
      ),
    );
  }

  void _addMaterial() {
    setState(() {
      _materials.add(_MaterialItem());
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      _materials.removeAt(index);
    });
  }

  Future<void> _submitEstimate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_materials.isEmpty) {
      _showErrorSnackBar('Please add at least one material');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Convert materials to EstimateMaterial objects
      final materialsList = _materials
          .map((m) => EstimateMaterial(
                name: m.nameController.text,
                cost: m.cost,
                quantity: m.quantity,
              ))
          .toList();

      final laborCost = double.tryParse(_laborCostController.text) ?? 0;

      final result = await OutcallService.submitEstimate(
        jobReference: widget.jobReference,
        artisanId: widget.artisanId,
        materials: materialsList,
        laborCost: laborCost,
        timeline: _timelineController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() => _isSubmitted = true);
        _showSuccessDialog(result.totalEstimate);
        widget.onSuccess?.call();
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(double totalEstimate) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
            const SizedBox(width: AppTheme.spaceSM),
            const Text('Estimate Submitted!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your estimate has been submitted to the customer.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            _buildAmountSummaryCard(
              label: 'Total Estimate',
              value: _formatCurrency(totalEstimate),
              emphasized: true,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'You will be notified when the customer accepts or declines.',
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
  void dispose() {
    _timelineController.dispose();
    _notesController.dispose();
    _laborCostController.dispose();
    for (var material in _materials) {
      material.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _buildSubmittedView();
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              decoration: BoxDecoration(
                gradient: AppTheme.subtleGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSM),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: const Icon(Icons.receipt_long, color: AppTheme.primary),
                  ),
                  const SizedBox(width: AppTheme.spaceBase),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Job Reference', style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
                        const SizedBox(height: 2),
                        Text(widget.jobReference, style: AppTheme.titleSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Materials',
                  style: AppTheme.headline3,
                ),
                TextButton.icon(
                  onPressed: _addMaterial,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),

            if (_materials.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spaceXL),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: AppTheme.divider),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textTertiary),
                      const SizedBox(height: AppTheme.spaceSM),
                      Text('No materials added', style: AppTheme.bodyMedium),
                      const SizedBox(height: AppTheme.spaceSM),
                      ElevatedButton(
                        onPressed: _addMaterial,
                        child: const Text('Add First Material'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _materials.length,
                itemBuilder: (context, index) {
                  final material = _materials[index];
                  return _MaterialCard(
                    material: material,
                    onRemove: () => _removeMaterial(index),
                    onChanged: () => setState(() {}),
                  );
                },
              ),

            const SizedBox(height: AppTheme.spaceXL),

            if (_materials.isNotEmpty)
              _buildAmountSummaryCard(
                label: 'Materials Total',
                value: _formatCurrency(_totalMaterials),
              ),

            const SizedBox(height: AppTheme.spaceXL),

            Text(
              'Labor Cost',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextFormField(
              controller: _laborCostController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: '₦ ',
                hintText: 'Enter labor cost',
                prefixIcon: Icon(Icons.handyman_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter labor cost';
                }
                final cost = double.tryParse(value);
                if (cost == null || cost < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppTheme.spaceXL),

            Text(
              'Timeline',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextFormField(
              controller: _timelineController,
              decoration: const InputDecoration(
                hintText: 'e.g., 2 days, 1 week',
                prefixIcon: Icon(Icons.schedule),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter estimated timeline';
                }
                return null;
              },
            ),

            const SizedBox(height: AppTheme.spaceXL),

            Text(
              'Notes (Optional)',
              style: AppTheme.headline3,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any additional notes for the customer...',
                prefixIcon: Icon(Icons.sticky_note_2_outlined),
              ),
            ),

            const SizedBox(height: AppTheme.spaceXL),

            _buildAmountSummaryCard(
              label: 'Total Estimate',
              value: _formatCurrency(_totalEstimate),
              emphasized: true,
            ),

            const SizedBox(height: AppTheme.space2XL),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitEstimate,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Estimate',
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

            const SizedBox(height: AppTheme.spaceBase),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space2XL),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceXL),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: AppTheme.shadowMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 80,
              ),
              const SizedBox(height: AppTheme.spaceXL),
              Text(
                'Estimate Submitted',
                style: AppTheme.headline2,
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Your estimate for job ${widget.jobReference} has been submitted.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceXL),
              Text(
                'Waiting for customer approval...',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  int quantity = 1;

  double get cost => double.tryParse(costController.text) ?? 0;

  void dispose() {
    nameController.dispose();
    costController.dispose();
  }
}

class _MaterialCard extends StatelessWidget {
  final _MaterialItem material;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _MaterialCard({
    required this.material,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: material.nameController,
                    decoration: const InputDecoration(
                      labelText: 'Material Name',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSM),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM),
            LayoutBuilder(
              builder: (context, constraints) {
                final costField = TextFormField(
                  controller: material.costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  textAlign: TextAlign.right,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Cost per unit',
                    hintText: '0.00',
                    prefixText: '₦ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                    helperText: 'Enter price for one item',
                    isDense: true,
                  ),
                  onChanged: (_) => onChanged(),
                );

                final quantityControl = Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXS),
                  decoration: BoxDecoration(
                    color: AppTheme.inputFill,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Qty:', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: material.quantity > 1
                            ? () {
                                material.quantity--;
                                onChanged();
                              }
                            : null,
                      ),
                      Text(
                        '${material.quantity}',
                        style: AppTheme.titleMedium,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          material.quantity++;
                          onChanged();
                        },
                      ),
                    ],
                  ),
                );

                final totalPreview = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSM,
                    vertical: AppTheme.spaceXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    'Line total: ₦${(material.cost * material.quantity).toStringAsFixed(2)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      costField,
                      const SizedBox(height: AppTheme.spaceSM),
                      Row(
                        children: [
                          quantityControl,
                          const Spacer(),
                          Flexible(child: totalPreview),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: costField),
                        const SizedBox(width: AppTheme.spaceSM),
                        quantityControl,
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXS),
                    Align(
                      alignment: Alignment.centerRight,
                      child: totalPreview,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
