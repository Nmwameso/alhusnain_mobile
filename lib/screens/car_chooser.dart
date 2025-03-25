import 'package:flutter/material.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'config.dart';

import '../services/api_service.dart';

class CarChooserScreen extends StatefulWidget {
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    _productsSearcher.connectFilterState(_filterState);
  }

  FacetList _createFacetList(String attribute) {
    return _productsSearcher.buildFacetList(
      filterState: _filterState,
      attribute: attribute,
    );
  }
  void _logActivity() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiService = ApiService();

    try {
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

  Widget _buildFacetStep(String title, FacetList facetList, String? selectedValue, Function(String?) onSelect) {
    return StreamBuilder<List<SelectableFacet>>(
      stream: facetList.facets,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }
        final facets = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: facets.map((facet) {
                return ChoiceChip(
                  label: Text(facet.item.value, style: TextStyle(fontWeight: FontWeight.bold)),
                  selected: selectedValue == facet.item.value,
                  selectedColor: Colors.green,
                  backgroundColor: Colors.grey[200],
                  onSelected: (isSelected) {
                    setState(() => onSelect(isSelected ? facet.item.value : null));
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Your Car")),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && selectedDCategory == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a Category to proceed."), backgroundColor: Colors.red),
            );
            return;
          }
          if (_currentStep == 4) {
            _navigateToSearch();
          } else {
            setState(() => _currentStep += 1);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            children: [
              ElevatedButton(
                onPressed: details.onStepContinue,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Next", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: details.onStepCancel,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: BorderSide(color: Colors.orange),
                ),
                child: const Text("Back", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text("Select Category"),
            content: _buildFacetStep("What are you using the car for?", _drivingcategoryFacetList, selectedDCategory, (val) {
              setState(() {
                selectedDCategory = val;
                _filterState.clear();
                if (val != null) {
                  _filterState.add(FilterGroupID.and('category'),
                      {Filter.facet('categories.Driving Category', val)});
                }
              });
            }),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text("Body Type"),
            content: _buildFacetStep("Select Body Type", _bodytypeFacetList, selectedBodyType, (val) => setState(() => selectedBodyType = val)),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text("Make"),
            content: _buildFacetStep("Select Car Make", _makeFacetList, selectedMake, (val) => setState(() => selectedMake = val)),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text("Fuel Type"),
            content: _buildFacetStep("Select Fuel Type", _fuelFacetList, selectedFuel, (val) => setState(() => selectedFuel = val)),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text("Engine Capacity"),
            content: Column(
              children: [
                Text(
                  "Select Engine Capacity",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                RangeSlider(
                  values: _selectedEngineRange,
                  min: 300,
                  max: 6000,
                  divisions: 57,
                  labels: RangeLabels(
                    _selectedEngineRange.start.round().toString(),
                    _selectedEngineRange.end.round().toString(),
                  ),
                  onChanged: (values) => setState(() => _selectedEngineRange = values),
                  activeColor: Colors.green, // Set slider color to green
                ),
              ],
            ),
            isActive: _currentStep >= 4,
          ),

        ],
      ),
    );
  }
}