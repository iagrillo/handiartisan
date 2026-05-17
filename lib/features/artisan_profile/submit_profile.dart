import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/app_theme.dart';
import '../models/artisan.dart';
import '../../services/artisan_service.dart';
import '../../services/supabase_upload_helper.dart';

class SubmitProfile extends StatefulWidget {
  final Artisan artisan;

  const SubmitProfile({
    super.key,
    required this.artisan,
  });

  @override
  State<SubmitProfile> createState() => _SubmitProfileState();
}

class _SubmitProfileState extends State<SubmitProfile> {
  late final TextEditingController fullNameController;
  late final TextEditingController businessNameController;
  late final TextEditingController phoneController;
  late final TextEditingController whatsappController;
  late final TextEditingController bioController;
  late final TextEditingController addressController;
  late final TextEditingController emailController;

  final ImagePicker _picker = ImagePicker();
  XFile? profileImageFile;
  Uint8List? profileImageBytes;
  String? profileImageUrl;

  bool isAvailable = false;
  bool isSaving = false;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.artisan.fullName);
    businessNameController =
        TextEditingController(text: widget.artisan.businessName ?? '');
    phoneController = TextEditingController(text: widget.artisan.phone);
    whatsappController =
        TextEditingController(text: widget.artisan.whatsapp ?? '');
    bioController = TextEditingController(text: widget.artisan.bio ?? '');
    addressController = TextEditingController(text: widget.artisan.address ?? '');
    emailController = TextEditingController(text: widget.artisan.email ?? '');
    isAvailable = widget.artisan.isAvailable ?? false;
    profileImageUrl = widget.artisan.profileImageUrl;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    businessNameController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    bioController.dispose();
    addressController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      debugPrint('Starting image picker...');
      // Request permissions for Android
      if (Platform.isAndroid) {
        final photosStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;
        final cameraStatus = await Permission.camera.status;
        debugPrint('Android photos permission status: $photosStatus');
        debugPrint('Android storage permission status: $storageStatus');
        debugPrint('Android camera permission status: $cameraStatus');
        if (!photosStatus.isGranted) await Permission.photos.request();
        if (!storageStatus.isGranted) await Permission.storage.request();
        if (!cameraStatus.isGranted) await Permission.camera.request();
      }
      // Show a dialog to let user choose between gallery and camera
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Camera'),
            ),
          ],
        ),
      );
      if (source == null) return;
      final picked = await _picker.pickImage(
        source: source,
        requestFullMetadata: true,
      );
      debugPrint('Picked file: $picked');
      if (picked == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
        }
        return;
      }
      await _handlePickedImage(picked);
    } catch (e) {
      debugPrint('Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image picker error: $e')),
        );
      }
    }
  }

  Future<void> _handlePickedImage(XFile picked) async {
    setState(() {
      isUploadingImage = true;
    });
    try {
      final bytes = await picked.readAsBytes();
      debugPrint('Read ${bytes.length} bytes from image');
      setState(() {
        profileImageBytes = bytes;
      });
      debugPrint('Starting upload to Supabase...');
      final url = await SupabaseUploadHelper.uploadImage(bytes, folder: 'profile', fileName: picked.name);
      debugPrint('Upload result: $url');
      if (url != null && url.isNotEmpty) {
        setState(() {
          profileImageUrl = url;
          profileImageBytes = null;
          isUploadingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture updated: $url')),
          );
        }
      } else {
        setState(() {
          profileImageBytes = null;
          isUploadingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image. URL: $url')),
          );
        }
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      setState(() {
        profileImageBytes = null;
        isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    }
  }

  Future<void> _submitProfile() async {
    // Validate required fields
    if (fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        businessNameController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        bioController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields are required.')),
        );
      }
      return;
    }

    setState(() => isSaving = true);

    try {
      debugPrint('Submitting new artisan profile');
      final data = <String, dynamic>{
        'full_name': fullNameController.text.trim(),
        'business_name': businessNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'whatsapp': whatsappController.text.trim(),
        'bio': bioController.text.trim(),
        'address': addressController.text.trim(),
        'email': emailController.text.trim(),
        'is_available': isAvailable,
        'profile_image_url': profileImageUrl,
        // Add other required fields here (e.g., category, state, city)
        // Example:
        // 'category': categoryController.text.trim(),
        // 'state': stateController.text.trim(),
        // 'city': cityController.text.trim(),
      };
      debugPrint('Data to submit: $data');
      final ok = await ArtisanService().addArtisan(Artisan.fromJson(data));
      debugPrint('Add result: $ok');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Profile registered.' : 'Registration failed.')),
      );
      if (ok) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build image provider for avatar
    ImageProvider? imageProvider;
    if (profileImageBytes != null) {
      imageProvider = MemoryImage(profileImageBytes!);
    } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(profileImageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.inputFill,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 50, color: AppTheme.textSecondary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.shadowColor.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white),
                        tooltip: 'Upload Picture',
                        onPressed: isSaving || isUploadingImage ? null : _pickAndUploadProfileImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: businessNameController,
              decoration: const InputDecoration(labelText: 'Business Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: whatsappController,
              decoration: const InputDecoration(labelText: 'WhatsApp'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Available'),
                Switch(
                  value: isAvailable,
                  onChanged: isSaving ? null : (v) => setState(() => isAvailable = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _submitProfile,
                child: Text(isSaving ? 'Saving...' : 'Submit Profile'),
              ),
            ),
            if (isSaving) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
