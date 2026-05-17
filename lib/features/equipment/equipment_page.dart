import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:handihub_artisan_app/services/artisan_service.dart';
import 'package:handihub_artisan_app/features/utils/supabase.dart';
import 'package:handihub_artisan_app/features/models/sponsored_item.dart';

import '../ui/app_theme.dart';
import '../auth/password_recovery_flow.dart';
import 'equipment_details_page.dart';
import 'equipment_service.dart';
import 'gold_concrete_pump_info_page.dart';
import 'gold_cslm_info_page.dart';
import 'gold_equipment_info_page.dart';
import 'gold_large_infra_info_page.dart';
import 'gold_mobile_batching_plant_info_page.dart';
import 'gold_paver_machine_info_page.dart';
import 'gold_rmc_info_page.dart';
import 'gold_tora_batching_plant_info_page.dart';
import 'post_equipment_form_page.dart';
import 'widgets/equipment_sales_card.dart';
import 'widgets/featured_equipment_carousel.dart';
import 'widgets/gold_concrete_pump_card.dart';
import 'widgets/gold_cslm_card.dart';
import 'widgets/gold_equipment_card.dart';
import 'widgets/gold_large_infra_card.dart';
import 'widgets/gold_mobile_batching_plant_card.dart';
import 'widgets/gold_paver_machine_card.dart';
import 'widgets/gold_rmc_card.dart';
import 'widgets/gold_tora_batching_plant_card.dart';

