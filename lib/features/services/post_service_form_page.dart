import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/app_theme.dart';

class PostServiceFormPage extends StatefulWidget {
  const PostServiceFormPage({super.key});

  @override
  State<PostServiceFormPage> createState() => _PostServiceFormPageState();
}

class _PostServiceFormPageState extends State<PostServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Personal Information Controllers
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  // Location
  String? _selectedState;
  String? _selectedCity;

  // Power Tools Checkboxes
  bool _drills = false;
  bool _grinders = false;
  bool _saws = false;
  bool _sanders = false;
  bool _welding = false;
  final _powerToolsOtherController = TextEditingController();

  // Heavy Equipment Checkboxes
  bool _generators = false;
  bool _compressors = false;
  bool _excavators = false;
  bool _forklifts = false;
  bool _bulldozers = false;
  final _heavyEquipmentOtherController = TextEditingController();

  // Service Type Checkboxes
  bool _maintenance = false;
  bool _repair = false;
  bool _installation = false;
  bool _diagnostics = false;

  // Mobility
  String? _mobility; // 'mobile', 'workshop', 'both'

  // Experience & Certifications
  final _experienceSummaryController = TextEditingController();
  final _certificationsController = TextEditingController();

  // Nigerian States
  final List<String> _nigerianStates = [
    'Abia',
    'Adamawa',
    'Akwa Ibom',
    'Anambra',
    'Bauchi',
    'Bayelsa',
    'Benue',
    'Borno',
    'Cross River',
    'Delta',
    'Ebonyi',
    'Edo',
    'Ekiti',
    'Enugu',
    'Gombe',
    'Imo',
    'Jigawa',
    'Kaduna',
    'Kano',
    'Katsina',
    'Kebbi',
    'Kogi',
    'Kwara',
    'Lagos',
    'Nasarawa',
    'Niger',
    'Ogun',
    'Ondo',
    'Osun',
    'Oyo',
    'Plateau',
    'Sokoto',
    'Taraba',
    'Yobe',
    'Zamfara',
    'FCT'
  ];

  // Major cities per state
  final Map<String, List<String>> _citiesByState = {
    'Lagos': [
      'Lagos Island',
      'Lagos Mainland',
      'Ikeja',
      'Victoria Island',
      ' Lekki',
      'Badagry'
    ],
    'Abuja': ['Gwagwalada', 'Kuje', 'Abaji', 'Municipal', 'Bwari', 'Karu'],
    'Oyo': ['Ibadan', 'Oyo', 'Ogbomoso', 'Saki', 'Iseyin', 'Eruwa'],
    'Ogun': ['Abeokuta', 'Sagamu', 'Ilishan', 'Ibara', 'Mowe', 'Sango Ota'],
    'Kano': ['Kano', 'Dambatta', 'Wudil', 'Gwarzo', 'Kura', 'Rano'],
    'Rivers': [
      'Port Harcourt',
      'Obio-Akpor',
      'Okrika',
      'Owerri',
      'Degema',
      'Eleme'
    ],
    'Delta': ['Asaba', 'Warri', 'Sapele', 'Abraka', 'Ozoro', 'Ughelli'],
    'Enugu': ['Enugu', 'Nsukka', 'Awgu', 'Udi', 'Agbani', 'Oji River'],
    'Anambra': ['Awka', 'Onitsha', 'Nnewi', 'Ekwulobia', 'Ihiala', 'Awuzu'],
    'Imo': ['Owerri', 'Orlu', 'Okigwe', 'Mbaise', 'Obowo', 'Isiala Mbano'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _powerToolsOtherController.dispose();
    _heavyEquipmentOtherController.dispose();
    _experienceSummaryController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  List<String> get _availableCities {
    if (_selectedState == null) return [];
    return _citiesByState[_selectedState] ?? [_selectedState!];
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one service capability is selected
    if (!_drills &&
        !_grinders &&
        !_saws &&
        !_sanders &&
        !_welding &&
        !_generators &&
        !_compressors &&
        !_excavators &&
        !_forklifts &&
        !_bulldozers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one service capability')),
      );
      return;
    }

    // Validate at least one service type is selected
    if (!_maintenance && !_repair && !_installation && !_diagnostics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one service type')),
      );
      return;
    }

    // Validate mobility is selected
    if (_mobility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select mobility option')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.from('services').insert({
        'name': _nameController.text.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'state': _selectedState,
        'city': _selectedCity,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,

        // Power Tools
        'power_tools_drills': _drills,
        'power_tools_grinders': _grinders,
        'power_tools_saws': _saws,
        'power_tools_sanders': _sanders,
        'power_tools_welding': _welding,
        'power_tools_other': _powerToolsOtherController.text.trim().isNotEmpty
            ? _powerToolsOtherController.text.trim()
            : null,

        // Heavy Equipment
        'heavy_equipment_generators': _generators,
        'heavy_equipment_compressors': _compressors,
        'heavy_equipment_excavators': _excavators,
        'heavy_equipment_forklifts': _forklifts,
        'heavy_equipment_bulldozers': _bulldozers,
        'heavy_equipment_other':
            _heavyEquipmentOtherController.text.trim().isNotEmpty
                ? _heavyEquipmentOtherController.text.trim()
                : null,

        // Service Type
        'service_maintenance': _maintenance,
        'service_repair': _repair,
        'service_installation': _installation,
        'service_diagnostics': _diagnostics,

        // Mobility
        'mobility': _mobility,

        // Experience
        'experience_summary':
            _experienceSummaryController.text.trim().isNotEmpty
                ? _experienceSummaryController.text.trim()
                : null,
        'certifications': _certificationsController.text.trim().isNotEmpty
            ? _certificationsController.text.trim()
            : null,

        'status': 'approved',
      });

      if (response.error != null) {
        throw response.error!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service registered successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Service'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Personal Information Section
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: 10),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Full Name *'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Contact Number
            TextFormField(
              controller: _contactNumberController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Contact Number *'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter contact number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('Email (Optional)'),
            ),
            const SizedBox(height: 12),

            // Location Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: _inputDecoration('State *'),
                    items: _nigerianStates.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                        _selectedCity = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Select state';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: _inputDecoration('City *'),
                    items: _availableCities.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCity = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Select city';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: _inputDecoration('Full Address (Optional)'),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Service Capabilities'),
            const SizedBox(height: 12),

            // Power Tools Section
            _buildSubSection('Power Tools'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCheckbox(
                    'Drills', _drills, (v) => setState(() => _drills = v)),
                _buildCheckbox('Grinders', _grinders,
                    (v) => setState(() => _grinders = v)),
                _buildCheckbox('Saws', _saws, (v) => setState(() => _saws = v)),
                _buildCheckbox(
                    'Sanders', _sanders, (v) => setState(() => _sanders = v)),
                _buildCheckbox('Welding Machines', _welding,
                    (v) => setState(() => _welding = v)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _powerToolsOtherController,
              decoration: _inputDecoration('Other Power Tools (Optional)'),
            ),

            const SizedBox(height: 16),

            // Heavy Equipment Section
            _buildSubSection('Heavy Equipment'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCheckbox('Generators', _generators,
                    (v) => setState(() => _generators = v)),
                _buildCheckbox('Compressors', _compressors,
                    (v) => setState(() => _compressors = v)),
                _buildCheckbox('Excavators', _excavators,
                    (v) => setState(() => _excavators = v)),
                _buildCheckbox('Forklifts', _forklifts,
                    (v) => setState(() => _forklifts = v)),
                _buildCheckbox('Bulldozers', _bulldozers,
                    (v) => setState(() => _bulldozers = v)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _heavyEquipmentOtherController,
              decoration: _inputDecoration('Other Heavy Equipment (Optional)'),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Service Type'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCheckbox('Routine Maintenance', _maintenance,
                    (v) => setState(() => _maintenance = v)),
                _buildCheckbox(
                    'Repair', _repair, (v) => setState(() => _repair = v)),
                _buildCheckbox('Installation', _installation,
                    (v) => setState(() => _installation = v)),
                _buildCheckbox('Diagnostics/Inspection', _diagnostics,
                    (v) => setState(() => _diagnostics = v)),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Mobility'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRadioChip('Mobile', 'mobile', _mobility,
                    (v) => setState(() => _mobility = v)),
                _buildRadioChip('Workshop-based', 'workshop', _mobility,
                    (v) => setState(() => _mobility = v)),
                _buildRadioChip('Both', 'both', _mobility,
                    (v) => setState(() => _mobility = v)),
              ],
            ),
            const Text(
              'Mobile = can travel to client site | Workshop-based = client brings equipment',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Experience & Certifications'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _experienceSummaryController,
              maxLines: 4,
              decoration: _inputDecoration('Experience Summary (Optional)'),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _certificationsController,
              maxLines: 3,
              decoration:
                  _inputDecoration('Certifications / Training (Optional)'),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.surface),
                        ),
                      )
                    : const Text(
                        'Register Service',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceBase, vertical: AppTheme.spaceMD + 2),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.titleSmall.copyWith(color: AppTheme.primary),
    );
  }

  Widget _buildSubSection(String title) {
    return Text(
      title,
      style: AppTheme.labelMedium.copyWith(color: AppTheme.textPrimary),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppTheme.primary.withOpacity(0.2),
      checkmarkColor: AppTheme.primary,
    );
  }

  Widget _buildRadioChip(String label, String groupValue, String? currentValue,
      Function(String?) onChanged) {
    final isSelected = groupValue == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onChanged(groupValue);
      },
      selectedColor: AppTheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
