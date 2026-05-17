import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/supabase.dart';
import 'widgets/bottom_app_bar.dart';
import '../ui/app_theme.dart';

class StoreDetailsPage extends StatefulWidget {
  final Map<String, dynamic> store;

  const StoreDetailsPage({Key? key, required this.store}) : super(key: key);

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOwnerVerified = false;
  bool _isLoading = true;

  // Data from database
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _complaints = [];

  // Store data (may be updated after edit)
  late Map<String, dynamic> _store;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _store = widget.store;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final storeId = _store['id'];

      // Load products
      final productsRes = await SupabaseUtils.client
          .from('store_products')
          .select()
          .eq('store_id', storeId);
      _products = List<Map<String, dynamic>>.from(productsRes);

      // Load services
      final servicesRes = await SupabaseUtils.client
          .from('store_services')
          .select()
          .eq('store_id', storeId);
      _services = List<Map<String, dynamic>>.from(servicesRes);

      // Load reviews
      final reviewsRes = await SupabaseUtils.client
          .from('store_reviews')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);
      _reviews = List<Map<String, dynamic>>.from(reviewsRes);

      // Load complaints
      final complaintsRes = await SupabaseUtils.client
          .from('store_complaints')
          .select()
          .eq('store_id', storeId);
      _complaints = List<Map<String, dynamic>>.from(complaintsRes);
    } catch (e) {
      print('Error loading data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your store email and new password'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
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
              final email = emailController.text.trim().toLowerCase();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (email.isEmpty || newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter email and new password')),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              if (newPassword.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be at least 4 characters')),
                );
                return;
              }

              try {
                // First check if email exists for this store
                final store = await SupabaseUtils.client
                    .from('stores')
                    .select()
                    .eq('id', _store['id'])
                    .maybeSingle();

                final storedEmail =
                    (store?['email'] ?? '').toString().toLowerCase();

                if (storedEmail.isNotEmpty && storedEmail != email) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Email does not match our records'),
                          backgroundColor: AppTheme.error),
                    );
                  }
                  return;
                }

                // Update password and email
                await SupabaseUtils.client.from('stores').update({
                  'password_hash': newPassword,
                  'email': email,
                }).eq('id', _store['id']);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Password reset successfully! Use new password to login.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOwner() async {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Owner Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter the phone number and password used to register this store'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showForgotPasswordDialog();
              },
              child: const Text('Forgot Password?'),
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
              final password = passwordController.text.trim();

              if (phone.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter phone and password')),
                );
                return;
              }

              try {
                final result = await SupabaseUtils.client
                    .from('stores')
                    .select()
                    .eq('id', _store['id'])
                    .eq('phone_number', phone)
                    .eq('password_hash', password)
                    .maybeSingle();

                if (result != null) {
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _isOwnerVerified = true;
                      _store = Map<String, dynamic>.from(result);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Verification successful! You can now edit your store.'),
                          backgroundColor: AppTheme.success),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invalid phone or password'),
                          backgroundColor: AppTheme.error),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.error),
                  );
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall() async {
    final phone = _store['phone_number'] ?? _store['phone'] ?? '';
    if (phone.isEmpty) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    final whatsapp = _store['whatsapp_number'] ?? _store['whatsapp'] ?? '';
    if (whatsapp.isEmpty) return;

    // Remove any non-digit characters
    final cleanNumber = whatsapp.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _editStoreProfile() async {
    final nameController = TextEditingController(text: _store['name']);
    final addressController = TextEditingController(text: _store['address']);
    final phoneController =
        TextEditingController(text: _store['phone_number'] ?? '');
    final whatsappController =
        TextEditingController(text: _store['whatsapp_number'] ?? '');
    final descriptionController =
        TextEditingController(text: _store['description'] ?? '');
    final openHoursController =
        TextEditingController(text: _store['open_hours'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Store Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Store Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                    labelText: 'Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                    labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: whatsappController,
                decoration: const InputDecoration(
                    labelText: 'WhatsApp Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: openHoursController,
                decoration: const InputDecoration(
                    labelText: 'Open Hours',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Mon-Fri: 8am-6pm, Sat: 9am-5pm'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await SupabaseUtils.client.from('stores').update({
                        'name': nameController.text.trim(),
                        'address': addressController.text.trim(),
                        'phone_number': phoneController.text.trim(),
                        'whatsapp_number': whatsappController.text.trim(),
                        'open_hours': openHoursController.text.trim(),
                        'description': descriptionController.text.trim(),
                      }).eq('id', _store['id']);

                      if (mounted) {
                        setState(() {
                          _store['name'] = nameController.text.trim();
                          _store['address'] = addressController.text.trim();
                          _store['phone_number'] = phoneController.text.trim();
                          _store['whatsapp_number'] =
                              whatsappController.text.trim();
                          _store['description'] =
                              descriptionController.text.trim();
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Store updated!'),
                              backgroundColor: AppTheme.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    XFile? _selectedImage;
    final ImagePicker _imagePicker = ImagePicker();
    bool _isUploading = false;

    Future<String?> _uploadImage() async {
      if (_selectedImage == null) return null;
      try {
        final bytes = await _selectedImage!.readAsBytes();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'store-products/$fileName';

        await SupabaseUtils.client.storage
            .from('artisan-media')
            .uploadBinary(path, bytes);
        return SupabaseUtils.client.storage
            .from('artisan-media')
            .getPublicUrl(path);
      } catch (e) {
        print('Error uploading image: $e');
        return null;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Product',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Image Picker
                GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Choose from Gallery'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final image = await _imagePicker.pickImage(
                                    source: ImageSource.gallery);
                                if (image != null) {
                                  setModalState(() => _selectedImage = image);
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take a Photo'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final image = await _imagePicker.pickImage(
                                    source: ImageSource.camera);
                                if (image != null) {
                                  setModalState(() => _selectedImage = image);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.inputBorder),
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: AppTheme.success),
                              const SizedBox(width: 8),
                              const Text('Image selected'),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 32, color: AppTheme.textTertiary),
                              const SizedBox(height: 4),
                              Text('Tap to add product image',
                                  style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Product Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                            labelText: 'Price (₦)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Product name required')),
                              );
                              return;
                            }

                            setModalState(() => _isUploading = true);

                            try {
                              // Upload image first
                              String? imageUrl;
                              if (_selectedImage != null) {
                                imageUrl = await _uploadImage();
                              }

                              await SupabaseUtils.client
                                  .from('store_products')
                                  .insert({
                                'store_id': _store['id'],
                                'name': nameController.text.trim(),
                                'price': double.tryParse(
                                        priceController.text.trim()) ??
                                    0,
                                'quantity': int.tryParse(
                                        quantityController.text.trim()) ??
                                    1,
                                'description': descController.text.trim(),
                                'image_url': imageUrl,
                                'in_stock': true,
                              });

                              if (mounted) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Product added!'),
                                      backgroundColor: AppTheme.success),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                    child: _isUploading
                        ? const CircularProgressIndicator()
                        : const Text('Add Product'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final nameController = TextEditingController(text: product['name'] ?? '');
    final priceController =
        TextEditingController(text: product['price']?.toString() ?? '0');
    final descController =
        TextEditingController(text: product['description'] ?? '');
    final quantityController =
        TextEditingController(text: product['quantity']?.toString() ?? '1');
    bool inStock = product['in_stock'] == true;
    XFile? _selectedImage;
    final ImagePicker _imagePicker = ImagePicker();
    bool _isUploading = false;
    String? existingImageUrl = product['image_url'];

    Future<String?> _uploadImage() async {
      if (_selectedImage == null) return existingImageUrl;
      try {
        final bytes = await _selectedImage!.readAsBytes();
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'store-products/$fileName';

        await SupabaseUtils.client.storage
            .from('artisan-media')
            .uploadBinary(path, bytes);
        return SupabaseUtils.client.storage
            .from('artisan-media')
            .getPublicUrl(path);
      } catch (e) {
        print('Error uploading image: $e');
        return existingImageUrl;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Product',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.error),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Product?'),
                            content:
                                const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.error),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          try {
                            await SupabaseUtils.client
                                .from('store_products')
                                .delete()
                                .eq('id', product['id']);
                            Navigator.pop(context);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Product deleted!'),
                                  backgroundColor: AppTheme.error),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppTheme.error),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Image Picker
                GestureDetector(
                  onTap: () async {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Choose from Gallery'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final image = await _imagePicker.pickImage(
                                    source: ImageSource.gallery);
                                if (image != null) {
                                  setModalState(() {
                                    _selectedImage = image;
                                    existingImageUrl = null;
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take a Photo'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                final image = await _imagePicker.pickImage(
                                    source: ImageSource.camera);
                                if (image != null) {
                                  setModalState(() {
                                    _selectedImage = image;
                                    existingImageUrl = null;
                                  });
                                }
                              },
                            ),
                            if (existingImageUrl != null ||
                                _selectedImage != null)
                              ListTile(
                                leading: const Icon(Icons.delete,
                                    color: AppTheme.error),
                                title: const Text('Remove Image'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setModalState(() {
                                    _selectedImage = null;
                                    existingImageUrl = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.inputBorder),
                      color: AppTheme.inputFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.success),
                              SizedBox(width: 8),
                              Text('New image selected'),
                            ],
                          )
                        : existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(existingImageUrl!,
                                    fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 32, color: AppTheme.textTertiary),
                                  const SizedBox(height: 4),
                                  Text('Tap to change image',
                                      style: TextStyle(
                                          color: AppTheme.textTertiary,
                                          fontSize: 12)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Product Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                            labelText: 'Price (₦)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // In Stock Toggle
                SwitchListTile(
                  title: const Text('In Stock'),
                  value: inStock,
                  onChanged: (value) => setModalState(() => inStock = value),
                  contentPadding: EdgeInsets.zero,
                ),

                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Product name required')),
                              );
                              return;
                            }

                            setModalState(() => _isUploading = true);

                            try {
                              // Upload image first
                              String? imageUrl = await _uploadImage();

                              await SupabaseUtils.client
                                  .from('store_products')
                                  .update({
                                'name': nameController.text.trim(),
                                'price': double.tryParse(
                                        priceController.text.trim()) ??
                                    0,
                                'quantity': int.tryParse(
                                        quantityController.text.trim()) ??
                                    1,
                                'description': descController.text.trim(),
                                'image_url': imageUrl,
                                'in_stock': inStock,
                              }).eq('id', product['id']);

                              if (mounted) {
                                Navigator.pop(context);
                                _loadData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Product updated!'),
                                      backgroundColor: AppTheme.success),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppTheme.error),
                                );
                              }
                            }
                          },
                    child: _isUploading
                        ? const CircularProgressIndicator()
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addService() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Service',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Service Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                    labelText: 'Price (₦)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service name required')),
                      );
                      return;
                    }

                    try {
                      await SupabaseUtils.client.from('store_services').insert({
                        'store_id': _store['id'],
                        'name': nameController.text.trim(),
                        'price':
                            double.tryParse(priceController.text.trim()) ?? 0,
                        'description': descController.text.trim(),
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Service added!'),
                              backgroundColor: AppTheme.success),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error),
                        );
                      }
                    }
                  },
                  child: const Text('Add Service'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    final commentController = TextEditingController();
    int _selectedRating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Write a Review',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Rating'),
                Row(
                  children: List.generate(
                      5,
                      (i) => IconButton(
                            icon: Icon(
                                i < _selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppTheme.ratingStar),
                            onPressed: () =>
                                setDialogState(() => _selectedRating = i + 1),
                          )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                      labelText: 'Your Review', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await SupabaseUtils.client
                            .from('store_reviews')
                            .insert({
                          'store_id': _store['id'],
                          'rating': _selectedRating,
                          'comment': commentController.text.trim(),
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Review submitted!'),
                                backgroundColor: AppTheme.success),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.error),
                          );
                        }
                      }
                    },
                    child: const Text('Submit Review'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddComplaintDialog() {
    final complaintController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('File a Complaint',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: complaintController,
                decoration: const InputDecoration(
                  labelText: 'Describe your complaint',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  onPressed: () async {
                    if (complaintController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please describe your complaint')),
                      );
                      return;
                    }

                    try {
                      await SupabaseUtils.client
                          .from('store_complaints')
                          .insert({
                        'store_id': _store['id'],
                        'complaint_text': complaintController.text.trim(),
                        'user_name': 'Guest User',
                      });

                      if (mounted) {
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Complaint submitted!'),
                              backgroundColor: AppTheme.warning),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error),
                        );
                      }
                    }
                  },
                  child: const Text('Submit Complaint'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Calculate trust score
  double get _trustScore {
    if (_reviews.isEmpty) return 0;
    final avgRating =
        _reviews.map((r) => r['rating'] as int).reduce((a, b) => a + b) /
            _reviews.length;
    final complaintPenalty =
        _complaints.isNotEmpty ? _complaints.length * 5 : 0;
    return (avgRating * 20 - complaintPenalty).clamp(0, 100);
  }

  // Calculate rating stats
  Map<int, int> get _ratingStats {
    final stats = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var review in _reviews) {
      final rating = review['rating'] as int;
      stats[rating] = (stats[rating] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_store['name'] ?? 'Store'),
          actions: [
            if (!_isOwnerVerified)
              IconButton(
                icon: const Icon(Icons.lock_outline),
                tooltip: 'Edit Profile',
                onPressed: _verifyOwner,
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Store',
                onPressed: _editStoreProfile,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => setState(() => _isOwnerVerified = false),
              ),
            ],
          ],
          bottom: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(fontSize: 7),
            tabs: [
              Tab(text: 'Info'),
              Tab(
                  text:
                      'Products${_products.isNotEmpty ? ' (${_products.length})' : ''}'),
              Tab(
                  text:
                      'Services${_services.isNotEmpty ? ' (${_services.length})' : ''}'),
              Tab(
                  text:
                      'Reviews${_reviews.isNotEmpty ? ' (${_reviews.length})' : ''}'),
              Tab(text: 'Trust'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  // INFO TAB
                  _buildInfoTab(),
                  // PRODUCTS TAB
                  _buildProductsTab(),
                  // SERVICES TAB
                  _buildServicesTab(),
                  // REVIEWS TAB
                  _buildReviewsTab(),
                  // TRUST TAB
                  _buildTrustTab(),
                ],
              ),
        bottomNavigationBar: const CustomBottomAppBar(),
      ),
    );
  }

  Widget _buildInfoTab() {
    final categoryStr = (_store['category']?.toString() ?? '').toLowerCase();
    final isSupplier = categoryStr.contains('supplier');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit button for owner
          if (_isOwnerVerified)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _editStoreProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Store Info'),
              ),
            ),
          // Store Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSupplier ? AppTheme.primary : AppTheme.warning,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSupplier ? 'Supplier' : 'Store',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // Category
          if (_store['category'] != null) ...[
            Text('Category',
                style: AppTheme.titleSmall
                    .copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(_store['category'] ?? '',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
          ],

          // Phone Number
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.success),
              title: const Text('Phone'),
              subtitle: Text(
                  _store['phone_number'] ?? _store['phone'] ?? 'Not provided'),
              trailing: IconButton(
                icon: const Icon(Icons.call),
                onPressed: _makePhoneCall,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // WhatsApp
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat, color: AppTheme.success),
              title: const Text('WhatsApp'),
              subtitle: Text(_store['whatsapp_number'] ?? 'Not provided'),
              trailing: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _openWhatsApp,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Location
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: AppTheme.error),
              title: const Text('Address'),
              subtitle: Text(
                  '${_store['address'] ?? ''}, ${_store['city'] ?? ''}, ${_store['state'] ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.directions),
                onPressed: () {
                  // Open maps
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // CAC Number
          if (_store['cac_number'] != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.business),
                title: const Text('CAC Number'),
                subtitle: Text(_store['cac_number'] ?? ''),
              ),
            ),
          const SizedBox(height: 8),

          // Facebook
          if (_store['facebook_handle'] != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.facebook, color: AppTheme.info),
                title: const Text('Facebook'),
                subtitle: Text(_store['facebook_handle'] ?? ''),
              ),
            ),
          const SizedBox(height: 8),

          // Delivery
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.local_shipping, color: AppTheme.info),
              title: const Text('Delivery Available'),
              subtitle: Text(_store['can_deliver'] == true
                  ? 'Yes, this store delivers'
                  : 'No delivery'),
              value: _store['can_deliver'] == true,
              onChanged: _isOwnerVerified
                  ? (value) async {
                      try {
                        await SupabaseUtils.client.from('stores').update(
                            {'can_deliver': value}).eq('id', _store['id']);
                        setState(() => _store['can_deliver'] = value);
                      } catch (e) {
                        print('Error updating delivery: $e');
                      }
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          // Open Hours
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Open Hours'),
              subtitle: Text(_store['open_hours'] ?? 'Not specified'),
            ),
          ),
          const SizedBox(height: 8),

          // Description
          if (_store['description'] != null) ...[
            const Text('About',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_store['description'] ?? '',
                style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        if (_isOwnerVerified)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
        Expanded(
          child: _products.isEmpty
              ? const Center(child: Text('No products yet'))
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return GestureDetector(
                      onTap:
                          _isOwnerVerified ? () => _editProduct(product) : null,
                      child: Card(
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: product['image_url'] != null
                                        ? GestureDetector(
                                            onTap: () => _showEnlargedImage(
                                                context, product['image_url']),
                                            child: Image.network(
                                                product['image_url'],
                                                fit: BoxFit.cover,
                                                width: double.infinity),
                                          )
                                        : Container(
                                            color: AppTheme.inputFill,
                                            child: const Icon(
                                                Icons.shopping_bag,
                                                size: 40),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(product['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.5)),
                                  Text(
                                      '₦${(product['price'] ?? 0).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.5)),
                                  Text(
                                      product['in_stock'] == true
                                          ? 'In Stock'
                                          : 'Out of Stock',
                                      style: TextStyle(
                                          color: product['in_stock'] == true
                                              ? AppTheme.success
                                              : AppTheme.error,
                                          fontSize: 9)),
                                  if (product['quantity'] != null)
                                    Text('Qty: ${product['quantity']}',
                                        style: const TextStyle(fontSize: 9)),
                                ],
                              ),
                            ),
                            if (_isOwnerVerified)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: AppTheme.warning,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.edit,
                                      size: 16, color: Colors.white),
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

  Widget _buildServicesTab() {
    return Column(
      children: [
        if (_isOwnerVerified)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Add Service'),
            ),
          ),
        Expanded(
          child: _services.isEmpty
              ? const Center(child: Text('No services yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.build)),
                        title: Text(service['name'] ?? ''),
                        subtitle: Text(service['description'] ?? ''),
                        trailing: Text(
                            '₦${(service['price'] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: _showAddReviewDialog,
            icon: const Icon(Icons.rate_review),
            label: const Text('Write a Review'),
          ),
        ),
        // Rating summary
        if (_reviews.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                    _reviews.isEmpty
                        ? '0'
                        : (_reviews
                                    .map((r) => r['rating'] as int)
                                    .reduce((a, b) => a + b) /
                                _reviews.length)
                            .toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        children: List.generate(
                            5,
                            (i) => Icon(Icons.star,
                                color: AppTheme.ratingStar, size: 16))),
                    Text('${_reviews.length} reviews'),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: _reviews.isEmpty
              ? const Center(child: Text('No reviews yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text((review['user_name'] ?? 'U')[0]
                              .toString()
                              .toUpperCase()),
                        ),
                        title: Row(
                          children: [
                            Text(review['user_name'] ?? 'User'),
                            const SizedBox(width: 8),
                            Row(
                                children: List.generate(
                                    5,
                                    (i) => Icon(
                                        i < (review['rating'] ?? 5)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: AppTheme.ratingStar,
                                        size: 14))),
                          ],
                        ),
                        subtitle: Text(review['comment'] ?? ''),
                        trailing: review['is_verified_buyer'] == true
                            ? const Icon(Icons.verified,
                                color: AppTheme.info, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrustTab() {
    final totalComplaints = _complaints.length;
    final resolvedComplaints =
        _complaints.where((c) => c['status'] == 'resolved').length;
    final pendingComplaints =
        _complaints.where((c) => c['status'] == 'pending').length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trust Score Card
        Card(
          color: _trustScore >= 80
              ? AppTheme.success
              : _trustScore >= 50
                  ? AppTheme.warning
                  : AppTheme.error,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('${_trustScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Text('Trust Score',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Rating Distribution
        const Text('Rating Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...[5, 4, 3, 2, 1].map((rating) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('$rating '),
                  const Icon(Icons.star, color: AppTheme.ratingStar, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _reviews.isEmpty
                          ? 0
                          : (_ratingStats[rating] ?? 0) / _reviews.length,
                      backgroundColor: AppTheme.inputFill,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_ratingStats[rating] ?? 0}'),
                ],
              ),
            )),

        const Divider(height: 32),

        // Complaints Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Complaints',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _showAddComplaintDialog,
              icon: const Icon(Icons.warning, color: AppTheme.error),
              label: const Text('Report Issue'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: AppTheme.error),
                title: const Text('Total Complaints'),
                trailing: Text('$totalComplaints',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.check_circle, color: AppTheme.success),
                title: const Text('Resolved'),
                trailing: Text('$resolvedComplaints'),
              ),
              ListTile(
                leading: const Icon(Icons.pending, color: AppTheme.warning),
                title: const Text('Pending'),
                trailing: Text('$pendingComplaints'),
              ),
            ],
          ),
        ),

        const Divider(height: 32),

        // Store Info
        const Text('Store Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Phone'),
                subtitle: Text(_store['phone_number'] ??
                    _store['phone'] ??
                    'Not provided'),
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: AppTheme.success),
                  onPressed: _makePhoneCall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: AppTheme.success),
                title: const Text('WhatsApp'),
                subtitle: Text(_store['whatsapp_number'] ?? 'Not provided'),
                trailing: IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.success),
                  onPressed: _openWhatsApp,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Address'),
                subtitle: Text(
                    '${_store['address'] ?? ''}, ${_store['city'] ?? ''}, ${_store['state'] ?? ''}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
