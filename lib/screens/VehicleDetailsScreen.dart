import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/vehicle.dart';
import '../models/vehicle_details.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:intl/intl.dart'; // For time-based greeting


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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _vehicleDetails = ApiService().fetchVehicleDetails(widget.vehicleId);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Scaffold(
      floatingActionButton: _buildFloatingButtons(theme),
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
              _buildSliverAppBar(context, images, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(vehicle, textTheme, colors),
                      const SizedBox(height: 24),
                      _buildDivider(colors),
                      const SizedBox(height: 24),
                      _buildFeatureSection(features, theme),
                      _buildRelatedVehiclesSection(snapshot.data!.relatedByBrand, snapshot.data!.relatedByColor, snapshot.data!.vehicle, theme),

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
  Widget _buildFloatingButtons(ThemeData theme) {
    final colors = theme.colorScheme;
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
          child: Icon(Icons.share, color: colors.onPrimary),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white, // Icon color
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'whatsappButton',
          onPressed: () async {
            final vehicle = await _vehicleDetails;
            if (vehicle.vehicle != null) {
              final v = vehicle.vehicle!;

              // Get current hour
              int hour = DateTime.now().hour;
              String greeting;

              if (hour < 12) {
                greeting = "Good morning";
              } else if (hour < 18) {
                greeting = "Good afternoon";
              } else {
                greeting = "Good evening";
              }

              final String vehicleText = ''' 
              🚗 *$greeting, I'm interested in this vehicle ${v.yrOfMfg.substring(0, 4)} ${v.makeName} ${v.modelName}!*  
              
              ⚙️ *Stock ID:* ${v.stockID}  
              🛞 *Trans:* ${v.transm}  
              ⛽ *Fuel Type:* ${v.fuel}  
              ⚙️ *Drive Type:* ${v.drive}  
              🏎 *Engine:* ${v.engineCc} CC  
              🎨 *Color:* ${v.colour}  
              📍 *Location:* ${v.locationName}  
                    ''';

              final link = WhatsAppUnilink(
                phoneNumber: "+254748222222", // Ensure it's in international format
                text: vehicleText,
              );

              // Fix: Use launchUrlString instead of launchUrl()
              if (!await launchUrlString(link.toString(), mode: LaunchMode.externalApplication)) {
                throw 'Could not launch WhatsApp';
              }
            }
          },
          child: const Icon(Icons.chat),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
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
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text(
                    'Downloading images...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
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

  SliverAppBar _buildSliverAppBar(BuildContext context, List<String> images, ThemeData theme) {
    final colors = theme.colorScheme;
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
                    initialIndex: _currentPage,
                  ),
                ),
              )
                  : null,
              child: _buildImageCarousel(images),
            ),
            _buildImageGradient(colors),
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

  // Add this new widget in the _VehicleDetailsScreenState class
  Widget _buildDotsIndicator(int count, int currentIndex, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: currentIndex == index ? 20 : 6,
          decoration: BoxDecoration(
            color: currentIndex == index ? colors.primary : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

// Update the _buildImageCarousel widget to include dots indicator
  Widget _buildImageCarousel(List<String> images) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          // Explicitly enable scroll physics
          physics: const ClampingScrollPhysics(),
          onPageChanged: (int index) {
            setState(() => _currentPage = index);
          },
          itemBuilder: (context, index) => GestureDetector(
            // Allow both vertical and horizontal drags
            behavior: HitTestBehavior.opaque,
            onTap: () => images.isNotEmpty
                ? Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ImageGallery(
                  images: images,
                  initialIndex: _currentPage,
                ),
              ),
            )
                : null,
            child: CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => const _ErrorPlaceholder(),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildDotsIndicator(images.length, _currentPage, Theme.of(context).colorScheme),
        ),
      ],
    );
  }

  Widget _buildImageGradient(ColorScheme colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surface.withOpacity(0.3),
            Colors.transparent,
            Colors.transparent,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
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
        height: 40,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: images.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 65,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentPage == index
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

  Widget _buildTitleSection(Vehicle vehicle, TextTheme textTheme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stock ID with iOS-style badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'STOCK ID: ${vehicle.stockID}',
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Title with dynamic text scaling
        Text(
          '${vehicle.yrOfMfg.substring(0, 4)} ${vehicle.makeName} ${vehicle.modelName}',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14 * MediaQuery.of(context).textScaleFactor,
          ),
        ),
        const SizedBox(height: 15),
        // iOS-style detail grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 14,
          childAspectRatio: 1.6,
          children: [
            _buildDetailCell(
              icon: CupertinoIcons.gear,
              label: 'Transm:',
              value: vehicle.transm,
              colors: colors,
            ),
            _buildDetailCell(
              icon: CupertinoIcons.drop,
              label: 'Fuel:',
              value: vehicle.fuel,
              colors: colors,
            ),
            _buildDetailCell(
              icon: CupertinoIcons.car_detailed,
              label: 'Drive:',
              value: vehicle.drive,
              colors: colors,
            ),
            _buildDetailCell(
              icon: CupertinoIcons.speedometer,
              label: 'Mileage:',
              value: '${vehicle.mileage} km',
              colors: colors,
            ),
            _buildDetailCell(
              icon: CupertinoIcons.paintbrush,
              label: 'Colour:',
              value: vehicle.colour,
              colors: colors,
            ),
            _buildDetailCell(
              icon: CupertinoIcons.bolt,
              label: 'Engine:',
              value: '${vehicle.engineCc} CC',
              colors: colors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCell({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: colors.secondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(List<String> features, ThemeData theme) {
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: colors.outline),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Prevents scrolling inside a scrollable parent
          itemCount: features.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      features[index],
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRelatedVehiclesSection(List<Vehicle> relatedByBrand, List<Vehicle> relatedByColor, Vehicle vehicle, ThemeData theme) {
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container (
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (relatedByColor.isNotEmpty) ...[

              ListTile(
                title: Text(
                  'Other ${vehicle.makeName} ${vehicle.modelName} colours',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _buildHorizontalVehicleList(relatedByColor),
            ],
            if (relatedByBrand.isNotEmpty) ...[
              const SizedBox(height: 24),
              ListTile(
                title: Text(
                  'Similar Vehicles by Brand',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _buildHorizontalVehicleList(relatedByBrand),
            ],
          ],
        ),
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
                          const SizedBox(height: 1),
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

  Widget _buildDivider(ColorScheme colors) {
    return Divider(height: 1, color: colors.outline);
  }

  Widget _buildShimmerLoading() {
    final colors = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colors.surfaceVariant,
      highlightColor: colors.surface,
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
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 50),
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () {/*...*/},
            child: Text('Try Again', style: textTheme.labelLarge),
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
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.onSurface),
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
              onPageChanged: (index) {
                _transformationController.value = Matrix4.identity();
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) => GestureDetector(
                onDoubleTap: () => _handleDoubleTap(),
                child: InteractiveViewer(
                  panAxis: PanAxis.vertical,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image, size: 50, color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildThumbnailStrip(colors),

        ],
      ),
    );
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()
        ..translate(0.0, 0.0)
        ..scale(3.0);
    }
  }

  Widget _buildThumbnailStrip(ColorScheme colors) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 10),
              curve: Curves.easeInOut,
            );
            setState(() => _currentIndex = index);
          },
          child: Container(
            width: 50,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentIndex == index ? colors.primary : colors.outline,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
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
