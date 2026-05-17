import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/wallet_security_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/payment_service.dart';
import '../../widgets/paystack_payment_button.dart';

import '../auth/login_screen.dart';
import '../models/job.dart';
import '../models/wallet.dart';
import '../ui/app_theme.dart';

class WalletPage extends StatefulWidget {
  final bool showBottomNav;

  const WalletPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with WidgetsBindingObserver {
      void _showWithdrawalDialog() {
        final amountController = TextEditingController();
        final bankNameController = TextEditingController(text: _wallet?.bankName ?? '');
        final accountNumberController = TextEditingController(text: _wallet?.accountNumber ?? '');
        final accountNameController = TextEditingController(text: _wallet?.accountName ?? '');
        bool isLoading = false;

        showDialog(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Withdraw Funds'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (₦)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bankNameController,
                    decoration: const InputDecoration(labelText: 'Bank Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Account Number'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: accountNameController,
                    decoration: const InputDecoration(labelText: 'Account Name'),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final amount = int.tryParse(amountController.text.trim()) ?? 0;
                          final bankName = bankNameController.text.trim();
                          final accountNumber = accountNumberController.text.trim();
                          final accountName = accountNameController.text.trim();
                          if (amount <= 0 || bankName.isEmpty || accountNumber.isEmpty || accountName.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields with valid values.')),
                            );
                            return;
                          }
                          setDialogState(() => isLoading = true);
                          bool success = false;
                          try {
                            if (_artisanId == null) return;
                            // Call the withdrawal edge function via PaymentService
                            success = await PaymentService.withdrawFromWallet(
                              artisanId: _artisanId!,
                              amount: amount,
                              bankName: bankName,
                              accountNumber: accountNumber,
                              accountName: accountName,
                            );
                          } catch (e) {
                            success = false;
                          }
                          setDialogState(() => isLoading = false);
                          if (success) {
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              await _loadAllData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('₦$amount withdrawn successfully!')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Withdrawal failed.')),
                            );
                          }
                        },
                  child: const Text('Withdraw'),
                ),
              ],
            ),
          ),
        );
      }
    // Add stub for _buildTransactionsSection to fix missing method error
    Widget _buildTransactionsSection() {
      // TODO: Implement actual transaction list UI
      return const SizedBox.shrink();
    }
  // Add stub for _buildPendingJobsSection to fix missing method error
  Widget _buildPendingJobsSection() {
    return const SizedBox.shrink();
  }

  // Move dialog methods above build to avoid reference errors
  void _showDepositDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit Funds'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₦)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount.')),
                );
                return;
              }
              if (_artisanId == null) return;
              final success =
                  await PaymentService.depositToWallet(_artisanId!, amount);
              if (success) {
                if (mounted) {
                  Navigator.pop(context);
                  await _loadAllData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('₦$amount deposited successfully!')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deposit failed.')),
                );
              }
            },
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() {
    final amountController = TextEditingController();
    final emailController = TextEditingController();
    String? recipientName;
    String? recipientPhone;
    String? recipientArtisanId;
    bool isLoading = false;
    bool recipientNotFound = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Transfer Funds'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Recipient Email'),
                onChanged: (value) async {
                  setDialogState(() {
                    isLoading = true;
                    recipientNotFound = false;
                  });
                  final email = value.trim();
                  if (email.isEmpty) {
                    setDialogState(() {
                      recipientName = null;
                      recipientPhone = null;
                      recipientArtisanId = null;
                      isLoading = false;
                    });
                    return;
                  }
                  // Query Supabase for artisan info by email
                  final client = Supabase.instance.client;
                  try {
                    final response = await client
                        .from('artisans')
                        .select('id, name, phone')
                        .eq('email', email)
                        .maybeSingle();
                    if (response == null) {
                      setDialogState(() {
                        recipientName = null;
                        recipientPhone = null;
                        recipientArtisanId = null;
                        recipientNotFound = true;
                        isLoading = false;
                      });
                    } else {
                      setDialogState(() {
                        recipientName = response['name']?.toString();
                        recipientPhone = response['phone']?.toString();
                        recipientArtisanId = response['id']?.toString();
                        recipientNotFound = false;
                        isLoading = false;
                      });
                    }
                  } catch (e) {
                    setDialogState(() {
                      recipientName = null;
                      recipientPhone = null;
                      recipientArtisanId = null;
                      recipientNotFound = true;
                      isLoading = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              if (isLoading)
                const LinearProgressIndicator(),
              if (recipientName != null && recipientArtisanId != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: $recipientName'),
                    Text('Phone: ${recipientPhone ?? "-"}'),
                  ],
                ),
              if (recipientNotFound && emailController.text.isNotEmpty)
                const Text('No artisan found for this email.', style: TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₦)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (recipientArtisanId == null || isLoading)
                  ? null
                  : () async {
                      final amount = int.tryParse(amountController.text.trim()) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount.')),
                        );
                        return;
                      }
                      if (_artisanId == null) return;
                      final success = await PaymentService.transferFromWallet(
                        fromArtisanId: _artisanId!,
                        toArtisanId: recipientArtisanId!,
                        amount: amount,
                      );
                      if (success) {
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          await _loadAllData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('₦$amount transferred successfully!')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Transfer failed.')),
                        );
                      }
                    },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  Wallet? _wallet;
  List<Job> _jobs = [];
  List<PaymentTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<dynamic>>? _walletSubscription;
  StreamSubscription<List<dynamic>>? _jobsSubscription;
  Timer? _walletPollTimer;

  String? _artisanId;
  final TextEditingController _setPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _unlockPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _walletSubscription?.cancel();
    _jobsSubscription?.cancel();
    _walletPollTimer?.cancel();
    _setPinController.dispose();
    _confirmPinController.dispose();
    _unlockPinController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final authProvider = context.read<AuthProvider>();
    final walletSecurity = context.read<WalletSecurityProvider>();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (!authProvider.authenticated) {
      if (mounted) {
        setState(() {
          _artisanId = null;
          _wallet = null;
          _jobs = [];
          _transactions = [];
          _isLoading = false;
          _error = 'Sign in to access your wallet.';
        });
      }
      return;
    }

    final artisanId = await PaymentService.getArtisanIdForCurrentUser(
      email: authProvider.userEmail,
    );

    if (artisanId == null || artisanId.isEmpty) {
      if (mounted) {
        setState(() {
          _artisanId = null;
          _isLoading = false;
          _error =
              'No artisan profile is linked to ${authProvider.userEmail ?? 'this account'}.';
        });
      }
      return;
    }

    _artisanId = artisanId;
    await authProvider.refreshProfile();
    walletSecurity.checkTimeout();

    if (!authProvider.walletPinSet || !walletSecurity.walletUnlocked) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await _loadAllData();
  }

  void _showArtisanLoginDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  Future<void> _loadWalletData() async {
    if (_artisanId == null) return;
    final wallet = await PaymentService.getWallet(_artisanId!);
    if (mounted) setState(() => _wallet = wallet);
  }

  /// Loads wallet + jobs + transactions in parallel, then subscribes to
  /// realtime updates. Call this after login and on pull-to-refresh.
  Future<void> _loadAllData() async {
    if (_artisanId == null) return;
    try {
      final bundle = await PaymentService.getWalletBundle(_artisanId!);
      if (bundle.success) {
        if (mounted) {
          setState(() {
            _wallet = bundle.wallet;
            _jobs = bundle.jobs;
            _transactions = bundle.transactions;
          });
        }
      } else {
        await Future.wait([
          _loadWalletData(),
          _loadJobs(),
          _loadTransactions(),
        ]);
      }

      _subscribeToUpdates();
      _startWalletPoll();
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load wallet: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadJobs() async {
    if (_artisanId == null) return;
    final bundle = await PaymentService.getWalletBundle(_artisanId!);
    if (bundle.success) {
      if (mounted) setState(() => _jobs = bundle.jobs);
      return;
    }

    final jobs = await PaymentService.getJobsForArtisan(_artisanId!);
    if (mounted) setState(() => _jobs = jobs);
  }

  Future<void> _loadTransactions() async {
    if (_artisanId == null) return;
    final bundle = await PaymentService.getWalletBundle(_artisanId!);
    if (bundle.success) {
      if (mounted) setState(() => _transactions = bundle.transactions);
      return;
    }

    final transactions = await PaymentService.getTransactions(_artisanId!);
    if (mounted) setState(() => _transactions = transactions);
  }

  void _subscribeToUpdates() {
    if (_artisanId == null) return;

    // Unsubscribe from any previous subscriptions first
    _walletSubscription?.cancel();
    _jobsSubscription?.cancel();

    _walletSubscription = PaymentService.walletStream(_artisanId!).listen(
      (wallets) {
        if (wallets.isNotEmpty && mounted) {
          final wallet =
              Wallet.fromJson(Map<String, dynamic>.from(wallets.first));
          setState(() => _wallet = wallet);
        }
      },
      onError: (error) {
        debugPrint('WalletPage.walletStream error: $error');
      },
    );

    // Jobs/transactions are refreshed via periodic _loadAllData polling because
    // strict production RLS may block direct client streams for these tables.
  }

  void _startWalletPoll() {
    _walletPollTimer?.cancel();
    _walletPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _artisanId != null) {
        _loadAllData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final walletSecurity = context.read<WalletSecurityProvider>();

    if (state == AppLifecycleState.resumed) {
      walletSecurity.checkTimeout();
      if (mounted && _artisanId != null && walletSecurity.walletUnlocked) {
        _loadAllData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/directory');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeData,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Already on wallet
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(context, '/directory');
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(context, '/services');
                    break;
                  case 3:
                    Navigator.pushReplacementNamed(context, '/jobs');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Directory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.build),
                  label: 'Services',
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
    final authProvider = context.watch<AuthProvider>();
    final walletSecurity = context.watch<WalletSecurityProvider>();
    walletSecurity.checkTimeout();

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (!authProvider.authenticated) {
      return _buildAuthRequiredState();
    }

    if (!authProvider.walletPinSet) {
      return _buildSetWalletPinState(walletSecurity);
    }

    if (!walletSecurity.walletUnlocked) {
      return _buildUnlockWalletState(walletSecurity);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => walletSecurity.recordActivity(),
      onPointerMove: (_) => walletSecurity.recordActivity(),
      child: RefreshIndicator(
        onRefresh: () async {
          walletSecurity.recordActivity();
          await _loadAllData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWalletCard(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              if (_wallet == null || _wallet?.isVerified == false)
                _buildBankDetailsPrompt(),
              _buildPendingJobsSection(),
              const SizedBox(height: 20),
              _buildTransactionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthRequiredState() {
    return _buildWalletGate(
      icon: Icons.lock_outline,
      title: 'Sign in required',
      message:
          'Your Supabase session is not active. Sign in once to keep access across the app and wallet.',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showArtisanLoginDialog,
          icon: const Icon(Icons.login),
          label: const Text('Sign in'),
        ),
      ),
    );
  }

  Widget _buildSetWalletPinState(WalletSecurityProvider walletSecurity) {
    return _buildWalletGate(
      icon: Icons.pin_outlined,
      title: 'Set your wallet PIN',
      message:
          'Create a 4 to 6 digit PIN before opening your wallet. This is required once per account.',
      child: Column(
        children: [
          TextField(
            controller: _setPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'New wallet PIN',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSM),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Confirm wallet PIN',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
          if (walletSecurity.error != null) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              walletSecurity.error!.replaceFirst('Exception: ', ''),
              style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppTheme.spaceLG),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: walletSecurity.busy
                  ? null
                  : () async {
                      try {
                        await walletSecurity.setWalletPin(
                          pin: _setPinController.text,
                          confirmPin: _confirmPinController.text,
                        );
                        _setPinController.clear();
                        _confirmPinController.clear();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wallet PIN set successfully.'),
                          ),
                        );
                        await _initializeData();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
              child: walletSecurity.busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save wallet PIN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockWalletState(WalletSecurityProvider walletSecurity) {
    return _buildWalletGate(
      icon: Icons.lock_clock_outlined,
      title: 'Unlock wallet',
      message:
          'Enter your wallet PIN to continue. For security, the wallet auto-locks after 5 minutes of inactivity.',
      child: Column(
        children: [
          TextField(
            controller: _unlockPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Wallet PIN',
              prefixIcon: Icon(Icons.lock_open_outlined),
            ),
          ),
          if (walletSecurity.lockoutMessage != null) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              walletSecurity.lockoutMessage!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warning),
              textAlign: TextAlign.center,
            ),
          ] else if (walletSecurity.error != null) ...[
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              walletSecurity.error!.replaceFirst('Exception: ', ''),
              style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppTheme.spaceLG),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: walletSecurity.busy
                  ? null
                  : () async {
                      try {
                        await walletSecurity.unlockWallet(
                          _unlockPinController.text,
                        );
                        _unlockPinController.clear();
                        if (!mounted) return;
                        await _initializeData();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
              child: walletSecurity.busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unlock wallet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletGate({
    required IconData icon,
    required String title,
    required String message,
    required Widget child,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: AppTheme.divider),
              boxShadow: AppTheme.shadowSM,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Icon(icon, color: AppTheme.primary, size: 28),
                ),
                const SizedBox(height: AppTheme.spaceBase),
                Text(
                  title,
                  style: AppTheme.headline3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  message,
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceLG),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Updated formatter
  String _formatAmount(num amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  double _asDouble(num? value) => (value ?? 0).toDouble();

  double _higherOf(num a, num b) => a > b ? a.toDouble() : b.toDouble();

  double get _derivedAvailableBalance {
    double total = 0;
    for (final job in _jobs) {
      final status = (job.status ?? '').toLowerCase();
      final material = job.estimateMaterialsCost ?? 0;
      final labor = job.estimateLaborCost ?? 0;
      final hasSplit = material > 0 || labor > 0;

      if (hasSplit) {
        if (status == 'paid' ||
            status == 'pending_completion' ||
            status == 'pending_completion_confirmation') {
          total += material;
        } else if (status == 'completed') {
          total += material + labor;
        }
        continue;
      }

      if ((status == 'arrival_confirmed' ||
              status == 'outcall_confirmed' ||
              status == 'completed') &&
          job.escrowAmount > 0) {
        total += job.escrowAmount.toDouble();
      }
    }
    return total;
  }

  double get _derivedPendingBalance {
    double total = 0;
    for (final job in _jobs) {
      final status = (job.status ?? '').toLowerCase();
      final material = job.estimateMaterialsCost ?? 0;
      final labor = job.estimateLaborCost ?? 0;
      final hasSplit = material > 0 || labor > 0;

      if (hasSplit) {
        if (status == 'paid' ||
            status == 'pending_completion' ||
            status == 'pending_completion_confirmation') {
          total += labor;
        }
        continue;
      }

      if (status == 'paid' && job.escrowAmount > 0) {
        total += job.escrowAmount.toDouble();
      }
    }
    return total;
  }

  double get _derivedTotalEarned =>
      _derivedAvailableBalance + _derivedPendingBalance;

  bool get _shouldUseDerivedBalances {
    final walletAvailable = _asDouble(_wallet?.availableBalance);
    final walletPending = _asDouble(_wallet?.pendingBalance);
    final walletEarned = _asDouble(_wallet?.totalEarned);
    return _derivedTotalEarned > 0 &&
        (walletEarned + 0.01 < _derivedTotalEarned ||
            walletAvailable + walletPending + 0.01 <
                _derivedAvailableBalance + _derivedPendingBalance);
  }

  double get _displayAvailableBalance => _shouldUseDerivedBalances
      ? _higherOf(
          _asDouble(_wallet?.availableBalance), _derivedAvailableBalance)
      : _asDouble(_wallet?.availableBalance);

  double get _displayPendingBalance => _shouldUseDerivedBalances
      ? _higherOf(_asDouble(_wallet?.pendingBalance), _derivedPendingBalance)
      : _asDouble(_wallet?.pendingBalance);

  double get _displayTotalEarned => _shouldUseDerivedBalances
      ? _higherOf(_asDouble(_wallet?.totalEarned), _derivedTotalEarned)
      : _asDouble(_wallet?.totalEarned);

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  // ============ UI BUILDER METHODS ============

  Widget _buildWalletCard() {
    final availableBalance = _displayAvailableBalance;
    final pendingBalance = _displayPendingBalance;
    final totalEarned = _displayTotalEarned;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.shadowLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wallet',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSM,
                  vertical: AppTheme.spaceXXS + 1,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  _wallet?.isVerified == true ? 'Verified' : 'Unverified',
                  style: AppTheme.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Available: ₦${_formatAmount(availableBalance)}',
              style: AppTheme.headline2.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('Pending: ₦${_formatAmount(pendingBalance)}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('Total Earned: ₦${_formatAmount(totalEarned)}',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              // Fund Account Button (Paystack)
              if (_artisanId != null && _wallet != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: PaystackPaymentButton(
                      artisanId: _artisanId!,
                      customerEmail: _wallet!.accountName != null && _wallet!.accountName!.contains('@')
                        ? _wallet!.accountName!
                        : (Supabase.instance.client.auth.currentUser?.email ?? ''),
                      amount: 3000, // Default/test amount, can be parameterized
                      customerName: _wallet!.accountName,
                      customerPhone: null,
                      serviceType: null,
                      description: 'Wallet fund',
                      jobReference: null,
                      address: null,
                      buttonLabel: 'Fund Account',
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Transfer'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: _showTransferDialog,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Withdraw'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _showWithdrawalDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Withdrawn',
            '₦${_formatAmount(_wallet?.totalWithdrawn ?? 0)}',
            Icons.arrow_downward,
            AppTheme.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Jobs',
            '${_jobs.where((j) => j.status == 'paid').length}',
            Icons.pending_actions,
            AppTheme.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTheme.spaceXS),
            Text(title,
                style:
                    AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: AppTheme.spaceXXS + 2),
            Text(value, style: AppTheme.titleSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsPrompt() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXXS),
                Text(
                  'Add bank details to enable withdrawals.',
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showBankVerificationDialog,
            child: const Text('Add now'),
          ),
        ],
      ),
    );
  }

  void _showBankVerificationDialog() {
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    final supportedBanks = <String>[
      'Abbey Mortgage Bank',
      'Access Bank',
      'ALAT by Wema',
      'ASO Savings and Loans',
      'Bowen Microfinance Bank',
      'Carbon',
      'CEMCS Microfinance Bank',
      'Citibank Nigeria',
      'Ecobank Nigeria',
      'Ekondo Microfinance Bank',
      'Eyowo',
      'FairMoney Microfinance Bank',
      'Fidelity Bank',
      'First Bank of Nigeria',
      'First City Monument Bank (FCMB)',
      'Globus Bank',
      'Guaranty Trust Bank',
      'Heritage Bank',
      'Jaiz Bank',
      'Kuda Bank',
      'Keystone Bank',
      'Lotus Bank',
      'Moniepoint Microfinance Bank',
      'OPay',
      'Optimus Bank',
      'PalmPay',
      'Parallex Bank',
      'Polaris Bank',
      'PremiumTrust Bank',
      'Providus Bank',
      'Stanbic IBTC Bank',
      'Standard Chartered Bank',
      'Sterling Bank',
      'SunTrust Bank',
      'TAJ Bank',
      'Titan Trust Bank',
      'Union Bank of Nigeria',
      'United Bank for Africa',
      'Unity Bank',
      'VFD Microfinance Bank',
      'Wema Bank',
      'Zenith Bank',
    ]..sort();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Bank account verification', style: AppTheme.headline3),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your payout details for verification.',
                  style: AppTheme.bodySmall
                      .copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spaceBase),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    hintText: 'Select your bank',
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                  items: supportedBanks
                      .map(
                        (bank) => DropdownMenuItem(
                          value: bank,
                          child: Text(bank, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => bankNameController.text = val ?? '',
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    hintText: '10 digits',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                TextField(
                  controller: accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                if (isLoading) const CircularProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (bankNameController.text.isEmpty ||
                          accountNumberController.text.length != 10 ||
                          accountNameController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please fill all fields correctly. Account number must be 10 digits.')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        // First save bank details
                        final saved = await PaymentService.saveBankDetails(
                          artisanId: _artisanId!,
                          bankName: bankNameController.text,
                          accountNumber: accountNumberController.text,
                          accountName: accountNameController.text,
                        );

                        if (!saved) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to save bank details. Please confirm the bank name, account number, and account name, then try again.',
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                          return;
                        }

                        // Then verify wallet
                        final result =
                            await PaymentService.verifyWallet(_artisanId!);

                        if (result) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Bank account verified successfully!'),
                                backgroundColor: AppTheme.success),
                          );
                          _loadWalletData(); // Refresh wallet data
                        } else {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Verification failed. Please check your bank details and try again.'),
                                backgroundColor: AppTheme.error),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error),
                        );
                      } finally {
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
