import 'package:flutter/material.dart';
import '../models/artisan.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_upload_helper.dart';
import '../../services/artisan_service.dart';
import '../ui/app_theme.dart';

class EditArtisanProfilePage extends StatefulWidget {
  final Artisan artisan;
  final String email;
  final String phone;
  const EditArtisanProfilePage(
      {required this.artisan,
      required this.email,
      required this.phone,
      Key? key})
      : super(key: key);

  @override
  State<EditArtisanProfilePage> createState() => _EditArtisanProfilePageState();
}

class _EditArtisanProfilePageState extends State<EditArtisanProfilePage> {
  File? profileImageFile;
  Uint8List? profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  String? profileImageUrl;
  List<String> galleryImageUrls = [];

  late TextEditingController fullNameController;
  late TextEditingController businessNameController;
  late TextEditingController phoneController;
  late TextEditingController whatsappController;
  late TextEditingController bioController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  late TextEditingController cityController;

  bool isAvailable = false;
  double? latitude;
  double? longitude;
  bool isSaving = false;
  String submitError = '';

  @override
  void initState() {
    super.initState();
    final artisan = widget.artisan;
    fullNameController = TextEditingController(text: artisan.fullName);
    businessNameController =
        TextEditingController(text: artisan.businessName ?? '');
    phoneController = TextEditingController(text: widget.phone);
    whatsappController = TextEditingController(text: artisan.whatsapp ?? '');
    bioController = TextEditingController(text: artisan.bio ?? '');
    addressController = TextEditingController(text: artisan.address ?? '');
    emailController = TextEditingController(text: widget.email);
    cityController = TextEditingController(text: artisan.city ?? '');
    isAvailable = artisan.isAvailable ?? false;
    latitude = artisan.latitude;
    longitude = artisan.longitude;
    profileImageUrl = artisan.profileImageUrl;
    galleryImageUrls = List<String>.from(artisan.galleryImageUrls ?? []);
  }

