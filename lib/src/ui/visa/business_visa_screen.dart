import 'package:flutter/material.dart';
import 'package:flutter_sd_consultant/src/ui/visa/visa_category_screen.dart';

/// Business Visa listing screen.
class BusinessVisaScreen extends StatelessWidget {
  const BusinessVisaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VisaCategoryScreen(
      screenTitle: 'Business Visa',
      bannerHeadline: 'Expand Your Business\nGlobally',
      bannerSubtitle: 'Corporate setup & investor visa guidance for premier commercial centers',
      watermarkIcon: Icons.business_center_rounded,
      visas: [],
    );
  }
}




