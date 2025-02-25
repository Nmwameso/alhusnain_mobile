import 'package:ah_customer/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class CarChooserScreen extends StatefulWidget {
  @override
  _CarChooserScreenState createState() => _CarChooserScreenState();
}

class _CarChooserScreenState extends State<CarChooserScreen> {
  String? selectedCategory;
  String? selectedFuelType;

  final List<Map<String, dynamic>> categories = [
    {'label': 'Driving the Family', 'icon': Icons.family_restroom, 'query': "Driving the Family"},
    {'label': 'Off-roading', 'icon': Icons.terrain, 'query': "Off-roading"},
    {'label': 'Uber', 'icon': Icons.local_taxi, 'query': "UBER"},
    {'label': 'Luxury', 'icon': Icons.diamond, 'query': "Luxury"},
  ];

  final List<Map<String, dynamic>> fuelTypes = [
    {'label': 'Petrol', 'icon': Icons.local_gas_station},
    {'label': 'Diesel', 'icon': Icons.ev_station},
    {'label': 'Hybrid', 'icon': Icons.electric_car},
  ];

  void _navigateToSearch() {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a Category to proceed.")),
      );
      return;
    }

    String query = selectedCategory!;
    if (selectedFuelType != null) {
      query += " $selectedFuelType"; // ✅ Combine both if fuel type is selected
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleSearchPage(
          carLayout: CarLayout.list,
          onToggleLayout: () {},
          selectedBrand: query, // ✅ Pass the selection (Category + FuelType if available)
        ),
      ),
    );
  }


  Widget _buildSelectionCard(String label, IconData icon, String? selectedValue, VoidCallback onTap) {
    bool isSelected = label == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 140,
        child: Card(
          elevation: isSelected ? 6 : 2,
          color: isSelected ? Colors.blue.shade100 : Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: isSelected ? Colors.blue : Colors.black54),
                SizedBox(height: 12),
                Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionGrid(String title, List<Map<String, dynamic>> options, String? selectedValue, Function(String?) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            return _buildSelectionCard(
              options[index]['label'],
              options[index]['icon'],
              selectedValue,
                  () => setState(() {
                if (selectedValue == options[index]['label']) {
                  onSelect(null); // ✅ Uncheck if tapped again
                } else {
                  onSelect(options[index]['label']);
                }
              }),
            );
          },
        ),
        SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Choose Your Car")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Select Your Car Type", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildSelectionGrid("Choose a Category:", categories, selectedCategory, (val) => selectedCategory = val),
            SizedBox(height: 16),
            Text("2. Choose Fuel Type", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildSelectionGrid("Select Fuel Type:", fuelTypes, selectedFuelType, (val) => selectedFuelType = val),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _navigateToSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Find My Car", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
