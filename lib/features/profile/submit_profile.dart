import '../models/artisan.dart';
import '../models/category.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../ui/app_theme.dart';
import '../directory/artisan_provider.dart';
import '../utils/supabase.dart';
import '../../services/supabase_upload_helper.dart';

class SubmitProfile extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Artisan? artisan; // If provided, this is edit mode
  const SubmitProfile({Key? key, this.onSuccess, this.artisan})
      : super(key: key);

  @override
  State<SubmitProfile> createState() => _SubmitProfileState();
}

class _SubmitProfileState extends State<SubmitProfile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController fullNameController;
  late TextEditingController businessNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController whatsappController;
  int? categoryId;
  late TextEditingController bioController;
  late TextEditingController addressController;
  String? selectedState;
  String? selectedCity;
  List<String> statesList = [];
  List<String> citiesList = [];
  bool isAvailable = true; // Default to available
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  bool isSubmitting = false;
  String submitError = '';
  String? profilePreview;
  PlatformFile? profileImageFile;

  @override
  void initState() {
    super.initState();
    final artisan = widget.artisan;
    fullNameController = TextEditingController(text: artisan?.fullName ?? '');
    businessNameController =
        TextEditingController(text: artisan?.businessName ?? '');
    phoneController = TextEditingController(text: artisan?.phone ?? '');
    emailController = TextEditingController(text: artisan?.email ?? '');
    whatsappController = TextEditingController(text: artisan?.whatsapp ?? '');
    bioController = TextEditingController(text: artisan?.bio ?? '');
    addressController = TextEditingController(text: artisan?.address ?? '');
    selectedState = artisan?.state ?? '';
    selectedCity = artisan?.city ?? '';
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    if (artisan != null && artisan.category.isNotEmpty) {
      // Find matching category object and use its id
      final provider = Provider.of<ArtisanProvider>(context, listen: false);
      final categories = provider.categories;
      final match = categories.firstWhere(
        (cat) => cat.name == artisan.category,
        orElse: () => Category(id: 0, slug: '', name: '', icon: ''),
      );
      categoryId = match.id != 0 ? match.id : null;
    } else {
      categoryId = null;
    }
    profilePreview = artisan?.profileImageUrl;
    _loadStatesAndCities();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    businessNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    bioController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatesAndCities() async {
    try {
      // Load states
      final statesResponse = await SupabaseUtils.client
          .from('states')
          .select('name')
          .order('name');

      if (statesResponse != null && mounted) {
        setState(() {
          statesList =
              (statesResponse as List).map((s) => s['name'] as String).toList();
        });
      }

      // Load cities if state is selected
      if (selectedState != null && selectedState!.isNotEmpty) {
        await _loadCitiesForState(selectedState!);
      }
    } catch (e) {
      print('Error loading states: $e');
    }
  }

  Future<void> _loadCitiesForState(String state) async {
    try {
      // First get the state ID
      final stateResponse = await SupabaseUtils.client
          .from('states')
          .select('id')
          .eq('name', state)
          .maybeSingle();

      if (stateResponse != null && mounted) {
        final stateId = stateResponse['id'];
        final citiesResponse = await SupabaseUtils.client
            .from('cities')
            .select('name')
            .eq('state_id', stateId)
            .order('name');

        if (citiesResponse != null && mounted) {
          setState(() {
            citiesList = (citiesResponse as List)
                .map((c) => c['name'] as String)
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final dynamic fileToUpload = file.bytes ?? file.path;

        if (fileToUpload == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Could not read the selected image. Please try another file.'),
              ),
            );
          }
          return;
        }

        setState(() {
          profileImageFile = file;
          profilePreview = null; // Will show uploaded URL after upload
        });

        // Upload to Supabase Storage using the helper
        try {
          final publicUrl = await SupabaseUploadHelper.uploadImage(
            fileToUpload,
            fileName: '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
          );

          if (publicUrl != null) {
            setState(() {
              profilePreview = publicUrl;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image uploaded successfully!')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Upload failed. Please try again.')),
              );
            }
          }
        } catch (e) {
          print('Upload error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload error: $e')),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  // Generate bio from 3 questions
  String _generateBio(String craft, String experience, String special) {
    String bio = '';

    if (craft.isNotEmpty) {
      bio = 'I am a professional $craft';
    }

    if (experience.isNotEmpty) {
      if (bio.isNotEmpty) {
        bio += ' with $experience years of experience';
      } else {
        bio = 'I have $experience years of experience';
      }
    }

    if (special.isNotEmpty) {
      if (bio.isNotEmpty) {
        bio += '. $special';
      } else {
        bio = special;
      }
    }

    return bio.isNotEmpty ? bio : 'Professional artisan ready to serve you.';
  }

  void _showBioGeneratorDialog() {
    String craft = '';
    String experience = '';
    String special = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate Your Bio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Answer 3 questions to generate your bio:',
                  style: TextStyle(fontSize: 14)),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: '1. What is your craft/service?',
                  hintText: 'e.g., Carpenter, Plumber, Fashion Designer',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => craft = val,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: '2. How many years of experience?',
                  hintText: 'e.g., 5 years',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => experience = val,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: '3. What makes you special?',
                  hintText: 'e.g., I deliver on time, quality guaranteed',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => special = val,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final generatedBio = _generateBio(craft, experience, special);
              bioController.text = generatedBio;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bio generated!')),
              );
            },
            child: Text('Generate'),
          ),
        ],
      ),
    );
  }

  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    // Extra required check for phone, email, city
    if (phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        (selectedCity == null || selectedCity!.isEmpty)) {
      setState(() {
        submitError = 'Phone, Email, and City are required.';
      });
      return;
    }
    if (selectedState == null || selectedState!.isEmpty) {
      setState(() {
        submitError = 'Please select a State.';
      });
      return;
    }
    setState(() {
      isSubmitting = true;
      submitError = '';
    });

    try {
      // Get the category name from the selected categoryId
      String categoryName = '';
      if (categoryId != null) {
        final provider = Provider.of<ArtisanProvider>(context, listen: false);
        final categories = provider.categories;
        final match = categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => Category(id: 0, slug: '', name: '', icon: ''),
        );
        categoryName = match.name;
      }

      final response = await SupabaseUtils.client.from('artisans').insert({
        'full_name': fullNameController.text.trim(),
        'business_name': businessNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'city': selectedCity ?? '',
        'whatsapp': whatsappController.text.trim(),
        'category_id': categoryId,
        'category': categoryName,
        'bio': bioController.text.trim(),
        'address': addressController.text.trim(),
        'state': selectedState ?? '',
        'profile_image_url': profilePreview,
        'password': passwordController.text,
        'status': 'active',
        'is_available': isAvailable,
      });
      if (response == null) {
        // Insert succeeded (newer Supabase behavior returns null on success)
        if (widget.onSuccess != null) widget.onSuccess!();
        Navigator.pop(context);
      } else if (response is Map &&
          response.containsKey('error') &&
          response['error'] != null) {
        // Handle older API with error in Map
        setState(() {
          submitError = response['error'].toString();
        });
      } else {
        if (widget.onSuccess != null) widget.onSuccess!();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        submitError = e.toString();
      });
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (submitError.isNotEmpty)
                  Card(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    margin: EdgeInsets.only(bottom: AppTheme.spaceSM),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceSM),
                      child: Row(children: [
                        Icon(Icons.error, color: AppTheme.error, size: 20),
                        SizedBox(width: AppTheme.spaceSM),
                        Expanded(
                            child: Text(submitError,
                                style: TextStyle(
                                    color: AppTheme.error, fontSize: 12)))
                      ]),
                    ),
                  ),
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: profilePreview != null
                        ? NetworkImage(profilePreview!)
                        : null,
                    child: profilePreview == null
                        ? Icon(Icons.camera_alt,
                            size: 30, color: AppTheme.textSecondary)
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: fullNameController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: businessNameController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Business Name',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                SizedBox(height: 12),
                Consumer<ArtisanProvider>(
                  builder: (context, provider, _) {
                    final categories = provider.categories;
                    return DropdownButtonFormField<int>(
                      value: categoryId,
                      isExpanded: true,
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(fontSize: 13),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => categoryId = val),
                      validator: (val) =>
                          val == null ? 'Select a category' : null,
                    );
                  },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedState != null && selectedState!.isNotEmpty
                      ? selectedState
                      : null,
                  isExpanded: true,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'State',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  hint: Text('Select State', style: TextStyle(fontSize: 13)),
                  items: statesList
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedState = val;
                      selectedCity = null;
                      citiesList = [];
                    });
                    if (val != null) {
                      _loadCitiesForState(val);
                    }
                  },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Select a state' : null,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCity != null && selectedCity!.isNotEmpty
                      ? selectedCity
                      : null,
                  isExpanded: true,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'City',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  hint: Text('Select City', style: TextStyle(fontSize: 13)),
                  items: citiesList
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCity = val;
                    });
                  },
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Select a city' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your phone' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your email' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: whatsappController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'WhatsApp',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: bioController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Bio / Description',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.auto_awesome,
                          size: 20, color: AppTheme.warning),
                      tooltip: 'Generate bio with AI',
                      onPressed: _showBioGeneratorDialog,
                    ),
                  ),
                  maxLines: 3,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your bio' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  obscureText: true,
                  validator: (val) => val != passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<bool>(
                  value: isAvailable,
                  isExpanded: true,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(fontSize: 13),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppTheme.success, size: 18),
                          SizedBox(width: 8),
                          Text('Available'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: AppTheme.error, size: 18),
                          SizedBox(width: 8),
                          Text('Busy'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      isAvailable = val ?? true;
                    });
                  },
                ),
                SizedBox(height: 28),
                ElevatedButton(
                  onPressed: isSubmitting ? null : handleSubmit,
                  child:
                      Text(isSubmitting ? 'Submitting...' : 'Submit Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