class EquipmentPage extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const EquipmentPage({
    Key? key,
    this.showAppBar = true,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage>
    with TickerProviderStateMixin {
  final List<String> _featuredEquipmentImages = const [
    'assets/equipment1.png',
    'assets/equipment2.png',
    'assets/equipment3.png',
    'assets/equipment4.png',
    'assets/equipment5.png',
    'assets/equipment6.png',
    'assets/equipment7.png',
    'assets/equipment8.png',
    'assets/equipment9.png',
    'assets/equipment10.png',
    'assets/equipment11.png',
    'assets/equipment12.png',
  ];

  final EquipmentService _equipmentService = EquipmentService();
  final ArtisanService _artisanService = ArtisanService();

  late TabController _tabController;
  final List<String> _tabs = ['All', 'Sales', 'Rental', 'Services', 'Parts'];

  List<String> _states = [];
  List<String> _cities = [];
  List<Map<String, dynamic>> _equipmentList = [];

  String _state = '';
  String _city = '';
  String _search = '';
  String _selectedLocation = 'All Locations';
  String _selectedTab = 'All';

  bool _loading = false;
  String? _error;
  bool _isAdmin = false;

  static const Color _supplyBackground = Color(0xFFF3F4F6);

  List<SponsoredItem> _sponsoredSupplyItems = [];

  // Gold cards carousel
  int _goldCardPageIndex = 0;
  Timer? _goldCardTimer;
  late PageController _goldCardPageController;

  int get _goldCardTotalPages => _goldCards(context).length;

  // List of gold card widgets - using a function to have access to context
  List<Widget> _goldCards(BuildContext context) => [
        GoldMobileBatchingPlantCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const GoldMobileBatchingPlantInfoPage()),
          ),
        ),
        GoldCSLMCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoldCSLMInfoPage()),
          ),
        ),
        GoldRMCCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoldRMCInfoPage()),
          ),
        ),
        GoldLargeInfraCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoldLargeInfraInfoPage()),
          ),
        ),
        GoldPaverMachineCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoldPaverMachineInfoPage()),
          ),
        ),
        GoldConcretePumpCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoldConcretePumpInfoPage()),
          ),
        ),
        GoldToraBatchingPlantCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const GoldToraBatchingPlantInfoPage()),
          ),
        ),
        GoldEquipmentCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoldEquipmentInfoPage()),
          ),
        ),
      ];

  Future<void> _refreshData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _fetchStates(),
        _fetchEquipment(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _goldCardPageController = PageController(initialPage: _goldCardPageIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabs[_tabController.index]);
        _fetchEquipment();
      }
    });
    _fetchStates();
    _fetchEquipment();
    _loadSponsoredItems();

    // Start gold cards carousel timer (10 seconds)
    _goldCardTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _goldCardPageController.hasClients) {
        final int nextPage = (_goldCardPageIndex + 1) % _goldCardTotalPages;
        _goldCardPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _goldCardPageIndex = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _goldCardTimer?.cancel();
    _goldCardPageController.dispose();
    super.dispose();
  }

  Future<void> _loadSponsoredItems() async {
    try {
      final response = await Supabase.instance.client
          .from('sponsored_items')
          .select()
          .eq('category', 'equipment')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sponsoredSupplyItems = (response as List)
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

  Future<void> _fetchStates() async {
    try {
      final states = await _artisanService.fetchStates();
      states.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (!mounted) return;
      setState(() => _states = states);
    } catch (_) {}
  }

  Future<void> _fetchCities(String state) async {
    try {
      final cities = await _artisanService.fetchCities(state);
      cities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (!mounted) return;
      setState(() => _cities = cities);
    } catch (_) {}
  }

  Future<void> _fetchEquipment() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _equipmentService.fetchEquipment(
        tab: _selectedTab,
        search: _search,
        location: _city.isNotEmpty
            ? _city
            : (_state.isNotEmpty
                ? _state
                : (_selectedLocation == 'All Locations'
                    ? null
                    : _selectedLocation)),
      );

      if (!mounted) return;
      setState(() => _equipmentList = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openPostEquipmentForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostEquipmentFormPage()),
    );
    // Refresh equipment list after returning from form
    _fetchEquipment();
  }

  void _onBottomNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/directory');
      return;
    }
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/stores');
      return;
    }
    if (index == 2) return;
    if (index == 3) {
      Navigator.pushReplacementNamed(context, '/wallet');
      return;
    }
    if (index == 4) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  Future<void> _showAdminLogin(BuildContext context) async {
    debugPrint('ShowAdminLogin called, current _isAdmin: $_isAdmin');

    if (_isAdmin) {
      setState(() => _isAdmin = false);
      debugPrint('Admin logged out');
      return;
    }

    // Show password dialog
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin login', style: AppTheme.headline3),
            const SizedBox(height: AppTheme.spaceXXS),
            Text(
              'Enter the admin password to manage equipment listings.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spaceXS),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              controller: passwordController,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  PasswordRecoveryFlow.show(context);
                },
                child: const Text('Forgot Password?'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, passwordController.text);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );

    debugPrint('Password entered: $password');

    if (password != null) {
      const adminPassword =
          String.fromEnvironment('ADMIN_PASSWORD', defaultValue: '');
      if (password.trim() == adminPassword && adminPassword.isNotEmpty) {
        setState(() {
          _isAdmin = true;
        });
        debugPrint('Admin logged in successfully, _isAdmin now: $_isAdmin');

        // Force rebuild
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Admin logged in!'),
                backgroundColor: AppTheme.success),
          );
        }
      } else if (password.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Invalid password'),
                backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  Future<void> _deleteEquipment(String equipmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppTheme.error),
            const SizedBox(width: AppTheme.spaceSM),
            Text('Delete equipment?', style: AppTheme.headline3),
          ],
        ),
        content: Text(
          'This will permanently delete this equipment listing.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
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
            .from('equipment')
            .delete()
            .eq('id', equipmentId)
            .select();
        if (response.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to delete equipment'),
                  backgroundColor: AppTheme.error),
            );
          }
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Equipment deleted!'),
                backgroundColor: AppTheme.error),
          );
          _fetchEquipment();
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

  Widget _buildSponsoredSupplyStrip() {
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
        Text('Sponsored Services Near You', style: AppTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceSM),
        SizedBox(
          height: 308,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sponsoredSupplyItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSM),
            itemBuilder: (context, index) {
              final item = _sponsoredSupplyItems[index];
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
                      Text(item.subtitle, style: AppTheme.caption),
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
          Text('Top coating, paint and equipment supply partner',
              style: AppTheme.bodySmall),
          const SizedBox(height: AppTheme.spaceSM),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _launchCall('08033009999'),
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Call'),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              ElevatedButton.icon(
                onPressed: () => _launchWhatsapp('08033009999'),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('WhatsApp'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _supplyBackground,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Equipment Directory'),
              actions: [
                if (_isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('ADMIN',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  icon: const Icon(Icons.app_registration),
                  tooltip: 'Register / Submit',
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
                IconButton(
                  icon: Icon(
                      _isAdmin ? Icons.admin_panel_settings : Icons.shield),
                  tooltip: _isAdmin ? 'Admin (Tap to logout)' : 'Admin Login',
                  onPressed: () => _showAdminLogin(context),
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceSM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 36,
                child: TextField(
                  style: AppTheme.caption.copyWith(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search Equipment',
                    hintStyle:
                        AppTheme.caption.copyWith(color: AppTheme.textPrimary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: AppTheme.spaceSM),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _search = val);
                    _fetchEquipment();
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _state.isEmpty ? null : _state,
                      decoration: InputDecoration(
                        hintText: 'State',
                        hintStyle: AppTheme.caption
                            .copyWith(color: AppTheme.textPrimary),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceSM,
                          vertical: 6,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                      ),
                      style: AppTheme.caption
                          .copyWith(color: AppTheme.textPrimary),
                      items: _states
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) async {
                        setState(() {
                          _state = val ?? '';
                          _city = '';
                          _cities = [];
                        });
                        if (_state.isNotEmpty) await _fetchCities(_state);
                        _fetchEquipment();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _city.isEmpty ? null : _city,
                      decoration: InputDecoration(
                        hintText: 'City',
                        hintStyle: AppTheme.caption
                            .copyWith(color: AppTheme.textPrimary),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceSM,
                          vertical: 6,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                      ),
                      style: AppTheme.caption
                          .copyWith(color: AppTheme.textPrimary),
                      items: _cities
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => _city = val ?? '');
                        _fetchEquipment();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSM),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
                tabs: _tabs
                    .map((tab) => Tab(
                          child: Text(tab,
                              style:
                                  AppTheme.labelSmall.copyWith(fontSize: 10)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              _buildSponsoredSupplyStrip(),
              const SizedBox(height: AppTheme.spaceMD),
              Text(
                'Featured Supply Providers (Sponsored)',
                style: AppTheme.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              FeaturedEquipmentCarousel(images: _featuredEquipmentImages),
              const SizedBox(height: AppTheme.spaceSM),
              _buildSponsoredBanner(),
              const SizedBox(height: AppTheme.spaceSM),
              SizedBox(
                height: 90,
                child: PageView.builder(
                  controller: _goldCardPageController,
                  onPageChanged: (index) {
                    setState(() {
                      _goldCardPageIndex = index;
                    });
                  },
                  itemCount: _goldCardTotalPages,
                  itemBuilder: (context, pageIndex) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceBase),
                      child: _buildGoldCardWithNavigation(
                        pageIndex,
                        _goldCards(context)[pageIndex],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spaceMD),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(child: Text('Error: $_error'))
              else if (_equipmentList.isEmpty)
                const Center(child: Text('No equipment available.'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _equipmentList.length,
                  itemBuilder: (context, index) {
                    final eq = _equipmentList[index];
                    debugPrint('Equipment item $index: isAdmin=$_isAdmin');
                    return Stack(
                      children: [
                        EquipmentSalesCard(
                          imageUrl: eq['image_url'] ?? '',
                          title:
                              '${eq['name'] ?? ''}${eq['brand'] != null && (eq['brand'] as String).isNotEmpty ? ' - ${eq['brand']}' : ''}'
                                  .trim(),
                          price: eq['price'] ?? '',
                          condition: eq['type'] ?? eq['condition'] ?? '',
                          location: '${eq['city'] ?? ''}, ${eq['state'] ?? ''}'
                              .trim(),
                          rating: (eq['rating'] ?? 0).toDouble(),
                          seller: eq['contact_name'] ?? eq['seller'] ?? '',
                          equipment: eq,
                          onViewDetails: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EquipmentDetailsPage(equipment: eq),
                              ),
                            );
                          },
                        ),
                        if (_isAdmin)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              color: AppTheme.error,
                              padding: const EdgeInsets.all(4),
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white, size: 20),
                                onPressed: () => _deleteEquipment(eq['id']),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostEquipmentForm,
        tooltip: 'Add Equipment',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 2,
              onTap: _onBottomNavTap,
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
            )
          : null,
    );
  }

  // Build gold card with navigation based on index
  Widget _buildGoldCardWithNavigation(int index, Widget card) {
    return ClipRect(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              // Navigate based on card index
              switch (index) {
                case 0:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoldMobileBatchingPlantInfoPage(),
                    ),
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoldCSLMInfoPage()),
                  );
                  break;
                case 2:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GoldRMCInfoPage()),
                  );
                  break;
                case 3:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoldLargeInfraInfoPage(),
                    ),
                  );
                  break;
                case 4:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoldPaverMachineInfoPage(),
                    ),
                  );
                  break;
                case 5:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoldConcretePumpInfoPage(),
                    ),
                  );
                  break;
                case 6:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoldToraBatchingPlantInfoPage(),
                    ),
                  );
                  break;
                case 7:
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoldEquipmentInfoPage(),
                    ),
                  );
                  break;
              }
            },
            child: card,
          ),
          Positioned(
            top: 4,
            right: 8,
            child: Text(
              'Sale',
              style:
                  AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

