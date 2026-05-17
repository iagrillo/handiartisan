import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet.dart';
import '../models/sponsored_item.dart';
import '../../services/payment_service.dart';
import '../ui/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, Wallet> _wallets = {};
  bool _loadingWallets = false;
  List<SponsoredItem> _sponsoredItems = [];
  bool _loadingSponsored = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWallets();
    _loadSponsoredItems();
  }

  Future<void> _loadWallets() async {
    setState(() => _loadingWallets = true);
    try {
      final client = Supabase.instance.client;
      final response = await client.from('wallets').select();

      if (response.isNotEmpty) {
        final Map<String, Wallet> loadedWallets = {};
        for (var w in response) {
          final wallet = Wallet.fromJson(Map<String, dynamic>.from(w));
          loadedWallets[wallet.artisanId] = wallet;
        }
        if (mounted) {
          setState(() {
            _wallets = loadedWallets;
            _loadingWallets = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingWallets = false);
      }
    } catch (e) {
      debugPrint('Error loading wallets: $e');
      if (mounted) setState(() => _loadingWallets = false);
    }
  }

  Future<void> _releaseFunds(String artisanId, String artisanName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Funds'),
        content: Text(
          'Are you sure you want to release pending funds for $artisanName?\n\n'
          'This will move pending balance to available balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Release Funds'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Releasing funds...')),
    );

    final result = await PaymentService.releaseFunds(artisanId: artisanId);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Released ₦${_formatAmount(result.releasedAmount ?? 0)} successfully!',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      await _loadWallets();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to release funds'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  /// ✅ Updated to accept `num` instead of `int`
  String _formatAmount(num amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: AppTheme.titleMedium),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Artisans'),
            Tab(text: 'Stores'),
            Tab(text: 'Sponsored'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArtisansTab(),
          _buildStoresTab(),
          _buildSponsoredTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadWallets,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // ... rest of your artisan and store tab code remains unchanged ...

  Widget _buildArtisansTab() {
    return _loadingWallets
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadWallets,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              itemCount: _wallets.length,
              itemBuilder: (context, index) {
                final artisanId = _wallets.keys.elementAt(index);
                final wallet = _wallets[artisanId]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: Icon(Icons.person, color: AppTheme.primaryDark),
                    ),
                    title: Text('Artisan: ${artisanId.substring(0, 8)}...', style: AppTheme.labelLarge),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pending: ₦${_formatAmount(wallet.pendingBalance)}', style: AppTheme.bodySmall),
                        Text('Available: ₦${_formatAmount(wallet.availableBalance)}', style: AppTheme.bodySmall),
                      ],
                    ),
                    trailing: wallet.pendingBalance > 0
                        ? ElevatedButton(
                            onPressed: () => _releaseFunds(artisanId, 'Artisan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                            ),
                            child: const Text('Release'),
                          )
                        : const Chip(
                            label: Text('No pending'),
                            backgroundColor: AppTheme.textTertiary,
                          ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildStoresTab() {
    return Center(
      child: Text('Store management coming soon', style: AppTheme.bodyLarge),
    );
  }

  Future<void> _loadSponsoredItems() async {
    setState(() => _loadingSponsored = true);
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('sponsored_items')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sponsoredItems = (response as List)
              .map((item) => SponsoredItem.fromJson(item as Map<String, dynamic>))
              .toList();
          _loadingSponsored = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sponsored items: $e');
      if (mounted) setState(() => _loadingSponsored = false);
    }
  }

  Future<void> _addSponsoredItem(SponsoredItem item) async {
    try {
      await Supabase.instance.client
          .from('sponsored_items')
          .insert(item.toJson());
      await _loadSponsoredItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sponsored item added successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSponsoredItem(String itemId) async {
    try {
      await Supabase.instance.client
          .from('sponsored_items')
          .delete()
          .eq('id', itemId);
      await _loadSponsoredItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sponsored item deleted!'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAddSponsoredDialog() {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    final offerCtrl = TextEditingController();
    final ratingCtrl = TextEditingController(text: '4.5');
    final phoneCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController();
    String selectedCategory = 'artisan';
    String selectedIcon = 'business';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Sponsored Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextField(
                controller: subtitleCtrl,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextField(
                controller: offerCtrl,
                decoration: const InputDecoration(labelText: 'Offer'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextField(
                controller: ratingCtrl,
                decoration: const InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TextField(
                controller: whatsappCtrl,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'artisan', child: Text('Artisan')),
                  DropdownMenuItem(value: 'store', child: Text('Store')),
                  DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                ]
                    .map((item) => DropdownMenuItem(
                          value: item.value,
                          child: item.child,
                        ))
                    .toList(),
                onChanged: (value) => selectedCategory = value ?? 'artisan',
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newItem = SponsoredItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleCtrl.text,
                subtitle: subtitleCtrl.text,
                offer: offerCtrl.text,
                rating: double.tryParse(ratingCtrl.text) ?? 4.5,
                phone: phoneCtrl.text,
                whatsapp: whatsappCtrl.text,
                iconName: selectedIcon,
                category: selectedCategory,
                createdAt: DateTime.now(),
              );
              _addSponsoredItem(newItem);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredTab() {
    return _loadingSponsored
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadSponsoredItems,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceBase),
                  child: ElevatedButton.icon(
                    onPressed: _showAddSponsoredDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Sponsored Item'),
                  ),
                ),
                Expanded(
                  child: _sponsoredItems.isEmpty
                      ? Center(
                          child: Text(
                            'No sponsored items yet',
                            style: AppTheme.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.spaceBase),
                          itemCount: _sponsoredItems.length,
                          itemBuilder: (context, index) {
                            final item = _sponsoredItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.star,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                title: Text(item.title, style: AppTheme.labelLarge),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.subtitle,
                                        style: AppTheme.bodySmall),
                                    Text(item.category.toUpperCase(),
                                        style: AppTheme.caption),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppTheme.error),
                                  onPressed: () =>
                                      _deleteSponsoredItem(item.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
  }
}
