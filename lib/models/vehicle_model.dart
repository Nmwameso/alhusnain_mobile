import 'brand.dart';

class VehicleModel {
  final String id;
  final String modelName;
  final Brand make;

  VehicleModel({
    required this.id,
    required this.modelName,
    required this.make,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
      make: Brand.fromJson(json['make'] as Map<String, dynamic>? ?? {}),
    );
  }
}
