class BrandWithSearch {
  final String makeName;
  final String imageUrl;
  final int searchCount;

  BrandWithSearch({
    required this.makeName,
    required this.imageUrl,
    required this.searchCount,
  });

  factory BrandWithSearch.fromJson(Map<String, dynamic> json) {
    return BrandWithSearch(
      makeName: json['make_name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      searchCount: json['search_count'] as int? ?? 0,
    );
  }
}
