import 'package:flutter/material.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:provider/provider.dart';
import 'package:easy_stepper/easy_stepper.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'config.dart';

class CarChooserScreen extends StatefulWidget {
  late final VoidCallback? onComplete; // Add this parameter

  @override
  _CarChooserScreenState createState() => _CarChooserScreenState();
}

class _CarChooserScreenState extends State<CarChooserScreen> {
  final FilterState _filterState = FilterState();
  final HitsSearcher _productsSearcher = HitsSearcher(
    applicationID: AlgoliaConfig.applicationId,
    apiKey: AlgoliaConfig.apiKey,
    indexName: AlgoliaConfig.indexName,
  );

  late FacetList _drivingcategoryFacetList = _createFacetList('categories.Driving Category');
  late FacetList _makeFacetList = _createFacetList('make');
  late FacetList _bodytypeFacetList = _createFacetList('body_type');
  late FacetList _fuelFacetList = _createFacetList('fuel');

  RangeValues _selectedEngineRange = const RangeValues(300, 6000);

  String? selectedDCategory;
  String? selectedMake;
  String? selectedBodyType;
  String? selectedFuel;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _productsSearcher.connectFilterState(_filterState);
  }

  FacetList _createFacetList(String attribute) {
    return _productsSearcher.buildFacetList(filterState: _filterState, attribute: attribute);
  }

  void _logActivity() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();

    try {

      // Log car selection activity for analytics
      await apiService.logCustomerEvent(
        eventType: 'car_profile_built',
        metadata: {
          'driving_category': selectedDCategory ?? '',
          'make': selectedMake ?? '',
          'body_type': selectedBodyType ?? '',
          'fuel': selectedFuel ?? '',
          'engine_min': _selectedEngineRange.start.round(),
          'engine_max': _selectedEngineRange.end.round(),
          'step_completed': _currentStep,
        },
      );

      bool success = await apiService.logCarSelectionActivity(
        authProvider: authProvider,
        selectedDrivingCategory: selectedDCategory ?? "",
        selectedMake: selectedMake ?? "",
        selectedBodyType: selectedBodyType ?? "",
        selectedFuel: selectedFuel ?? "",
        engineMin: _selectedEngineRange.start,
        engineMax: _selectedEngineRange.end,
      );

      if (success) {
        print("Car selection activity logged successfully!");
      }
    } catch (e) {
      print("Error logging car selection: $e");
    }
  }

  void _navigateToSearch() {
    if (selectedDCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Category to proceed.")),
      );
      return;
    }
    _logActivity(); // Log user activity before navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSearchPage(
          selectedCategory: selectedDCategory,
          selectedBrand: selectedMake,
          selectedBodytype: selectedBodyType,
          selectedFuel: selectedFuel,
          carLayout: CarLayout.grid,
          onToggleLayout: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastStep = _currentStep == 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Build Your Car Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stepper Navigation
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: EasyStepper(
              activeStep: _currentStep,
              direction: Axis.horizontal,
              showLoadingAnimation: false,
              showStepBorder: true,
              stepRadius: 40, // Increased step size
              finishedStepBorderColor: Colors.green,
              activeStepIconColor: Colors.green,
              finishedStepIconColor: Colors.green,
              unreachedStepIconColor: Colors.grey,

              padding: const EdgeInsets.symmetric(horizontal: 10),
              steps: [
                EasyStep(icon: const Icon(Icons.category, size: 30), title: "Purpose"),
                EasyStep(icon: const Icon(Icons.directions_car, size: 30), title: "Body"),
                EasyStep(icon: const Icon(Icons.car_repair, size: 30), title: "Brand"),
                EasyStep(icon: const Icon(Icons.local_gas_station, size: 30), title: "Fuel"),
                EasyStep(icon: const Icon(Icons.speed, size: 30), title: "Engine"),
              ],
              onStepReached: (index) {
                setState(() => _currentStep = index);
              },
            ),
          ),

          // Step Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildFacetStep("Primary Use Case", _drivingcategoryFacetList, selectedDCategory, _handleCategoryChange),
                  _buildFacetStep("Preferred Body Style", _bodytypeFacetList, selectedBodyType, (val) => setState(() => selectedBodyType = val)),
                  _buildFacetStep("Brand Preference", _makeFacetList,
                      selectedMake,
                      _handleMakeChange
                  ),
                  _buildFacetStep("Fuel Type", _fuelFacetList, selectedFuel, (val) => setState(() => selectedFuel = val)),
                  _buildEngineStep(),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentStep > 0 ? () => setState(() => _currentStep -= 1) : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.green),
                    ),
                    child: const Text("BACK", style: TextStyle(color: Colors.green, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleNextButton,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStep ? Colors.green : theme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isLastStep ? "SEARCH NOW" : "CONTINUE",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCategoryChange(String? val) {
    setState(() {
      selectedDCategory = val;
      _filterState.clear();
      if (val != null) {
        _filterState.add(FilterGroupID.and('category'), {Filter.facet('categories.Driving Category', val)});
      }
      _selectedEngineRange = const RangeValues(300, 6000);
    });
  }

  void _handleMakeChange(String? val) {
    setState(() {
      selectedMake = val;
      selectedFuel = null; // Reset fuel selection when make changes

      _filterState.clear();
      if (selectedDCategory != null) {
        _filterState.add(
          FilterGroupID.and('category'),
          {Filter.facet('categories.Driving Category', selectedDCategory!)},
        );
      }
      if (selectedMake != null) {
        _filterState.add(
          FilterGroupID.and('make'),
          {Filter.facet('make', selectedMake!)},
        );
      }

      // Update Fuel Facet List based on selected make
      _fuelFacetList = _createFacetList('fuel');
    });
  }


  Widget _buildFacetStep(String title, FacetList facetList, String? selectedValue, Function(String?) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded( // ✅ put Expanded *inside* Column
          child: StreamBuilder<List<SelectableFacet>>(
            stream: facetList.facets,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                );
              }
              final facets = snapshot.data!;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: facets.map((facet) {
                      final isSelected = selectedValue == facet.item.value;
                      return ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            facet.item.value,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.green,
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.all(6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide.none
                              : BorderSide(color: Colors.grey[400]!),
                        ),
                        onSelected: (selected) =>
                            onSelect(selected ? facet.item.value : null),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEngineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Engine Capacity (cc)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 24),
        RangeSlider(
          values: _selectedEngineRange,
          min: 300,
          max: 6000,
          divisions: 50,
          labels: RangeLabels(_selectedEngineRange.start.toString(), _selectedEngineRange.end.toString()),
          onChanged: (values) => setState(() => _selectedEngineRange = values),
          activeColor: Theme.of(context).primaryColor,
          inactiveColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Future<void> _handleNextButton() async {

    final apiService = ApiService();

    // Log step navigation
    await apiService.logCustomerEvent(
      eventType: 'car_selection_step',
      metadata: {
        'step': _currentStep,
        'step_name': [
          'Purpose',
          'Body Style',
          'Make',
          'Fuel Type',
          'Engine Capacity'
        ][_currentStep],
      },
    );
    if (_currentStep == 0 && selectedDCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a Category to continue."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Prevent moving forward
    }

    if (_currentStep == 4) {
      _navigateToSearch();
      widget.onComplete?.call();
    } else {
      setState(() => _currentStep += 1);
    }
  }
}