  Future<void> _saveProfile() async {
    if (fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty) {
      setState(() {
        submitError = 'Full Name, Phone, Email, and City are required.';
      });
      return;
    }
    setState(() {
      isSaving = true;
      submitError = '';
    });
    final data = {
      'full_name': fullNameController.text.trim(),
      'business_name': businessNameController.text.trim(),
      'phone': phoneController.text.trim(),
      'whatsapp': whatsappController.text.trim(),
      'bio': bioController.text.trim(),
      'address': addressController.text.trim(),
      'email': emailController.text.trim(),
      'city': cityController.text.trim(),
      'is_available': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'profile_image_url': profileImageUrl,
      'gallery_image_urls': galleryImageUrls,
    };
    print('[EDIT] Saving profile_image_url: $profileImageUrl');
    final ok = await ArtisanService().updateArtisan(widget.artisan.id!, data);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        submitError = 'Failed to update profile.';
      });
    }
    setState(() => isSaving = false);
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
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Artisan Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (submitError.isNotEmpty)
              Card(
                color: AppTheme.error.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: AppTheme.spaceBase),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMD),
                  child: Row(children: [
                    const Icon(Icons.error, color: AppTheme.error),
                    const SizedBox(width: AppTheme.spaceMD),
                    Expanded(
                        child: Text(submitError,
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 16)))
                  ]),
                ),
              ),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Builder(
                    builder: (context) {
                      ImageProvider? imageProvider;
                      if (profileImageBytes != null) {
                        imageProvider = MemoryImage(profileImageBytes!);
                      } else if (profileImageFile != null) {
                        imageProvider = FileImage(profileImageFile!);
                      } else if (profileImageUrl != null &&
                          profileImageUrl!.isNotEmpty) {
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        final url = profileImageUrl!.contains('?')
                            ? '${profileImageUrl}&$timestamp'
                            : '${profileImageUrl}?$timestamp';
                        imageProvider = NetworkImage(url);
                      }
                      return CircleAvatar(
                        radius: 48,
                        backgroundImage: imageProvider,
                        child: (imageProvider == null)
                            ? const Icon(Icons.person, size: 48)
                            : null,
                      );
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        tooltip: 'Upload Picture',
                        onPressed: () async {
                          final picked = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (picked != null) {
                            // Delete old image first to avoid caching
                            if (profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty) {
                              try {
                                final uri = Uri.parse(profileImageUrl!);
                                final segments = uri.pathSegments;
                                final idxPath =
                                    segments.indexWhere((s) => s == 'profile');
                                if (idxPath != -1) {
                                  final path =
                                      segments.sublist(idxPath + 1).join('/');
                                  await SupabaseUploadHelper.deleteImage(path);
                                }
                              } catch (_) {}
                            }
                            final bytes = await picked.readAsBytes();
                            setState(() {
                              profileImageBytes = bytes;
                            });
                            // Don't pass fileName so UUID is used
                            final url = await SupabaseUploadHelper.uploadImage(
                                bytes,
                                folder: 'profile');
                            if (url != null) {
                              setState(() {
                                profileImageUrl = url;
                                profileImageBytes = null;
                              });
                            }
                          }
                        },
                      ),
                      if (profileImageBytes != null ||
                          profileImageFile != null ||
                          (profileImageUrl != null &&
                              profileImageUrl!.isNotEmpty))
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete Picture',
                          onPressed: () async {
                            if (profileImageUrl != null &&
                                profileImageUrl!.isNotEmpty) {
                              final uri = Uri.parse(profileImageUrl!);
                              final segments = uri.pathSegments;
                              final idx = segments.indexOf('object');
                              if (idx != -1 && idx + 1 < segments.length) {
                                final path =
                                    segments.sublist(idx + 1).join('/');
                                await SupabaseUploadHelper.deleteImage(path);
                              }
                            }
                            setState(() {
                              profileImageBytes = null;
                              profileImageFile = null;
                              profileImageUrl = '';
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            Text('Gallery:', style: AppTheme.titleSmall),
            const SizedBox(height: AppTheme.spaceSM),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: galleryImageUrls.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.spaceSM),
                itemBuilder: (context, idx) {
                  if (idx == galleryImageUrls.length) {
                    // Upload new gallery image
                    return InkWell(
                      onTap: () async {
                        final picked = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          final url = await SupabaseUploadHelper.uploadImage(
                              bytes,
                              folder: 'gallery',
                              fileName: picked.name);
                          if (url != null) {
                            final updatedGallery =
                                List<String>.from(galleryImageUrls)..add(url);
                            final ok = await ArtisanService()
                                .updateArtisan(widget.artisan.id!, {
                              'gallery_image_urls': updatedGallery,
                            });
                            if (ok) {
                              final updatedArtisan = await ArtisanService()
                                  .fetchArtisanById(widget.artisan.id!);
                              setState(() {
                                galleryImageUrls =
                                    updatedArtisan?.galleryImageUrls ??
                                        updatedGallery;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to update gallery in backend.')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Gallery upload failed. Please try again.')),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.inputFill,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Icon(Icons.add_a_photo,
                            size: 32, color: AppTheme.textTertiary),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Show full screen image
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child:
                                          Image.network(galleryImageUrls[idx]),
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
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                          child: Image.network(
                            galleryImageUrls[idx],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () async {
                            final uri = Uri.parse(galleryImageUrls[idx]);
                            final segments = uri.pathSegments;
                            final idxPath = segments.indexOf('object');
                            if (idxPath != -1 &&
                                idxPath + 1 < segments.length) {
                              final path =
                                  segments.sublist(idxPath + 1).join('/');
                              await SupabaseUploadHelper.deleteImage(path);
                            }
                            setState(() {
                              galleryImageUrls.removeAt(idx);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spaceBase),
            TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
                controller: businessNameController,
                decoration: const InputDecoration(labelText: 'Business Name')),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
                controller: whatsappController,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City')),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: AppTheme.spaceSM),
            TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 2),
            const SizedBox(height: AppTheme.spaceBase),
            Row(
              children: [
                const Text('Available:'),
                Switch(
                    value: isAvailable,
                    onChanged: (val) => setState(() => isAvailable = val)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Row(
              children: [
                const Text('Show Distance:'),
                Switch(
                  value: widget.artisan.showDistance ?? false,
                  onChanged: (val) {
                    setState(() {
                      widget.artisan.showDistance = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXL),
            ElevatedButton(
              onPressed: isSaving ? null : _saveProfile,
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
