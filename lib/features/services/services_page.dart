import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ui/app_theme.dart';
import 'service_card.dart';
import 'post_service_form_page.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<dynamic> _services = [];
  bool _isLoading = true;
  String? _error;

  // Filter states
  String? _selectedState;
  String? _selectedCity;
  String? _selectedServiceType;
  String? _selectedMobility;

  // Nigerian States
  final List<String> _nigerianStates = [
    'Abia', 'Adamawa', 'Akwa Ibom', 'Anambra', 'Bauchi', 'Bayelsa',
    'Benue', 'Borno', 'Cross River', 'Delta', 'Ebonyi', 'Edo',
    'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna',
    'Kano', 'Katsina', 'Kebbi', 'Kogi', 'Kwara', 'Lagos',
    'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo',
    'Plateau', 'Sokoto', 'Taraba', 'Yobe', 'Zamfara', 'FCT'
  ];

  // Major cities per state
  final Map<String, List<String>> _citiesByState = {
    'Lagos': ['Lagos Island', 'Lagos Mainland', 'Ikeja', 'Victoria Island', 'Lekki', 'Badagry'],
    'Abuja': ['Gwagwalada', 'Kuje', 'Abaji', 'Municipal', 'Bwari', 'Karu'],
    'Oyo': ['Ibadan', 'Oyo', 'Ogbomoso', 'Saki', 'Iseyin', 'Eruwa'],
    'Ogun': ['Abeokuta', 'Sagamu', 'Ilishan', 'Ibara', 'Mowe', 'Sango Ota'],
    'Kano': ['Kano', 'Dambatta', 'Wudil', 'Gwarzo', 'Kura', 'Rano'],
    'Rivers': ['Port Harcourt', 'Obio-Akpor', 'Okrika', 'Owerri', 'Degema', 'Eleme'],
    'Delta': ['Asaba', 'Warri', 'Sapele', 'Abraka', 'Ozoro', 'Ughelli'],
    'Enugu': ['Enugu', 'Nsukka', 'Awgu', 'Udi', 'Agbani', 'Oji River'],
    'Anambra': ['Awka', 'Onitsha', 'Nnewi', 'Ekwulobia', 'Ihiala', 'Awuzu'],
    'Imo': ['Owerri', 'Orlu', 'Okigwe', 'Mbaise', 'Obowo', 'Isiala Mbano'],
  };

  List<String> get _availableCities {
    if (_selectedState == null) return [];
    return _citiesByState[_selectedState] ?? [_selectedState!];
  }

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('services')
          .select()
          .eq('status', 'approved');

      setState(() {
        _services = response as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredServices {
    return _services.where((service) {
      // State filter
      if (_selectedState != null && service['state'] != _selectedState) {
        return false;
      }
      // City filter
      if (_selectedCity != null && service['city'] != _selectedCity) {
        return false;
      }
      // Service type filter
      if (_selectedServiceType != null) {
        switch (_selectedServiceType) {
          case 'maintenance':
            if (service['service_maintenance'] != true) return false;
            break;
          case 'repair':
            if (service['service_repair'] != true) return false;
            break;
          case 'installation':
            if (service['service_installation'] != true) return false;
            break;
          case 'diagnostics':
            if (service['service_diagnostics'] != true) return false;
            break;
        }
      }
      // Mobility filter
      if (_selectedMobility != null && service['mobility'] != _selectedMobility) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppTheme.spaceLG),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Services', style: AppTheme.headline3),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedState = null;
                        _selectedCity = null;
                        _selectedServiceType = null;
                        _selectedMobility = null;
                      });
                      setState(() {});
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(
                'Refine services by location, service type, and mobility.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spaceLG),

              // State
              const Text('State', style: AppTheme.labelLarge),
              const SizedBox(height: AppTheme.spaceSM),
              DropdownButtonFormField<String>(
                value: _selectedState,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceBase, vertical: AppTheme.spaceMD),
                ),
                items: _nigerianStates.map((state) {
                  return DropdownMenuItem(value: state, child: Text(state, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _selectedState = value;
                    _selectedCity = null;
                  });
                  setState(() {});
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // City
              const Text('City', style: AppTheme.labelLarge),
              const SizedBox(height: AppTheme.spaceSM),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceBase, vertical: AppTheme.spaceMD),
                ),
                items: _availableCities.map((city) {
                  return DropdownMenuItem(value: city, child: Text(city, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (value) {
                  setModalState(() => _selectedCity = value);
                  setState(() {});
                },
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Service Type
              const Text('Service Type', style: AppTheme.labelLarge),
              const SizedBox(height: AppTheme.spaceSM),
              Wrap(
                spacing: AppTheme.spaceSM,
                runSpacing: AppTheme.spaceSM,
                children: [
                  _buildFilterChip('Maintenance', 'maintenance', setModalState),
                  _buildFilterChip('Repair', 'repair', setModalState),
                  _buildFilterChip('Installation', 'installation', setModalState),
                  _buildFilterChip('Diagnostics', 'diagnostics', setModalState),
                ],
              ),
              const SizedBox(height: AppTheme.spaceBase),

              // Mobility
              const Text('Mobility', style: AppTheme.labelLarge),
              const SizedBox(height: AppTheme.spaceSM),
              Wrap(
                spacing: AppTheme.spaceSM,
                runSpacing: AppTheme.spaceSM,
                children: [
                  _buildFilterChip('Mobile', 'mobile', setModalState),
                  _buildFilterChip('Workshop', 'workshop', setModalState),
                  _buildFilterChip('Both', 'both', setModalState),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXL),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                  ),
                  child: Text(
                    'Show ${_filteredServices.length} Results',
                    style: AppTheme.titleMedium.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, StateSetter setModalState) {
    final isSelected = _selectedServiceType == value || _selectedMobility == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (_selectedServiceType == value || _selectedMobility == value) {
          setModalState(() {
            _selectedServiceType = null;
            _selectedMobility = null;
          });
        } else {
          if (value == 'mobile' || value == 'workshop' || value == 'both') {
            setModalState(() => _selectedMobility = value);
          } else {
            setModalState(() => _selectedServiceType = value);
          }
        }
        setState(() {});
      },
      selectedColor: AppTheme.primary.withOpacity(0.2),
      checkmarkColor: AppTheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Services'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: AppTheme.spaceBase),
                      ElevatedButton(
                        onPressed: _fetchServices,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filteredServices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.build_outlined, size: 64, color: AppTheme.textTertiary),
                          const SizedBox(height: AppTheme.spaceBase),
                          const Text(
                            'No services found',
                            style: AppTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spaceSM),
                          const Text(
                            'Be the first to register a service!',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchServices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spaceBase),
                        itemCount: _filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = _filteredServices[index];
                          return ServiceCard(service: service);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostServiceFormPage()),
          ).then((_) => _fetchServices());
        },
        tooltip: 'Add Service',
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
