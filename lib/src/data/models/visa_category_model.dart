import 'package:flutter/material.dart';

class VisaCategoryModel {
  const VisaCategoryModel({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
    this.imageAsset,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final String? imageAsset;

  VisaCategoryModel copyWith({
    String? id,
    String? label,
    IconData? icon,
    Color? color,
    String? imageAsset,
  }) {
    return VisaCategoryModel(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }

  factory VisaCategoryModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    return VisaCategoryModel(
      id: id,
      label: json['label'] as String? ?? '',
      icon: _parseIcon(json['icon_name'] as String?),
      color: _parseColor(json['color_hex'] as String?),
      imageAsset: json['image_asset'] as String? ?? _defaultAssetForId(id),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon_name': icon.codePoint.toString(),
      'color_hex': color != null
          ? '#${color!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
          : null,
      'image_asset': imageAsset,
    };
  }

  static String? _defaultAssetForId(String id) {
    return switch (id.toLowerCase().replaceAll('-', '_')) {
      'scholarships' => 'assets/images/scholarships_transparent.png',
      'sponsored_jobs' => 'assets/images/sponsored_jobs_transparent.png',
      'visit' || 'visit_visa' => 'assets/images/visit_visa_transparent.png',
      'business' || 'business_visa' => 'assets/images/business_visa_transparent.png',
      'golden' || 'golden_visa' => 'assets/images/golden_visa_transparent.png',
      'study' || 'study_visa' => 'assets/images/study_visa_transparent.png',
      'work' || 'work_visa' => 'assets/images/work_visa_transparent.png',
      _ => null,
    };
  }

  static IconData _parseIcon(String? iconName) {
    return switch (iconName) {
      'auto_stories_rounded' => Icons.auto_stories_rounded,
      'handshake_rounded' => Icons.handshake_rounded,
      'flight_takeoff_rounded' => Icons.flight_takeoff_rounded,
      'business_center_rounded' => Icons.business_center_rounded,
      'workspace_premium_rounded' => Icons.workspace_premium_rounded,
      'school_rounded' => Icons.school_rounded,
      'work_rounded' => Icons.work_rounded,
      _ => Icons.category_rounded,
    };
  }

  static Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    final clean = hexString.replaceAll('#', '').replaceAll('0x', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return null;
  }
}

