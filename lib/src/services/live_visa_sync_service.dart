import 'dart:async';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/ui/visa/visa_category_screen.dart';

class LiveVisaSyncService {
  LiveVisaSyncService._();
  static final instance = LiveVisaSyncService._();

  static String _resolveCountryCode(String? countryId, String? countryName) {
    final cId = (countryId ?? '').toLowerCase();
    final cName = (countryName ?? '').toLowerCase();
    if (cId == 'uk' || cName.contains('united kingdom') || cName.contains('britain')) return 'GB';
    if (cId == 'canada' || cName.contains('canada')) return 'CA';
    if (cId == 'australia' || cName.contains('australia')) return 'AU';
    if (cId == 'dubai' || cName.contains('dubai') || cName.contains('emirates') || cName.contains('uae')) return 'AE';
    if (cId == 'usa' || cName.contains('united states') || cName.contains('america')) return 'US';
    if (cId == 'germany' || cName.contains('germany') || cName.contains('schengen')) return 'DE';
    if (cName.contains('ireland')) return 'IE';
    if (cName.contains('turkey')) return 'TR';
    if (cName.contains('saudi')) return 'SA';
    if (cName.contains('malaysia')) return 'MY';
    return 'GB';
  }

  Future<List<VisaItemData>> fetchVisasByCategory(String categoryId) async {
    try {
      final res = await SupabaseDatabaseService.instance.client
          .from('visa_listings')
          .select('*')
          .eq('is_active', true)
          .order('is_featured', ascending: false)
          .order('created_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(res);
      final activeRows = rows.where((r) {
        final cat = (r['category_id'] as String? ?? '').toLowerCase();
        return cat == categoryId.toLowerCase();
      }).toList();

      return activeRows.map((r) {
        final countryCode = _resolveCountryCode(
          r['country_id'] as String?,
          r['country_name'] as String?,
        );

        return VisaItemData(
          id: (r['id'] as String?),
          countryCode: countryCode,
          countryName: (r['country_name'] as String?) ?? '',
          title: (r['title'] as String?) ?? '',
          subtitle: (r['subtitle'] as String?) ?? '',
          duration: (r['processing_time'] as String?) ??
              (r['duration'] as String?) ??
              '3-4 weeks',
          validity: (r['validity'] as String?) ?? 'Standard Validity',
          approvalRate: (r['success_rate'] as String?) ??
              (r['approval_rate'] as String?) ??
              '95% approved',
          fee: (r['fee'] as String?) ?? 'PKR 30,000',
          badgeText: (r['badge_text'] as String?) ??
              ((r['is_featured'] == true) ? 'Popular' : null),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Stream<List<VisaItemData>> streamVisasByCategory(String categoryId) {
    try {
      return SupabaseDatabaseService.instance.client
          .from('visa_listings')
          .stream(primaryKey: ['id'])
          .handleError((_) => <Map<String, dynamic>>[])
          .map((rows) {
            final activeRows = rows.where((r) {
              final active = r['is_active'] as bool? ?? true;
              final cat = (r['category_id'] as String? ?? '').toLowerCase();
              return active && cat == categoryId.toLowerCase();
            }).toList();

            return activeRows.map((r) {
              final countryCode = _resolveCountryCode(
                r['country_id'] as String?,
                r['country_name'] as String?,
              );

              return VisaItemData(
                id: (r['id'] as String?),
                countryCode: countryCode,
                countryName: (r['country_name'] as String?) ?? '',
                title: (r['title'] as String?) ?? '',
                subtitle: (r['subtitle'] as String?) ?? '',
                duration: (r['processing_time'] as String?) ?? (r['duration'] as String?) ?? '3-4 weeks',
                validity: (r['validity'] as String?) ?? 'Standard Validity',
                approvalRate: (r['success_rate'] as String?) ?? (r['approval_rate'] as String?) ?? '95% approved',
                fee: (r['fee'] as String?) ?? 'PKR 30,000',
                badgeText: (r['badge_text'] as String?) ??
                    ((r['is_featured'] == true) ? 'Popular' : null),
              );
            }).toList();
          });
    } catch (_) {
      return const Stream.empty();
    }
  }
}
