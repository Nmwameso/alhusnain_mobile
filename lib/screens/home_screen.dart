import 'package:ah_customer/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'car_chooser.dart';
import 'home_contents.dart';
import 'wishlist_screen.dart';
import 'contact_screen.dart';

enum CarLayout { grid, list }

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  CarLayout _carLayout = CarLayout.grid;

  void _onItemTapped(int index) {
    if (index == 1) {
      _showVehicleDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _toggleLayout() {
    setState(() {
      _carLayout = _carLayout == CarLayout.grid ? CarLayout.list : CarLayout.grid;
    });
  }

  void _showVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Find Your Vehicle",
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, // Ensures center alignment
            children: [
              Text(
                "Would you like to use the Car Chooser or proceed directly to search?",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center, // Centers the buttons
          actions: [
            Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CarChooserScreen()),
                      );
                    },
                    child: Text("Use Car Chooser"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    child: Text("Proceed to Search"),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeContents(carLayout: _carLayout, onToggleLayout: _toggleLayout),
      VehicleSearchPage(carLayout: _carLayout, onToggleLayout: _toggleLayout),
      WishlistScreen(),
      ContactScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AL-HUSNAIN MOTORS'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_carLayout == CarLayout.grid ? Icons.list : Icons.grid_view),
            onPressed: _toggleLayout,
            tooltip: 'Switch Layout',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        indicatorColor: Colors.blue.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 28),
            selectedIcon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined, size: 28),
            selectedIcon: Icon(Icons.directions_car, size: 28),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border, size: 28),
            selectedIcon: Icon(Icons.favorite, size: 28, color: Colors.red),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_mail_outlined, size: 28),
            selectedIcon: Icon(Icons.contact_mail, size: 28),
            label: 'Contact',
          ),
        ],
      ),
    );
  }
}
