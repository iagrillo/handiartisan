import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/artisan.dart';
import '../../services/artisan_service.dart';
import '../../services/supabase_upload_helper.dart';
import '../utils/supabase.dart';
import '../payment/outcall_book_button.dart';
import '../ui/app_theme.dart';

class ArtisanProfilePage extends StatefulWidget {
  final Artisan artisan;
  final String? currentUserEmail;

  const ArtisanProfilePage({
    required this.artisan,
    this.currentUserEmail,
    Key? key,
  }) : super(key: key);

  @override
  State<ArtisanProfilePage> createState() => _ArtisanProfilePageState();
}

class _ArtisanProfilePageState extends State<ArtisanProfilePage> {
  String? currentUserEmail;
  late Artisan _artisan;

  late TextEditingController fullNameController;
  late TextEditingController businessNameController;
  late TextEditingController phoneController;
  late TextEditingController whatsappController;
  late TextEditingController bioController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  late final TextEditingController categoryController;
  late final TextEditingController stateController;
  late final TextEditingController cityController;
  List<String> categories = [];
  List<String> states = [];
  List<String> cities = [];

  bool isAvailable = false;
  double? latitude;
  double? longitude;
  bool isSaving = false;

  bool showInitialInput = true;
  final TextEditingController initialPhoneController = TextEditingController();
  final TextEditingController initialEmailController = TextEditingController();

  Timer? _autoRefreshTimer;
  static const Duration _autoRefreshInterval = Duration(seconds: 30);

  bool get _isOwner =>
      currentUserEmail != null && _artisan.email == currentUserEmail;

  @override
  void initState() {
    super.initState();
    _artisan = widget.artisan;

    fullNameController = TextEditingController(text: _artisan.fullName);
    businessNameController =
        TextEditingController(text: _artisan.businessName ?? '');
    phoneController = TextEditingController(text: _artisan.phone);
    whatsappController = TextEditingController(text: _artisan.whatsapp ?? '');
    bioController = TextEditingController(text: _artisan.bio ?? '');
    addressController = TextEditingController(text: _artisan.address ?? '');
    emailController = TextEditingController(text: _artisan.email ?? '');
    categoryController = TextEditingController(text: _artisan.category ?? '');
    stateController = TextEditingController(text: _artisan.state ?? '');
    cityController = TextEditingController(text: _artisan.city ?? '');
    isAvailable = _artisan.isAvailable ?? false;
    latitude = _artisan.latitude;
    longitude = _artisan.longitude;
    initialPhoneController.text = _artisan.phone;
    initialEmailController.text = _artisan.email ?? '';
    _fetchDropdowns();
  }

