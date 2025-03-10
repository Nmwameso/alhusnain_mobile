import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/brand_with_search.dart';
import '../models/home_data.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../models/vehicle.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/api_service.dart';
import '../widgets/FavoriteIcon.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'VehicleDetailsScreen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for encoding/decoding data


class HomeContents extends StatefulWidget {
  final CarLayout carLayout;
  final VoidCallback onToggleLayout;

  const HomeContents({Key? key, required this.carLayout, required this.onToggleLayout}) : super(key: key);

  @override
  _HomeContentsState createState() => _HomeContentsState();
}

class _HomeContentsState extends State<HomeContents> {
  Set<String> _notifiedCars = {}; // Stores vehicle IDs that are subscribed // Stores subscribed vehicle IDs

  @override
  void initState() {
    super.initState();
    _loadNotifiedCars(); // Load saved data on app startup
  }

  /// **Load Notified Cars from SharedPreferences**
  Future<void> _loadNotifiedCars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('notified_cars');

    if (savedData != null) {
      setState(() {
        _notifiedCars = Set<String>.from(jsonDecode(savedData));
      });
    }
  }

  /// **Save Notified Cars to SharedPreferences**
  Future<void> _saveNotifiedCars() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notified_cars', jsonEncode(_notifiedCars.toList()));
  }
  // void _toggleNotifyMe(BuildContext context, Vehicle car) async {
  //   final apiService = ApiService();
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //   final user = authProvider.currentUser;
  //
  //
  //   if (user == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please log in to receive notifications')),
  //     );
  //     return;
  //   }
  //
  //   setState(() {
  //     if (_notifiedCars.contains(car.vehicleId)) {
  //       _notifiedCars.remove(car.vehicleId);
  //     } else {
  //       _notifiedCars.add(car.vehicleId);
  //     }
  //   });
  //
  //   await _saveNotifiedCars(); // ✅ Save changes to SharedPreferences
  //   try {
  //     if (_notifiedCars.contains(car.vehicleId)) {
  //       // ✅ Send request to register notification
  //       await apiService.submitUpcomingCarNotification(
  //         vehicleId: car.vehicleId,
  //         fullName: user.name,
  //         email: user.email,
  //       );
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('You will be notified when ${car.makeName} ${car.modelName} is available!'),backgroundColor: Colors.green,),
  //       );
  //     } else {
  //       // ❌ Send request to remove notification
  //       await apiService.removeUpcomingCarNotification(car.vehicleId);
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('You will no longer receive updates for ${car.makeName} ${car.modelName}.'), backgroundColor: Colors.orange,),
  //       );
  //     }
  //   } catch (error) {
  //     // ❗ Rollback UI state if API request fails
  //     setState(() {
  //       if (_notifiedCars.contains(car.vehicleId)) {
  //         _notifiedCars.remove(car.vehicleId);
  //       } else {
  //         _notifiedCars.add(car.vehicleId);
  //       }
  //     });
  //     await _saveNotifiedCars(); // ✅ Save updated state after rollback
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${error.toString()}'),backgroundColor: Colors.red,),
  //     );
  //   }
  // }

  Future<void> _toggleNotifyMe(BuildContext context, Vehicle car) async {
    final apiService = ApiService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage notifications')),
      );
      return;
    }

    bool isNotifying = !_notifiedCars.contains(car.vehicleId);

    if (isNotifying) {
      // Show confirmation dialog before enabling notifications
      bool confirmSubscription = await _showSubscriptionDialog(context, car);
      if (!confirmSubscription) return;
    } else {
      // Show confirmation dialog before removing notifications
      bool confirmRemoval = await _showConfirmationDialog(context, car);
      if (!confirmRemoval) return;
    }

    // ✅ Update UI state optimistically
    setState(() {
      if (isNotifying) {
        _notifiedCars.add(car.vehicleId);
      } else {
        _notifiedCars.remove(car.vehicleId);
      }
    });

    await _saveNotifiedCars(); // ✅ Persist changes in SharedPreferences

    try {
      if (isNotifying) {
        // ✅ Register notification with API
        await apiService.submitUpcomingCarNotification(
          vehicleId: car.vehicleId,
          fullName: user.name,
          email: user.email,
        );

        // ✅ Subscribe to Firebase topic for this vehicle
        try {
          await FirebaseMessaging.instance.subscribeToTopic('vehicle_${car.vehicleId}');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('FCM Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You will be notified when ${car.makeName} ${car.modelName} is available!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ❌ Remove notification from API
        await apiService.removeUpcomingCarNotification(car.vehicleId);

        // ✅ Unsubscribe from Firebase topic
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic('vehicle_${car.vehicleId}');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('FCM Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You will no longer receive updates for ${car.makeName} ${car.modelName}.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      // ❗ Rollback UI state if API request fails
      setState(() {
        if (isNotifying) {
          _notifiedCars.remove(car.vehicleId);
        } else {
          _notifiedCars.add(car.vehicleId);
        }
      });

      await _saveNotifiedCars(); // ✅ Save rollback state

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showSubscriptionDialog(BuildContext context, Vehicle car) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Subscribe to Updates?"),
        content: Text("Do you want to receive notifications when ${car.makeName} ${car.modelName} is available  in stock?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            child: Text("Yes"),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed
  }


  Future<bool> _showConfirmationDialog(BuildContext context, Vehicle car) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove Notification?'),
          content: Text('Are you sure you want to stop notifications for ${car.makeName} ${car.modelName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), // ❌ Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true), // ✅ Confirm
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  void _navigateToDetails(BuildContext context, Vehicle car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(vehicleId: car.vehicleId),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
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
                      : () => context.read<HomeProvider>().fetchHomeData(),
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
  Widget _buildContent(HomeData data) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildBrands(data.brandsWithSearch)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Featured Cars'),
          ),
        ),
        _buildCarGrid(data.featuredCars),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Latest Cars'),
          ),
        ),
        _buildCarGrid(data.latestCars),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverToBoxAdapter(
            child: _buildSectionTitle('Upcoming Cars'),
          ),
        ),
        _buildCarGrid(data.upcomingCars, isUpcoming: true), // Pass isUpcoming
      ],
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
  Widget _buildBrands(List<BrandWithSearch> brandsWithSearch) {
    return SizedBox(
      height: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Popular Brands',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: brandsWithSearch.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final brand = brandsWithSearch[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleSearchPage(
                          selectedBrand: brand.makeName,
                          carLayout: widget.carLayout,
                          onToggleLayout: widget.onToggleLayout,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 88,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildBrandImage(brand.imageUrl),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 80,
                          child: Text(
                            brand.makeName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBrandImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Icon(Icons.business, size: 32, color: Colors.grey);
    }

    final isSvg = imageUrl.toLowerCase().endsWith('.svg');
    final cacheManager = DefaultCacheManager();

    return FutureBuilder<File>(
      future: cacheManager.getSingleFile(imageUrl), // Fetch and cache if necessary
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Icon(Icons.broken_image, size: 32, color: Colors.grey);
        }

        final file = snapshot.data!;

        if (isSvg) {
          return SvgPicture.network(
            imageUrl, // Load SVG directly from network
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholderBuilder: (context) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return Image.file(
          file,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          cacheWidth: 128,
          cacheHeight: 128,
        );
      },
    );
  }
  Widget _buildNotifyButton(Vehicle car) {
    bool isNotified = _notifiedCars.contains(car.vehicleId);

    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: () => _toggleNotifyMe(context, car),
        style: ElevatedButton.styleFrom(
          backgroundColor: isNotified ? Colors.red : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        icon: Icon(
          isNotified ? Icons.notifications_off : Icons.notifications_active,
          size: 14,
        ),
        label: Text(isNotified ? 'Unnotify' : 'Notify Me'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return _buildLoading();
        if (provider.error != null) return _buildError(context, provider.error!);
        return _buildContent(provider.homeData!);
      },
    );
  }

  Widget _buildCarCard(BuildContext context, Vehicle car, {bool isUpcoming = false}) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context, car),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: car.mainPhoto,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.car_repair, size: 32, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('Image not available', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteIcon(vehicleId: car.vehicleId),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Text(
                        '${car.makeName} ${car.modelName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  _buildInfoRow(context, 'StockID', '${car.stockID}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, 'Year', '${car.yrOfMfg.substring(0, 4)}'),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, 'Fuel', car.fuel),
                  if (isUpcoming) ...[
                    const SizedBox(height: 8),
                    _buildNotifyButton(car),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarGrid(List<Vehicle> cars, {bool isUpcoming = false}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: widget.carLayout == CarLayout.grid
          ? SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildCarCard(context, cars[index], isUpcoming: isUpcoming),
          childCount: cars.length,
        ),
      )
          : SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) => _buildHorizontalCarCard(context, cars[index], isUpcoming: isUpcoming),
          childCount: cars.length,
        ),
      ),
    );
  }
  Widget _buildHorizontalCarCard(BuildContext context, Vehicle car, {bool isUpcoming = false}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: colors.surface,
        child: GestureDetector(
          onTap: () => _navigateToDetails(context, car),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: car.mainPhoto,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colors.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colors.surfaceVariant,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.car_repair, size: 32, color: colors.onSurfaceVariant),
                                const SizedBox(height: 4),
                                Text(
                                  'Image not available',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: FavoriteIcon(vehicleId: car.vehicleId),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${car.makeName} ${car.modelName}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildCompactInfoRow(context, 'StockID', '${car.stockID}'),
                        _buildCompactInfoRow(context, 'Year', '${car.yrOfMfg.substring(0, 4)}'),
                        _buildCompactInfoRow(context, 'Fuel', car.fuel),

                        if (isUpcoming) ...[
                          const SizedBox(height: 8),
                          _buildNotifyButton(car),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(context, String label, String value) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(context, String label, String value) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,

            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
