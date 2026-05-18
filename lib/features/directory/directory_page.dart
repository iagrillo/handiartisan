import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/artisan.dart';
import '../models/category.dart';
import '../models/sponsored_item.dart';
import '../../services/artisan_service.dart';
import '../../services/location_service.dart';
import 'widgets/artisan_card.dart';
import 'edit_artisan_profile_page.dart';
import '../utils/supabase.dart';
import '../equipment/equipment_page.dart';
import '../wallet/wallet_page.dart';
import '../jobs/jobs_page.dart';
import '../ui/app_theme.dart';
import '../auth/password_recovery_flow.dart';
import 'package:provider/provider.dart';
import '../utils/location_helper.dart';
import 'artisan_provider.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({Key? key}) : super(key: key);

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage>
    with SingleTickerProviderStateMixin {
  final ArtisanService _artisanService = ArtisanService();
  final LocationService _locationService = LocationService();

  List<Artisan> _artisans = [];
  List<Category> _categories = [];
  List<String> _states = [];
  List<String> _cities = [];

  bool _loading = true;
  String _search = '';
  String _category = '';
  String _state = '';
  String _city = '';

  // Location related state
  bool _locationEnabled = false;
  double? _userLatitude;
  double? _userLongitude;

  int _currentIndex = 0;

  bool isAdmin = false; // set to true after admin login
  bool isLoggedIn = true;

  late AnimationController _animationController;

  static const Color _directoryBackground = Color(0xFFF3F4F6);

  List<SponsoredItem> _sponsoredServiceItems = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animationController.forward();
    _loadInitialData();
    _loadSponsoredItems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Artisan> _sortSponsored(List<Artisan> items) {
    final sorted = List<Artisan>.from(items);
    sorted.sort((a, b) {
      final priorityCompare = b.priorityScore.compareTo(a.priorityScore);
      if (priorityCompare != 0) return priorityCompare;
      return (b.rating ?? 0).compareTo(a.rating ?? 0);
    });
    return sorted;
  }

  Future<void> _launchCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _normalizeWhatsapp(String phoneNumber) {
    var phone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!phone.startsWith('234')) {
      if (phone.startsWith('0')) {
        phone = '234${phone.substring(1)}';
      } else if (phone.length == 10) {
        phone = '234$phone';
      }
    }
    return phone;
  }

  Future<void> _launchWhatsapp(String whatsappNumber) async {
    final normalized = _normalizeWhatsapp(whatsappNumber);
    final url = Uri.parse('https://wa.me/$normalized?text=Hello');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  List<Artisan> _fallbackArtisans() {
    return [
      Artisan(
        fullName: 'Tolex Paint',
        businessName: 'Tolex Paint',
        phone: '08020000001',
        whatsapp: '08020000001',
        category: 'Painting',
        city: 'Lagos',
        state: 'Lagos',
        rating: 4.6,
      ),
      Artisan(
        fullName: 'Wills Carpenter',
        businessName: 'Wills Carpenter',
        phone: '08020000002',
        whatsapp: '08020000002',
        category: 'Carpentry',
        city: 'Abuja',
        state: 'FCT',
        rating: 4.7,
      ),
      Artisan(
        fullName: 'Ace Paint Experts',
        businessName: 'Ace Paint Experts',
        phone: '08020000003',
        whatsapp: '08020000003',
        category: 'Painting',
        city: 'Port Harcourt',
        state: 'Rivers',
        rating: 4.5,
      ),
      Artisan(
        fullName: 'Precision Tiling',
        businessName: 'Precision Tiling',
        phone: '08020000004',
        whatsapp: '08020000004',
        category: 'Tiling',
        city: 'Ibadan',
        state: 'Oyo',
        rating: 4.8,
      ),
    ];
  }

  Widget _buildSponsoredServicesSection() {
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
            TextButton(
              onPressed: () {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Showing sponsored services in this area'),
                    backgroundColor: AppTheme.info,
                  ),
                );
              },
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSM),
        SizedBox(
          height: 308,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _sponsoredServiceItems.length,
            itemBuilder: (context, index) {
              final service = _sponsoredServiceItems[index];

              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spaceSM),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.44,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(color: AppTheme.divider),
                    boxShadow: AppTheme.shadowSM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusLG),
                        ),
                        child: Container(
                          height: 88,
                          width: double.infinity,
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          child: Icon(_getIconData(service.iconName), color: AppTheme.primary),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceSM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              style: AppTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spaceXXS),
                            Text(
                              service.subtitle,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spaceXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceSM,
                                vertical: AppTheme.spaceXXS + 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                service.offer,
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXS),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  service.rating.toStringAsFixed(1),
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
                                onPressed: () => _launchCall(service.phone),
                                child: const Text('Call'),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXXS),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _launchWhatsapp(service.whatsapp),
                                child: const Text('WhatsApp'),
                              ),
                            ),
                          ],
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

  Widget _buildFeaturedSponsoredSection(List<Artisan> featuredArtisans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Featured Artisans (Sponsored)', style: AppTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceSM),
        ...featuredArtisans.take(4).map(
          (artisan) {
            final locationLabel = [
              if (artisan.city?.isNotEmpty == true) artisan.city,
              if (artisan.state?.isNotEmpty == true) artisan.state,
            ].whereType<String>().join(', ');

            return Container(
              margin: const EdgeInsets.only(bottom: AppTheme.spaceSM),
              padding: const EdgeInsets.all(AppTheme.spaceBase),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                border: Border.all(color: AppTheme.divider),
                boxShadow: AppTheme.shadowSM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          artisan.businessName?.isNotEmpty == true
                              ? artisan.businessName!
                              : artisan.fullName,
                          style: AppTheme.titleSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceSM,
                          vertical: AppTheme.spaceXXS + 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          'Sponsored',
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXXS),
                  Text(artisan.category, style: AppTheme.bodySmall),
                  if (locationLabel.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceXXS),
                    Text(locationLabel, style: AppTheme.caption),
                  ],
                  const SizedBox(height: AppTheme.spaceXS),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (artisan.rating ?? 4.5).toStringAsFixed(1),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: artisan.phone.isNotEmpty
                              ? () => _launchCall(artisan.phone)
                              : null,
                          icon: const Icon(Icons.phone_outlined, size: 16),
                          label: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: artisan.whatsapp?.isNotEmpty == true
                              ? () => _launchWhatsapp(artisan.whatsapp!)
                              : null,
                          icon:
                              const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEliteCoatingsBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.16),
            AppTheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.16)),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              child: Container(
                width: 86,
                height: 86,
                color: AppTheme.primary.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.format_paint_outlined,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceBase),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sponsored', style: AppTheme.caption),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Elite Coatings Ltd.',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spaceXXS),
                  Text('Lagos, Nigeria', style: AppTheme.caption),
                  const SizedBox(height: AppTheme.spaceSM),
                  Wrap(
                    spacing: AppTheme.spaceXS,
                    children: [
                      _AdTag(label: 'Top Rated'),
                      _AdTag(label: 'Fast Service'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  Wrap(
                    spacing: AppTheme.spaceSM,
                    runSpacing: AppTheme.spaceXS,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _launchCall('08030009999'),
                        icon: const Icon(Icons.phone_outlined, size: 16),
                        label: const Text('Call'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _launchWhatsapp('08030009999'),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('WhatsApp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadInitialData() async {
    final categories = await _artisanService.fetchCategories();
    final states = await _artisanService.fetchStates();

    states.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _categories = categories;
      _states = states;
    });

    await _fetchArtisans();
  }

  Future<void> _fetchArtisans() async {
    setState(() => _loading = true);

    final data = await _artisanService.fetchArtisans(
      search: _search,
      category: _category.isEmpty ? null : _category,
      state: _state.isEmpty ? null : _state,
      city: _city.isEmpty ? null : _city,
    );

    if (!mounted) return;

    setState(() {
      _artisans = data;
      // Sort by distance if location is enabled
      if (_locationEnabled && _userLatitude != null && _userLongitude != null) {
        _artisans.sort((a, b) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;
          final distA = _locationService.calculateDistance(
            _userLatitude!,
            _userLongitude!,
            a.latitude!,
            a.longitude!,
          );
          final distB = _locationService.calculateDistance(
            _userLatitude!,
            _userLongitude!,
            b.latitude!,
            b.longitude!,
          );
          return distA.compareTo(distB);
        });
      }
      _loading = false;
    });
  }

  Future<void> _loadSponsoredItems() async {
    try {
      final response = await Supabase.instance.client
          .from('sponsored_items')
          .select()
          .eq('category', 'artisan')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sponsoredServiceItems = (response as List)
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

  Future<void> _toggleLocation() async {
    final provider = Provider.of<ArtisanProvider>(context, listen: false);
    if (_locationEnabled) {
      setState(() {
        _locationEnabled = false;
        _userLatitude = null;
        _userLongitude = null;
      });
      provider.setNearMe(false);
    } else {
      try {
        final position = await LocationHelper.getCurrentPosition();
        if (position != null) {
          setState(() {
            _locationEnabled = true;
            _userLatitude = position.latitude;
            _userLongitude = position.longitude;
          });
          provider.setNearMe(true, lat: position.latitude, lng: position.longitude);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Could not get location. Please enable location services and permissions.'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showAdminLogin(BuildContext context) async {
    if (isAdmin) {
      setState(() => isAdmin = false);
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
                  labelText: 'Password', border: OutlineInputBorder()),
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
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              const adminPassword =
                  String.fromEnvironment('ADMIN_PASSWORD', defaultValue: '');
              if (passwordController.text.trim() == adminPassword &&
                  adminPassword.isNotEmpty) {
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => isAdmin = true);
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

  Future<void> _deleteArtisan(String artisanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Artisan?'),
        content: const Text('This will permanently delete this artisan.'),
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
            .from('artisans')
            .delete()
            .eq('id', artisanId)
            .select();

        if (response.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Failed to delete artisan - record not found'),
                  backgroundColor: AppTheme.error),
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Artisan deleted!'),
                backgroundColor: AppTheme.error),
          );
          await _fetchArtisans();
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

  Future<void> _toggleFeatured(String artisanId, bool currentStatus) async {
    try {
      await SupabaseUtils.client
          .from('artisans')
          .update({'isFeatured': !currentStatus}).eq('id', artisanId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus
                ? 'Artisan is now featured!'
                : 'Artisan removed from featured'),
            backgroundColor: AppTheme.success,
          ),
        );
        await _fetchArtisans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Widget _buildDropdown({
    required String hint,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      style: AppTheme.bodyMedium,
      iconSize: 18,
      isDense: true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppTheme.spaceSM + 2,
          horizontal: AppTheme.spaceBase,
        ),
      ),
      isExpanded: true,
      items: [
        DropdownMenuItem<String>(
            value: null, child: Text('All $hint', style: AppTheme.bodySmall)),
        ...items.map(
          (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item,
                style: AppTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space3XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off,
                  size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('No artisans found', style: AppTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              'Try adjusting your filters or search terms',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditArtisanProfile({
    required Artisan artisan,
    required String email,
    required String phone,
  }) async {
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
      await _fetchArtisans();
      if (!mounted) return;
      setState(() => _currentIndex = 0);
    }
  }

  Future<void> _showArtisanProfileInputDialog() async {
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Find Your Artisan Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
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
                  await _openEditArtisanProfile(
                    artisan: artisan,
                    email: email,
                    phone: phone,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No profile found with that phone/email.'),
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
  }

  Widget _buildProfileTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.manage_accounts_outlined,
                  size: 40,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Text('Manage Your Artisan Profile', style: AppTheme.titleLarge),
              const SizedBox(height: AppTheme.spaceSM),
              Text(
                'Submit a new artisan profile or open your existing one to update your picture and details.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spaceLG),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/profile');
                    if (!mounted) return;
                    await _fetchArtisans();
                  },
                  icon: const Icon(Icons.app_registration),
                  label: const Text('Submit New Profile'),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showArtisanProfileInputDialog,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Existing Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/stores');
      return;
    }

    // Navigate to Jobs page (index 5 in bottom nav)
    if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JobsPage()),
      );
      return;
    }

    // Refresh artisans when switching to Directory tab
    if (index == 0 && _currentIndex != 0) {
      _fetchArtisans();
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    String appBarTitle;

    if (_currentIndex == 0) {
      appBarTitle = 'Artisan Directory';
      final featured = _sortSponsored(
        _artisans.where((a) {
          return a.isFeatured == true ||
              (a.isSponsored && a.adType == AdType.featured);
        }).toList(),
      );
        final organic = _artisans.where((a) => !a.isSponsored).toList();
        // Determine if any filter is active
        final bool filterActive = _search.isNotEmpty || _state.isNotEmpty || _city.isNotEmpty || _category.isNotEmpty;
        final displayListings = (organic.isNotEmpty)
          ? organic
          : (filterActive ? [] : _fallbackArtisans());
        final featuredDisplay =
          featured.isNotEmpty ? featured : _fallbackArtisans().take(3).toList();

      body = ColoredBox(
        color: _directoryBackground,
        child: Column(
          children: [
            // Filter card
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceBase,
                AppTheme.spaceSM,
                AppTheme.spaceBase,
                AppTheme.spaceBase,
              ),
              child: Column(
                children: [
                  // Search
                  TextField(
                    style: AppTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search artisans, skills...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() => _search = '');
                                _fetchArtisans();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceBase,
                        vertical: AppTheme.spaceSM + 2,
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      _search = val;
                      _fetchArtisans();
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceSM),
                  // Row 2: Category + State
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          hint: 'Category',
                          value: _category,
                          items: _categories.map((c) => c.name).toList(),
                          onChanged: (val) {
                            setState(() => _category = val ?? '');
                            _fetchArtisans();
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Expanded(
                        child: _buildDropdown(
                          hint: 'State',
                          value: _state,
                          items: _states,
                          onChanged: (val) async {
                            setState(() {
                              _state = val ?? '';
                              _city = '';
                              _cities = [];
                            });
                            if (_state.isNotEmpty) {
                              final cities =
                                  await _artisanService.fetchCities(_state);
                              cities.sort((a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()));
                              if (!mounted) return;
                              setState(() => _cities = cities);
                            }
                            _fetchArtisans();
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_cities.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceSM),
                    _buildDropdown(
                      hint: 'City',
                      value: _city,
                      items: _cities,
                      onChanged: (val) {
                        setState(() => _city = val ?? '');
                        _fetchArtisans();
                      },
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceSM),
                  // Location toggle
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 16,
                        color: _locationEnabled
                            ? AppTheme.success
                            : AppTheme.textTertiary,
                      ),
                      const SizedBox(width: AppTheme.spaceXS),
                      Text(
                        'Near me',
                        style: AppTheme.labelSmall.copyWith(
                          color: _locationEnabled
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: _locationEnabled,
                          onChanged: (_) => _toggleLocation(),
                          activeThumbColor: AppTheme.success,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const Spacer(),
                      if (_locationEnabled && _userLatitude != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceSM,
                            vertical: AppTheme.spaceXXS + 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort,
                                  size: 12, color: AppTheme.success),
                              const SizedBox(width: 3),
                              Text(
                                'By distance',
                                style: AppTheme.caption.copyWith(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : displayListings.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchArtisans,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.spaceBase),
                            itemCount: displayListings.length + 3,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.spaceBase,
                                  ),
                                  child: _buildSponsoredServicesSection(),
                                );
                              }

                              if (index == 1) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.spaceBase,
                                  ),
                                  child: _buildFeaturedSponsoredSection(
                                    featuredDisplay,
                                  ),
                                );
                              }

                              if (index == 2) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.spaceBase,
                                  ),
                                  child: _buildEliteCoatingsBanner(),
                                );
                              }

                              final artisan = displayListings[index - 3];
                              final artisanId = artisan.id;

                              return Stack(
                                children: [
                                  ArtisanCard(
                                    artisan: artisan,
                                    userLat:
                                        _locationEnabled ? _userLatitude : null,
                                    userLng: _locationEnabled
                                        ? _userLongitude
                                        : null,
                                  ),
                                  if (isAdmin && artisanId != null)
                                    Positioned(
                                      top: AppTheme.spaceSM,
                                      right: AppTheme.spaceSM,
                                      child: Row(
                                        children: [
                                          _AdminActionButton(
                                            icon: Icons.star,
                                            color: (artisan.isFeatured ?? false)
                                                ? AppTheme.warning
                                                : AppTheme.textTertiary,
                                            onTap: () => _toggleFeatured(
                                              artisanId,
                                              artisan.isFeatured ?? false,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppTheme.spaceXS,
                                          ),
                                          _AdminActionButton(
                                            icon: Icons.delete,
                                            color: AppTheme.error,
                                            onTap: () =>
                                                _deleteArtisan(artisanId),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      );
    } else if (_currentIndex == 2) {
      appBarTitle = 'Equipment Directory';
      // IMPORTANT: disable nested bars to avoid duplicate app bars/nav bars
      body = const EquipmentPage(
        showAppBar: false,
        showBottomNav: false,
      );
    } else if (_currentIndex == 3) {
      appBarTitle = 'Wallet';
      body = const WalletPage(showBottomNav: false);
    } else {
      appBarTitle = 'Profile';
      body = _buildProfileTab();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.app_registration),
              tooltip: 'Register / Submit',
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          IconButton(
            icon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.shield),
            tooltip: isAdmin ? 'Admin Panel (Tap to logout)' : 'Admin Login',
            onPressed: () => _showAdminLogin(context),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: FadeTransition(
            opacity: _animationController,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textTertiary,
              selectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: AppTheme.fontFamily,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: AppTheme.fontFamily,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Directory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.store_outlined),
                  activeIcon: Icon(Icons.store),
                  label: 'Store',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.build_outlined),
                  activeIcon: Icon(Icons.build),
                  label: 'Equipment',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_outlined),
                  activeIcon: Icon(Icons.edit),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline),
                  activeIcon: Icon(Icons.work),
                  label: 'Jobs',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdTag extends StatelessWidget {
  final String label;

  const _AdTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: AppTheme.spaceXXS + 1,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceXS + 2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: AppTheme.shadowSM,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
