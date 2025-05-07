// ✅ Fully Optimized VehicleSearchPage with UI
import 'dart:async';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'VehicleDetailsScreen.dart';
import 'config.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class VehicleSearchPage extends StatefulWidget {
  final CarLayout carLayout;
  final VoidCallback onToggleLayout;
  final String? selectedCategory;
  final String? selectedBrand;
  final String? selectedModel;
  final String? selectedColor;
  final String? selectedYear;
  final String? selectedBodytype;
  final String? selectedFuel;
  final String? selectedDrive;
  final String? selectedTrasmission;
  final String? selectedFeatures;

  const VehicleSearchPage({
    Key? key,
    this.selectedCategory,
    this.selectedBrand,
    this.selectedModel,
    this.selectedColor,
    this.selectedYear,
    this.selectedBodytype,
    this.selectedFuel,
    this.selectedDrive,
    this.selectedTrasmission,
    this.selectedFeatures,
    required this.carLayout,
    required this.onToggleLayout,
  }) : super(key: key);

  @override
  _VehicleSearchPageState createState() => _VehicleSearchPageState();


}

class _VehicleSearchPageState extends State<VehicleSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  static const int _pageSize = 8;
  Map<String, String> selectedFilters = {};
  bool restrictToMombasa = false;


  final HitsSearcher _productsSearcher = HitsSearcher(
    applicationID: AlgoliaConfig.applicationId,
    apiKey: AlgoliaConfig.apiKey,
    indexName: AlgoliaConfig.indexName,
  );

  final _filterState = FilterState();
  final _pagingController = PagingController<int, Hit>(firstPageKey: 0);

  final List<String> _filterAttributes = [
    'categories.Driving Category', 'make', 'model', 'colour', 'yr_of_mfg',
    'body_type', 'fuel', 'drive', 'transm', 'features'
  ];

  late final Map<String, FacetList> _facetLists = {
    for (var attr in _filterAttributes)
      attr: _productsSearcher.buildFacetList(filterState: _filterState, attribute: attr)
  };

  @override
  void initState() {
    super.initState();
    _checkLocationRestriction();
    _productsSearcher.responses.listen((_) => setState(() {}));
    _productsSearcher.connectFilterState(_filterState);
    _pagingController.addPageRequestListener(_fetchPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyInitialFilters());
  }

  Future<void> _checkLocationRestriction() async {
    final prefs = await SharedPreferences.getInstance();
    restrictToMombasa = prefs.getBool('location_denied') ?? false;

    if (restrictToMombasa) {
      _filterState.add(FilterGroupID.and('location'), {
        Filter.facet('location', 'MOMBASA'),
      });
    }
  }

  void _applyInitialFilters() {
    _filterState.clear();
    Map<String, String> newFilters = {};
    for (var entry in {
      'categories.Driving Category': widget.selectedCategory,
      'make': widget.selectedBrand,
      'model': widget.selectedModel,
      'colour': widget.selectedColor,
      'yr_of_mfg': widget.selectedYear,
      'body_type': widget.selectedBodytype,
      'fuel': widget.selectedFuel,
      'drive': widget.selectedDrive,
      'transm': widget.selectedTrasmission,
      'features': widget.selectedFeatures
    }.entries) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        _facetLists[entry.key]?.toggle(entry.value!);
        _filterState.add(FilterGroupID.and(entry.key), {Filter.facet(entry.key, entry.value!)});
        newFilters[entry.key] = entry.value!;
      }
    }
    setState(() => selectedFilters = newFilters);
  }

  void _handleFacetSelection(String attribute, FacetList facetList, List<SelectableFacet> facets, String? value) {
    if (value == null) return;

    if (selectedFilters.containsKey(attribute)) {
      final previousValue = selectedFilters[attribute]!;
      if (previousValue == value) return; // same value, do nothing
      facetList.toggle(previousValue);
      _filterState.remove(FilterGroupID.and(attribute), {Filter.facet(attribute, previousValue)});
    }

    facetList.toggle(value);
    _filterState.add(FilterGroupID.and(attribute), {Filter.facet(attribute, value)});

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _pagingController.refresh();
    });

    setState(() {
      selectedFilters[attribute] = value;
    });
  }

  void _clearFacetSelection(String attribute, FacetList facetList, List<SelectableFacet> facets) {
    if (!selectedFilters.containsKey(attribute)) return;

    final previousValue = selectedFilters[attribute]!;
    facetList.toggle(previousValue);
    _filterState.remove(FilterGroupID.and(attribute), {Filter.facet(attribute, previousValue)});

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _pagingController.refresh();
    });

    setState(() {
      selectedFilters.remove(attribute);
    });
  }


  Future<void> _fetchPage(int pageKey) async {
    try {
      _productsSearcher.applyState((state) => state.copyWith(
        query: _controller.text.trim(),
        page: pageKey,
        hitsPerPage: _pageSize,
      ));
      final response = await _productsSearcher.responses.take(1).first;
      final isLastPage = response.hits.length < _pageSize;
      isLastPage
          ? _pagingController.appendLastPage(response.hits)
          : _pagingController.appendPage(response.hits, pageKey + 1);
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isEmpty) _filterState.clear();
      _pagingController.refresh();
    });
  }

  Widget _filters(BuildContext context, ScrollController controller) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.all(16),
              itemCount: _filterAttributes.length,
              itemBuilder: (context, index) {
                final attr = _filterAttributes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildFacetDropdown(
                    attr,
                    attr,
                    _facetLists[attr]!,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search vehicles...',
          prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              _onSearchChanged('');
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSelectedFilters() {
    if (selectedFilters.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: selectedFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = selectedFilters.entries.elementAt(index);
          return Chip(
            label: Text('${entry.key}: ${entry.value}', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.green.shade600,
            deleteIcon: const Icon(Icons.close, color: Colors.white),
            onDeleted: () => _clearFacetSelection(entry.key, _facetLists[entry.key]!, []),
          );
        },
      ),
    );
  }

  Widget _buildResultsGrid() {
    return PagedGridView<int, Hit>(
      pagingController: _pagingController,
      shrinkWrap: true, // ✅ Prevents height constraint issue
      physics: BouncingScrollPhysics(), // ✅ Allows smooth scrolling
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      builderDelegate: PagedChildBuilderDelegate<Hit>(
        itemBuilder: (context, item, index) => _buildVehicleCard(item),
        firstPageProgressIndicatorBuilder: (_) => _buildShimmerLoading(),
        noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
      ),
    );
  }

  Widget _buildResultsList() {
    return PagedListView<int, Hit>(
      pagingController: _pagingController,
      physics: BouncingScrollPhysics(), // ✅ Ensures smooth scrolling
      builderDelegate: PagedChildBuilderDelegate<Hit>(
        itemBuilder: (context, item, index) => _buildHorizontalCarCard(item),
        firstPageProgressIndicatorBuilder: (_) => _buildShimmerLoading(),
        noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
      ),
    );
  }
  Widget _buildHorizontalCarCard(Hit vehicle) {
    return Card(
      //
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final apiService = ApiService();
          await apiService.logCustomerEvent(
            eventType: 'viewed_vehicle_details',
            metadata: {
              'vehicle_id': vehicle['vehicle_id'].toString(),
              'make': vehicle['make'],
              'model': vehicle['model'],
              'fuel': vehicle['fuel'],
              'year': vehicle['yr_of_mfg'],
              'origin': 'Search page',
            },
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(
                vehicleId: vehicle['vehicle_id'].toString(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: vehicle['main_photo'] ?? '',
                  width: 120,
                  height: 100,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    width: 120,
                    height: 100,
                    child: const Icon(Icons.car_repair, color: Colors.grey, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle['make']} ${vehicle['model']}',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow('Year', vehicle['yr_of_mfg']?.toString() ?? 'N/A'),
                    _buildInfoRow('Fuel', vehicle['fuel']?.toString() ?? 'N/A'),
                    _buildInfoRow('Mileage', '${vehicle['mileage']} km'),
                    _buildInfoRow('Trans', vehicle['transm']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Hit vehicle) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final apiService = ApiService();
          await apiService.logCustomerEvent(
            eventType: 'viewed_vehicle_details',
            metadata: {
              'vehicle_id': vehicle['vehicle_id'].toString(),
              'make': vehicle['make'],
              'model': vehicle['model'],
              'fuel': vehicle['fuel'],
              'year': vehicle['yr_of_mfg'],
            },
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(
                vehicleId: vehicle['vehicle_id'].toString(),
              ),
            ),
          );
        },
        child: IntrinsicHeight( // ✅ Prevents overflow issue
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: vehicle['main_photo'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 95, // ✅ Fixed height
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white, height: 140),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        height: 140,
                        child: const Center(
                          child: Icon(Icons.directions_car, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                        child: Text(
                          '${vehicle['make']} ${vehicle['model']}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Year', vehicle['yr_of_mfg']?.toString() ?? 'N/A'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Fuel', vehicle['fuel']?.toString() ?? 'N/A'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Mileage', '${vehicle['mileage']} km'),
                    const SizedBox(height: 4),
                    _buildInfoRow('Trans', vehicle['transm']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
      ],
    );
  }
  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.green,
        highlightColor: Colors.red.shade300,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6, // Number of shimmer boxes
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // ✅ Same 2 columns as your vehicle grid
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // ✅ Match vehicle card ratio
          ),
          itemBuilder: (_, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Car Image Placeholder
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade300,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Icon(Icons.directions_car_filled_sharp, size: 100, color: Colors.red),
                      ),
                    ),
                  ),
                  // Car Details Placeholder
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: double.infinity, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Container(height: 12, width: 60, color: Colors.grey.shade300),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildEmptyState() => const Center(child: Text('No results found.'));

  Widget _buildFacetDropdown(String title, String attribute, FacetList facetList) {
    return StreamBuilder<List<SelectableFacet>>(
      stream: facetList.facets,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final facets = snapshot.data!;
        final selectedFacet = facets.firstWhereOrNull((f) => f.isSelected);
        final selectedValue = selectedFacet?.item.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: selectedValue,
                hint: Text("Select $title"), // ✅ Dynamic placeholder
                items: facets.map((f) {
                  return DropdownMenuItem(
                    value: f.item.value,
                    child: Text(
                      f.item.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) => _handleFacetSelection(attribute, facetList, facets, val),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.5, // ✅ Half screen
                minChildSize: 0.3,
                maxChildSize: 0.5, // ✅ Limit to half
                builder: (_, controller) => _filters(context, controller),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildSelectedFilters(),
          Expanded(child: widget.carLayout == CarLayout.grid ? _buildResultsGrid() : _buildResultsList()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _productsSearcher.dispose();
    _filterState.dispose();
    _pagingController.dispose();
    _facetLists.values.forEach((f) => f.dispose());
    super.dispose();
  }
}

extension FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
