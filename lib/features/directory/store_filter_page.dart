import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/artisan_service.dart';
import 'store_provider.dart';
import 'widgets/store_card.dart';
import 'edit_artisan_profile_page.dart';
import 'register_type_page.dart';
import 'store_details_page.dart';
import '../models/artisan.dart';
import '../models/sponsored_item.dart';
import '../utils/supabase.dart';
import '../ui/app_theme.dart';
import '../auth/password_recovery_flow.dart';

class StoreFilterPage extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const StoreFilterPage({
    Key? key,
    this.showAppBar = true,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<StoreFilterPage> createState() => _StoreFilterPageState();
}

class _StoreFilterPageState extends State<StoreFilterPage>
    with SingleTickerProviderStateMixin {
  final ArtisanService _artisanService = ArtisanService();
  bool _isAdmin = false;

  List<String> _states = [];
  List<String> _cities = [];
  String _selectedState = '';
  String _selectedCity = '';

  int _currentIndex = 1;
  late AnimationController _animationController;
  String _activeTab = 'Stores';

  static const Color _storeBackground = Color(0xFFF3F4F6);

  List<SponsoredItem> _sponsoredStoreItems = [];

  final double _filterHeight = 40;
  final TextStyle _filterTextStyle = AppTheme.labelMedium.copyWith(
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w400,
  );

  Future<void> _showAdminLogin(BuildContext context) async {
    if (_isAdmin) {
      // Already admin, logout
      setState(() => _isAdmin = false);
      return;
    }

    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  PasswordRecoveryFlow.show(this.context);
                },
                child: const Text('Forgot Password?'),
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
            onPressed: () {
              const adminPassword =
                  String.fromEnvironment('ADMIN_PASSWORD', defaultValue: '');
              if (passwordController.text.trim() == adminPassword &&
                  adminPassword.isNotEmpty) {
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _isAdmin = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Admin logged in!'),
                        backgroundColor: AppTheme.success),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid password'),
                        backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStore(String storeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Store?'),
        content: const Text(
            'This will permanently delete this store and all its products, reviews, and complaints.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await SupabaseUtils.client
            .from('stores')
            .delete()
            .eq('id', storeId)
            .select();

        if (response.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to delete store - record not found'),
                  backgroundColor: AppTheme.error),
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Store deleted!'),
                backgroundColor: AppTheme.error),
          );
          // Trigger refresh by updating state
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animationController.forward();
    _loadStates();
    _loadSponsoredItems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSponsoredItems() async {
    try {
      final response = await Supabase.instance.client
          .from('sponsored_items')
          .select()
          .eq('category', 'store')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sponsoredStoreItems = (response as List)
              .map((item) => SponsoredItem.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading sponsored items: $e');
    }
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'business': Icons.business,
      'build_circle_outlined': Icons.build_circle_outlined,
      'handyman_outlined': Icons.handyman_outlined,
      'carpenter_outlined': Icons.carpenter_outlined,
      'format_paint_outlined': Icons.format_paint_outlined,
      'plumbing_outlined': Icons.plumbing_outlined,
      'electrical_services': Icons.electrical_services,
      'ac_unit': Icons.ac_unit,
      'construction': Icons.construction,
      'precision_manufacturing_outlined': Icons.precision_manufacturing_outlined,
      'storefront_outlined': Icons.storefront_outlined,
      'inventory_2_outlined': Icons.inventory_2_outlined,
    };
    return iconMap[iconName] ?? Icons.business;
  }

  Future<void> _loadStates() async {
    final states = await _artisanService.fetchStates();
    states.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;
    setState(() => _states = states);
  }

  Future<void> _refreshData() async {
    final provider = context.read<StoreProvider>();
    await provider.fetchStores();
  }

  Future<void> _loadCities(String state) async {
    final cities = await _artisanService.fetchCities(state);
    cities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (!mounted) return;
    setState(() => _cities = cities);
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _filterTextStyle,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
          vertical: AppTheme.spaceSM, horizontal: AppTheme.spaceSM + 2),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
    );
  }

  Widget _box(Widget child) => SizedBox(height: _filterHeight, child: child);

  bool _isSupplyStore(Map<String, dynamic> store) {
    final category = (store['category'] ?? '').toString().toLowerCase();
    final type = (store['type'] ?? '').toString().toLowerCase();
    return category.contains('supply') || type.contains('supply');
  }

  String _storeName(Map<String, dynamic> store) {
    return (store['store_name'] ?? store['name'] ?? 'Unnamed Store').toString();
  }

  String _subtitle(Map<String, dynamic> store) {
    final description = (store['description'] ?? '').toString().trim();
    if (description.isNotEmpty) return description;
    return (store['category'] ?? 'Store & supplies').toString();
  }

  List<Map<String, dynamic>> _tabFilteredStores(
      List<Map<String, dynamic>> stores) {
    return stores.where((store) {
      final isSupply = _isSupplyStore(store);
      if (_activeTab == 'Supply') return isSupply;
      return !isSupply;
    }).toList();
  }

  Widget _buildTabButton(String label) {
    final selected = _activeTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = label),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.inputFill,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.labelLarge.copyWith(
              color: selected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsapp(String phoneNumber) async {
    var phone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!phone.startsWith('234') && phone.startsWith('0')) {
      phone = '234${phone.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$phone?text=Hello');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildSponsoredStripSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sponsored',
          style: AppTheme.caption.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXXS),
        Row(
          children: [
            Text('Sponsored Services Near You', style: AppTheme.titleSmall),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        SizedBox(
          height: 308,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sponsoredStoreItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSM),
            itemBuilder: (context, index) {
              final item = _sponsoredStoreItems[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.44,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(color: AppTheme.divider),
                  boxShadow: AppTheme.shadowSM,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                        alignment: Alignment.center,
                        child: Icon(_getIconData(item.iconName), color: AppTheme.primary),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titleSmall),
                      Text(item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption),
                      const SizedBox(height: AppTheme.spaceXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceSM, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          item.offer,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppTheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _launchCall(item.phone),
                          child: const Text('Call'),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXXS),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _launchWhatsapp(item.whatsapp),
                          child: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSponsoredBanner() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.14),
            AppTheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sponsored', style: AppTheme.caption),
          const SizedBox(height: AppTheme.spaceXXS),
          Text('Elite Coatings Ltd.', style: AppTheme.titleSmall),
          const SizedBox(height: AppTheme.spaceXXS),
          Text('Premium paints, coatings and finishing supplies',
              style: AppTheme.bodySmall),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _launchCall('08032000001'),
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Call'),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              ElevatedButton.icon(
                onPressed: () => _launchWhatsapp('08032000001'),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('WhatsApp'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddStoreSupply() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterTypePage()),
    );
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/directory');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/equipment');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/wallet');
        break;
      case 4:
        showDialog(
          context: context,
          builder: (context) {
            final phoneController = TextEditingController();
            final emailController = TextEditingController();

            return AlertDialog(
              title: const Text('Security Check'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
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
                    final phone = phoneController.text.trim();
                    final email = emailController.text.trim();
                    if (phone.isEmpty || email.isEmpty) return;

                    final response = await SupabaseUtils.client
                        .from('artisans')
                        .select()
                        .eq('phone', phone)
                        .eq('email', email)
                        .limit(1)
                        .maybeSingle();

                    if (!mounted) return;

                    if (response != null) {
                      final artisan = Artisan.fromJson(response);
                      Navigator.pop(context);
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditArtisanProfilePage(
                            artisan: artisan,
                            email: email,
                            phone: phone,
                          ),
                        ),
                      );
                      if (result == true) {
                        await _refreshData();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('No profile found with that phone/email.'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoreProvider(),
      child: Scaffold(
        backgroundColor: _storeBackground,
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('Store/Supply Directory'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    tooltip: 'Admin',
                    onPressed: () => _showAdminLogin(context),
                  ),
                ],
              )
            : null,
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceSM),
            child: Column(
              children: [
                Consumer<StoreProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      children: [
                        // Search on top
                        _box(
                          TextField(
                            style: _filterTextStyle,
                            decoration: _decoration('Search'),
                            onChanged: provider.setSearch,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSM),

                        // State + City below search
                        Row(
                          children: [
                            Expanded(
                              child: _box(
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedState.isEmpty
                                      ? null
                                      : _selectedState,
                                  style: _filterTextStyle,
                                  isExpanded: true,
                                  decoration: _decoration('State'),
                                  items: _states
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) async {
                                    setState(() {
                                      _selectedState = val ?? '';
                                      _selectedCity = '';
                                      _cities = [];
                                    });
                                    provider.setState(_selectedState);
                                    if (_selectedState.isNotEmpty) {
                                      await _loadCities(_selectedState);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSM),
                            Expanded(
                              child: _box(
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedCity.isEmpty
                                      ? null
                                      : _selectedCity,
                                  style: _filterTextStyle,
                                  isExpanded: true,
                                  decoration: _decoration('City'),
                                  items: _cities
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedCity = val ?? '');
                                    provider.setCity(_selectedCity);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spaceMD),
                Expanded(
                  child: Consumer<StoreProvider>(
                    builder: (context, provider, _) {
                      if (provider.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (provider.stores.isEmpty) {
                        return Center(
                            child: Text('No stores found.',
                                style: AppTheme.bodyMedium));
                      }
                      final filteredStores =
                          _tabFilteredStores(provider.stores);
                      final featuredFiltered =
                          _tabFilteredStores(provider.featuredStores);

                      return ListView(
                        children: [
                          Row(
                            children: [
                              _buildTabButton('Stores'),
                              const SizedBox(width: AppTheme.spaceMD),
                              _buildTabButton('Supply'),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          _buildSponsoredStripSection(),
                          const SizedBox(height: AppTheme.spaceMD),
                          Text(
                            'Featured Stores (Sponsored)',
                            style: AppTheme.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceSM),
                          if (featuredFiltered.isEmpty)
                            const SizedBox.shrink()
                          else
                            ...featuredFiltered.take(3).map((store) {
                              final status =
                                  (store['status_text'] ?? store['open_status'] ?? 'Open')
                                      .toString();
                              final rating = (store['rating'] is num)
                                  ? (store['rating'] as num).toDouble()
                                  : 4.5;
                              return StoreCard(
                                logoUrl: (store['logo_url'] ?? '').toString(),
                                storeName: _storeName(store),
                                subtitle: _subtitle(store),
                                city: (store['city'] ?? '').toString(),
                                state: (store['state'] ?? '').toString(),
                                statusLabel: status.isEmpty ? 'Open' : status,
                                isOpen: status.toLowerCase() == 'open',
                                rating: rating,
                                phone: (store['phone'] ?? '').toString(),
                                whatsapp: (store['whatsapp'] ?? '').toString(),
                                onWhatsapp: () {},
                                onViewStore: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoreDetailsPage(store: store),
                                    ),
                                  );
                                },
                              );
                            }),
                          const SizedBox(height: AppTheme.spaceSM),
                          _buildSponsoredBanner(),
                          const SizedBox(height: AppTheme.spaceMD),
                          Text(
                            'All stores',
                            style: AppTheme.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXS + 2),
                          if (filteredStores.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spaceMD),
                              child: Center(
                                  child: Text('No stores found for this tab.',
                                      style: AppTheme.bodyMedium)),
                            )
                          else
                            ...List.generate(filteredStores.length, (index) {
                              final store = filteredStores[index];
                              final status = (store['status_text'] ??
                                      store['open_status'] ??
                                      'Open')
                                  .toString();
                              final rating = (store['rating'] is num)
                                  ? (store['rating'] as num).toDouble()
                                  : 4.5;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Stack(
                                  children: [
                                    StoreCard(
                                      logoUrl:
                                          (store['logo_url'] ?? '').toString(),
                                      storeName: _storeName(store),
                                      subtitle: _subtitle(store),
                                      city: (store['city'] ?? '').toString(),
                                      state: (store['state'] ?? '').toString(),
                                      statusLabel:
                                          status.isEmpty ? 'Open' : status,
                                      isOpen: status.toLowerCase() == 'open',
                                      rating: rating,
                                      phone: (store['phone'] ?? '').toString(),
                                      whatsapp:
                                          (store['whatsapp'] ?? '').toString(),
                                      onWhatsapp: () {},
                                      onViewStore: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                StoreDetailsPage(store: store),
                                          ),
                                        );
                                      },
                                    ),
                                    if (_isAdmin)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (store['is_featured'] ==
                                                        true)
                                                    ? AppTheme.warning
                                                    : AppTheme.inputFill,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radiusMD),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    (store['is_featured'] ==
                                                            true)
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color:
                                                        (store['is_featured'] ==
                                                                true)
                                                            ? Colors.white
                                                            : AppTheme
                                                                .textTertiary,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final newValue = !(store[
                                                              'is_featured'] ==
                                                          true);
                                                      final success =
                                                          await context
                                                              .read<
                                                                  StoreProvider>()
                                                              .updateStore(
                                                        store['id'],
                                                        {
                                                          'is_featured':
                                                              newValue
                                                        },
                                                      );
                                                      setState(() {});
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(success
                                                                ? (newValue
                                                                    ? 'Store is now popular!'
                                                                    : 'Store removed from popular')
                                                                : 'Failed to update store'),
                                                            backgroundColor:
                                                                success
                                                                    ? AppTheme
                                                                        .success
                                                                    : AppTheme
                                                                        .error,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Text(
                                                      'Popular',
                                                      style: AppTheme.labelSmall
                                                          .copyWith(
                                                        color: (store[
                                                                    'is_featured'] ==
                                                                true)
                                                            ? Colors.white
                                                            : AppTheme
                                                                .textTertiary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: AppTheme.error,
                                                  size: 28),
                                              onPressed: () =>
                                                  _deleteStore(store['id']),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddStoreSupply,
          tooltip: 'Add Store/Supply',
          child: const Icon(Icons.add_business),
        ),
        bottomNavigationBar: widget.showBottomNav
            ? FadeTransition(
                opacity: _animationController,
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onNavTap,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppTheme.primary,
                  unselectedItemColor: AppTheme.textTertiary,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: 'Directory',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.store),
                      label: 'Store/Supply',
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
                      icon: Icon(Icons.edit),
                      label: 'Profile',
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

