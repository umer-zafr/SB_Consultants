import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';
import 'package:flutter_sd_consultant/src/data/repositories/detail_repository.dart';
import 'package:flutter_sd_consultant/src/ui/detail/detail_screen.dart';
import 'package:flutter_sd_consultant/src/theme/theme.dart';

void main() {
  // #region debug-point A-B:render-evidence
  final evidenceClient = HttpClient();
  for (final dark in [false, true]) {
    testWidgets('audit detail at narrow width ${dark ? "dark" : "light"}', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = dark
          ? buildDarkTheme(primaryColorHex: '#1B3A5C')
          : buildLightTheme(primaryColorHex: '#1B3A5C');
      await tester.pumpWidget(ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: DetailScreen(item: DetailRepository.getDubaiGoldenVisaDetail()),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      final errors = <String>[];
      Object? error;
      while ((error = tester.takeException()) != null) {
        errors.add(error.toString());
      }
      final titles = <String, String>{};
      for (final label in ['Processing Information', 'Eligibility Criteria', 'Fee Breakdown']) {
        final matches = find.text(label);
        if (matches.evaluate().isNotEmpty) {
          titles[label] = tester.widget<Text>(matches.first).style?.color.toString() ?? 'inherited';
        }
      }
      if (const bool.fromEnvironment('AUDIT_LOG')) {
        await tester.runAsync(() async {
          final request = await evidenceClient.postUrl(Uri.parse('http://127.0.0.1:7777/event'));
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode({
            'sessionId': 'theme-visibility-audit',
            'runId': const String.fromEnvironment('AUDIT_RUN', defaultValue: 'pre-fix'),
            'hypothesisId': 'A-B',
            'location': 'detail_screen_test',
            'msg': '[DEBUG] narrow detail rendering',
            'data': {'dark': dark, 'errors': errors, 'headings': titles},
          }));
          await (await request.close()).drain<void>();
        });
      }
      expect(errors, isEmpty);
    });
  }
  // #endregion
  testWidgets('DetailScreen builds and renders UK Student Visa', (WidgetTester tester) async {
    final detail = DetailRepository.getUkStudentVisaDetail();

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            home: DetailScreen(item: detail),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('UK Student Visa'), findsOneWidget);
    expect(find.text('About this visa'), findsOneWidget);
    expect(find.text('Processing Information'), findsOneWidget);
    expect(find.text('Eligibility Criteria'), findsOneWidget);
    expect(find.text('Mandatory Documents'), findsOneWidget);
    expect(find.text('Fee Breakdown'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
    // Ensure NO call or message or chat icon
    expect(find.byIcon(Icons.chat), findsNothing);
    expect(find.byIcon(Icons.call), findsNothing);
    expect(find.byIcon(Icons.phone), findsNothing);
  });

  testWidgets('DetailScreen displays unique varied details for Canada Work Permit', (WidgetTester tester) async {
    final canadaDetail = DetailRepository.getCanadaWorkPermitDetail();

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            home: DetailScreen(item: canadaDetail),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Canada LMIA Work Permit'), findsOneWidget);
    expect(find.text('🇨🇦 Canada'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
  });

  testWidgets('DetailScreen displays unique varied details for Dubai Golden Visa', (WidgetTester tester) async {
    final dubaiDetail = DetailRepository.getDubaiGoldenVisaDetail();

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            home: DetailScreen(item: dubaiDetail),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Dubai 10-Year Golden Visa'), findsOneWidget);
    expect(find.text('🇦🇪 United Arab Emirates'), findsOneWidget);
    expect(find.text('PKR 40,000'), findsWidgets);
  });

  testWidgets('DetailRepository generates tailored details for any generic visa listing', (WidgetTester tester) async {
    const listing = VisaListingModel(
      id: 'ger-c-1',
      title: 'Germany Job Seeker Visa',
      subtitle: 'Germany • Opportunity & Employment',
      categoryName: 'Work Visa',
      categoryId: 'work',
      countryId: 'germany',
      countryName: 'Germany',
      imageUrl: 'https://images.unsplash.com/photo-1587330979470-3595ac045ab0?w=800',
      fee: 'PKR 40,000',
      processingTime: '4-6 wks',
      validity: '1 Year',
      successRate: '95%',
      statusBadge: 'Available',
    );

    final detail = DetailRepository.getDetailForVisa(listing);
    expect(detail.title, contains('Germany'));
    expect(detail.countryFlag.isNotEmpty || detail.countryFlag.contains('🇩🇪'), isTrue);
    expect(detail.timelineSteps, isNotEmpty);
    expect(detail.mandatoryDocuments, isNotEmpty);
    expect(detail.eligibilityCriteria, isNotEmpty);
  });
}
