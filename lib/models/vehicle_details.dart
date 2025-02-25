import 'package:ah_customer/models/vehicle.dart';

class VehicleDetails {
  final Vehicle vehicle;
  final List<Vehicle> relatedByBrand;
  final List<Vehicle> relatedByColor;
  final List<String> vehicleFeatures;  // ✅ Now a list of feature names

  VehicleDetails({
    required this.vehicle,
    required this.relatedByBrand,
    required this.relatedByColor,
    required this.vehicleFeatures,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      vehicle: Vehicle.fromJson(json['vehicle']),
      relatedByBrand: (json['related_by_brand'] as List<dynamic>?)
          ?.map((e) => Vehicle.fromJson(e))
          .toList() ??
          [],
      relatedByColor: (json['related_by_color'] as List<dynamic>?)
          ?.map((e) => Vehicle.fromJson(e))
          .toList() ??
          [],
      vehicleFeatures: List<String>.from(json['vehicle_features'] ?? []),  // ✅ Correctly maps features
    );
  }
}
