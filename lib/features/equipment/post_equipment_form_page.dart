import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../ui/app_theme.dart';

class PostEquipmentFormPage extends StatefulWidget {
  const PostEquipmentFormPage({Key? key}) : super(key: key);

  @override
  State<PostEquipmentFormPage> createState() => _PostEquipmentFormPageState();
}

class _PostEquipmentFormPageState extends State<PostEquipmentFormPage> {
  String? _selectedType;
  String? _selectedState;
  String? _selectedCity;
  List<String> _states = [];
  List<String> _cities = [];
  Map<String, List<String>> _stateCityMap = {};
  bool _isLoadingLocations = true;

  // Types: Sale, Rental, Services, Parts
  final List<String> _types = ['Sale', 'Rental', 'Services', 'Parts'];

  // Parts categories
  final List<String> _partsCategories = [
    'Heavy Equipment Parts',
    'Power Tools Parts',
    'Electrical Parts',
    'Hydraulics',
    'Engines',
    'Attachments',
    'Consumables',
    'Other'
  ];

  // Parts sub-categories based on selected category
  final Map<String, List<String>> _partsSubCategories = {
    'Heavy Equipment Parts': [
      'Undercarriage',
      'Hydraulic System',
      'Engine Components',
      'Transmission',
      'Electrical',
      'Body Parts',
      'Other'
    ],
    'Power Tools Parts': [
      'Motors',
      'Batteries',
      'Chargers',
      'Switches',
      'Bearings',
      'Accessories',
      'Other'
    ],
    'Electrical Parts': [
      'Alternators',
      'Starters',
      'Sensors',
      'Wiring Harnesses',
      'Control Panels',
      'Other'
    ],
    'Hydraulics': ['Pumps', 'Cylinders', 'Valves', 'Hoses', 'Motors', 'Other'],
    'Engines': [
      'Pistons',
      'Crankshaft',
      'Cylinder Head',
      'Turbocharger',
      'Fuel System',
      'Other'
    ],
    'Attachments': [
      'Buckets',
      'Breakers',
      'Augers',
      'Forks',
      'Grapples',
      'Other'
    ],
    'Consumables': [
      'Filters',
      'Belts',
      'Hoses',
      'Seals',
      'Bearings',
      'Lubricants',
      'Other'
    ],
    'Other': ['Other'],
  };

  // Categories: Heavy Equipment or Power Tools
  final List<String> _categories = ['Heavy Equipment', 'Power Tools'];

  // Rental periods
  final List<String> _rentalPeriods = ['Hour', 'Day', 'Week'];

  // Price types for sales
  final List<String> _priceTypes = ['Firm', 'Negotiable'];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController specsController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController rentalRateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contactNameController = TextEditingController();
  final TextEditingController contactPhoneController = TextEditingController();
  // Parts-specific controllers
  final TextEditingController partNumberController = TextEditingController();
  final TextEditingController compatibleWithController =
      TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  String? _selectedCategory;
  String? _selectedRentalPeriod;
  String? _selectedPriceType;
  String? _selectedPartsCategory;
  String? _selectedPartsSubCategory;
  bool _partsInStock = true;
  bool _loading = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;

  // Services specific - service types
  bool _serviceMaintenance = false;
  bool _serviceRepair = false;
  bool _serviceInstallation = false;
  bool _serviceDiagnostics = false;

  // Services specific - mobility
  String _mobility = 'both'; // 'mobile', 'workshop', 'both'

