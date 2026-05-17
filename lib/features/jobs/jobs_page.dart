import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../ui/app_theme.dart';
import '../../services/payment_service.dart';
import '../../services/outcall_service.dart';
import '../directory/register_type_page.dart';
import '../models/job.dart';
import '../outcall/submit_estimate_form.dart';
import '../auth/password_recovery_flow.dart';
import '../../widgets/escrow_badge.dart';

class JobsPage extends StatefulWidget {
  final bool showBottomNav;

  const JobsPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> with WidgetsBindingObserver {
  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _artisanId;
  String? _customerEmail;
  String? _customerPhone;
  bool _isCustomer = false;
  Timer? _jobsPollTimer;
  final Map<String, TextEditingController> _arrivalOtpControllers = {};
  final Map<String, FocusNode> _arrivalOtpFocusNodes = {};

  bool get _isEditingArrivalOtp =>
      _arrivalOtpFocusNodes.values.any((node) => node.hasFocus);

  String _formatNaira(num amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final restored = await _restoreArtisanSession(showLoading: true);
    if (!restored && mounted) {
      setState(() => _isLoading = false);
      Future.microtask(_showUserTypeDialog);
    }
  }

  Future<bool> _restoreArtisanSession({bool showLoading = false}) async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.initialized) {
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!authProvider.authenticated) {
      return false;
    }

    final artisanId = await PaymentService.getArtisanIdForCurrentUser(
      email: authProvider.userEmail,
    );

    if (!mounted || artisanId == null || artisanId.isEmpty) {
      return false;
    }

    setState(() {
      _artisanId = artisanId;
      _customerEmail = null;
      _customerPhone = null;
      _isCustomer = false;
    });

