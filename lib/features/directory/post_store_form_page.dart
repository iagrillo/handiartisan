import 'package:flutter/material.dart';
import '../utils/supabase.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../ui/app_theme.dart';

class PostStoreFormPage extends StatefulWidget {
  final String? initialType;

  const PostStoreFormPage({Key? key, this.initialType}) : super(key: key);

  @override
  State<PostStoreFormPage> createState() => _PostStoreFormPageState();
}

class _PostStoreFormPageState extends State<PostStoreFormPage> {
  String? _selectedState;
  String? _selectedCity;
  List<String> _states = [];
  List<String> _cities = [];
  Map<String, List<String>> _stateCityMap = {};
  bool _isLoadingLocations = true;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController otherCategoryController = TextEditingController();

  // Selected type: Store or Supplier
  String _selectedType = 'store';
  
  // Selected categories (multi-select)
  final List<String> _selectedCategories = [];
  
  // Show other category text field
  bool _showOtherCategory = false;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;

  // Nigeria-focused categories
  final List<String> _categories = [
    'Groceries',
    'Farm Produce',
    'Building Materials',
    'Electronics',
    'Fashion & Clothing',
    'Household Items',
    'Beverages',
    'Cosmetics & Beauty',
    'Pharmaceuticals',
    'Stationery',
    'Hardware Tools',
    'General Merchandise',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'store';
    _loadLocations();
  }

