class BodyType {
  final String name;
  final String imageUrl;

  BodyType({required this.name, required this.imageUrl});

  factory BodyType.fromJson(Map<String, dynamic> json) {
    return BodyType(
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}