    await _loadJobs(showLoading: showLoading);
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jobsPollTimer?.cancel();
    for (final controller in _arrivalOtpControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _arrivalOtpFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (_isCustomer && (_customerEmail != null || _customerPhone != null)) {
        _loadCustomerJobs(showLoading: false);
      } else if (_artisanId != null) {
        _loadJobs(showLoading: false);
      } else {
        _restoreArtisanSession(showLoading: false);
      }
    }
  }

  void _startJobsPolling() {
    _jobsPollTimer?.cancel();
    _jobsPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _isLoading || _isEditingArrivalOtp) return;
      if (_isCustomer && (_customerEmail != null || _customerPhone != null)) {
        _loadCustomerJobs(showLoading: false);
      } else if (_artisanId != null) {
        _loadJobs(showLoading: false);
      }
    });
  }

  Future<void> _logoutCurrentSession() async {
    _jobsPollTimer?.cancel();

    final authProvider = context.read<AuthProvider>();
    final wasArtisanSession = _artisanId != null;

    if (wasArtisanSession && authProvider.authenticated) {
      await authProvider.logout();
    }

    if (!mounted) return;

    setState(() {
      _artisanId = null;
      _customerEmail = null;
      _customerPhone = null;
      _isCustomer = false;
      _jobs = [];
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasArtisanSession
              ? 'Artisan session logged out.'
              : 'Customer job session cleared.',
        ),
      ),
    );

    Future.microtask(_showUserTypeDialog);
  }

  void _showUserTypeDialog() {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (dialogContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLG,
            AppTheme.spaceSM,
            AppTheme.spaceLG,
            AppTheme.spaceLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
              const SizedBox(height: AppTheme.spaceBase),
              Text('Continue as', style: AppTheme.headline3),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Choose your role to view the right job workflow.',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLG),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showCustomerLoginDialog();
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text('I am a Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showArtisanLoginForm();
                  },
                  icon: const Icon(Icons.build_outlined),
                  label: const Text('I am an Artisan'),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacementNamed(context, '/directory');
                },
                child: const Text('Back to Directory'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomerLoginDialog() {
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Customer Login'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email or phone to view your jobs',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushReplacementNamed(context, '/directory');
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();

              if (phone.isEmpty && email.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter at least email or phone')),
                );
                return;
              }

              // Store customer info and load customer jobs
              _customerEmail = email.isNotEmpty ? email : null;
              _customerPhone = phone.isNotEmpty ? phone : null;

              Navigator.pop(dialogContext);

              // Load jobs for this specific customer
              _loadCustomerJobs();
            },
            child: const Text('View Jobs'),
          ),
        ],
      ),
    );
  }

  void _showArtisanLoginForm() {
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Artisan Login'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    PasswordRecoveryFlow.show(
                      context,
                      initialEmail: emailController.text.trim(),
                      initialPhone: phoneController.text.trim(),
                    );
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushReplacementNamed(context, '/directory');
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterTypePage()),
              );
            },
            child: const Text('Register'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text;

              if (phone.isEmpty || email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final response = await Supabase.instance.client.auth
                    .signInWithPassword(email: email, password: password);

                if (response.user == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Invalid credentials')),
                  );
                  return;
                }

                final artisan = await Supabase.instance.client
                    .from('artisans')
                    .select('id, email, phone')
                    .eq('phone', phone)
                    .eq('email', email)
                    .limit(1)
                    .maybeSingle();

                if (artisan == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No artisan profile is linked to this account yet.',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  _artisanId = artisan['id']?.toString();
                  _customerEmail = null;
                  _customerPhone = null;
                  _isCustomer = false;
                });

                Navigator.pop(dialogContext);
                _loadJobs();
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Login failed: $e')),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<List<Job>> _syncPendingPaidJobs(List<Job> jobs) async {
    final syncedJobs = <Job>[];

    for (final job in jobs) {
      final shouldVerify = (job.status ?? '').toLowerCase() == 'pending' &&
          (job.paymentReference?.isNotEmpty ?? false);

      if (!shouldVerify) {
        syncedJobs.add(job);
        continue;
      }

      final refreshed = await PaymentService.confirmPaymentForJob(
        job.jobReference,
      );
      syncedJobs.add(refreshed ?? job);
    }

    return syncedJobs;
  }

  Future<void> _syncPaymentStatus(Job job) async {
    try {
      final refreshed = await PaymentService.confirmPaymentForJob(
        job.jobReference,
      );

      if (!mounted) return;

      if (refreshed != null && refreshed.status == 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment confirmed successfully.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _isCustomer ? _loadCustomerJobs() : _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payment is still pending confirmation. Please wait a few seconds and try again.'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking payment status: $e')),
      );
    }
  }

  Future<void> _loadJobs({bool showLoading = true}) async {
    if (_artisanId == null) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _isCustomer = false;
      });
    } else {
      _isCustomer = false;
    }

    final jobs = await PaymentService.getJobsForArtisan(_artisanId!);
    final syncedJobs = await _syncPendingPaidJobs(jobs);

    if (mounted) {
      setState(() {
        _jobs = syncedJobs;
        _isLoading = false;
      });
      _startJobsPolling();
    }
  }

  Future<void> _loadCustomerJobs({bool showLoading = true}) async {
    if (_customerEmail == null && _customerPhone == null) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _isCustomer = true;
      });
    } else {
      _isCustomer = true;
    }

    try {
      final jobs =
          await PaymentService.getJobsForCustomer(_customerEmail ?? '');
      final syncedJobs = await _syncPendingPaidJobs(jobs);

      if (!mounted) return;

      setState(() {
        _jobs = syncedJobs;
        _isLoading = false;
      });
      _startJobsPolling();

      // Show debug info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Found ${jobs.length} jobs for email: ${_customerEmail ?? "none"}, phone: ${_customerPhone ?? "none"}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final hasActiveSession = authProvider.authenticated ||
        _artisanId != null ||
        _isCustomer ||
        _customerEmail != null ||
        _customerPhone != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/directory');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : (_isCustomer ? _loadCustomerJobs : _loadJobs),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              if (!hasActiveSession) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No active jobs session to logout yet.'),
                  ),
                );
                return;
              }

              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout session'),
                  content: Text(
                    _artisanId != null || authProvider.authenticated
                        ? 'Do you want to logout your artisan session from Jobs?'
                        : 'Do you want to clear this customer jobs session?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await _logoutCurrentSession();
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 4,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(context, '/directory');
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(context, '/stores');
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(context, '/equipment');
                    break;
                  case 3:
                    Navigator.pushReplacementNamed(context, '/wallet');
                    break;
                  case 4:
                    // Already on jobs
                    break;
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Directory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Store',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.build),
                  label: 'Equipment',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work),
                  label: 'Jobs',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No jobs yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Jobs will appear here when customers book your services',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String label;

    switch (status) {
      case 'verified':
      case 'paid':
        chipColor = AppTheme.success;
        label = 'Paid';
        break;
      case 'arrival_confirmed':
      case 'outcall_confirmed':
        chipColor = AppTheme.primary;
        label = 'Outcall Confirmed';
        break;
      case 'estimate_pending':
        chipColor = AppTheme.primary;
        label = 'Outcall Confirmed';
        break;
      case 'pending':
        chipColor = AppTheme.warning;
        label = 'Pending';
        break;
      case 'estimate_submitted':
        chipColor = AppTheme.primary;
        label = 'Estimate Sent';
        break;
      case 'accepted':
      case 'estimate_accepted':
        chipColor = AppTheme.info;
        label = 'Work in Progress';
        break;
      case 'declined':
      case 'estimate_declined':
        chipColor = AppTheme.error;
        label = 'Declined';
        break;
      case 'pending_completion':
      case 'pending_completion_confirmation':
        chipColor = AppTheme.warning;
        label = 'Awaiting Verification';
        break;
      case 'completed':
        chipColor = AppTheme.success;
        label = 'Completed';
        break;
      default:
        chipColor = AppTheme.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: AppTheme.spaceXXS + 1,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: chipColor.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    final hasSubmittedEstimate = (job.estimateTotal ?? 0) > 0 ||
        (job.estimateMaterialsCost ?? 0) > 0 ||
        (job.estimateLaborCost ?? 0) > 0;
    final isInitialOutcallBooking =
        (job.serviceType ?? '').toLowerCase() == 'outcall' &&
            !hasSubmittedEstimate;
    final depositLabel =
        hasSubmittedEstimate ? 'Estimate Deposit' : 'Outcall Deposit';
    final depositAmount = isInitialOutcallBooking
        ? 2000.0
        : job.escrowAmount > 0
            ? job.escrowAmount.toDouble()
            : (hasSubmittedEstimate
                ? (job.estimateTotal ?? 0)
                : job.amountPaid.toDouble());

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.jobReference,
                    style: AppTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(job.status ?? ''),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXS),
            if (job.customerName != null)
              Text(
                'Customer: ${job.customerName}',
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
            if (job.customerPhone != null) ...[
              const SizedBox(height: AppTheme.spaceXXS + 2),
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 16, color: AppTheme.success),
                  const SizedBox(width: 4),
                  Text(
                    job.customerPhone!,
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  // Call Customer Button
                  IconButton(
                    icon: const Icon(Icons.call_outlined,
                        color: AppTheme.success),
                    onPressed: () => _makePhoneCall(job.customerPhone!),
                    tooltip: 'Call Customer',
                  ),
                  // WhatsApp Customer Button
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: AppTheme.whatsapp),
                    onPressed: () => _openWhatsAppChat(job.customerPhone!,
                        customerName: job.customerName),
                    tooltip: 'WhatsApp Customer',
                  ),
                ],
              ),
            ],
            if (job.customerEmail != null) ...[
              const SizedBox(height: AppTheme.spaceXXS + 2),
              Row(
                children: [
                  const Icon(Icons.email,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.customerEmail ?? '',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (job.serviceType != null) ...[
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Service: ${job.serviceType}',
                style:
                    AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
            ],
            if (job.address != null) ...[
              const SizedBox(height: AppTheme.spaceXXS + 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: AppTheme.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.address!,
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.spaceXS),
            if (depositAmount > 0)
              EscrowBadge(
                label: depositLabel,
                amount: '₦${_formatNaira(depositAmount)}',
                showSurface: true,
                expandLabel: true,
              ),
            if (depositAmount > 0)
              const SizedBox(height: AppTheme.spaceXXS + 2),
            Text(
              'Amount: ₦${_formatNaira(depositAmount > 0 ? depositAmount : job.amountPaid)}',
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.success,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            _buildActionButtons(job),
          ],
        ),
      ),
    );
  }

  /// Build customer-specific action buttons
  Widget _buildCustomerActionButtons(Job job) {
    final hasAcceptedEstimate = ((job.estimateTotal ?? 0) > 0 ||
            (job.estimateMaterialsCost ?? 0) > 0 ||
            (job.estimateLaborCost ?? 0) > 0) &&
        (job.estimateStatus == 'accepted' ||
            job.estimateStatus == 'estimate_accepted');

    final isWorkInProgress = job.status == 'accepted' ||
        job.status == 'estimate_accepted' ||
        hasAcceptedEstimate;

    if (isWorkInProgress &&
        job.status != 'pending_completion' &&
        job.status != 'pending_completion_confirmation' &&
        job.status != 'completed') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Work in progress',
            style:
                TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    switch (job.status) {
      case 'pending':
        // Check if customer requested new estimate
        if (job.customerRequestedNewEstimate == true) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Waiting for new estimate...',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }
        if (job.paymentReference?.isNotEmpty ?? false) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Payment is being confirmed.',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _syncPaymentStatus(job),
                icon: const Icon(Icons.refresh),
                label: const Text('I Have Paid'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ],
          );
        }
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Waiting for payment...',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 'paid':
      case 'arrival_confirmed':
      case 'outcall_confirmed':
      case 'estimate_pending':
      case 'estimate_submitted':
        // Show OTP / estimate stage updates for the customer.
        return _buildCustomerEstimateDisplay(job);

      case 'accepted':
      case 'estimate_accepted':
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Work in progress',
              style: TextStyle(
                  color: AppTheme.success, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 'pending_completion':
      case 'pending_completion_confirmation':
        // Customer sees the OTP and reads it aloud to the artisan
        return _buildCustomerCompletionOtpDisplay(job);

      case 'completed':
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Job completed!',
              style: TextStyle(
                  color: AppTheme.success, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        );

      default:
        return const Text('View job details');
    }
  }

  /// Show estimate display for customer with Accept/Decline buttons
  Widget _buildCustomerEstimateDisplay(Job job) {
    // Check if there's an estimate
    final hasEstimate = job.estimateTotal != null && job.estimateTotal! > 0;

    if (!hasEstimate && job.customerRequestedNewEstimate == true) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Waiting for new estimate...',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (hasEstimate && job.estimateStatus == 'pending') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'You have a new estimate!',
            style: TextStyle(
              color: AppTheme.warning,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warning),
            ),
            child: Column(
              children: [
                if (job.estimateMaterialsCost != null &&
                    job.estimateMaterialsCost! > 0)
                  _buildEstimateRow('Materials', job.estimateMaterialsCost!),
                if (job.estimateLaborCost != null && job.estimateLaborCost! > 0)
                  _buildEstimateRow('Labor', job.estimateLaborCost!),
                const Divider(),
                _buildEstimateRow('Total', job.estimateTotal ?? 0,
                    isBold: true),
                if (job.estimateTimeline != null &&
                    job.estimateTimeline!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Timeline:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(job.estimateTimeline!),
                    ],
                  ),
                ],
                if (job.estimateNotes != null &&
                    job.estimateNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(job.estimateNotes!),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToEstimate(job, 'accepted'),
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToEstimate(job, 'declined'),
                  icon: const Icon(Icons.close),
                  label: const Text('Decline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // If payment is complete for an accepted estimate, show the customer OTP/waiting state
    if ((job.status == 'paid' &&
            (job.estimateStatus == 'accepted' ||
                job.estimateStatus == 'estimate_accepted')) ||
        job.status == 'pending_completion' ||
        job.status == 'pending_completion_confirmation') {
      return _buildCustomerOtpDisplay(job);
    }

    // Show accepted/declined status
    if (hasEstimate && job.estimateStatus == 'accepted') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppTheme.success),
            SizedBox(width: 8),
            Text(
              'Estimate Accepted',
              style: TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (job.estimateStatus == 'declined') {
      final isDeclinedByArtisan = job.declinedBy == 'artisan';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDeclinedByArtisan ? Icons.person_off : Icons.cancel,
                  color: AppTheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  isDeclinedByArtisan
                      ? 'Job Declined by Artisan'
                      : 'Estimate Declined',
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (isDeclinedByArtisan) ...[
              const SizedBox(height: 12),
              const Text(
                'The artisan declined your job. You can request a new estimate from another artisan or close this job.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _requestNewEstimate(job),
                      icon: const Icon(Icons.replay),
                      label: const Text('Request New Estimate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _closeJob(job),
                      icon: const Icon(Icons.close),
                      label: const Text('Close Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.textSecondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'You declined this estimate. Choose an action below:',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _requestNewEstimate(job),
                      icon: const Icon(Icons.replay),
                      label: const Text('Request New Estimate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _closeJob(job),
                      icon: const Icon(Icons.close),
                      label: const Text('Close Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.textSecondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Fall back to OTP display
    return _buildCustomerOtpDisplay(job);
  }

  Widget _buildEstimateRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '₦${_formatNaira(amount)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToEstimate(Job job, String response) async {
    try {
      // If accepting, show payment method selection first
      if (response == 'accepted') {
        _showPaymentMethodDialog(job);
        return;
      }

      // For decline, show options dialog first
      _showDeclineOptionsDialog(job);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeclineOptionsDialog(Job job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Decline Estimate'),
          ],
        ),
        content: const Text(
          'What would you like to do?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _processDeclineWithAction(job, 'request_new');
            },
            icon: const Icon(Icons.replay),
            label: const Text('Request New Estimate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _processDeclineWithAction(job, 'close_job');
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

  Future<void> _processDeclineWithAction(Job job, String action) async {
    try {
      final client = Supabase.instance.client;

      if (action == 'close_job') {
        // Close the job - update status to closed
        await client.from('jobs').update({
          'status': 'closed',
          'estimate_status': 'declined',
          'declined_by': 'customer',
          'estimate_responded_at': DateTime.now().toIso8601String(),
        }).eq('id', job.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job closed'),
            backgroundColor: AppTheme.error,
          ),
        );
      } else {
        // Request new estimate - keep the job in the post-arrival estimate stage
        // so the artisan can submit a revised quote immediately.
        await client.from('jobs').update({
          'status': 'arrival_confirmed',
          'estimate_status': 'declined',
          'declined_by': null,
          'customer_requested_new_estimate': true,
          'estimate_responded_at': DateTime.now().toIso8601String(),
          // Clear the old estimate so artisan can submit a new one
          'estimate_materials': null,
          'estimate_materials_cost': null,
          'estimate_labor_cost': null,
          'estimate_total': null,
          'estimate_timeline': null,
          'estimate_notes': null,
          'estimate_submitted_at': null,
        }).eq('id', job.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent! Artisan can submit a new estimate.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      _loadCustomerJobs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _requestNewEstimate(Job job) async {
    try {
      final client = Supabase.instance.client;

      // Keep the job at the estimate stage so the artisan can resubmit directly.
      await client.from('jobs').update({
        'status': 'arrival_confirmed',
        'estimate_status': 'declined',
        'declined_by': null,
        'customer_requested_new_estimate': true,
        // Clear the old estimate
        'estimate_materials': null,
        'estimate_materials_cost': null,
        'estimate_labor_cost': null,
        'estimate_total': null,
        'estimate_timeline': null,
        'estimate_notes': null,
        'estimate_submitted_at': null,
      }).eq('id', job.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent! Artisans can now submit new estimates.'),
          backgroundColor: AppTheme.success,
        ),
      );

      _loadCustomerJobs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _closeJob(Job job) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Job'),
        content: const Text(
            'Are you sure you want to close this job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final client = Supabase.instance.client;
                await client.from('jobs').update({
                  'status': 'closed',
                  'estimate_status': null,
                  'declined_by': null,
                }).eq('id', job.id!);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job closed successfully.'),
                    backgroundColor: AppTheme.success,
                  ),
                );

                _loadCustomerJobs();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Close Job'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodDialog(Job job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Choose Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How would you like to pay for this job?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            // Pay into Wallet (Paystack)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processPaymentViaWallet(job);
              },
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Pay into Wallet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            // Pay Cash/Transfer
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processPaymentCashOrTransfer(job);
              },
              icon: const Icon(Icons.money),
              label: const Text('Pay Cash/Transfer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.success,
                side: const BorderSide(color: AppTheme.success),
                padding: const EdgeInsets.symmetric(vertical: 16),
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

  Future<void> _processPaymentViaWallet(Job job) async {
    try {
      // Calculate total amount with 10% service fee
      final estimateAmount = (job.estimateTotal != null &&
              job.estimateTotal! > 0)
          ? job.estimateTotal!
          : ((job.estimateMaterialsCost ?? 0) + (job.estimateLaborCost ?? 0));
      if (estimateAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to initialize payment. Estimate amount is invalid.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
      final serviceFee = estimateAmount * 0.10;
      final totalAmountWithFee = (estimateAmount + serviceFee).round();

      // Initialize Paystack payment
      final paymentResult = await PaymentService.initializePayment(
        artisanId: job.artisanId ?? '',
        customerEmail: job.customerEmail ?? '',
        amount: totalAmountWithFee.toInt(),
        jobReference: job.jobReference,
        serviceType: job.serviceType ?? '',
        customerName: job.customerName ?? '',
        customerPhone: job.customerPhone ?? '',
        description: 'Payment for job ${job.jobReference}',
        address: job.address,
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
          _showEstimatePaymentConfirmationDialog(job);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open payment page'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(paymentResult.error ?? 'Payment initialization failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showEstimatePaymentConfirmationDialog(Job job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.payment, color: AppTheme.primary),
            SizedBox(width: AppTheme.spaceSM),
            Text('Confirm Transaction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete the payment in Paystack, then tap Check Status. The estimate will only be accepted after payment is verified.',
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              'Job Reference: ${job.jobReference}',
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
            onPressed: () {
              Navigator.pop(dialogContext);
              _syncPaymentStatus(job);
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPaymentCashOrTransfer(Job job) async {
    try {
      // Accept the estimate
      await _acceptEstimate(job);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Estimate accepted! Please pay artisan directly via cash or transfer.'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 5),
        ),
      );

      _loadCustomerJobs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _acceptEstimate(Job job) async {
    final client = Supabase.instance.client;

    // Update status to 'accepted'
    await client.from('jobs').update({
      'status': 'accepted',
      'estimate_status': 'accepted',
    }).eq('id', job.id!);
  }

  Future<void> _finishJob(Job job) async {
    try {
      final result = await PaymentService.generateJobCompletionOtp(
        jobReference: job.jobReference,
        artisanId: job.artisanId!,
      );

      if (!mounted) return;

      if (result.success) {
        // Artisan does NOT see the OTP — it goes to the customer only.
        // The artisan waits for the customer to call out the OTP to them.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'OTP sent to customer. Ask the customer to read it to you.'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 5),
          ),
        );
        _loadJobs(); // Refresh so artisan screen moves to OTP entry state
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.message}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _confirmCustomerOtp(Job job) async {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Customer OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter the OTP the customer gave you to release labor payment.'),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: 'Enter 6-digit OTP',
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter 6-digit OTP')),
                );
                return;
              }

              Navigator.pop(context);

              final result = await PaymentService.verifyAndReleaseLabor(
                jobReference: job.jobReference,
                artisanId: job.artisanId!,
                customerOtp: otpController.text,
              );

              if (result.success) {
                _loadJobs(showLoading: false);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.account_balance_wallet,
                            color: AppTheme.success),
                        SizedBox(width: 8),
                        Text('Payment Released!'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppTheme.success, size: 64),
                        const SizedBox(height: 12),
                        const Text(
                          'Job completed successfully.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₦${result.amountReleased.toStringAsFixed(0)} has been moved to your available balance.',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Check your wallet to see your updated balance.',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _loadJobs();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white),
                        child: const Text('Great!'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${result.message}'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            child: const Text('Complete Job'),
          ),
        ],
      ),
    );
  }

  /// Show OTP display for customer when artisan has arrived
  Widget _buildCustomerOtpDisplay(Job job) {
    // Check if there's an OTP in the job data directly
    final hasOtp = job.arrivalOtp != null && job.arrivalOtp!.isNotEmpty;

    // Check if OTP is still valid
    DateTime? expiry;
    try {
      if (job.arrivalOtpExpiry != null) {
        expiry = DateTime.parse(job.arrivalOtpExpiry!);
      }
    } catch (_) {}
    final isOtpValid =
        hasOtp && expiry != null && expiry.isAfter(DateTime.now());

    if (job.status == 'estimate_pending' ||
        job.status == 'arrival_confirmed' ||
        job.status == 'outcall_confirmed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: const Column(
          children: [
            Icon(Icons.verified_outlined, color: AppTheme.primary, size: 48),
            SizedBox(height: 8),
            Text(
              'Outcall Confirmed',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'Arrival has been verified successfully. The artisan can now prepare your estimate.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (isOtpValid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Artisan is at your location!',
            style: TextStyle(
              color: AppTheme.success,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary),
            ),
            child: Column(
              children: [
                const Text(
                  'Your Verification Code:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  job.arrivalOtp!,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Give this code to the artisan to verify',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // No OTP yet - show waiting message with instructions
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Waiting for artisan to arrive...',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
          ),
          child: const Column(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warning, size: 24),
              SizedBox(height: 8),
              Text(
                'The artisan will generate a code when they arrive at your location.',
                style: TextStyle(color: AppTheme.warning, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// CUSTOMER SIDE: Shows the OTP large and clearly so the customer can
  /// read it aloud to the artisan over the phone or in person.
  Widget _buildCustomerCompletionOtpDisplay(Job job) {
    final hasOtp = job.completionOtp != null && job.completionOtp!.isNotEmpty;
    final isOtpValid = job.completionOtpExpiry != null &&
        DateTime.tryParse(job.completionOtpExpiry!) != null &&
        DateTime.parse(job.completionOtpExpiry!).isAfter(DateTime.now());

    if (!hasOtp || !isOtpValid) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning),
        ),
        child: const Column(
          children: [
            Icon(Icons.hourglass_empty, color: AppTheme.warning, size: 48),
            SizedBox(height: 8),
            Text(
              'Waiting for artisan to finish job...',
              style: TextStyle(
                  color: AppTheme.warning, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'You will see a code here when the artisan marks the job as done.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.success),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
              const SizedBox(height: 8),
              const Text(
                'Work Completed!',
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Read this code to the artisan:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Large OTP display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success, width: 2),
                ),
                child: Text(
                  job.completionOtp!,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 14,
                    color: AppTheme.success,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Call or show this code to your artisan to release payment.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Job job) {
    // If not logged in as artisan, show customer-specific UI
    if (_artisanId == null) {
      // Customer view - show appropriate actions based on status
      return _buildCustomerActionButtons(job);
    }

    final jobStatus = job.status ?? 'pending';
    final hasSubmittedEstimate = (job.estimateTotal ?? 0) > 0 ||
        (job.estimateMaterialsCost ?? 0) > 0 ||
        (job.estimateLaborCost ?? 0) > 0;
    final isAcceptedEstimate = hasSubmittedEstimate &&
        (job.estimateStatus == 'accepted' ||
            job.estimateStatus == 'estimate_accepted');
    final isAwaitingArrivalVerification = jobStatus == 'paid' &&
        (job.serviceType ?? '').toLowerCase() == 'outcall' &&
        !hasSubmittedEstimate;

    debugPrint(
        'Artisan view - job: ${job.jobReference}, status: $jobStatus, estimateTotal: ${job.estimateTotal}');

    if (isAwaitingArrivalVerification) {
      return _buildArrivalVerification(job);
    }

    if (isAcceptedEstimate &&
        jobStatus != 'pending_completion' &&
        jobStatus != 'pending_completion_confirmation' &&
        jobStatus != 'completed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.success),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success, size: 48),
                SizedBox(height: 8),
                Text(
                  'Estimate Accepted!',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'The customer has accepted your estimate.',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _finishJob(job),
            icon: const Icon(Icons.check),
            label: const Text('Finish Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      );
    }

    switch (jobStatus) {
      case 'pending':
        // Check if customer requested new estimate - show estimate form directly
        // Also check estimate_status == 'declined' as fallback
        if (job.customerRequestedNewEstimate == true ||
            job.estimateStatus == 'declined') {
          debugPrint('Customer requested new estimate - showing form');
          return SubmitEstimateForm(
            jobReference: job.jobReference,
            artisanId: _artisanId!,
            onSuccess: () {
              _loadJobs();
            },
          );
        }
        // Check if this is an outcall waiting for artisan arrival
        if (job.estimateTotal == null || job.estimateTotal == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Waiting for customer to book outcall...',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }
        // Has estimate but waiting for customer response
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Waiting for customer to respond to estimate...',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 'paid':
        // If the customer asked for a revised quote, jump straight back to the
        // estimate form instead of forcing arrival confirmation again.
        if (job.customerRequestedNewEstimate == true ||
            (job.estimateStatus == 'declined' && job.declinedBy != 'artisan')) {
          return SubmitEstimateForm(
            jobReference: job.jobReference,
            artisanId: _artisanId!,
            onSuccess: () {
              _loadJobs();
            },
          );
        }

        // If this is a paid estimate job, show finish/completion flow instead of arrival verification
        if (isAcceptedEstimate) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Estimate Accepted!',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The customer has accepted your estimate.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _finishJob(job),
                icon: const Icon(Icons.check),
                label: const Text('Finish Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          );
        }

        // Outcall verification - artisan arrives and verifies with OTP.
        // Estimate submission is available after arrival is confirmed.
        return _buildArrivalVerification(job);

      case 'estimate_pending':
      case 'arrival_confirmed':
      case 'outcall_confirmed':
        // Arrival has been verified, so the artisan can now submit an estimate.
        return SubmitEstimateForm(
          jobReference: job.jobReference,
          artisanId: _artisanId!,
          onSuccess: () {
            _loadJobs();
          },
        );

      case 'estimate_submitted':
        // Wait for customer to accept/decline
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Estimate submitted. Waiting for customer review...',
              style: TextStyle(color: AppTheme.warning),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 'accepted':
      case 'estimate_accepted':
        // Show Finish Job button to generate completion OTP
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Estimate Accepted!',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The customer has accepted your estimate.',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _finishJob(job),
              icon: const Icon(Icons.check),
              label: const Text('Finish Job'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        );

      case 'pending_completion':
      case 'pending_completion_confirmation':
        final hasOtp =
            job.completionOtp != null && job.completionOtp!.isNotEmpty;
        final isOtpValid = job.completionOtpExpiry != null &&
            DateTime.tryParse(job.completionOtpExpiry!) != null &&
            DateTime.parse(job.completionOtpExpiry!).isAfter(DateTime.now());

        if (hasOtp && isOtpValid) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.warning, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Job Marked as Done',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ask customer for OTP to complete the job',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _confirmCustomerOtp(job),
                icon: const Icon(Icons.verified),
                label: const Text('Enter Customer OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          );
        } else {
          // OTP expired or invalid, allow re-generating
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Verification timeout. Re-generate OTP?',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _finishJob(job),
                icon: const Icon(Icons.refresh),
                label: const Text('Generate New OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        }

      case 'declined':
      case 'estimate_declined':
        final isDeclinedByArtisan = job.declinedBy == 'artisan';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error),
              ),
              child: Column(
                children: [
                  Icon(
                    isDeclinedByArtisan ? Icons.person_off : Icons.cancel,
                    color: AppTheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDeclinedByArtisan
                        ? 'Job Declined by You'
                        : 'Estimate Declined',
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDeclinedByArtisan
                        ? 'You declined this job. Customer can request a new estimate.'
                        : (job.customerRequestedNewEstimate == true)
                            ? 'Customer requested a new estimate. Submit your estimate.'
                            : 'Estimate declined - Waiting for customer input',
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Show submit button when:
            // 1. Artisan declined and job is pending (artisan can re-submit)
            // 2. Customer declined AND requested new estimate (artisan can resubmit)
            // Hide when customer declined but hasn't chosen an option yet
            if ((isDeclinedByArtisan && job.status == 'pending') ||
                job.customerRequestedNewEstimate == true) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubmitEstimateForm(
                        jobReference: job.jobReference,
                        artisanId: _artisanId!,
                        onSuccess: () {
                          _loadJobs();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.replay),
                label: const Text('Submit New Estimate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ],
        );

      case 'completed':
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Job completed!',
              style: TextStyle(
                  color: AppTheme.success, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Build arrival verification UI - artisan clicks "I've Arrived" then enters OTP
  Widget _buildArrivalVerification(Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tap "I\'ve Arrived" to send an OTP to the customer',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Step 1: Artisan clicks "I've Arrived" to generate OTP
        ElevatedButton.icon(
          onPressed: () => _generateArrivalOtp(job),
          icon: const Icon(Icons.location_on),
          label: const Text("I've Arrived - Send OTP"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'After the customer receives the code, enter it below to verify the outcall.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Step 2: Enter OTP from customer
        _buildOtpEntry(job),
      ],
    );
  }

  Future<void> _generateArrivalOtp(Job job) async {
    try {
      debugPrint(
          'Generating OTP for job: ${job.jobReference}, artisan: $_artisanId, id: ${job.id}');

      // Use direct database call instead of edge function
      final success = await PaymentService.generateArrivalOtp(job.id!);

      debugPrint('OTP generation result: $success');

      if (!mounted) return;

      if (success) {
        // Tell artisan to wait for customer to call with the code
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'OTP sent to customer! Wait for customer to call you with the code.'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 5),
          ),
        );
        _loadJobs(); // Refresh to show arrival status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to generate OTP'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Widget _buildOtpEntry(Job job) {
    final jobKey = job.id ?? job.jobReference;
    final otpController = _arrivalOtpControllers.putIfAbsent(
      jobKey,
      () => TextEditingController(),
    );
    final otpFocusNode = _arrivalOtpFocusNodes.putIfAbsent(jobKey, () {
      final node = FocusNode();
      node.addListener(() {
        if (mounted) setState(() {});
      });
      return node;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: otpController,
          focusNode: otpFocusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          onTapOutside: (_) => otpFocusNode.unfocus(),
          decoration: const InputDecoration(
            labelText: 'Enter verification code',
            hintText: 'Get code from customer',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        if (otpFocusNode.hasFocus) ...[
          const SizedBox(height: 4),
          Text(
            'Auto-refresh is paused while you enter the OTP.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final otp = otpController.text.trim();
            if (otp.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please enter the verification code')),
              );
              return;
            }
            otpFocusNode.unfocus();
            await _verifyArrivalOtp(job, otp);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
          ),
          child: const Text('Verify & Confirm Arrival'),
        ),
      ],
    );
  }

  Future<void> _verifyArrivalOtp(Job job, String otp) async {
    try {
      final result = await OutcallService.verifyOutcallVisit(
        jobReference: job.jobReference,
        artisanId: _artisanId!,
        customerId: job.customerEmail ?? '',
        verificationMethod: 'otp',
        otp: otp,
      );

      if (!mounted) return;

      if (result.success) {
        // Move the job into the estimate stage as a client-side fallback so it
        // never appears to regress back to a generic pending state.
        try {
          final jobData =
              await PaymentService.getJobByReference(job.jobReference);
          if (jobData != null) {
            final updated = await PaymentService.updateJobStatus(
              jobData.id!,
              'estimate_pending',
            );
            debugPrint(
              'Status update result for ${job.jobReference}: $updated',
            );
          } else {
            debugPrint('Job not found for reference: ${job.jobReference}');
          }
        } catch (e) {
          debugPrint('Error updating job status: $e');
        }

        _arrivalOtpControllers[job.id ?? job.jobReference]?.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Arrival confirmed! You can now submit the estimate. ₦${result.amountReleased} released to wallet',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadJobs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${result.message}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsAppChat(String phoneNumber,
      {String? customerName}) async {
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '234${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('234') && cleanNumber.length == 10) {
      cleanNumber = '234$cleanNumber';
    }

    final greeting = (customerName != null && customerName.trim().isNotEmpty)
        ? 'Hello ${customerName.trim()}, I am reaching out about your HandiArtisan job.'
        : 'Hello, I am reaching out about your HandiArtisan job.';
    final uri = Uri.parse(
      'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(greeting)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
