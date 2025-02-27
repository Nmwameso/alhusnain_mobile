import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import '../providers/auth_provider.dart';
import '../screens/VehicleDetailsScreen.dart';

class RecommendedVehicles extends StatefulWidget {
  @override
  _RecommendedVehiclesState createState() => _RecommendedVehiclesState();
}

class _RecommendedVehiclesState extends State<RecommendedVehicles> {
  final HitsSearcher _recommendationSearcher = HitsSearcher(
    applicationID: 'R93EVX2DVK',
    apiKey: '757b56318f855a2589d80754d66d9183',
    indexName: 'vehicles_index',
  );

  List<Hit> _recommendedVehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    List<String> searchHistory = await authProvider.getUserSearchHistory();

    // ✅ Remove short words & duplicates
    searchHistory = searchHistory
        .where((term) => term.length > 2) // Remove words like "a", "b"
        .toSet() // Remove duplicates
        .toList();
    print("Filtered Search History: $searchHistory");

    if (searchHistory.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ✅ Perform multiple searches using Algolia's multi-query search
      final responses = await Future.wait(
        searchHistory.map((term) async {
          _recommendationSearcher.applyState(
                (state) => state.copyWith(query: term, hitsPerPage: 8),
          );

          return await _recommendationSearcher.responses.first;
        }),
      );

      // ✅ Merge results from all searches
      List<Hit> allResults = responses.expand((res) => res.hits.cast<Hit>()).toList();

      setState(() {
        _recommendedVehicles = allResults;
        _isLoading = false;
      });

      print("Final Recommendations: $_recommendedVehicles");
    } catch (error) {
      print("Error fetching recommendations: $error");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_recommendedVehicles.isEmpty) {
      return Center(child: Text('No recommendations found.'));
    }

    return SizedBox(
      height: 250, // ✅ Set fixed height for horizontal scrolling
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // ✅ Horizontal scrolling
        itemCount: _recommendedVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _recommendedVehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildVehicleCard(Hit vehicle) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsScreen(vehicleId: vehicle['vehicle_id'].toString()),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Vehicle Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                vehicle['main_photo'] ?? '',
                width: 180,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 180,
                  height: 120,
                  color: Colors.grey[300],
                  child: Icon(Icons.car_repair, color: Colors.grey, size: 40),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vehicle['make']} ${vehicle['model']}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Year: ${vehicle['yr_of_mfg']} • Fuel: ${vehicle['fuel']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
