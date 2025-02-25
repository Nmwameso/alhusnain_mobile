import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/vehicle.dart';
import '../models/vehicle_details.dart';
import '../services/api_service.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;
  const VehicleDetailsScreen({Key? key, required this.vehicleId}) : super(key: key);

  @override
  _VehicleDetailsScreenState createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late Future<VehicleDetails> _vehicleDetails;
  int _selectedImageIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vehicleDetails = ApiService().fetchVehicleDetails(widget.vehicleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _buildFloatingButtons(),
      body: FutureBuilder<VehicleDetails>(
        future: _vehicleDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          } else if (snapshot.hasError) {
            return _buildErrorScreen('Failed to load details. Please try again.');
          } else if (!snapshot.hasData || snapshot.data!.vehicle == null) {
            return _buildErrorScreen('No data available.');
          }

          final vehicle = snapshot.data!.vehicle;
          final images = [vehicle.mainPhoto, ...vehicle.images];
          final features = snapshot.data!.vehicleFeatures;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(context, images),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(vehicle),
                      const SizedBox(height: 24),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      _buildFeatureSection(features),
                      const SizedBox(height: 24),
                      _buildRelatedVehiclesSection(snapshot.data!.relatedByBrand, snapshot.data!.relatedByColor, snapshot.data!.vehicle),

                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Floating Buttons for Contact Seller & Share
  Widget _buildFloatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'shareButton',
          onPressed: () async {
            final vehicle = await _vehicleDetails;
            if (vehicle.vehicle != null) {
              await _shareVehicleImages(vehicle.vehicle!);
            }
          },
          child: const Icon(Icons.share),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  /// Share Vehicle Images
  Future<void> _shareVehicleImages(Vehicle vehicle) async {
    final Map<String, String> mapUrls = {
      'Mombasa': 'https://maps.app.goo.gl/tjH5xv39EmvdFB5SA',
      'Nairobi': 'https://maps.app.goo.gl/j5HkE2qJKG7HGixX9',
      'Kisumu': 'https://maps.app.goo.gl/zqYXtFAWFCFpUyBT7',
    };
    
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Downloading images...'),
              ],
            ),
          ),
        );

        final tempDir = await getTemporaryDirectory();
        final List<XFile> imageFiles = [];
        final List<String> images = [vehicle.mainPhoto, ...vehicle.images];

        for (var i = 0; i < images.length; i++) {
          final imageUrl = images[i];
          final fileName = 'vehicle_$i.jpg';
          final filePath = '${tempDir.path}/$fileName';

          await Dio().download(imageUrl, filePath);
          imageFiles.add(XFile(filePath));
        }

        // Close loading dialog
        Navigator.pop(context);

        // Normalize location name (trim & lowercase for better matching)
        String formattedLocation = vehicle.locationName.trim().toLowerCase();

        // Create a case-insensitive map
        final Map<String, String> mapUrlsLower = {
          for (var entry in mapUrls.entries) entry.key.toLowerCase(): entry.value
        };

        // Get Google Maps link
        String locationUrl = mapUrlsLower[formattedLocation] ?? 'https://www.google.com/maps';

        // Vehicle details text with Google Maps link
        final String vehicleText = '''
        🚗 *Check out this ${vehicle.yrOfMfg.substring(0, 4)} ${vehicle.makeName} ${vehicle.modelName}!*  
        
        🛞 *Trans:* ${vehicle.transm}  
        ⛽ *Fuel Type:* ${vehicle.fuel}  
        ⚙️ *Drive Type:* ${vehicle.drive}  
        🏎 *Engine:* ${vehicle.engineCc} CC  
        🎨 *Color:* ${vehicle.colour}  
        📍 *Location:* ${vehicle.locationName}  
        🌍 *View on Maps:* $locationUrl  
        
        📸 *Images attached below!*
            ''';

        // Copy text to clipboard (for Android)
        Clipboard.setData(ClipboardData(text: vehicleText));

        // Share images
        await Share.shareXFiles(imageFiles);

        // Show toast for Android users
        if (Platform.isAndroid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details copied! Paste it in WhatsApp after sharing.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog in case of error
        Navigator.pop(context);

        print('Error sharing images: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share images')),
        );
      }

  }

  SliverAppBar _buildSliverAppBar(BuildContext context, List<String> images) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => images.isNotEmpty
                  ? Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ImageGallery(
                    images: images,
                    initialIndex: _selectedImageIndex,
                  ),
                ),
              )
                  : null,
              child: _buildMainImage(images),
            ),
            _buildImageGradient(),
            _buildImageIndicator(images),
            if (images.length > 1) _buildThumbnailPreview(images),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildMainImage(List<String> images) {
    return images.isNotEmpty
        ? CachedNetworkImage(
      imageUrl: images[_selectedImageIndex],
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.grey[200]),
      errorWidget: (context, url, error) => const _ErrorPlaceholder(),
    )
        : const _ErrorPlaceholder();
  }

  Widget _buildImageGradient() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildImageIndicator(List<String> images) {
    return Positioned(
      bottom: images.length > 1 ? 96 : 16,
      left: 16,
      child: Row(
        children: [
          const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '${images.length}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPreview(List<String> images) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => setState(() => _selectedImageIndex = index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedImageIndex == index
                      ? Colors.white
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTitleSection(Vehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STOCKID: ${vehicle.stockID} ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '${vehicle.yrOfMfg.substring(0, 4)} ${vehicle.makeName} ${vehicle.modelName}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${vehicle.transm} • ${vehicle.fuel} • ${vehicle.drive}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),


      ],
    );
  }

  Widget _buildFeatureSection(List<String> features) {
    if (features.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Divider(), // Adds a thin line for better separation
        const SizedBox(height: 8),
        Wrap(
          spacing: 20, // Reduces spacing to prevent overflow
          runSpacing: 10, // Keeps features evenly spaced
          children: features.map((feature) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250), // Prevents overflow
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      // overflow: TextOverflow.ellipsis, // Prevents text overflow
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  Widget _buildRelatedVehiclesSection(List<Vehicle> relatedByBrand, List<Vehicle> relatedByColor, Vehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (relatedByColor.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Other ${vehicle.makeName} ${vehicle.modelName} colours',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildHorizontalVehicleList(relatedByColor),
        ],
        if (relatedByBrand.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Similar Vehicles by Brand',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildHorizontalVehicleList(relatedByBrand),
        ],
      ],
    );
  }


  Widget _buildHorizontalVehicleList(List<Vehicle> vehicles) {
    return SizedBox(
      height: 230, // Increased height slightly to avoid overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final car = vehicles[index];
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
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: CachedNetworkImage(
                      imageUrl: car.mainPhoto,
                      height: 100,
                      width: 170,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  Expanded( // Ensures content doesn't overflow
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Prevents overflow
                        children: [
                          Text(
                            '${car.makeName} ${car.modelName}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _buildCompactInfoRow('StockID', car.stockID),
                          _buildCompactInfoRow('Year', '${car.yrOfMfg.substring(0, 4)}'),
                          _buildCompactInfoRow('Fuel', car.fuel),
                          _buildCompactInfoRow('Mileage', '${car.mileage} km'),
                          _buildCompactInfoRow('Transmission', car.transm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildCompactInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200]);
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(expandedHeight: 280),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 200,
                    height: 28,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => setState(() {
              _vehicleDetails = ApiService().fetchVehicleDetails(widget.vehicleId);
            }),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGallery({required this.images, required this.initialIndex});

  @override
  __ImageGalleryState createState() => __ImageGalleryState();
}

class __ImageGalleryState extends State<_ImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
          ),
          _buildThumbnailStrip(),
        ],
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: 60, // Ensures no overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300), // Smooth transition
              curve: Curves.easeInOut,
            );
            setState(() => _currentIndex = index); // Ensure index updates
          },
          child: Container(
            width: 50,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
