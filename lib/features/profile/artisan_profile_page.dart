import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/artisan.dart';
import '../models/category.dart';
import '../ui/app_theme.dart';

import '../../services/artisan_service.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'profile_upload_stub.dart'
  if (dart.library.html) 'profile_upload_web.dart'
  if (dart.library.io) 'profile_upload_mobile.dart' as platform_upload;

class ArtisanProfilePage extends StatefulWidget {
  final Artisan artisan;
  const ArtisanProfilePage({Key? key, required this.artisan}) : super(key: key);

  @override
  State<ArtisanProfilePage> createState() => _ArtisanProfilePageState();
}

class _ArtisanProfilePageState extends State<ArtisanProfilePage> {
  String? newProfileImageUrl;
  List<String> newGalleryImages = [];
  bool isProfileUploading = false;
  bool isGalleryUploading = false;
  String selectedCategory = '';
  String selectedState = '';
  String selectedCity = '';
  List<String> states = [];
  List<String> cities = [];
  List<Category> categories = [];
  late TextEditingController fullNameController;
  late TextEditingController businessNameController;
  late TextEditingController phoneController;
  late TextEditingController whatsappController;
  late TextEditingController categoryController;
  late TextEditingController addressController;
  late TextEditingController bioController;
  bool isAvailable = false;
  double? latitude;
  double? longitude;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.artisan.fullName);
    businessNameController = TextEditingController(text: widget.artisan.businessName ?? '');
    phoneController = TextEditingController(text: widget.artisan.phone);
    whatsappController = TextEditingController(text: widget.artisan.whatsapp ?? '');
    categoryController = TextEditingController(text: widget.artisan.category ?? '');
    addressController = TextEditingController(text: widget.artisan.address ?? '');
    bioController = TextEditingController(text: widget.artisan.bio ?? '');
    selectedCategory = widget.artisan.category ?? '';
    selectedState = widget.artisan.state ?? '';
    selectedCity = widget.artisan.city ?? '';
    isAvailable = widget.artisan.isAvailable ?? false;
    latitude = widget.artisan.latitude;
    longitude = widget.artisan.longitude;
    _fetchDropdowns();
  }

  Future<void> _setLocation() async {
    // Use geolocator to get current location
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        latitude = pos.latitude;
        longitude = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location set: ($latitude, $longitude)')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<void> pickProfileImage() async {
    setState(() => isProfileUploading = true);
    await platform_upload.platformHandleProfileUpload(
      context: context,
      onSuccess: (url) {
        setState(() {
          newProfileImageUrl = url;
          isProfileUploading = false;
        });
      },
      onError: (err) {
        setState(() => isProfileUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile image upload failed: $err')));
      },
      setUploading: (uploading) => setState(() => isProfileUploading = uploading),
    );
  }

  Future<void> addGalleryImage() async {
    setState(() => isGalleryUploading = true);
    await platform_upload.platformHandleProfileUpload(
      context: context,
      onSuccess: (url) {
        setState(() {
          newGalleryImages.add(url);
          isGalleryUploading = false;
        });
      },
      onError: (err) {
        setState(() => isGalleryUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gallery image upload failed: $err')));
      },
      setUploading: (uploading) => setState(() => isGalleryUploading = uploading),
    );
  }

  void removeGalleryImage(int index) {
    setState(() {
      if (index < newGalleryImages.length) {
        newGalleryImages.removeAt(index);
      } else if (widget.artisan.galleryImageUrls != null && index < (widget.artisan.galleryImageUrls!.length + newGalleryImages.length)) {
        // Remove from original gallery (mark for deletion in real app)
        // For now, just ignore
      }
    });
  }

  Future<void> _fetchDropdowns() async {
    final service = ArtisanService();
    categories = await service.fetchCategories();
    states = await service.fetchStates();
    if (selectedState.isNotEmpty) {
      cities = await service.fetchCities(selectedState);
    } else {
      cities = [];
    }
    setState(() {});
  }

  @override
  void dispose() {
    fullNameController.dispose();
    businessNameController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    categoryController.dispose();
    addressController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void handleSubmit() async {
    setState(() { isSaving = true; });
    if (!mounted) return;
    final updated = {
      'full_name': fullNameController.text.trim(),
      'business_name': businessNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'whatsapp': whatsappController.text.trim(),
      'category': selectedCategory,
      'state': selectedState,
      'city': selectedCity,
      'address': addressController.text.trim(),
      'bio': bioController.text.trim(),
      'is_available': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'profile_image_url': newProfileImageUrl ?? widget.artisan.profileImageUrl,
      'gallery_image_urls': jsonEncode([
        ...?widget.artisan.galleryImageUrls,
        ...newGalleryImages,
      ]),
      'status': 'pending',
    };
    final id = widget.artisan.id;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile ID missing or empty. Cannot update.')),
      );
      if (mounted) {
      setState(() { isSaving = false; });
      }
      return;
    }
    final success = await ArtisanService().updateArtisan(id, updated);
    if (mounted) {
    setState(() { isSaving = false; });
    }
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile submitted for admin approval.')),
      );
      // Redirect to admin dashboard after save
      Navigator.of(context).pushNamedAndRemoveUntil('/admin-dashboard', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile. Please check your network and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: AppTheme.error),
            tooltip: 'Delete Profile',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Profile'),
                  content: Text('Are you sure you want to delete your profile? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                  ],
                ),
              );
              if (confirm == true) {
                final id = widget.artisan.id;
                if (id != null && id.isNotEmpty) {
                  final success = await ArtisanService().deleteArtisan(id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile deleted.')));
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete profile.')));
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: (newProfileImageUrl != null && newProfileImageUrl!.isNotEmpty)
                          ? NetworkImage(newProfileImageUrl!)
                          : (widget.artisan.profileImageUrl != null && widget.artisan.profileImageUrl!.isNotEmpty)
                              ? NetworkImage(widget.artisan.profileImageUrl!)
                              : null,
                      child: ((newProfileImageUrl == null || newProfileImageUrl!.isEmpty) && (widget.artisan.profileImageUrl == null || widget.artisan.profileImageUrl!.isEmpty))
                          ? Icon(Icons.person, size: 40, color: AppTheme.textSecondary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: pickProfileImage,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: businessNameController,
                decoration: InputDecoration(labelText: 'Business Name'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 8),
              TextField(
                controller: whatsappController,
                decoration: InputDecoration(labelText: 'WhatsApp'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: (selectedCategory.isNotEmpty && categories.map((cat) => cat.name).toSet().contains(selectedCategory))
                    ? selectedCategory
                    : null,
                decoration: InputDecoration(labelText: 'Category'),
                items: categories
                    .map((cat) => cat.name)
                    .toSet()
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val ?? ''),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: (selectedState.isNotEmpty && states.contains(selectedState)) ? selectedState : null,
                decoration: InputDecoration(labelText: 'State'),
                items: states
                    .toSet()
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) async {
                  setState(() => selectedState = val ?? '');
                  cities = await ArtisanService().fetchCities(selectedState);
                  setState(() {});
                },
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: (selectedCity.isNotEmpty && cities.contains(selectedCity)) ? selectedCity : null,
                decoration: InputDecoration(labelText: 'City'),
                items: cities
                    .toSet()
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCity = val ?? ''),
              ),
              SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: bioController,
                decoration: InputDecoration(labelText: 'Bio'),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Available:'),
                  Switch(
                    value: isAvailable,
                    onChanged: (val) => setState(() => isAvailable = val),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _setLocation,
                    icon: Icon(Icons.my_location),
                    label: Text('Set Location'),
                  ),
                  if (latitude != null && longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text('(${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})'),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Text('Work Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (widget.artisan.galleryImageUrls != null)
                    ...widget.artisan.galleryImageUrls!.asMap().entries.map((entry) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => removeGalleryImage(entry.key),
                            child: Container(
                              color: Colors.white,
                        child: Icon(Icons.close, color: AppTheme.error, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )),
                  ...newGalleryImages.asMap().entries.map((entry) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => removeGalleryImage(entry.key),
                          child: Container(
                            color: Colors.white,
                            child: Icon(Icons.close, color: Colors.red, size: 20),
                          ),
                        ),
                      ),
                    ],
                  )),
                  GestureDetector(
                    onTap: addGalleryImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.inputFill,
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Icon(Icons.add_a_photo, color: AppTheme.primary, size: 32),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSaving ? null : handleSubmit,
                child: isSaving ? CircularProgressIndicator() : Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
