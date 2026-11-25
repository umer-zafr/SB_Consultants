const String kAllCountriesId = 'all';

class CountryModel {
  const CountryModel({
    required this.id,
    required this.name,
    this.flagEmoji,
    this.flagImageUrl,
  });

  final String id;
  final String name;
  final String? flagEmoji;
  final String? flagImageUrl;

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      flagEmoji: json['flag_emoji'] as String?,
      flagImageUrl: json['flag_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'flag_emoji': flagEmoji,
      'flag_image_url': flagImageUrl,
    };
  }
}

