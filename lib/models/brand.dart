class Brand {
  final String makeName;
  final String imageUrl;
  final String id;

  Brand({required this.makeName, required this.imageUrl, required this.id});

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      makeName: json['make_name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      id: json['id'] as String? ?? '',
    );
  }
}