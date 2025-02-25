class Location {
  final String id;
  final String locationName;

  Location({required this.id, required this.locationName});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String? ?? '',
      locationName: json['location_name'] as String? ?? '',
    );
  }
}