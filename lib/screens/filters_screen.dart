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

  late final Map<String, FacetList> _facetLists = {
    'Categories': _createFacetList('categories.Driving Category'),
    'Make': _createFacetList('make'),
    'Model': _createFacetList('model'),
    'Colour': _createFacetList('colour'),
    'Year': _createFacetList('yr_of_mfg'),
    'Body Type': _createFacetList('body_type'),
    'Fuel': _createFacetList('fuel'),
    'Drive': _createFacetList('drive'),
    'Transmission': _createFacetList('transm'),
    'Features': _createFacetList('features'),
  };

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
    final facetResults = await Future.wait(
      _facetLists.values.map((facetList) => facetList.facets.first),
    );

    final selectedValues = facetResults.map((facets) =>
    facets.firstWhereOrNull((f) => f.isSelected)?.item.value).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSearchPage(
          selectedCategory: selectedValues[0],
          selectedBrand: selectedValues[1],
          selectedModel: selectedValues[2],
          selectedColor: selectedValues[3],
          selectedYear: selectedValues[4],
          selectedBodytype: selectedValues[5],
          selectedFuel: selectedValues[6],
          selectedDrive: selectedValues[7],
          selectedTrasmission: selectedValues[8],
          selectedFeatures: selectedValues[9],
          carLayout: widget.carLayout,
          onToggleLayout: widget.onToggleLayout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _facetLists.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFacetDropdown(entry.key, entry.value),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Apply Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedValue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                hint: Text('Select $title', style: TextStyle(color: Colors.grey[600])),
                items: facets.map((selectable) {
                  final facet = selectable.item;
                  return DropdownMenuItem(value: facet.value, child: Text(facet.value));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    facetList.toggle(value);
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
