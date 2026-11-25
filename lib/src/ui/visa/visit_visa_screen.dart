import 'package:flutter/material.dart';
import 'package:flutter_sd_consultant/src/ui/visa/visa_category_screen.dart';

/// Visit Visa listing screen.
class VisitVisaScreen extends StatelessWidget {
  const VisitVisaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VisaCategoryScreen(
      screenTitle: 'Visit Visa',
      bannerHeadline: 'Explore the World\nwith Confidence',
      bannerSubtitle: 'Expert tourist & visitor visa guidance for UK, Canada, Australia & more',
      watermarkIcon: Icons.flight_takeoff_rounded,
      visas: [],
    );
  }
}