  Future<void> _pickImages(BuildContext context) async {
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
                final images = await _imagePicker.pickMultiImage();
                if (images.isNotEmpty) {
                  setState(() {
                    _selectedImages.addAll(images);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final image =
                    await _imagePicker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _selectedImages.add(image);
                  });
                }
              },
            ),
            if (_selectedImages.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.error),
                title: const Text('Clear All Images'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImages.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _selectedImages) {
      try {
        final bytes = await image.readAsBytes();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final path = 'equipment-images/$fileName';

        await Supabase.instance.client.storage
            .from('artisan-media')
            .uploadBinary(path, bytes);
        final url = Supabase.instance.client.storage
            .from('artisan-media')
            .getPublicUrl(path);
        imageUrls.add(url);
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
    return imageUrls;
  }

  // Helper to get subcategories for selected parts category
  List<String> get _currentSubCategories {
    if (_selectedPartsCategory == null) return [];
    return _partsSubCategories[_selectedPartsCategory] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final statesResponse = await Supabase.instance.client
          .from('states')
          .select('name')
          .order('name');

      if (statesResponse == null || (statesResponse as List).isEmpty) {
        _useDefaultLocations();
        return;
      }

      final statesList =
          (statesResponse as List).map((e) => e['name'] as String).toList();

      final citiesResponse = await Supabase.instance.client
          .from('cities')
          .select('name,state_id,states!inner(name)')
          .order('name');

      final Map<String, List<String>> cityMap = {};
      final List<String> allCities = [];

      if (citiesResponse != null && (citiesResponse as List).isNotEmpty) {
        for (final cityData in citiesResponse) {
          final cityName = cityData['name'] as String;
          final stateName = cityData['states']?['name'] as String?;

          allCities.add(cityName);
          if (stateName != null) {
            cityMap.putIfAbsent(stateName, () => []).add(cityName);
          }
        }
      }

      if (mounted) {
        setState(() {
          _states = statesList;
          _cities = allCities.isNotEmpty ? allCities : _getDefaultCities();
          _stateCityMap = cityMap;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
      _useDefaultLocations();
    }
  }

  List<String> _getDefaultCities() {
    return [
      'Ikeja',
      'Lekki',
      'Victoria Island',
      'Abuja',
      'Kano',
      'Ibadan',
      'Port Harcourt',
      'Benin City',
      'Enugu',
      'Abeokuta',
      'Warri',
      'Jos'
    ];
  }

  void _useDefaultLocations() {
    if (mounted) {
      setState(() {
        _states = [
          'Lagos',
          'Abuja',
          'Kano',
          'Ogun',
          'Oyo',
          'Osun',
          'Ondo',
          'Edo',
          'Delta',
          'Rivers',
          'Kaduna',
          'Plateau',
          'Enugu'
        ];
        _cities = _getDefaultCities();
        _stateCityMap = {
          'Lagos': [
            'Ikeja',
            'Lekki',
            'Victoria Island',
            'Apapa',
            'Yaba',
            'Surulere',
            'Ikoyi'
          ],
          'Abuja': ['Gwagwalada', 'Kuje', 'Bwari', 'Kubwa'],
          'Kano': ['Kano'],
          'Ogun': ['Abeokuta'],
          'Oyo': ['Ibadan'],
          'Rivers': ['Port Harcourt'],
          'Edo': ['Benin City'],
          'Delta': ['Warri'],
          'Plateau': ['Jos'],
          'Enugu': ['Enugu'],
        };
        _isLoadingLocations = false;
      });
    }
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      _cities = _stateCityMap[state] ?? _getDefaultCities();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one image'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Sale, Rental, or Services')),
      );
      return;
    }
    if (_selectedType == 'Rental' && _selectedRentalPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select rental period')),
      );
      return;
    }
    if (_selectedType == 'Sale' && _selectedPriceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select price type (Firm/Negotiable)')),
      );
      return;
    }
    // For Services type, require contact phone
    if (_selectedType == 'Services' &&
        contactPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter contact number for your service')),
      );
      return;
    }
    // For Services type, require at least one service type
    if (_selectedType == 'Services' &&
        !_serviceMaintenance &&
        !_serviceRepair &&
        !_serviceInstallation &&
        !_serviceDiagnostics) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one service type')),
      );
      return;
    }
    // For Parts type, require contact phone
    if (_selectedType == 'Parts' &&
        contactPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter contact number for your parts')),
      );
      return;
    }
    if (_selectedState == null || _selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select state and city')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Upload images first
      List<String> imageUrls = [];
      setState(() => _isUploading = true);
      imageUrls = await _uploadImages();
      setState(() => _isUploading = false);

      // Build description with contact info
      String description = '';
      if (descriptionController.text.trim().isNotEmpty) {
        description = descriptionController.text.trim();
      }
      if (contactNameController.text.trim().isNotEmpty) {
        description += '\n\nContact: ${contactNameController.text.trim()}';
      }
      if (contactPhoneController.text.trim().isNotEmpty) {
        description += '\nPhone: ${contactPhoneController.text.trim()}';
      }

      // For rental, combine price and rate
      String price = priceController.text.trim();
      if (_selectedType == 'Rental' &&
          rentalRateController.text.trim().isNotEmpty) {
        price =
            '${rentalRateController.text.trim()} / ${_selectedRentalPeriod}';
      }

      // Build insert data
      Map<String, dynamic> insertData = {
        'name': nameController.text.trim(),
        'category': _selectedCategory ?? 'Heavy Equipment',
        'brand': brandController.text.trim().isNotEmpty
            ? brandController.text.trim()
            : null,
        'specs': specsController.text.trim(),
        'price': _selectedType == 'Services' ? 'Services' : price,
        'type': _selectedType,
        'state': _selectedState,
        'city': _selectedCity,
        'description': description.isNotEmpty ? description : null,
        'contact_name': contactNameController.text.trim().isNotEmpty
            ? contactNameController.text.trim()
            : null,
        'contact_phone': contactPhoneController.text.trim().isNotEmpty
            ? contactPhoneController.text.trim()
            : null,
        'rental_period':
            _selectedType == 'Rental' ? _selectedRentalPeriod : null,
        'rental_rate':
            _selectedType == 'Rental' ? rentalRateController.text.trim() : null,
        'price_type': _selectedType == 'Sale' ? _selectedPriceType : null,
        'status': 'approved',
        'image_url': imageUrls.isNotEmpty ? imageUrls.first : null,
      };

      // For Services type, insert into services table instead
      if (_selectedType == 'Services') {
        final serviceResponse =
            await Supabase.instance.client.from('services').insert({
          'name': nameController.text.trim(),
          'contact_number': contactPhoneController.text.trim().isNotEmpty
              ? contactPhoneController.text.trim()
              : null,
          'email': null,
          'state': _selectedState,
          'city': _selectedCity,
          'address': descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
          'power_tools_drills': _selectedCategory == 'Power Tools',
          'power_tools_grinders': false,
          'power_tools_saws': false,
          'power_tools_sanders': false,
          'power_tools_welding': false,
          'power_tools_other': null,
          'heavy_equipment_generators': _selectedCategory == 'Heavy Equipment',
          'heavy_equipment_compressors': false,
          'heavy_equipment_excavators': false,
          'heavy_equipment_forklifts': false,
          'heavy_equipment_bulldozers': false,
          'heavy_equipment_other': null,
          'service_maintenance': _serviceMaintenance,
          'service_repair': _serviceRepair,
          'service_installation': _serviceInstallation,
          'service_diagnostics': _serviceDiagnostics,
          'mobility': _mobility,
          'experience_summary': specsController.text.trim().isNotEmpty
              ? specsController.text.trim()
              : null,
          'certifications': brandController.text.trim().isNotEmpty
              ? brandController.text.trim()
              : null,
          'status': 'approved',
        }).select();

        setState(() => _loading = false);

        if (serviceResponse != null && (serviceResponse as List).isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service registered successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to register service');
        }
        return;
      }

      // For Parts type, insert into parts table instead
      if (_selectedType == 'Parts') {
        final partsResponse =
            await Supabase.instance.client.from('parts').insert({
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
          'category': _selectedPartsCategory ?? 'Other',
          'sub_category': _selectedPartsSubCategory,
          'brand': brandController.text.trim().isNotEmpty
              ? brandController.text.trim()
              : null,
          'model': specsController.text.trim().isNotEmpty
              ? specsController.text.trim()
              : null,
          'part_number': partNumberController.text.trim().isNotEmpty
              ? partNumberController.text.trim()
              : null,
          'compatible_with': compatibleWithController.text.trim().isNotEmpty
              ? compatibleWithController.text.trim()
              : null,
          'price': priceController.text.trim().isNotEmpty
              ? priceController.text.trim()
              : null,
          'price_type': _selectedPriceType ?? 'Firm',
          'state': _selectedState,
          'city': _selectedCity,
          'contact_name': contactNameController.text.trim().isNotEmpty
              ? contactNameController.text.trim()
              : null,
          'contact_phone': contactPhoneController.text.trim().isNotEmpty
              ? contactPhoneController.text.trim()
              : null,
          'in_stock': _partsInStock,
          'quantity': quantityController.text.trim().isNotEmpty
              ? int.tryParse(quantityController.text.trim())
              : null,
          'status': 'approved',
        }).select();

        setState(() => _loading = false);

        if (partsResponse != null && (partsResponse as List).isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Parts posted successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to register parts');
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('equipment')
          .insert(insertData)
          .select();

      setState(() => _loading = false);

      if (response != null && (response as List).isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Equipment posted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Equipment posted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _loading = false);
      print('Exception posting equipment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Equipment', style: TextStyle(fontSize: 10)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceBase - 6),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sale or Rental Toggle
                    const Text('Post Type *',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildTypeButton('Sale'),
                        _buildTypeButton('Rental'),
                        _buildTypeButton('Services'),
                        _buildTypeButton('Parts'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Equipment Images
                    const Text('Equipment Images *',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _pickImages(context),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.inputBorder),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                          color: AppTheme.inputFill,
                        ),
                        child: _selectedImages.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 40, color: AppTheme.textTertiary),
                                  const SizedBox(height: AppTheme.spaceSM),
                                  Text(
                                    'Tap to add images',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(File(
                                                _selectedImages[index].path)),
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
                                            padding: const EdgeInsets.all(
                                                AppTheme.spaceXS),
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
                    const SizedBox(height: 10),

                    // Category Dropdown
                    const Text('Category *',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat,
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),

                    // Equipment Name
                    const Text('Equipment Name *',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Concrete Pump, Generator',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        isDense: true,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),

                    // Brand (Optional)
                    const Text('Brand Name',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: brandController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., CAT, Komatsu, Honda (Optional)',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Specifications
                    const Text('Specifications *',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: specsController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 50m boom, 100KVA, 20 ton',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16),

                    // Price Section - Different for Sale vs Rental vs Services
                    if (_selectedType == 'Services') ...[
                      // Service capabilities section
                      Text('Service Capabilities *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                      const SizedBox(height: 4),
                      SizedBox(height: 8),
                      Text(
                          'Category: ' +
                              (_selectedCategory ?? 'Heavy Equipment'),
                          style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),

                      // Service Types - Interactive
                      Text('Service Type:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Maintenance'),
                            selected: _serviceMaintenance,
                            onSelected: (val) =>
                                setState(() => _serviceMaintenance = val),
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                          ),
                          FilterChip(
                            label: const Text('Repair'),
                            selected: _serviceRepair,
                            onSelected: (val) =>
                                setState(() => _serviceRepair = val),
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                          ),
                          FilterChip(
                            label: const Text('Installation'),
                            selected: _serviceInstallation,
                            onSelected: (val) =>
                                setState(() => _serviceInstallation = val),
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                          ),
                          FilterChip(
                            label: const Text('Diagnostics'),
                            selected: _serviceDiagnostics,
                            onSelected: (val) =>
                                setState(() => _serviceDiagnostics = val),
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Mobility - Interactive
                      Text('Mobility *',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Mobile'),
                            selected: _mobility == 'mobile',
                            onSelected: (_) =>
                                setState(() => _mobility = 'mobile'),
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                          ),
                          FilterChip(
                            label: const Text('Workshop'),
                            selected: _mobility == 'workshop',
                            onSelected: (_) =>
                                setState(() => _mobility = 'workshop'),
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                          ),
                          FilterChip(
                            label: const Text('Both'),
                            selected: _mobility == 'both',
                            onSelected: (_) =>
                                setState(() => _mobility = 'both'),
                            selectedColor: AppTheme.primary.withOpacity(0.2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Experience Summary
                      Text('Experience Summary',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: specsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Describe your expertise and experience...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Certifications
                      Text('Certifications / Training',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: brandController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Any certifications or training...',
                        ),
                      ),
                    ] else if (_selectedType == 'Parts') ...[
                      // Parts-specific section
                      Text('Parts Category *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedPartsCategory,
                        items: _partsCategories
                            .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat,
                                    style: const TextStyle(fontSize: 11))))
                            .toList(),
                        onChanged: (val) => setState(() {
                          _selectedPartsCategory = val;
                          _selectedPartsSubCategory = null;
                        }),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                          hintText: 'Select parts category',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sub-category
                      if (_selectedPartsCategory != null) ...[
                        Text('Sub-Category',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedPartsSubCategory,
                          items: _currentSubCategories
                              .map((sub) => DropdownMenuItem(
                                  value: sub,
                                  child: Text(sub,
                                      style: const TextStyle(fontSize: 11))))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedPartsSubCategory = val),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                            hintText: 'Select sub-category',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Part Number
                      Text('Part Number',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: partNumberController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'e.g., ABC-12345 (Optional)',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Compatible With
                      Text('Compatible With',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: compatibleWithController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'e.g., CAT 320 Excavator, Honda GX390 (Optional)',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // In Stock Toggle
                      Row(
                        children: [
                          Text('In Stock:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Switch(
                            value: _partsInStock,
                            onChanged: (val) =>
                                setState(() => _partsInStock = val),
                            activeColor: AppTheme.primary,
                          ),
                          Text(_partsInStock ? 'Yes' : 'No'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quantity
                      if (_partsInStock) ...[
                        Text('Quantity Available',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Number of units (Optional)',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Price for Parts
                      Text('Price *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Amount',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedPriceType,
                              items: _priceTypes
                                  .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 10))))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedPriceType = val),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ] else if (_selectedType == 'Rental') ...[
                      Text('Rental Rate *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10)),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: rentalRateController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Amount',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedRentalPeriod,
                              items: _rentalPeriods
                                  .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 10))))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedRentalPeriod = val),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text('Price *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10)),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Amount',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedPriceType,
                              items: _priceTypes
                                  .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 10))))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedPriceType = val),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                isDense: true,
                              ),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 16),

                    // Contact Name
                    Text('Contact Name *',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10)),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: contactNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Your name or business name',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16),

                    // Contact Phone
                    Text('Contact Phone *',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10)),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: contactPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 08012345678',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 16),

                    // Description
                    Text('Additional Description',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10)),
                    SizedBox(height: 6),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Any additional details about the equipment',
                      ),
                    ),
                    SizedBox(height: 16),

                    // State and City
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('State *',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10)),
                              SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedState,
                                isExpanded: true,
                                items: _states
                                    .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: _isLoadingLocations
                                    ? null
                                    : (val) => _onStateChanged(val),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('City *',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10)),
                              SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _selectedCity,
                                isExpanded: true,
                                items: _cities
                                    .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c,
                                            overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: _isLoadingLocations
                                    ? null
                                    : (val) =>
                                        setState(() => _selectedCity = val),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v == null ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.surface,
                        ),
                        child: Text(
                          _loading ? 'Posting...' : 'Post Equipment',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeButton(String type) {
    final isSelected = _selectedType == type;
    Color buttonColor;
    Color borderColor;
    if (type == 'Services') {
      buttonColor = isSelected ? AppTheme.warning : AppTheme.inputFill;
      borderColor = isSelected ? AppTheme.warning : AppTheme.inputBorder;
    } else if (type == 'Parts') {
      buttonColor = isSelected ? AppTheme.error : AppTheme.inputFill;
      borderColor = isSelected ? AppTheme.error : AppTheme.inputBorder;
    } else {
      buttonColor = isSelected ? AppTheme.primary : AppTheme.inputFill;
      borderColor = isSelected ? AppTheme.primary : AppTheme.inputBorder;
    }
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        width: 75,
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            type,
            style: TextStyle(
              color: isSelected ? AppTheme.surface : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    specsController.dispose();
    priceController.dispose();
    rentalRateController.dispose();
    descriptionController.dispose();
    contactNameController.dispose();
    contactPhoneController.dispose();
    super.dispose();
  }
}
