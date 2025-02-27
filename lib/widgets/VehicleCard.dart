import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/vehicle.dart';
import '../screens/VehicleDetailsScreen.dart';
import 'FavoriteIcon.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle car;

  const VehicleCard({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsScreen(vehicleId: car.vehicleId),
          ),
        );
      },
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: car.mainPhoto,
                  width: double.infinity,
                  height: 100,
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
                        Text('Image not available',
                            style: TextStyle(fontSize: 10)),
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
                        fontSize: 14,
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('StockID', '${car.stockID}'),
                  const SizedBox(height: 3),
                  _buildInfoRow('Year', '${car.yrOfMfg.substring(0, 4)}'),
                  const SizedBox(height: 3),
                  _buildInfoRow('Fuel', car.fuel),
                  const SizedBox(height: 3),
                  _buildInfoRow('Mileage', '${car.mileage} km'),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
