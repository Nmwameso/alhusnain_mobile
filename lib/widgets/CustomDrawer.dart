import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/about_us_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/socials_screen.dart';

class CustomDrawer extends StatelessWidget {
  final double drawerWidth;
  final VoidCallback onClose;

  const CustomDrawer({
    Key? key,
    required this.drawerWidth,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: drawerWidth,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20), // ✅ Rounded Top-Right
          bottomRight: Radius.circular(20), // ✅ Rounded Bottom-Right
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(25), // ✅ Ensures clipping inside rounded corners
          bottomRight: Radius.circular(25),
        ),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 🔹 Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0E8044), Color(0xFF0A5E32)], // ✅ Modern Green Gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // 🔹 Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Close Button (Aligned to Right)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () {
                        Future.delayed(Duration.zero, onClose);
                      },
                    ),
                  ),

                  // 🔹 User Profile Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // 🔹 User Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                              ? NetworkImage(user.photoUrl!)
                              : const AssetImage( 'assets/logo.png',) as ImageProvider,
                        ),
                        const SizedBox(width: 10),

                        // 🔹 User Name (Prevent Null Issue)
                        Expanded(
                          child: Text(
                            user?.name ?? "Guest",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 🔹 Notification Icon
                        IconButton(
                          icon: const Icon(Icons.notifications, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Scrollable Menu Items
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          _buildDrawerItem(context, Icons.home, "Home", null),
                          _buildDrawerItem(context, Icons.person, "Profile", ProfileScreen()),
                          _buildDrawerItem(context, Icons.group, "Socials", SocialsScreen()),
                          _buildDrawerItem(context, Icons.info, "About", AboutUsScreen()),
                        ],
                      ),
                    ),
                  ),

                  // 🔹 Logout Button (Fixed at Bottom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: const Text("Logout", style: TextStyle(color: Colors.white)),
                      onTap: () {
                        authProvider.logout(context);
                        Navigator.pushReplacementNamed(context, '/login');
                        Future.delayed(Duration.zero, onClose);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget? screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: () {
        Future.delayed(Duration.zero, onClose);
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        }
      },
    );
  }
}
