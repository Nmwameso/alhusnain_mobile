import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'config.dart';
import 'home_screen.dart';
import 'search_screen.dart'; // Import VehicleSearchPage

class FiltersScreen extends StatefulWidget {
  final CarLayout carLayout;
  final VoidCallback onToggleLayout;

  FiltersScreen({required this.carLayout, required this.onToggleLayout});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final FilterState _filterState = FilterState();
  final HitsSearcher _productsSearcher = HitsSearcher(
    applicationID: AlgoliaConfig.applicationId,
    apiKey: AlgoliaConfig.apiKey,
    indexName: AlgoliaConfig.indexName,
  );


  // Facet lists with helper method
  late final FacetList _makeFacetList = _createFacetList('make');
  late final FacetList _modelFacetList = _createFacetList('model');
  late final FacetList _colorFacetList = _createFacetList('colour');
  late final FacetList _yrFacetList = _createFacetList('yr_of_mfg');
  late final FacetList _bodytypeFacetList = _createFacetList('body_type');
  late final FacetList _fuelFacetList = _createFacetList('fuel');
  late final FacetList _driveFacetList = _createFacetList('drive');
  late final FacetList _trasmissionFacetList = _createFacetList('transm');
  late final FacetList _featuresFacetList = _createFacetList('features');


  FacetList _createFacetList(String attribute) {
    return _productsSearcher.buildFacetList(
      filterState: _filterState,
      attribute: attribute,
    );
  }


  @override
  void initState() {
    super.initState();
    _productsSearcher.connectFilterState(_filterState);
  }

  void _applyFilters() async {
    final facetsMake = await _makeFacetList.facets.first;
    final facetsModel = await _modelFacetList.facets.first;
    final facetsColor = await _colorFacetList.facets.first;
    final facetsYear = await _yrFacetList.facets.first;
    final facetsBodytype = await _bodytypeFacetList.facets.first;
    final facetsFuel = await _fuelFacetList.facets.first;
    final facetsDrive = await _driveFacetList.facets.first;
    final facetsTrasmission = await _trasmissionFacetList.facets.first;
    final facetsFeatures = await _featuresFacetList.facets.first;

    final selectedBrand = facetsMake.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedModel = facetsModel.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedColor = facetsColor.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedYear = facetsYear.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedBodytype = facetsBodytype.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedFuel = facetsFuel.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedDrive = facetsDrive.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedTrasmission = facetsTrasmission.firstWhereOrNull((f) => f.isSelected)?.item.value;
    final selectedFeatures = facetsFeatures.firstWhereOrNull((f) => f.isSelected)?.item.value;

    // ✅ Navigate directly to VehicleSearchPage instead of pop()
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSearchPage(
          selectedBrand: selectedBrand,
          selectedModel: selectedModel,
          selectedColor: selectedColor,
          selectedYear: selectedYear,
          selectedBodytype: selectedBodytype,
          selectedFuel: selectedFuel,
          selectedDrive: selectedDrive,
          selectedTrasmission: selectedTrasmission,
          selectedFeatures: selectedFeatures,
          carLayout: widget.carLayout,
          onToggleLayout: widget.onToggleLayout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filters')),
      body: Column(
        children: [
          // Scrollable filter list
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(), // iOS-style scroll
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFacetDropdown('Make', _makeFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Model', _modelFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Colour', _colorFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Year', _yrFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Body type', _bodytypeFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Fuel', _fuelFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Drive', _driveFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Transmission', _trasmissionFacetList),
                  const SizedBox(height: 16),
                  _buildFacetDropdown('Features', _featuresFacetList),
                  const SizedBox(height: 32), // Bottom padding
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text("Apply Filters"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacetDropdown(String title, FacetList facetList) {
    return StreamBuilder<List<SelectableFacet>>(
      stream: facetList.facets,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }
        final facets = snapshot.data ?? [];
        if (facets.isEmpty) {
          return Text('$title: No options available', style: TextStyle(fontSize: 16, color: Colors.grey[600]));
        }
        String? selectedValue = facets.firstWhereOrNull((f) => f.isSelected)?.item.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: selectedValue,
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
              hint: Text('Select $title', style: TextStyle(color: Colors.grey[600])),
              items: facets.map((selectable) {
                final facet = selectable.item;
                return DropdownMenuItem(value: facet.value, child: Text(facet.value));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  for (var f in facets.where((f) => f.isSelected)) {
                    facetList.toggle(f.item.value);
                  }
                  facetList.toggle(value);
                  setState(() {});
                }
              },
            ),
          ],
        );
      },
    );
  }
}
