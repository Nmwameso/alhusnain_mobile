import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ah_customer/providers/auth_provider.dart';
import 'package:ah_customer/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Map<String, dynamic>>> _directImportFuture;

  @override
  void initState() {
    super.initState();
    _directImportFuture = _fetchDirectImportRequests();
  }

  /// Fetch Direct Import Requests from API
  Future<List<Map<String, dynamic>>> _fetchDirectImportRequests() async {
    try {
      return await ApiService().fetchDirectImportRequests();
    } catch (e) {
      print("Error fetching direct import requests: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return DefaultTabController(
      length: 2, // ✅ Two tabs: Profile & Direct Import Cars
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Profile'),
              Tab(icon: Icon(Icons.directions_car), text: 'Direct Import Cars'),
            ],
          ),
        ),
        body: user == null
            ? _buildNoUserView(context)
            : TabBarView(
          children: [
            _buildUserProfile(context, user, authProvider), // ✅ Profile Tab
            _buildDirectImportCars(), // ✅ Direct Import Cars Tab
          ],
        ),
      ),
    );
  }

  /// ✅ UI when no user is logged in
  Widget _buildNoUserView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No user logged in',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.login),
            label: const Text('Login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ UI for logged-in users (Profile Tab)
  Widget _buildUserProfile(BuildContext context, user, AuthProvider authProvider) {
    return Column(
      children: [
        _buildProfileHeader(user),
        Expanded(child: _buildUserInfo(user)),
        _buildLogoutButton(context, authProvider),
      ],
    );
  }

  /// ✅ Google-style Profile Header
  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// ✅ User details in a Google-style card format
  Widget _buildUserInfo(user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            _buildInfoTile(Icons.person, 'Full Name', user.name),
            _buildDivider(),
            _buildInfoTile(Icons.email, 'Email', user.email),
          ],
        ),
      ),
    );
  }

  /// ✅ Single information tile
  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: const TextStyle(color: Colors.black87)),
    );
  }

  /// ✅ Logout button
  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: ElevatedButton.icon(
        onPressed: () {
          authProvider.logout(context);
          Navigator.pushReplacementNamed(context, '/login');
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// ✅ Direct Import Cars Tab with API Data
  Widget _buildDirectImportCars() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _directImportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // ✅ Show loader while fetching
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text("No Direct Import Requests Found"));
        }

        final directImports = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: directImports.length,
          itemBuilder: (context, index) {
            final item = directImports[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.green),
                title: Text("${item['make']} ${item['model']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Features: ${item['features']}"),
                    Text("Status: ${item['status']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text("Requested on: ${item['created_at']}"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ Divider between user details
  Widget _buildDivider() {
    return const Divider(thickness: 1, height: 0, indent: 16, endIndent: 16);
  }
}
