import 'package:flutter/material.dart';
import 'package:flutter_sd_consultant/src/ui/visa/visa_category_screen.dart';

/// Golden Visa listing screen.
class GoldenVisaScreen extends StatelessWidget {
  const GoldenVisaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VisaCategoryScreen(
      screenTitle: 'Golden Visa',
      bannerHeadline: 'Secure Golden Residency\nwith Ease',
      bannerSubtitle: 'Long-term residence permits & second passports for investors & families',
      watermarkIcon: Icons.verified_rounded,
      visas: [],
    );
  }
}
