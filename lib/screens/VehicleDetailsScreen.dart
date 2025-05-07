import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import '../models/vehicle.dart';
import '../models/vehicle_details.dart';
import '../services/api_service.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailsScreen({Key? key, required this.vehicleId}) : super(key: key);

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late Future<VehicleDetails> _vehicleDetails;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoadingShare = false;

  @override
  void initState() {
    super.initState();
    _vehicleDetails = ApiService().fetchVehicleDetails(widget.vehicleId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: _buildFloatingButtons(),
      body: FutureBuilder<VehicleDetails>(
        future: _vehicleDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          } else if (snapshot.hasError) {
            return _buildErrorScreen('Something went wrong.');
          } else if (!snapshot.hasData || snapshot.data!.vehicle == null) {
            return _buildErrorScreen('Vehicle not found.');
          }

          final vehicle = snapshot.data!.vehicle!;
          final images = [vehicle.mainPhoto, ...vehicle.images];

          return CustomScrollView(
            slivers: [
              _buildAppBar(images),
              SliverToBoxAdapter(
                child: _buildDetailsContent(vehicle),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildRelatedVehicles(snapshot.data!.relatedByColor, snapshot.data!.relatedByBrand),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✅ AppBar with Blurred Background
  Widget _buildAppBar(List<String> images) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: images.length,
              itemBuilder: (_, index) => CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[300]),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildPageIndicator(images.length),
            ),
            // Below PageView inside Stack
            Positioned(
              bottom: 5, // Higher up so it doesn't overlap page dots
              left: 0,
              right: 0,
              child: SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _currentPage == index ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: images[index],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[300]),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ✅ Vehicle Details Layout
  Widget _buildDetailsContent(Vehicle vehicle) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vehicle.yrOfMfg.substring(0, 4)} ${vehicle.makeName} ${vehicle.modelName}',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.outline),
          const SizedBox(height: 16),
          _buildDetailRow('Transmission', vehicle.transm),
          _buildDetailRow('Fuel Type', vehicle.fuel),
          _buildDetailRow('Drive', vehicle.drive),
          _buildDetailRow('Mileage', '${vehicle.mileage} km'),
          _buildDetailRow('Color', vehicle.colour),
          _buildDetailRow('Engine Capacity', '${vehicle.engineCc} CC'),
          _buildDetailRow('Location', vehicle.locationName),
        ],
      ),
    );
  }

  Widget _buildRelatedVehicles(List<Vehicle> relatedByColor, List<Vehicle> relatedByBrand) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (relatedByColor.isNotEmpty) ...[
          Text(
            'Other Colors of this Model',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: relatedByColor.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildVehicleCard(relatedByColor[index]),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (relatedByBrand.isNotEmpty) ...[
          Text(
            'Similar Vehicles by Brand',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: relatedByBrand.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildVehicleCard(relatedByBrand[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleCard(Vehicle car) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailsScreen(vehicleId: car.vehicleId),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔷 Vehicle Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: car.mainPhoto,
                height: 100,
                width: 170,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.directions_car),
              ),
            ),

            // 🔷 Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${car.makeName} ${car.modelName}',
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _buildCompactInfoRow('StockID', car.stockID),
                    _buildCompactInfoRow('Year', car.yrOfMfg.substring(0, 4)),
                    _buildCompactInfoRow('Fuel', car.fuel),
                    _buildCompactInfoRow('Trans', car.transm),
                    _buildCompactInfoRow('Mileage', '${car.mileage} km'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: textTheme.bodyLarge),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Floating Buttons
  Widget _buildFloatingButtons() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'share',
          backgroundColor: colors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onPressed: _isLoadingShare ? null : _shareVehicle,
          child: _isLoadingShare
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.share),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'whatsapp',
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onPressed: _contactWhatsApp,
          child: const Icon(Icons.chat),
        ),
      ],
    );
  }

  // ✅ Contact Seller via WhatsApp
  Future<void> _contactWhatsApp() async {
    final details = await _vehicleDetails;
    final v = details.vehicle!;

    final link = WhatsAppUnilink(
      phoneNumber: "+254748222222",
      text: "Hello, I am interested in ${v.makeName} ${v.modelName} (${v.yrOfMfg})!",
    );
    if (!await launchUrlString(link.toString(), mode: LaunchMode.externalApplication)) {
      throw 'Could not open WhatsApp';
    }
  }

  // ✅ Share vehicle images
  Future<void> _shareVehicle() async {
    final vehicle = await _vehicleDetails;
    final v = vehicle.vehicle!;
    final images = [v.mainPhoto, ...v.images];
    final mapUrls = {
      'Mombasa': 'https://maps.app.goo.gl/tjH5xv39EmvdFB5SA',
      'Nairobi': 'https://maps.app.goo.gl/j5HkE2qJKG7HGixX9',
      'Kisumu': 'https://maps.app.goo.gl/zqYXtFAWFCFpUyBT7',
    };

    setState(() => _isLoadingShare = true);

    try {
      final tempDir = await getTemporaryDirectory();
      List<XFile> files = [];

      for (var i = 0; i < images.length; i++) {
        final imageUrl = images[i];
        final fileName = 'vehicle_$i.jpg';
        final filePath = '${tempDir.path}/$fileName';

        await Dio().download(imageUrl, filePath);
        files.add(XFile(filePath));
      }

      // Normalize location name
      String formattedLocation = v.locationName.trim().toLowerCase();
      final mapUrlsLower = {
        for (var entry in mapUrls.entries) entry.key.toLowerCase(): entry.value,
      };
      String locationUrl = mapUrlsLower[formattedLocation] ?? 'https://www.google.com/maps';

      final vehicleText = '''
      🚗 *Check out this ${v.yrOfMfg.substring(0, 4)} ${v.makeName} ${v.modelName}!*  
      
      ⚙️ *Stock ID:* ${v.stockID}  
      🛞 *Trans:* ${v.transm}  
      ⛽ *Fuel Type:* ${v.fuel}  
      ⚙️ *Drive Type:* ${v.drive}  
      🏎 *Engine:* ${v.engineCc} CC  
      🎨 *Color:* ${v.colour}  
      📍 *Location:* ${v.locationName}  
      🌍 *View on Maps:* $locationUrl  
      
      📸 *Images attached below!*
      ''';

      // Copy text to clipboard
      await Clipboard.setData(ClipboardData(text: vehicleText));

      // Share files
      await Share.shareXFiles(files);

      // Notify Android users
      if (Platform.isAndroid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle details copied. Paste it in WhatsApp after sharing.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share vehicle.')),
      );
      print('Error sharing vehicle: $e');
    } finally {
      setState(() => _isLoadingShare = false);
    }
  }


  // ✅ Shimmer Loader
  Widget _buildShimmerLoader() {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.surface,
      child: Column(
        children: [
          Container(height: 300, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(6, (_) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 20,
                width: double.infinity,
                color: Colors.white,
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Error Screen
  Widget _buildErrorScreen(String message) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
