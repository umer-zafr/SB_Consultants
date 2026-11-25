/// Model representing a verified client visa approval / success story.
class SuccessStoryModel {
  const SuccessStoryModel({
    required this.id,
    required this.clientName,
    required this.avatarUrl,
    required this.visaType,
    required this.countryName,
    required this.countryFlag,
    required this.processingTime,
    required this.rating,
    required this.quote,
    required this.universityOrEmployer,
    required this.approvedDate,
    this.badgeText = 'Verified Approval',
  });

  final String id;
  final String clientName;
  final String avatarUrl;
  final String visaType;
  final String countryName;
  final String countryFlag;
  final String processingTime;
  final double rating;
  final String quote;
  final String universityOrEmployer;
  final String approvedDate;
  final String badgeText;

  static double _parseRating(dynamic val) {
    if (val == null) return 5;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? 5;
    }
    return 5;
  }

  factory SuccessStoryModel.fromJson(Map<String, dynamic> json) {
    return SuccessStoryModel(
      id: json['id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      visaType: json['visa_type']?.toString() ?? '',
      countryName: json['country_name']?.toString() ?? '',
      countryFlag: json['country_flag']?.toString() ?? '🌍',
      processingTime: json['processing_time']?.toString() ?? '',
      rating: _parseRating(json['rating']),
      quote: json['quote']?.toString() ?? '',
      universityOrEmployer: json['university_or_employer']?.toString() ?? '',
      approvedDate: json['approved_date']?.toString() ?? '',
      badgeText: json['badge_text']?.toString() ?? 'Verified Approval',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'avatar_url': avatarUrl,
      'visa_type': visaType,
      'country_name': countryName,
      'country_flag': countryFlag,
      'processing_time': processingTime,
      'rating': rating,
      'quote': quote,
      'university_or_employer': universityOrEmployer,
      'approved_date': approvedDate,
      'badge_text': badgeText,
    };
  }
}
