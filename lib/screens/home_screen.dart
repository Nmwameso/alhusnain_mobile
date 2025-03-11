import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';
import '../screens/car_chooser.dart';
import '../screens/filters_screen.dart';
import '../screens/home_contents.dart';
import '../screens/wishlist_screen.dart';
import '../screens/search_screen.dart';
import '../screens/direct_import_screen.dart'; // ✅ Import Direct Import Screen
import '../widgets/CustomDrawer.dart';

enum CarLayout { grid, list }

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  CarLayout _carLayout = CarLayout.grid;
  bool _isDrawerOpen = false;
  final double drawerWidth = 355;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
    });
  }

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
          title: const Text("Find Your Vehicle", textAlign: TextAlign.center),
          content: const Text("Would you like to use the Car Chooser or proceed directly to search?", textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => CarChooserScreen()));
              },
              child: const Text("Use Car Chooser"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final filters = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FiltersScreen(carLayout: _carLayout, onToggleLayout: _toggleLayout)),
                );
                if (filters != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleSearchPage(
                        selectedBrand: filters['selectedBrand'],
                        selectedModel: filters['selectedModel'],
                        selectedColor: filters['selectedColor'],
                        carLayout: _carLayout,
                        onToggleLayout: _toggleLayout,
                      ),
                    ),
                  );
                }
              },
              child: const Text("Proceed to Search"),
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
      DirectImportScreen(), // ✅ Added Direct Import Screen
    ];

    return Stack(
      children: [
        // 🔹 Custom Drawer
        Positioned(
          left: _isDrawerOpen ? 0 : -drawerWidth,
          top: 0,
          bottom: 0,
          child: CustomDrawer(
            drawerWidth: drawerWidth,
            onClose: _closeDrawer,
          ),
        ),

        // 🔹 Main Content (Shrinks when drawer opens)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(_isDrawerOpen ? drawerWidth * 0.2 : 0, 0, 0),
          child: Transform.scale(
            scale: _isDrawerOpen ? 0.65 : 1.0, // ✅ Smooth centered shrink effect
            alignment: Alignment.center, // ✅ Ensures the shrink effect is centered
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: _isDrawerOpen ? BorderRadius.circular(20) : BorderRadius.zero, // ✅ Rounded Borders
                boxShadow: _isDrawerOpen
                    ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: _isDrawerOpen ? BorderRadius.circular(30) : BorderRadius.zero, // ✅ Clipping the content
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('AL-HUSNAIN MOTORS'),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: _toggleDrawer,
                    ),
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
                    destinations: [
                      const NavigationDestination(
                        icon: Icon(Icons.home_outlined, size: 28),
                        selectedIcon: Icon(Icons.home, size: 28),
                        label: 'Home',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.directions_car_outlined, size: 28),
                        selectedIcon: Icon(Icons.directions_car, size: 28),
                        label: 'Vehicles',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.favorite_border, size: 28),
                        selectedIcon: Icon(Icons.favorite, size: 28, color: Colors.red),
                        label: 'Wishlist',
                      ),
                      const NavigationDestination(
                        icon: Icon(Icons.local_shipping_outlined, size: 28), // ✅ Added Direct Import Icon
                        selectedIcon: Icon(Icons.local_shipping, size: 28),
                        label: 'Direct Import',
                      ),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