  Future<void> _fetchDropdowns() async {
    categories = await ArtisanService()
        .fetchCategories()
        .then((list) => list.map((c) => c.name).toList());
    states = await ArtisanService().fetchStates();
    if (stateController.text.isNotEmpty) {
      cities = await ArtisanService().fetchCities(stateController.text);
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    currentUserEmail = widget.currentUserEmail;
    if (currentUserEmail == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['email'] != null) {
        currentUserEmail = args['email'] as String;
      }
    }

    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) async {
      if (!mounted) return;
      if (_isOwner) return;
      await _refreshProfile(showMessage: false, overwriteControllers: false);
    });
  }

  Future<void> _refreshProfile({
    bool showMessage = false,
    bool overwriteControllers = false,
  }) async {
    if (_artisan.id == null) return;

    final updatedArtisan = _artisan.copyWith(
      fullName: fullNameController.text.trim(),
      businessName: businessNameController.text.trim(),
      phone: phoneController.text.trim(),
      whatsapp: whatsappController.text.trim(),
      bio: bioController.text.trim(),
      address: addressController.text.trim(),
      email: emailController.text.trim(),
      category: categoryController.text.trim(),
      state: stateController.text.trim(),
      city: cityController.text.trim(),
      isAvailable: isAvailable,
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted || updatedArtisan == null) return;

    setState(() {
      _artisan = updatedArtisan;
      isAvailable = updatedArtisan.isAvailable ?? false;
      latitude = updatedArtisan.latitude;
      longitude = updatedArtisan.longitude;

      if (overwriteControllers) {
        fullNameController.text = updatedArtisan.fullName;
        businessNameController.text = updatedArtisan.businessName ?? '';
        phoneController.text = updatedArtisan.phone;
        whatsappController.text = updatedArtisan.whatsapp ?? '';
        bioController.text = updatedArtisan.bio ?? '';
        addressController.text = updatedArtisan.address ?? '';
        emailController.text = updatedArtisan.email ?? '';
        categoryController.text = updatedArtisan.category ?? '';
        stateController.text = updatedArtisan.state ?? '';
        cityController.text = updatedArtisan.city ?? '';
      }
    });

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile refreshed')),
      );
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (!_isOwner || _artisan.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only profile owner can upload image.')),
      );
      return;
    }

    if (Platform.isAndroid) {
      // For Android 13+, we need to request specific media permissions
      PermissionStatus status;

      // First try photos permission (Android 13+)
      status = await Permission.photos.request();

      // If not granted, try storage permission (Android 12 and below)
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // Check if any permission was granted
      if (!status.isGranted) {
        // Try to open app settings if permission is permanently denied
        if (status.isPermanentlyDenied) {
          if (!mounted) return;
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                  'Photo access permission is required. Please enable it in app settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
          return;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Photo permission denied. Please grant permission to upload photos.')),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => isSaving = true);

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final publicUrl = await SupabaseUploadHelper.uploadImage(
        bytes,
        folder: 'artisan_profiles/${_artisan.id}',
        fileName: fileName,
      );

      if (publicUrl == null || publicUrl.isEmpty) {
        throw Exception('Image upload did not return a public URL.');
      }

      final ok = await ArtisanService().updateArtisan(
        _artisan.id!,
        {'profile_image_url': publicUrl},
      );

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Picture uploaded, but the profile update was blocked by the database. Run the Supabase profile policy fix and try again.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _artisan = _artisan.copyWith(profileImageUrl: publicUrl);
      });
      await _refreshProfile(showMessage: false, overwriteControllers: false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _setLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable Location service.')),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location set: ($latitude, $longitude)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_artisan.id == null) return;

    // Validate required fields
    if (fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Full Name, Phone, and Email are required.')),
        );
      }
      return;
    }

    setState(() => isSaving = true);

    final data = {
      'full_name': fullNameController.text.trim(),
      'business_name': businessNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'whatsapp': whatsappController.text.trim(),
      'bio': bioController.text.trim(),
      'address': addressController.text.trim(),
      'email': emailController.text.trim(),
      'is_available': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'category': categoryController.text.trim(),
      'state': stateController.text.trim(),
      'city': cityController.text.trim(),
    };

    final ok = await ArtisanService().updateArtisan(_artisan.id!, data);

    if (ok) {
      await _refreshProfile(showMessage: true, overwriteControllers: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update profile. The database permission for this artisan record is still blocking the save.',
          ),
        ),
      );
    }
    if (mounted) setState(() => isSaving = false);
  }

  Future<void> _launchWhatsApp(String phoneNumber, {String? message}) async {
    // Clean the phone number - remove any spaces, dashes, or parentheses
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If the number starts with 0, replace it with 234 (Nigeria country code)
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '234${cleanNumber.substring(1)}';
    }

    // Add country code if not present
    if (!cleanNumber.startsWith('234')) {
      cleanNumber = '234$cleanNumber';
    }

    final String whatsappMessage =
        message ?? 'Good day, I would like to book a job with you';
    final String url =
        'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(whatsappMessage)}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _showOutcallBookingSheet(BuildContext context, Artisan artisan) {
    // Get current user email
    final userEmail =
        currentUserEmail ?? SupabaseUtils.client.auth.currentUser?.email;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
        ),
        child: OutcallBookButtonSimple(
          artisan: artisan,
          customerEmail: userEmail,
          onPaymentSuccess: () {
            // Navigate to Jobs page after successful payment
            Navigator.pop(context); // Close bottom sheet
            Navigator.pushNamed(context, '/jobs');
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    fullNameController.dispose();
    businessNameController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    bioController.dispose();
    addressController.dispose();
    emailController.dispose();
    initialPhoneController.dispose();
    initialEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artisan = _artisan;
    final isOwner = _isOwner;

    if (showInitialInput && isOwner) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Enter Contact Info')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: AppTheme.shadowMD,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    ),
                    child: const Icon(Icons.badge_outlined,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: AppTheme.spaceBase),
                  Text('Let\'s set up your profile', style: AppTheme.headline3),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'Add your main contact details so customers can reach you and manage bookings smoothly.',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  TextField(
                    controller: initialPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTheme.spaceBase),
                  TextField(
                    controller: initialEmailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppTheme.spaceLG),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          phoneController.text = initialPhoneController.text;
                          emailController.text = initialEmailController.text;
                          showInitialInput = false;
                        });
                      },
                      child: const Text('Continue to Edit Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Artisan Profile')),
      body: RefreshIndicator(
        onRefresh: () => _refreshProfile(
          showMessage: false,
          overwriteControllers: isOwner,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spaceBase),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHero(artisan, isOwner),
              const SizedBox(height: AppTheme.spaceBase),
              _buildSectionCard(
                title: 'About',
                icon: Icons.info_outline,
                child: isOwner
                    ? TextField(
                        controller: bioController,
                        decoration: const InputDecoration(labelText: 'Bio'),
                        maxLines: 3,
                      )
                    : Text(
                        (artisan.bio ?? '').isEmpty
                            ? 'No bio added yet.'
                            : artisan.bio!,
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.textSecondary),
                      ),
              ),
              const SizedBox(height: AppTheme.spaceBase),
              _buildSectionCard(
                title: 'Contact details',
                icon: Icons.contact_phone_outlined,
                child: Column(
                  children: [
                    isOwner
                        ? TextField(
                            controller: addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          )
                        : _buildInfoRow(Icons.location_on_outlined, 'Address',
                            artisan.address ?? 'Not added'),
                    const SizedBox(height: AppTheme.spaceSM),
                    isOwner
                        ? TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                          )
                        : _buildInfoRow(
                            Icons.phone_outlined, 'Phone', artisan.phone),
                    const SizedBox(height: AppTheme.spaceSM),
                    isOwner
                        ? TextField(
                            controller: whatsappController,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp',
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                            keyboardType: TextInputType.phone,
                          )
                        : _buildInfoRow(Icons.chat_bubble_outline, 'WhatsApp',
                            artisan.whatsapp ?? 'Not added'),
                    if (isOwner) ...[
                      const SizedBox(height: AppTheme.spaceSM),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceBase),
              // Book Button for non-owners
              if (!isOwner &&
                  (artisan.whatsapp != null && artisan.whatsapp!.isNotEmpty))
                _buildActionButton(
                  label: 'Inquire on WhatsApp',
                  icon: Icons.message_outlined,
                  color: AppTheme.whatsapp,
                  onPressed: () =>
                      _launchWhatsApp(artisan.whatsapp ?? artisan.phone),
                ),
              const SizedBox(height: AppTheme.spaceSM),
              // Outcall Button for non-owners - Pay with Paystack
              if (!isOwner &&
                  (artisan.whatsapp != null && artisan.whatsapp!.isNotEmpty))
                _buildActionButton(
                  label: 'Book Outcall - ₦3,000',
                  icon: Icons.payment_outlined,
                  color: AppTheme.primary,
                  onPressed: () => _showOutcallBookingSheet(context, artisan),
                ),
              const SizedBox(height: AppTheme.spaceBase),
              _buildSectionCard(
                title: 'Availability',
                icon: Icons.verified_user_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceSM,
                            vertical: AppTheme.spaceXXS + 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isAvailable
                                    ? AppTheme.success
                                    : AppTheme.error)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            isAvailable ? 'Available' : 'Unavailable',
                            style: AppTheme.caption.copyWith(
                              color: isAvailable
                                  ? AppTheme.success
                                  : AppTheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isOwner)
                          Switch(
                            value: isAvailable,
                            onChanged: (val) async {
                              setState(() => isAvailable = val);
                              await _saveProfile();
                            },
                          )
                        else
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            color:
                                isAvailable ? AppTheme.success : AppTheme.error,
                          ),
                      ],
                    ),
                    if (latitude != null && longitude != null) ...[
                      const SizedBox(height: AppTheme.spaceSM),
                      Text(
                        'Saved location: (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})',
                        style: AppTheme.bodySmall
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                    if (isOwner) ...[
                      const SizedBox(height: AppTheme.spaceSM),
                      OutlinedButton.icon(
                        onPressed: _setLocation,
                        icon: const Icon(Icons.my_location_outlined),
                        label: const Text('Set Location'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceBase),
              if (artisan.galleryImageUrls != null &&
                  artisan.galleryImageUrls!.isNotEmpty) ...[
                Text(
                  'Gallery',
                  style: AppTheme.titleSmall,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: artisan.galleryImageUrls!.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppTheme.spaceSM),
                    itemBuilder: (context, idx) => GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(10),
                            child: Stack(
                              children: [
                                Center(
                                  child: InteractiveViewer(
                                    child: Image.network(
                                        artisan.galleryImageUrls![idx]),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 30),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        child: Container(
                          decoration:
                              BoxDecoration(boxShadow: AppTheme.shadowSM),
                          child: Image.network(
                            artisan.galleryImageUrls![idx],
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (isSaving) ...[
                const SizedBox(height: AppTheme.spaceMD),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: AppTheme.spaceBase),
              if (isOwner)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                    onPressed: isSaving ? null : _saveProfile,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required TextEditingController controller,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : null,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        controller.text = value ?? '';
        onChanged(value);
      },
      isExpanded: true,
    );
  }

  Widget _buildProfileHero(Artisan artisan, bool isOwner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        gradient: AppTheme.subtleGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.inputFill,
                backgroundImage: (artisan.profileImageUrl != null &&
                        artisan.profileImageUrl!.isNotEmpty)
                    ? NetworkImage(artisan.profileImageUrlWithCache ??
                        artisan.profileImageUrl!)
                    : null,
                child: (artisan.profileImageUrl == null ||
                        artisan.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person,
                        size: 40, color: AppTheme.textTertiary)
                    : null,
              ),
              if (isOwner)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: InkWell(
                    onTap: isSaving ? null : _pickAndUploadProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXS + 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.spaceBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isOwner
                    ? TextField(
                        controller: fullNameController,
                        decoration:
                            const InputDecoration(labelText: 'Full Name'),
                      )
                    : Text(artisan.fullName, style: AppTheme.headline3),
                const SizedBox(height: AppTheme.spaceSM),
                isOwner
                    ? TextField(
                        controller: businessNameController,
                        decoration:
                            const InputDecoration(labelText: 'Business Name'),
                      )
                    : Text(
                        (artisan.businessName ?? '').isEmpty
                            ? 'Independent artisan'
                            : artisan.businessName!,
                        style: AppTheme.bodyLarge
                            .copyWith(color: AppTheme.textSecondary),
                      ),
                const SizedBox(height: AppTheme.spaceSM),
                Wrap(
                  spacing: AppTheme.spaceXS,
                  runSpacing: AppTheme.spaceXS,
                  children: [
                    if ((artisan.category ?? '').isNotEmpty)
                      _buildMetaChip(
                          Icons.handyman_outlined, artisan.category!),
                    if ((artisan.city ?? '').isNotEmpty ||
                        (artisan.state ?? '').isNotEmpty)
                      _buildMetaChip(
                        Icons.place_outlined,
                        [
                          if ((artisan.city ?? '').isNotEmpty) artisan.city,
                          if ((artisan.state ?? '').isNotEmpty) artisan.state,
                        ].whereType<String>().join(', '),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceBase),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: AppTheme.spaceXS),
              Text(title, style: AppTheme.titleSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spaceBase),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textTertiary),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSM,
        vertical: AppTheme.spaceXXS + 2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
