import 'package:ah_customer/models/vehicle.dart';
import 'package:ah_customer/models/vehicle_model.dart';

import 'body_type.dart';
import 'brand.dart';
import 'brand_with_search.dart';
import 'location.dart';

class HomeData {
  final List<BodyType> bodytypes;
  final List<Brand> brands;
  final List<BrandWithSearch> brandsWithSearch;
  final List<VehicleModel> models;
  final List<Location> locations;
  final List<Vehicle> latestCars;
  final List<Vehicle> upcomingCars;

  HomeData({
    required this.bodytypes,
    required this.brands,
    required this.brandsWithSearch,
    required this.models,
    required this.locations,
    required this.latestCars,
    required this.upcomingCars,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      bodytypes: (json['bodytypes'] as List<dynamic>?)
          ?.map((e) => BodyType.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      brands: (json['brands'] as List<dynamic>?)
          ?.map((e) => Brand.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      brandsWithSearch: (json['brands_with_search'] as List<dynamic>?)
          ?.map((e) => BrandWithSearch.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      models: (json['models'] as List<dynamic>?)
          ?.map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      locations: (json['locations'] as List<dynamic>?)
          ?.map((e) => Location.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      latestCars: (json['latest_cars'] as List<dynamic>?)
          ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      upcomingCars: (json['upcoming_cars'] as List<dynamic>?)
          ?.map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}