  @override
  void dispose() {
    businessNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    descriptionController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLG,
            AppTheme.spaceSM,
            AppTheme.spaceLG,
            AppTheme.spaceLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceBase),
              Text('Store images', style: AppTheme.headline3),
              const SizedBox(height: AppTheme.spaceXXS),
              Text(
                'Add gallery images for your store or supplier listing.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceBase),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final images = await _imagePicker.pickMultiImage();
                  if (images.isNotEmpty) {
                    setState(() {
                      _selectedImages.addAll(images);
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _imagePicker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _selectedImages.add(image);
                    });
                  }
                },
              ),
              if (_selectedImages.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: AppTheme.error),
                  title: const Text('Clear All Images'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImages.clear();
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _selectedImages) {
      try {
        final bytes = await image.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final path = 'store-images/$fileName';
        
        await SupabaseUtils.client.storage.from('artisan-media').uploadBinary(path, bytes);
        final url = SupabaseUtils.client.storage.from('artisan-media').getPublicUrl(path);
        imageUrls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
    return imageUrls;
  }

  Future<void> _loadLocations() async {
    try {
      // Fetch states from Supabase
      final statesResponse = await SupabaseUtils.client
          .from('states')
          .select('name')
          .order('name');
      
      final statesList = (statesResponse as List)
          .map((e) => e['name'] as String)
          .toList();

      // Fetch cities from Supabase
      final citiesResponse = await SupabaseUtils.client
          .from('cities')
          .select('name,state_id,states!inner(name)')
          .order('name');

      final Map<String, List<String>> cityMap = {};
      final List<String> allCities = [];

      for (final cityData in citiesResponse) {
        final cityName = cityData['name'] as String;
        final stateName = cityData['states']?['name'] as String?;
        
        allCities.add(cityName);
        if (stateName != null) {
          cityMap.putIfAbsent(stateName, () => []).add(cityName);
        }
      }

      if (mounted) {
        setState(() {
          _states = statesList;
          _cities = allCities;
          _stateCityMap = cityMap;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
      // Fallback to default values
      if (mounted) {
        setState(() {
          _states = ['Lagos', 'Abuja', 'Kano', 'Ogun', 'Oyo', 'Osun', 'Ondo', 'Edo', 'Delta', 'Rivers'];
          _cities = ['Ikeja', 'Lekki', 'Victoria Island', 'Abuja', 'Kano'];
          _stateCityMap = {
            'Lagos': ['Ikeja', 'Lekki', 'Victoria Island', 'Apapa', 'Yaba'],
            'Abuja': ['Gwagwalada', 'Kuje', 'Bwari'],
          };
          _isLoadingLocations = false;
        });
      }
    }
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      _cities = _stateCityMap[state] ?? [];
    });
  }

  void _onCategoryChanged(String category, bool selected) {
    setState(() {
      if (category == 'Other') {
        _showOtherCategory = selected;
        if (!selected) {
          otherCategoryController.clear();
        }
      }
      
      if (selected) {
        if (!_selectedCategories.contains(category)) {
          _selectedCategories.add(category);
        }
      } else {
        _selectedCategories.remove(category);
      }
    });
  }

  String _getCategoriesString() {
    List<String> cats = List.from(_selectedCategories);
    if (_showOtherCategory && otherCategoryController.text.isNotEmpty) {
      final index = cats.indexOf('Other');
      if (index != -1) {
        cats[index] = 'Other (${otherCategoryController.text})';
      }
    }
    return cats.join(', ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a state'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a city'), backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Upload images first if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploading = true);
        imageUrls = await _uploadImages();
        setState(() => _isUploading = false);
      }

      // Insert into stores table
      final typeLabel = _selectedType == 'store' ? 'Store' : 'Supplier';
      final fullDescription = '$typeLabel - ${_getCategoriesString()}${descriptionController.text.trim().isNotEmpty ? '\n\n' + descriptionController.text.trim() : ''}\n\n📱 ${phoneController.text.trim()}${whatsappController.text.trim().isNotEmpty ? '\n💬 ' + whatsappController.text.trim() : ''}';
      
      await SupabaseUtils.client.from('stores').insert({
        'name': businessNameController.text.trim(),
        'state': _selectedState,
        'city': _selectedCity,
        'address': addressController.text.trim(),
        'category': _getCategoriesString(),
        'description': fullDescription,
        'status': 'approved',
        'phone_number': phoneController.text.trim(),
        'whatsapp_number': whatsappController.text.trim(),
        'password_hash': passwordController.text.trim(),
        if (imageUrls.isNotEmpty) 'logo_url': imageUrls.first,
        if (imageUrls.length > 1) 'image_urls': imageUrls,
      });

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedType == 'store' ? 'Store' : 'Supplier'} registered successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedType == 'store' ? 'Register Store' : 'Register Supplier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Register As Store/Supplier toggle
                    Text(
                      'Register As',
                      style: AppTheme.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedType = 'store'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedType == 'store' 
                                    ? AppTheme.primary 
                                    : AppTheme.inputFill,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                border: Border.all(
                                  color: _selectedType == 'store' 
                                      ? AppTheme.primary 
                                      : AppTheme.inputBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.store,
                                    color: _selectedType == 'store' 
                                        ? Colors.white 
                                        : AppTheme.textPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spaceSM),
                                  Text(
                                    'Store',
                                    style: AppTheme.labelLarge.copyWith(
                                      color: _selectedType == 'store' 
                                          ? Colors.white 
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedType = 'supplier'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _selectedType == 'supplier' 
                                    ? AppTheme.primary 
                                    : AppTheme.inputFill,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                border: Border.all(
                                  color: _selectedType == 'supplier' 
                                      ? AppTheme.primary 
                                      : AppTheme.inputBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    color: _selectedType == 'supplier' 
                                        ? Colors.white 
                                        : AppTheme.textPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppTheme.spaceSM),
                                  Text(
                                    'Supplier',
                                    style: AppTheme.labelLarge.copyWith(
                                      color: _selectedType == 'supplier' 
                                          ? Colors.white 
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Business Name
                    _buildLabel('Business Name'),
                    TextFormField(
                      controller: businessNameController,
                      decoration: _inputDecoration('Enter your business name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v == null || v.trim().isEmpty 
                          ? 'Business name is required' 
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // Store Images
                    _buildLabel('Store Images (Optional)'),
                    const SizedBox(height: AppTheme.spaceSM),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.inputBorder),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          color: AppTheme.inputFill,
                        ),
                        child: _selectedImages.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: AppTheme.textTertiary),
                                  const SizedBox(height: AppTheme.spaceSM),
                                  Text(
                                    'Tap to add images',
                                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(AppTheme.spaceSM),
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        margin: const EdgeInsets.only(right: AppTheme.spaceSM),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                          image: DecorationImage(
                                            image: FileImage(File(_selectedImages[index].path)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(AppTheme.spaceXS),
                                            decoration: const BoxDecoration(
                                              color: AppTheme.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // What Do You Sell or Supply? (Multi-select)
                    _buildLabel('What Do You Sell or Supply?'),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.inputBorder),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Column(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategories.contains(category);
                          return CheckboxListTile(
                            title: Text(category, style: AppTheme.bodySmall.copyWith(fontSize: 13)),
                            value: isSelected,
                            onChanged: (selected) => _onCategoryChanged(category, selected ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSM),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    // Other category text field
                    if (_showOtherCategory) ...[
                      const SizedBox(height: AppTheme.spaceSM),
                      TextFormField(
                        controller: otherCategoryController,
                        decoration: _inputDecoration('Specify other category'),
                        validator: (v) => _showOtherCategory && (v == null || v.trim().isEmpty) 
                            ? 'Please specify your category' 
                            : null,
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceBase),

                    // State
                    _buildLabel('State'),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      items: _states.map((state) => DropdownMenuItem(
                        value: state, 
                        child: Text(state, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: _isLoadingLocations ? null : (val) => _onStateChanged(val),
                      decoration: _inputDecoration('Select state'),
                      validator: (v) => v == null || v.isEmpty ? 'State is required' : null,
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // City
                    _buildLabel('City'),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      items: _cities.map((city) => DropdownMenuItem(
                        value: city, 
                        child: Text(city, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: _isLoadingLocations ? null : (val) => setState(() => _selectedCity = val),
                      decoration: _inputDecoration('Select city'),
                      validator: (v) => v == null || v.isEmpty ? 'City is required' : null,
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // Full Address
                    _buildLabel('Full Address'),
                    TextFormField(
                      controller: addressController,
                      decoration: _inputDecoration('Enter your full address'),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => v == null || v.trim().isEmpty 
                          ? 'Address is required' 
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // Phone Number
                    _buildLabel('Phone Number'),
                    TextFormField(
                      controller: phoneController,
                      decoration: _inputDecoration('Enter your phone number'),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (v.trim().length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // WhatsApp Number
                    _buildLabel('WhatsApp Number (Optional)'),
                    TextFormField(
                      controller: whatsappController,
                      decoration: _inputDecoration('Enter your WhatsApp number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // Description
                    _buildLabel('More Info About Your Business (Optional)'),
                    TextFormField(
                      controller: descriptionController,
                      decoration: _inputDecoration('Tell us more about your business...'),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // Password
                    _buildLabel('Password'),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                        filled: true,
                        fillColor: AppTheme.inputFill,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textTertiary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Password is required';
                        }
                        if (v.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceBase),

                    // Confirm Password
                    _buildLabel('Confirm Password'),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        hintText: 'Confirm your password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                        filled: true,
                        fillColor: AppTheme.inputFill,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textTertiary,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v.trim() != passwordController.text.trim()) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space2XL),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                          ),
                          elevation: 0,
                        ),
                        child: _loading 
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _selectedType == 'store' 
                                    ? 'Register Store' 
                                    : 'Register Supplier',
                                style: AppTheme.labelLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Text(
        text,
        style: AppTheme.labelLarge,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
      filled: true,
      fillColor: AppTheme.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceBase, vertical: 14),
    );
  }
}
