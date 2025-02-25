class Vehicle {
  final String vehicleId;
  final String makeName;
  final String modelName;
  final String yrOfMfg;
  final String engineCc;
  final String fuel;
  final String transm;
  final String mileage;
  final String colour;
  final String locationName;
  final String drive;
  final String mainPhoto;
  final String stockID;
  final List<String> images;

  Vehicle({
    required this.vehicleId,
    required this.makeName,
    required this.modelName,
    required this.yrOfMfg,
    required this.engineCc,
    required this.fuel,
    required this.transm,
    required this.mileage,
    required this.colour,
    required this.locationName,
    required this.drive,
    required this.mainPhoto,
    required this.stockID,
    required this.images,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicle_id'] ?? '',
      makeName: json['make_name'] ?? 'Unknown',
      modelName: json['model_name'] ?? 'Unknown',
      yrOfMfg: json['yr_of_mfg'] ?? 'N/A',
      engineCc: json['engine_cc']?.toString() ?? 'N/A',
      fuel: json['fuel'] ?? 'N/A',
      transm: json['transm'] ?? 'N/A',
      mileage: json['mileage']?.toString() ?? '0',
      colour: json['colour'] ?? 'N/A',
      locationName: json['location_name'] ?? 'N/A',
      drive: json['drive'] ?? 'N/A',
      mainPhoto: json['main_photo'] ?? '',
      stockID: json['stockID'] ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
