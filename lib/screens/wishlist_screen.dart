import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehicle.dart';
import '../models/vehicle_details.dart';
import '../services/api_service.dart';
import '../widgets/VehicleCard.dart';

class WishlistScreen extends StatefulWidget {
  @override
  _WishlistScreenState createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Vehicle> wishlist = [];
  bool isGridView = true;
  bool isLoading = false; // ✅ Added to show loading indicator

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteIds = prefs.getStringList('favorites') ?? [];
    List<Vehicle> fetchedVehicles = [];

    for (String vehicleId in favoriteIds) {
      try {
        VehicleDetails? vehicleDetails = await ApiService().fetchVehicleDetails(vehicleId);

        if (vehicleDetails != null && vehicleDetails.vehicle != null) {
          Vehicle vehicle = Vehicle(
            vehicleId: vehicleDetails.vehicle.vehicleId,
            mainPhoto: vehicleDetails.vehicle.mainPhoto,
            makeName: vehicleDetails.vehicle.makeName,
            modelName: vehicleDetails.vehicle.modelName,
            stockID: vehicleDetails.vehicle.stockID,
            yrOfMfg: vehicleDetails.vehicle.yrOfMfg,
            fuel: vehicleDetails.vehicle.fuel,
            mileage: vehicleDetails.vehicle.mileage,
            transm: vehicleDetails.vehicle.transm,
            engineCc: vehicleDetails.vehicle.engineCc ?? '',
            colour: vehicleDetails.vehicle.colour ?? '',
            locationName: vehicleDetails.vehicle.locationName ?? '',
            drive: vehicleDetails.vehicle.drive ?? '',
            images: vehicleDetails.vehicle.images ?? [], // ✅ Ensure images are handled
          );
          fetchedVehicles.add(vehicle);
        }
      } catch (e) {
        print("Error fetching vehicle $vehicleId: $e");
      }
    }

    setState(() {
      wishlist = fetchedVehicles;
      isLoading = false;
    });
  }

  Future<void> _clearWishlist() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorites');
    setState(() {
      wishlist.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
          ),
          if (wishlist.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _clearWishlist(),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // ✅ Show loader while fetching data
          : wishlist.isEmpty
          ? const Center(
        child: Text(
          'No favorites yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadWishlist,
        child: isGridView ? _buildGridView() : _buildListView(),
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        itemCount: wishlist.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return VehicleCard(car: wishlist[index]);
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: wishlist.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: VehicleCard(car: wishlist[index]),
        );
      },
    );
  }
}
