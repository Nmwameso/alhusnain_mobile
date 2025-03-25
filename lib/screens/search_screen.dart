import 'dart:async';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'VehicleDetailsScreen.dart';
import 'chat_screen.dart';
import 'config.dart';
import 'home_screen.dart'; // Import for `firstWhereOrNull`
import 'package:connectivity_plus/connectivity_plus.dart';

class SearchMetadata {
  final int nbHits;
  const SearchMetadata(this.nbHits);
  factory SearchMetadata.fromResponse(SearchResponse response) => SearchMetadata(response.nbHits);
}

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

  // Algolia Configuration
  final HitsSearcher _productsSearcher = HitsSearcher(
    applicationID: AlgoliaConfig.applicationId,
    apiKey: AlgoliaConfig.apiKey,
    indexName: AlgoliaConfig.indexName,
  );

  final GlobalKey<ScaffoldState> _mainScaffoldKey = GlobalKey();
  final _filterState = FilterState();
  final PagingController<int, Hit> _pagingController = PagingController(firstPageKey: 0);

  // Facet Lists
  late final FacetList _drivingcategoryFacetList = _createFacetList('categories.Driving Category');
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

    _productsSearcher.responses.listen((response) {
      if (mounted) setState(() {});
    });

    _productsSearcher.connectFilterState(_filterState);
    _pagingController.addPageRequestListener(_fetchPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialFilters();
    });
  }

  void _applyInitialFilters() {
    _filterState.clear(); // ✅ Clear previous filters before applying new ones

    void applyFilter(String? value, String attribute, FacetList facetList) {
      if (value != null && value.isNotEmpty) {
        facetList.toggle(value);

        // Debug: Check if value is correctly toggled
        print("FacetList for $attribute after toggle: ${facetList.runtimeType}");



        selectedFilters[attribute] = value;

        // ✅ Apply the filter to `_filterState`
        _filterState.add(FilterGroupID.and(attribute), {Filter.facet(attribute, value)});

        // Debug: Print the applied filters in _filterState

      }
    }


    applyFilter(widget.selectedCategory, 'categories.Driving Category', _drivingcategoryFacetList);
    applyFilter(widget.selectedBrand, 'make', _makeFacetList);
    applyFilter(widget.selectedModel, 'model', _modelFacetList);
    applyFilter(widget.selectedColor, 'colour', _colorFacetList);
    applyFilter(widget.selectedYear, 'yr_of_mfg', _yrFacetList);
    applyFilter(widget.selectedBodytype, 'body_type', _bodytypeFacetList);
    applyFilter(widget.selectedFuel, 'fuel', _fuelFacetList);
    applyFilter(widget.selectedDrive, 'drive', _driveFacetList);
    applyFilter(widget.selectedTrasmission, 'transm', _trasmissionFacetList);
    applyFilter(widget.selectedFeatures, 'features', _featuresFacetList);

    print("Applied Filters:");
    selectedFilters.forEach((key, value) {
      print("$key: $value");
    });


  }



  Future<void> _fetchPage(int pageKey) async {
    try {
      _productsSearcher.applyState((state) => state.copyWith(
        query: _controller.text.trim(),
        page: pageKey,
        hitsPerPage: _pageSize,
      ));

      final response = await _productsSearcher.responses.first;
      final isLastPage = response.hits.length < _pageSize;

      isLastPage
          ? _pagingController.appendLastPage(response.hits)
          : _pagingController.appendPage(response.hits, pageKey + 1);
    } catch (error) {
      _pagingController.error = error;
      print(error);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isEmpty) _filterState.clear();
      _pagingController.refresh();
    });
  }

  // Filter UI Components
  Widget _filters(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Filters')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildFacetDropdown('categories.Driving Category', 'categories.Driving Category', _drivingcategoryFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Make', 'make', _makeFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Model', 'model', _modelFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Colour', 'colour', _colorFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Year', 'yr_of_mfg', _yrFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Body type', 'body_type', _bodytypeFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Fuel', 'fuel', _fuelFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Drive', 'drive', _driveFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Transmission', 'transm', _trasmissionFacetList),
          const SizedBox(height: 16),
          _buildFacetDropdown('Features', 'features', _featuresFacetList),
        ],
      ),
    ),
  );

  Widget _buildSelectedFilters() {
    if (selectedFilters.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: selectedFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = selectedFilters.entries.elementAt(index);
          return Chip(
            label: Text(
              '${_getAttributeDisplayName(entry.key)}: ${entry.value}',
              style: const TextStyle(color: Colors.white), // White text for contrast
            ),
            backgroundColor: Colors.green.shade600, // Green background
            deleteIcon: const Icon(Icons.close, size: 18, color: Colors.red), // Red X icon
            onDeleted: () => _clearFilter(entry.key, entry.value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Smooth rounded edges
              side: BorderSide(color: Colors.green.shade800), // Slight border for depth
            ),
          );
        },
      ),
    );
  }


  String _getAttributeDisplayName(String attribute) {
    switch (attribute) {
      case 'categories.Driving Category': return 'categories.Driving Category';
      case 'make': return 'Make';
      case 'model': return 'Model';
      case 'colour': return 'Color';
      case 'yr_of_mfg': return 'Year';
      case 'body_type': return 'Body Type';
      case 'fuel': return 'Fuel';
      case 'drive': return 'Drive';
      case 'transm': return 'Transmission';
      case 'features': return 'Features';
      default: return attribute;
    }
  }

  void _clearFilter(String attribute, String value) {
    final facetList = _getFacetListForAttribute(attribute);

    if (facetList != null) {
      facetList.toggle(value);

      // ✅ Remove the specific filter from _filterState
      _filterState.remove(FilterGroupID.and(attribute), {Filter.facet(attribute, value)});

      // ✅ Cancel any previous debounce before starting a new one
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _pagingController.refresh();
      });

      // ✅ Finally, update the UI
      setState(() => selectedFilters.remove(attribute));
    }
  }


  FacetList? _getFacetListForAttribute(String attribute) {
    switch (attribute) {
      case 'categories.Driving Category': return _drivingcategoryFacetList;
      case 'make': return _makeFacetList;
      case 'model': return _modelFacetList;
      case 'colour': return _colorFacetList;
      case 'yr_of_mfg': return _yrFacetList;
      case 'body_type': return _bodytypeFacetList;
      case 'fuel': return _fuelFacetList;
      case 'drive': return _driveFacetList;
      case 'transm': return _trasmissionFacetList;
      case 'features': return _featuresFacetList;
      default: return null;
    }
  }
  Widget _buildFacetDropdown(String title, String attribute, FacetList facetList) {
    return StreamBuilder<List<SelectableFacet>>(
      stream: facetList.facets,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final facets = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _FacetDropdown(
              facets: facets,
              title: title,
              onChanged: (value) => _handleFacetSelection(attribute, facetList, facets, value),
              onClear: () => _clearFacetSelection(attribute, facetList, facets),
            ),
          ],
        );
      },
    );
  }

  void _handleFacetSelection(String attribute, FacetList facetList, List<SelectableFacet> facets, String? value) {
    if (value == null) return;

    setState(() {
      // Clear previous selection
      if (selectedFilters.containsKey(attribute)) {
        facetList.toggle(selectedFilters[attribute]!);
      }

      // Toggle new selection
      facetList.toggle(value);
      selectedFilters[attribute] = value;

      // Refresh facets from `facetList`
      facets.clear();

    });

    _pagingController.refresh();
  }



  void _clearFacetSelection(String attribute, FacetList facetList, List<SelectableFacet> facets) {
    if (selectedFilters.containsKey(attribute)) {
      facetList.toggle(selectedFilters[attribute]!);
      setState(() => selectedFilters.remove(attribute));
      _pagingController.refresh();

      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (attribute.isEmpty) _filterState.clear();
        _pagingController.refresh();
      });
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search vehicles...',
          prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
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
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: _onSearchChanged,
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
        onTap: () {
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
      ],
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

  Widget _buildVehicleCard(Hit vehicle) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SizedBox( // Restricts height to prevent overflow
        height: 300, // Adjust this value as needed
        child: GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: 6,
          physics: NeverScrollableScrollPhysics(), // ✅ Prevents scrolling when loading
          shrinkWrap: true, // ✅ Ensures it fits inside a Column
          itemBuilder: (_, __) => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ Simulated Image Loading
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                SizedBox(height: 10),

                // ✅ Simulated Text Loading
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: Colors.white), // Title
                      SizedBox(height: 8),
                      Container(height: 12, width: 80, color: Colors.white), // Subtitle
                      SizedBox(height: 8),
                      Container(height: 12, width: 60, color: Colors.white), // Price
                      SizedBox(height: 8),
                      Container(height: 10, width: 100, color: Colors.white), // Extra Details
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No vehicles found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text('Try different search terms',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return FutureBuilder<List<ConnectivityResult>>(
      future: Connectivity().checkConnectivity(),
      builder: (context, snapshot) {
        bool isOffline = snapshot.hasData &&
            snapshot.data!.isNotEmpty &&
            snapshot.data!.first == ConnectivityResult.none;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOffline ? Icons.wifi_off : Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isOffline ? 'No Internet Connection' : 'Connection Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOffline
                      ? 'Please check your internet connection and try again.'
                      : error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: isOffline
                      ? null
                      : () {
                    _pagingController.refresh();
                    _fetchPage(0);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: isOffline
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _mainScaffoldKey,
      appBar: AppBar(
        title: const Text('Vehicle Search'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _mainScaffoldKey.currentState?.openEndDrawer(),
            icon: const Icon(Icons.filter_list_sharp),
            tooltip: 'Filters',
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(),
              ),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: _filters(context),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildSelectedFilters(),
          Expanded(
            child: StreamBuilder<SearchResponse>(
              stream: _productsSearcher.responses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(context, snapshot.error.toString());
                }

                final results = snapshot.data?.hits ?? [];
                if (results.isEmpty) {
                  return _buildEmptyState();
                }

                return widget.carLayout == CarLayout.grid
                    ? _buildResultsGrid()
                    : _buildResultsList();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _productsSearcher.dispose();
    _filterState.dispose();
    [_drivingcategoryFacetList, _makeFacetList, _modelFacetList, _colorFacetList, _yrFacetList, _bodytypeFacetList]
        .forEach((f) => f.dispose());
    _pagingController.dispose();

  }

}
class _FacetDropdown extends StatelessWidget {
  final List<SelectableFacet> facets;
  final String title;
  final ValueChanged<String?> onChanged;
  final VoidCallback onClear;

  const _FacetDropdown({
    required this.facets,
    required this.title,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final selectedFacet = facets.firstWhereOrNull((f) => f.isSelected);
    final selectedValue = selectedFacet?.item.value;

    print(selectedValue); // Debugging
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: selectedValue,
            items: facets.map((f) => DropdownMenuItem(
              value: f.item.value,
              child: Text(f.item.value),
            )).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              hintText: 'Select $title',
            ),
          ),
        ),
        if (selectedValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              icon: Icon(Icons.clear, size: 20),
              label: Text("Clear Selection"),
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red)),
            ),
          ),
      ],
    );
  }
}
extension _FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}