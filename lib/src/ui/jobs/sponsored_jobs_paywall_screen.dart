import 'dart:async';
import 'dart:ui';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';
import 'package:flutter_sd_consultant/src/shared/widgets/app_dashboard_bottom_nav.dart';
import 'package:flutter_sd_consultant/src/ui/home/providers/home_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Representation of a verified sponsored job listing item.
class _DirectoryJobItem {
  _DirectoryJobItem({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.flag,
    required this.avatarInitials,
    required this.avatarBgColor,
    required this.salary,
    required this.salaryPeriod,
    required this.postedTime,
    required this.employmentType,
    required this.externalUrl,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String flag;
  final String avatarInitials;
  final int avatarBgColor;
  final String salary;
  final String salaryPeriod;
  final String postedTime;
  final String employmentType;
  final String externalUrl;
  bool isBookmarked = false;
}

/// Representation of an international verified scholarship listing item.
class _DirectoryScholarshipItem {
  _DirectoryScholarshipItem({
    required this.id,
    required this.title,
    required this.institution,
    required this.location,
    required this.flag,
    required this.avatarInitials,
    required this.avatarBgColor,
    required this.funding,
    required this.degreeLevel,
    required this.postedTime,
    required this.externalUrl,
  });

  final String id;
  final String title;
  final String institution;
  final String location;
  final String flag;
  final String avatarInitials;
  final int avatarBgColor;
  final String funding;
  final String degreeLevel;
  final String postedTime;
  final String externalUrl;
  bool isBookmarked = false;
}

/// Screen displaying either:
/// 1. The Locked Directory Paywall (matching `media_1790622659495.png`)
/// 2. The Unlocked Verified Listing (matching `media_1790623542673.png`)
///
/// Features automatic unlocking after payment checkout, testing toggle,
/// filter pills, sorting options, and direct external redirect for sponsored jobs.
class SponsoredJobsPaywallScreen extends ConsumerStatefulWidget {
  const SponsoredJobsPaywallScreen({
    super.key,
    this.isScholarship = false,
    this.forceUnlocked,
  });

  final bool isScholarship;
  final bool? forceUnlocked;

  @override
  ConsumerState<SponsoredJobsPaywallScreen> createState() =>
      _SponsoredJobsPaywallScreenState();
}

class _SponsoredJobsPaywallScreenState
    extends ConsumerState<SponsoredJobsPaywallScreen> {
  int _selectedFilterIndex = 0;
  bool _isUnlocking = false;
  String _selectedSort = 'Recommended';

  String _selectedCountryFilter = 'All';
  String _selectedJobTypeFilter = 'All';
  String _selectedDegreeLevelFilter = 'All';
  String _selectedSalaryFilter = 'All';
  String _selectedFundingFilter = 'All';

  bool _isSearchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _jobsRealtimeChannel;
  RealtimeChannel? _adminBroadcastChannel;
  Timer? _pollingTimer;

  List<_DirectoryJobItem>? _remoteJobs;
  List<_DirectoryScholarshipItem>? _remoteScholarships;

  static String _resolveFlag(String? flag, String location) {
    if (flag != null && flag.trim().isNotEmpty) return flag.trim();
    final loc = location.toLowerCase();
    if (loc.contains('uk') || loc.contains('united kingdom') || loc.contains('london') || loc.contains('manchester') || loc.contains('birmingham')) return '🇬🇧';
    if (loc.contains('canada') || loc.contains('toronto') || loc.contains('vancouver') || loc.contains('ottawa')) return '🇨🇦';
    if (loc.contains('germany') || loc.contains('berlin') || loc.contains('munich') || loc.contains('bonn')) return '🇩🇪';
    if (loc.contains('australia') || loc.contains('sydney') || loc.contains('melbourne')) return '🇦🇺';
    if (loc.contains('uae') || loc.contains('dubai') || loc.contains('abu dhabi')) return '🇦🇪';
    if (loc.contains('usa') || loc.contains('united states') || loc.contains('america')) return '🇺🇸';
    if (loc.contains('turkey') || loc.contains('turkiye')) return '🇹🇷';
    return '🌍';
  }

  static String _resolveInitials(String? initials, String title, String company) {
    if (initials != null && initials.trim().isNotEmpty) return initials.trim().toUpperCase();
    final src = company.trim().isNotEmpty ? company.trim() : title.trim();
    final parts = src.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return src.length >= 2 ? src.substring(0, 2).toUpperCase() : 'SB';
  }

  static int _resolveColor(dynamic val) {
    if (val is int) return val;
    if (val is String && val.trim().isNotEmpty) {
      try {
        final clean = val.replaceAll('#', '').replaceAll('0x', '');
        return int.parse('0xFF$clean');
      } catch (_) {}
    }
    return 0xFF002444;
  }

  Future<void> _fetchLiveItems() async {
    try {
      final client = SupabaseDatabaseService.instance.client;
      if (widget.isScholarship) {
        final res = await client
            .from('sponsored_jobs')
            .select('*')
            .eq('type', 'scholarship')
            .eq('is_active', true)
            .order('is_featured', ascending: false)
            .order('created_at', ascending: false);

        final items = <_DirectoryScholarshipItem>[];
        for (final row in List<Map<String, dynamic>>.from(res)) {
          final title = row['title']?.toString() ?? 'Scholarship';
          final inst = row['company_or_institution']?.toString() ?? row['institution']?.toString() ?? 'International Academy';
          final loc = row['location']?.toString() ?? 'Global';
          items.add(
            _DirectoryScholarshipItem(
              id: row['id']?.toString() ?? '',
              title: title,
              institution: inst,
              location: loc,
              flag: _resolveFlag(row['country_flag']?.toString(), loc),
              avatarInitials: _resolveInitials(row['avatar_initials']?.toString(), title, inst),
              avatarBgColor: _resolveColor(row['avatar_bg_color']),
              funding: row['salary_or_funding']?.toString() ?? row['funding']?.toString() ?? 'Full / Partial Funding',
              degreeLevel: row['degree_level']?.toString() ?? 'Postgraduate / Master',
              postedTime: row['posted_time']?.toString() ?? 'Open Now',
              externalUrl: row['external_url']?.toString() ?? '',
            ),
          );
        }

        try {
          final visaRes = await client
              .from('visa_listings')
              .select('*')
              .eq('category_id', 'scholarships')
              .eq('is_active', true)
              .order('created_at', ascending: false);
          for (final row in List<Map<String, dynamic>>.from(visaRes)) {
            final title = row['title']?.toString() ?? 'Scholarship';
            final inst = row['country_name']?.toString() ?? 'Official Program';
            final loc = row['country_name']?.toString() ?? 'International';
            if (items.any((x) => x.id == row['id']?.toString())) continue;
            items.insert(
              0,
              _DirectoryScholarshipItem(
                id: row['id']?.toString() ?? '',
                title: title,
                institution: inst,
                location: loc,
                flag: _resolveFlag(null, loc),
                avatarInitials: _resolveInitials(null, title, inst),
                avatarBgColor: 0xFF002444,
                funding: row['salary_or_funding']?.toString() ?? row['fee']?.toString() ?? 'Funded Opportunity',
                degreeLevel: 'All Degrees',
                postedTime: 'Active',
                externalUrl: '',
              ),
            );
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _remoteScholarships = items;
          });
        }
      } else {
        final res = await client
            .from('sponsored_jobs')
            .select('*')
            .eq('type', 'job')
            .eq('is_active', true)
            .order('is_featured', ascending: false)
            .order('created_at', ascending: false);

        final items = <_DirectoryJobItem>[];
        for (final row in List<Map<String, dynamic>>.from(res)) {
          final title = row['title']?.toString() ?? 'Sponsored Job';
          final comp = row['company_or_institution']?.toString() ?? row['company']?.toString() ?? 'Verified Employer';
          final loc = row['location']?.toString() ?? 'International';
          items.add(
            _DirectoryJobItem(
              id: row['id']?.toString() ?? '',
              title: title,
              company: comp,
              location: loc,
              flag: _resolveFlag(row['country_flag']?.toString(), loc),
              avatarInitials: _resolveInitials(row['avatar_initials']?.toString(), title, comp),
              avatarBgColor: _resolveColor(row['avatar_bg_color']),
              salary: row['salary_or_funding']?.toString() ?? row['salary']?.toString() ?? 'Competitive Pay',
              salaryPeriod: row['salary_period']?.toString() ?? '/ yr',
              postedTime: row['posted_time']?.toString() ?? 'Recently Added',
              employmentType: row['employment_type']?.toString() ?? 'Full-time',
              externalUrl: row['external_url']?.toString() ?? '',
            ),
          );
        }

        try {
          final visaRes = await client
              .from('visa_listings')
              .select('*')
              .or('category_id.eq.sponsored_jobs,category_id.eq.jobs')
              .eq('is_active', true)
              .order('created_at', ascending: false);
          for (final row in List<Map<String, dynamic>>.from(visaRes)) {
            final title = row['title']?.toString() ?? 'Sponsored Job';
            final comp = row['country_name']?.toString() ?? 'Verified Sponsor';
            final loc = row['country_name']?.toString() ?? 'International';
            if (items.any((x) => x.id == row['id']?.toString())) continue;
            items.insert(
              0,
              _DirectoryJobItem(
                id: row['id']?.toString() ?? '',
                title: title,
                company: comp,
                location: loc,
                flag: _resolveFlag(null, loc),
                avatarInitials: _resolveInitials(null, title, comp),
                avatarBgColor: 0xFF002444,
                salary: row['salary']?.toString() ?? row['salary_or_funding']?.toString() ?? 'Competitive Pay',
                salaryPeriod: '/ yr',
                postedTime: 'Active',
                employmentType: 'Full-time',
                externalUrl: '',
              ),
            );
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _remoteJobs = items;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLiveWatcher();
    });
  }

  void _initLiveWatcher() {
    syncDirectoryUnlocks(ref);
    _fetchLiveItems();

    // Listen to directory items additions/updates in real-time
    try {
      _adminBroadcastChannel = SupabaseDatabaseService.instance.client
          .channel('admin-dashboard-realtime-channel')
        ..onBroadcast(
          event: 'payment_verified',
          callback: (payload) => _handleRealtimeUnlock(payload),
        )
        ..onBroadcast(
          event: 'payment_approved',
          callback: (payload) => _handleRealtimeUnlock(payload),
        )
        ..onBroadcast(
          event: 'directory_unlocked',
          callback: (payload) => _handleRealtimeUnlock(payload),
        )
        ..subscribe();
    } catch (_) {}

    try {
      _jobsRealtimeChannel = SupabaseDatabaseService.instance.client
          .channel('dir_items_live_${widget.isScholarship ? "sch" : "jobs"}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'sponsored_jobs',
            callback: (_) {
              if (mounted) _fetchLiveItems();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'visa_listings',
            callback: (_) {
              if (mounted) _fetchLiveItems();
            },
          )
          .subscribe();
    } catch (_) {}

    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (user != null) {
      final channelName = 'dir_live_${widget.isScholarship ? "sch" : "jobs"}_${user.id}';
      try {
        _realtimeChannel = SupabaseDatabaseService.instance.client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'user_directory_unlocks',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: user.id,
              ),
              callback: (_) {
                if (mounted) syncDirectoryUnlocks(ref);
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'payments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: user.id,
              ),
              callback: (_) {
                if (mounted) syncDirectoryUnlocks(ref);
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'applications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: user.id,
              ),
              callback: (_) {
                if (mounted) syncDirectoryUnlocks(ref);
              },
            )
            .subscribe();
      } catch (_) {}

      // Fast auto-polling heartbeat fallback while on this screen
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        if (!mounted) return;
        if (!_isUnlocked) {
          syncDirectoryUnlocks(ref);
        } else {
          _pollingTimer?.cancel();
        }
      });
    }
  }

  Future<void> _handleRealtimeUnlock(Map<String, dynamic> payload) async {
    final targetUserId = payload['user_id']?.toString();
    final currentUser = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (targetUserId != null && currentUser != null && targetUserId != currentUser.id) {
      return;
    }

    final dirType = payload['directory_type']?.toString().toLowerCase();
    final refNum = payload['reference_number']?.toString().toLowerCase() ?? '';
    final isSch = dirType == 'scholarships' ||
        dirType == 'scholarship' ||
        (dirType == null &&
            (refNum.contains('scholarship') ||
                refNum.startsWith('sb-sc') ||
                refNum.contains('-sc-')));
    final isJob = dirType == 'sponsored_jobs' ||
        dirType == 'job' ||
        dirType == 'jobs' ||
        (dirType == null &&
            (refNum.contains('job') ||
                refNum.startsWith('sb-wv') ||
                refNum.contains('-wv-')));

    if (widget.isScholarship && isSch) {
      ref.read(isScholarshipsUnlockedProvider.notifier).state = true;
      if (currentUser != null) {
        await StorageService.instance.setBool(kPrefKeyScholarshipsUnlockedFor(currentUser.id), true);
      }
      final curPending = Map<String, Map<String, dynamic>?>.from(ref.read(pendingDirectoryPaymentsProvider));
      curPending['scholarships'] = null;
      ref.read(pendingDirectoryPaymentsProvider.notifier).state = curPending;
    } else if (!widget.isScholarship && isJob) {
      ref.read(isSponsoredJobsUnlockedProvider.notifier).state = true;
      if (currentUser != null) {
        await StorageService.instance.setBool(kPrefKeySponsoredJobsUnlockedFor(currentUser.id), true);
      }
      final curPending = Map<String, Map<String, dynamic>?>.from(ref.read(pendingDirectoryPaymentsProvider));
      curPending['sponsored_jobs'] = null;
      ref.read(pendingDirectoryPaymentsProvider.notifier).state = curPending;
    }

    await syncDirectoryUnlocks(ref);
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    if (_adminBroadcastChannel != null) {
      try {
        SupabaseDatabaseService.instance.client.removeChannel(_adminBroadcastChannel!);
      } catch (_) {}
    }
    if (_realtimeChannel != null) {
      try {
        SupabaseDatabaseService.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
    }
    if (_jobsRealtimeChannel != null) {
      try {
        SupabaseDatabaseService.instance.client.removeChannel(_jobsRealtimeChannel!);
      } catch (_) {}
    }
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filterChips => widget.isScholarship
      ? [
          'All',
          if (_selectedCountryFilter != 'All') _selectedCountryFilter else 'Country',
          if (_selectedDegreeLevelFilter != 'All') _selectedDegreeLevelFilter else 'Degree Level',
          if (_selectedFundingFilter != 'All') _selectedFundingFilter else 'Funding',
          'Newest',
        ]
      : [
          'All',
          if (_selectedCountryFilter != 'All') _selectedCountryFilter else 'Country',
          if (_selectedJobTypeFilter != 'All') _selectedJobTypeFilter else 'Job Type',
          if (_selectedSalaryFilter != 'All') _selectedSalaryFilter else 'Salary',
          'Newest',
        ];

  String get _screenTitle =>
      widget.isScholarship ? 'Scholarships' : 'Sponsored Jobs';

  bool get _isUnlocked {
    if (widget.forceUnlocked != null) return widget.forceUnlocked!;
    if (widget.isScholarship) {
      return ref.watch(isScholarshipsUnlockedProvider);
    } else {
      return ref.watch(isSponsoredJobsUnlockedProvider);
    }
  }

  // Initialized list of verified sponsored jobs directly from media_1790623542673.png
  late final List<_DirectoryJobItem> _jobsList = [
    _DirectoryJobItem(
      id: 'job-warehouse-operator',
      title: 'Warehouse Operator',
      company: 'Apex Logistics UK',
      location: 'Manchester, UK',
      flag: '🇬🇧',
      avatarInitials: 'AL',
      avatarBgColor: 0xFF002444,
      salary: '£28,500 – £32,000',
      salaryPeriod: '/ yr',
      postedTime: '2 days ago',
      employmentType: 'Full-time',
      externalUrl:
          'https://uk.indeed.com/jobs?q=warehouse+operator+visa+sponsorship',
    ),
    _DirectoryJobItem(
      id: 'job-registered-nurse',
      title: 'Registered Nurse (Band 5)',
      company: 'St. Jude NHS Trust',
      location: 'Birmingham, UK',
      flag: '🇬🇧',
      avatarInitials: 'NHS',
      avatarBgColor: 0xFF005EB8,
      salary: '£36,000 – £44,000',
      salaryPeriod: '/ yr',
      postedTime: 'Just now',
      employmentType: 'Full-time',
      externalUrl: 'https://www.jobs.nhs.uk/',
    ),
    _DirectoryJobItem(
      id: 'job-civil-engineer',
      title: 'Civil Site Engineer',
      company: 'Balfour Infrastructure',
      location: 'Toronto, ON, Canada',
      flag: '🇨🇦',
      avatarInitials: 'NB',
      avatarBgColor: 0xFF1B3A5C,
      salary: r'CAD$82,000 – $95,000',
      salaryPeriod: '/ yr',
      postedTime: '3 days ago',
      employmentType: 'Full-time',
      externalUrl:
          'https://ca.indeed.com/jobs?q=civil+engineer+visa+sponsorship',
    ),
    _DirectoryJobItem(
      id: 'job-fleet-supply-chain',
      title: 'Fleet & Supply Chain Coordinator',
      company: 'Emirates Tech Logistics',
      location: 'Dubai, UAE',
      flag: '🇦🇪',
      avatarInitials: 'EK',
      avatarBgColor: 0xFF002444,
      salary: 'AED 16,000 – 20,000',
      salaryPeriod: '/ mo',
      postedTime: '1 day ago',
      employmentType: 'Full-time',
      externalUrl: 'https://www.bayt.com/en/uae/jobs/supply-chain/',
    ),
    _DirectoryJobItem(
      id: 'job-mechatronics-technician',
      title: 'Mechatronics Technician',
      company: 'Bavaria Auto Systems',
      location: 'Munich, Germany',
      flag: '🇩🇪',
      avatarInitials: 'BM',
      avatarBgColor: 0xFF3D6186,
      salary: '€48,000 – €55,000',
      salaryPeriod: '/ yr',
      postedTime: '4 days ago',
      employmentType: 'Full-time',
      externalUrl:
          'https://www.make-it-in-germany.com/en/working-in-germany/jobs',
    ),
    _DirectoryJobItem(
      id: 'job-junior-devops',
      title: 'Junior DevOps Engineer',
      company: 'CyberFortress EU',
      location: 'Berlin, Germany',
      flag: '🇩🇪',
      avatarInitials: 'CY',
      avatarBgColor: 0xFF002444,
      salary: '€58,000 – €68,000',
      salaryPeriod: '/ yr',
      postedTime: '5 days ago',
      employmentType: 'Full-time',
      externalUrl: 'https://de.indeed.com/jobs?q=devops+visa+sponsorship',
    ),
  ];

  // Initialized list of verified international scholarships
  late final List<_DirectoryScholarshipItem> _scholarshipsList = [
    _DirectoryScholarshipItem(
      id: 'sch-chevening-uk',
      title: "Chevening Master's Scholarship",
      institution: 'UK Foreign & Commonwealth Office',
      location: 'London, UK',
      flag: '🇬🇧',
      avatarInitials: 'CH',
      avatarBgColor: 0xFF002444,
      funding: 'Full Tuition + £18,000/yr',
      degreeLevel: 'Postgraduate',
      postedTime: 'Intake 2026 Open',
      externalUrl: 'https://www.chevening.org/scholarships/',
    ),
    _DirectoryScholarshipItem(
      id: 'sch-daad-germany',
      title: 'DAAD Helmut-Schmidt Programme',
      institution: 'German Academic Exchange Service',
      location: 'Bonn, Germany',
      flag: '🇩🇪',
      avatarInitials: 'DAAD',
      avatarBgColor: 0xFF005EB8,
      funding: '€934/mo + Health & Travel',
      degreeLevel: 'Master / PhD',
      postedTime: 'Open Now',
      externalUrl: 'https://www.daad.de/en/',
    ),
    _DirectoryScholarshipItem(
      id: 'sch-vanier-canada',
      title: 'Vanier Canada Graduate Scholarship',
      institution: 'Government of Canada',
      location: 'Ottawa, ON, Canada',
      flag: '🇨🇦',
      avatarInitials: 'VC',
      avatarBgColor: 0xFF1B3A5C,
      funding: r'CAD$50,000 / yr (3 Yrs)',
      degreeLevel: 'Doctoral / PhD',
      postedTime: '3 days ago',
      externalUrl: 'https://vanier.gc.ca/en/home-accueil.html',
    ),
    _DirectoryScholarshipItem(
      id: 'sch-erasmus-mundus',
      title: 'Erasmus Mundus Joint Master Degree',
      institution: 'European Commission',
      location: 'Brussels, European Union',
      flag: '🇪🇺',
      avatarInitials: 'EM',
      avatarBgColor: 0xFF002444,
      funding: '€1,400/mo + Full Tuition',
      degreeLevel: 'Joint Master',
      postedTime: '1 day ago',
      externalUrl: 'https://erasmus-plus.ec.europa.eu/',
    ),
    _DirectoryScholarshipItem(
      id: 'sch-australia-awards',
      title: 'Australia Awards Scholarships',
      institution: 'DFAT Australia',
      location: 'Canberra, Australia',
      flag: '🇦🇺',
      avatarInitials: 'AA',
      avatarBgColor: 0xFF1B3A5C,
      funding: 'Full Tuition + Return Airfare',
      degreeLevel: 'Undergrad / Masters',
      postedTime: '4 days ago',
      externalUrl:
          'https://www.dfat.gov.au/people-to-people/australia-awards',
    ),
    _DirectoryScholarshipItem(
      id: 'sch-turkiye-burslari',
      title: 'Turkiye Burslari State Scholarship',
      institution: 'Government of Türkiye',
      location: 'Ankara, Turkey',
      flag: '🇹🇷',
      avatarInitials: 'TB',
      avatarBgColor: 0xFF002444,
      funding: 'Full Tuition + Accommodation',
      degreeLevel: 'All Degrees',
      postedTime: '5 days ago',
      externalUrl: 'https://www.turkiyeburslari.gov.tr/',
    ),
  ];

  List<_DirectoryJobItem> get _filteredJobs {
    final source = _remoteJobs ?? _jobsList;
    var list = List<_DirectoryJobItem>.from(source);

    // Country
    if (_selectedCountryFilter != 'All') {
      final c = _selectedCountryFilter.toLowerCase();
      list = list.where((j) {
        final loc = j.location.toLowerCase();
        if (loc.contains(c)) return true;
        if (c == 'uk' &&
            (loc.contains('uk') ||
                loc.contains('united kingdom') ||
                loc.contains('manchester') ||
                loc.contains('london') ||
                loc.contains('birmingham'))) {
          return true;
        }
        if (c == 'germany' &&
            (loc.contains('germany') ||
                loc.contains('berlin') ||
                loc.contains('munich'))) {
          return true;
        }
        if (c == 'australia' &&
            (loc.contains('australia') ||
                loc.contains('sydney') ||
                loc.contains('melbourne'))) {
          return true;
        }
        if (c == 'canada' &&
            (loc.contains('canada') ||
                loc.contains('toronto') ||
                loc.contains('vancouver'))) {
          return true;
        }
        if (c == 'uae' &&
            (loc.contains('uae') ||
                loc.contains('dubai') ||
                loc.contains('abu dhabi'))) {
          return true;
        }
        if (c == 'usa' &&
            (loc.contains('usa') ||
                loc.contains('united states') ||
                loc.contains('texas') ||
                loc.contains('california'))) {
          return true;
        }
        return false;
      }).toList();
    }

    // Job Type
    if (_selectedJobTypeFilter != 'All') {
      final t = _selectedJobTypeFilter.toLowerCase();
      list = list.where((j) {
        return j.employmentType.toLowerCase().contains(t) ||
            j.title.toLowerCase().contains(t);
      }).toList();
    }

    // Salary
    if (_selectedSalaryFilter != 'All') {
      final s = _selectedSalaryFilter.toLowerCase();
      list = list.where((j) {
        final sal = j.salary.toLowerCase();
        if (s.contains('25') || s.contains('35')) {
          return sal.contains('28') || sal.contains('32') || sal.contains('30') || sal.contains('34');
        }
        if (s.contains('35') || s.contains('50')) {
          return sal.contains('38') || sal.contains('42') || sal.contains('45') || sal.contains('48') || sal.contains('50');
        }
        if (s.contains('50+') || s.contains('60') || s.contains('high')) {
          return sal.contains('55') || sal.contains('60') || sal.contains('65') || sal.contains('70');
        }
        return true;
      }).toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((j) {
        return j.title.toLowerCase().contains(q) ||
            j.company.toLowerCase().contains(q) ||
            j.location.toLowerCase().contains(q) ||
            j.salary.toLowerCase().contains(q);
      }).toList();
    }

    // Sort
    if (_selectedSort == 'Highest Compensation' || _selectedSort == 'Highest Salary') {
      list.sort((a, b) => b.salary.compareTo(a.salary));
    } else if (_selectedSort == 'Newest' || _selectedFilterIndex == 4) {
      list.sort((a, b) => a.postedTime.compareTo(b.postedTime));
    }

    return list;
  }

  List<_DirectoryScholarshipItem> get _filteredScholarships {
    final source = _remoteScholarships ?? _scholarshipsList;
    var list = List<_DirectoryScholarshipItem>.from(source);

    // Country
    if (_selectedCountryFilter != 'All') {
      final c = _selectedCountryFilter.toLowerCase();
      list = list.where((s) {
        final loc = s.location.toLowerCase();
        if (loc.contains(c)) return true;
        if (c == 'uk' &&
            (loc.contains('uk') ||
                loc.contains('oxford') ||
                loc.contains('london') ||
                loc.contains('united kingdom'))) {
          return true;
        }
        if (c == 'canada' &&
            (loc.contains('canada') ||
                loc.contains('ottawa') ||
                loc.contains('toronto'))) {
          return true;
        }
        if (c == 'australia' &&
            (loc.contains('australia') ||
                loc.contains('canberra') ||
                loc.contains('sydney'))) {
          return true;
        }
        if ((c == 'europe' || c == 'eu') &&
            (loc.contains('europe') ||
                loc.contains('european') ||
                loc.contains('brussels') ||
                loc.contains('germany'))) {
          return true;
        }
        if (c == 'turkey' &&
            (loc.contains('turkey') ||
                loc.contains('türkiye') ||
                loc.contains('ankara'))) {
          return true;
        }
        return false;
      }).toList();
    }

    // Degree Level
    if (_selectedDegreeLevelFilter != 'All') {
      final d = _selectedDegreeLevelFilter.toLowerCase();
      list = list.where((s) {
        return s.degreeLevel.toLowerCase().contains(d) ||
            s.title.toLowerCase().contains(d) ||
            (d.contains('all') && s.degreeLevel.toLowerCase().contains('all'));
      }).toList();
    }

    // Funding
    if (_selectedFundingFilter != 'All') {
      final f = _selectedFundingFilter.toLowerCase();
      list = list.where((s) {
        final fund = s.funding.toLowerCase();
        if (f.contains('stipend') || f.contains('airfare')) {
          return fund.contains('stipend') || fund.contains('mo') || fund.contains('airfare') || fund.contains('/mo');
        }
        if (f.contains('full tuition')) {
          return fund.contains('full tuition');
        }
        return true;
      }).toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.institution.toLowerCase().contains(q) ||
            s.location.toLowerCase().contains(q) ||
            s.funding.toLowerCase().contains(q) ||
            s.degreeLevel.toLowerCase().contains(q);
      }).toList();
    }

    // Sort
    if (_selectedSort == 'Highest Compensation' || _selectedSort == 'Full Funding') {
      list.sort((a, b) => b.funding.compareTo(a.funding));
    } else if (_selectedSort == 'Newest' || _selectedFilterIndex == 4) {
      list.sort((a, b) => a.postedTime.compareTo(b.postedTime));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlocked = _isUnlocked;
    final pendingMap = ref.watch(pendingDirectoryPaymentsProvider);
    final pendingPayment = widget.isScholarship
        ? pendingMap['scholarships']
        : pendingMap['sponsored_jobs'];
    final placement = widget.isScholarship ? 'scholarships' : 'jobs';
    final asyncBanners = ref.watch(liveTargetedBannersStreamProvider(placement));
    final banners = (asyncBanners.hasValue && asyncBanners.value != null)
        ? asyncBanners.value!
        : const <Map<String, String>>[];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF),
      appBar: _buildTopAppBar(context, isDark),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Promotion Carousel Card (1 banner or up to 5 in scrolling carousel)
            _JobsFeaturedPromotionCarousel(
              banners: banners,
              isScholarship: widget.isScholarship,
            ),
            SizedBox(height: 16.h),

            // Filter Chips & Results Count / Sorting Row
            _buildFilterCountSection(context),
            SizedBox(height: 16.h),

            // Dynamic Section: Unlocked Listing OR Payment Pending OR Locked Paywall
            if (unlocked)
              _buildUnlockedListingSection(context)
            else if (pendingPayment != null)
              _buildPaymentPendingSection(context, pendingPayment, isDark)
            else
              _buildLockedPaywallSection(context),

            SizedBox(height: 24.h),
          ],
        ),
      ),
      bottomNavigationBar: const AppDashboardBottomNav(currentIndex: 0),
    );
  }

  // ===========================================================================
  // TOP APP BAR
  // ===========================================================================
  PreferredSizeWidget _buildTopAppBar(BuildContext context, bool isDark) {
    final hasActiveFilters = _selectedCountryFilter != 'All' ||
        _selectedJobTypeFilter != 'All' ||
        _selectedDegreeLevelFilter != 'All' ||
        _selectedSalaryFilter != 'All' ||
        _selectedFundingFilter != 'All' ||
        _searchQuery.trim().isNotEmpty;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: isDark ? Colors.white : const Color(0xFF002444),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      centerTitle: true,
      title: _isSearchOpen
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(
                fontSize: 14.5.sp,
                color: isDark ? Colors.white : const Color(0xFF002444),
              ),
              decoration: InputDecoration(
                hintText: widget.isScholarship
                    ? 'Search scholarships, grants...'
                    : 'Search jobs, roles, companies...',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            )
          : Text(
              _screenTitle,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF002444),
                letterSpacing: -0.2,
              ),
            ),
      actions: [
        if (_isSearchOpen)
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : const Color(0xFF002444),
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = false;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )
        else
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white : const Color(0xFF002444),
              size: 22.sp,
            ),
            tooltip: 'Search listings',
            onPressed: () {
              setState(() {
                _isSearchOpen = true;
              });
            },
          ),
        if (hasActiveFilters && !_isSearchOpen)
          IconButton(
            icon: Icon(
              Icons.filter_alt_off_rounded,
              color: const Color(0xFFEF4444),
              size: 20.sp,
            ),
            tooltip: 'Reset Filters',
            onPressed: _resetAllFilters,
          ),
      ],
    );
  }



  // ===========================================================================
  // 4. RESULTS COUNT & FILTER ROW
  // ===========================================================================
  Widget _buildFilterCountSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilters = _selectedCountryFilter != 'All' ||
        _selectedJobTypeFilter != 'All' ||
        _selectedDegreeLevelFilter != 'All' ||
        _selectedSalaryFilter != 'All' ||
        _selectedFundingFilter != 'All' ||
        _searchQuery.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Filter Pills (Scrollable with no overflow)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (int i = 0; i < _filterChips.length; i++) ...[
                if (i == 0)
                  _buildFilterPill(
                    index: i,
                    label: _filterChips[i],
                    isSelected: _selectedFilterIndex == 0 && !hasActiveFilters,
                    onTap: _resetAllFilters,
                  )
                else
                  _buildDropdownFilterPill(
                    index: i,
                    label: _filterChips[i],
                    isSelected: _isPillActive(i),
                    onTap: () => _handleFilterPillTap(i),
                  ),
                SizedBox(width: 8.w),
              ],
            ],
          ),
        ),
        SizedBox(height: 10.h),

        // Active Filter Banner if filters are engaged
        if (hasActiveFilters) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F9),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFD0DCEB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt_rounded,
                  size: 14.sp,
                  color: const Color(0xFF2563EB),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Active: ${[
                          if (_selectedCountryFilter != 'All')
                            'Country: $_selectedCountryFilter',
                          if (_selectedJobTypeFilter != 'All')
                            'Job: $_selectedJobTypeFilter',
                          if (_selectedDegreeLevelFilter != 'All')
                            'Degree: $_selectedDegreeLevelFilter',
                          if (_selectedSalaryFilter != 'All')
                            'Salary: $_selectedSalaryFilter',
                          if (_selectedFundingFilter != 'All')
                            'Funding: $_selectedFundingFilter',
                          if (_searchQuery.trim().isNotEmpty)
                            'Search: "$_searchQuery"',
                        ].join(' • ')}',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: _resetAllFilters,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],

        // Count line & Sort Button (matches media_1790623542673.png)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                children: [
                  Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3D6186),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 7.w),
                  Flexible(
                    child: Text(
                      widget.isScholarship
                          ? '${_filteredScholarships.length} scholarships available'
                          : '${_filteredJobs.length} jobs available',
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF002444),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            InkWell(
              onTap: () => _showSortModal(context),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.5.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFEAEFF5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: isDark ? Border.all(color: const Color(0xFF27272A), width: 1) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sort: $_selectedSort',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 14.sp,
                      color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF0F172A),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isPillActive(int index) {
    if (index == 1) return _selectedCountryFilter != 'All';
    if (index == 2) {
      return widget.isScholarship
          ? _selectedDegreeLevelFilter != 'All'
          : _selectedJobTypeFilter != 'All';
    }
    if (index == 3) {
      return widget.isScholarship
          ? _selectedFundingFilter != 'All'
          : _selectedSalaryFilter != 'All';
    }
    if (index == 4) return _selectedSort == 'Newest';
    return _selectedFilterIndex == index;
  }

  void _handleFilterPillTap(int index) {
    setState(() => _selectedFilterIndex = index);
    if (index == 1) {
      _showCountryFilterModal(context);
    } else if (index == 2) {
      if (widget.isScholarship) {
        _showDegreeLevelFilterModal(context);
      } else {
        _showJobTypeFilterModal(context);
      }
    } else if (index == 3) {
      if (widget.isScholarship) {
        _showFundingFilterModal(context);
      } else {
        _showSalaryFilterModal(context);
      }
    } else if (index == 4) {
      setState(() => _selectedSort = 'Newest');
      showGlobalToast(message: 'Sorted by Newest listings', status: 'info');
    }
  }

  Widget _buildFilterPill({
    required int index,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
              : (isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8)),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilterPill({
    required int index,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
              : (isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8)),
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16.sp,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  void _resetAllFilters() {
    setState(() {
      _selectedFilterIndex = 0;
      _selectedCountryFilter = 'All';
      _selectedJobTypeFilter = 'All';
      _selectedDegreeLevelFilter = 'All';
      _selectedSalaryFilter = 'All';
      _selectedFundingFilter = 'All';
      _selectedSort = 'Recommended';
      _searchQuery = '';
      _searchController.clear();
      _isSearchOpen = false;
    });
  }

  void _showCountryFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = widget.isScholarship
        ? ['All', 'UK', 'Canada', 'Australia', 'Europe', 'Turkey']
        : ['All', 'UK', 'Canada', 'Australia', 'Germany', 'UAE', 'USA'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Country / Region',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF002444),
                      ),
                    ),
                    if (_selectedCountryFilter != 'All')
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCountryFilter = 'All';
                            _selectedFilterIndex = 0;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: options.map((opt) {
                    final isSel = _selectedCountryFilter == opt;
                    return FilterChip(
                      selected: isSel,
                      label: Text(opt),
                      selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                      backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5FA),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSel
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                      ),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedCountryFilter = opt;
                          _selectedFilterIndex = opt == 'All' ? 0 : 1;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJobTypeFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ['All', 'Full-time', 'Healthcare', 'Engineering', 'Logistics', 'Finance'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Job / Industry Type',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF002444),
                      ),
                    ),
                    if (_selectedJobTypeFilter != 'All')
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedJobTypeFilter = 'All';
                            _selectedFilterIndex = 0;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: options.map((opt) {
                    final isSel = _selectedJobTypeFilter == opt;
                    return FilterChip(
                      selected: isSel,
                      label: Text(opt),
                      selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                      backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5FA),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSel
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                      ),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedJobTypeFilter = opt;
                          _selectedFilterIndex = opt == 'All' ? 0 : 2;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDegreeLevelFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ['All', 'Undergrad', 'Masters', 'PhD', 'All Degrees'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Degree Level',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF002444),
                      ),
                    ),
                    if (_selectedDegreeLevelFilter != 'All')
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDegreeLevelFilter = 'All';
                            _selectedFilterIndex = 0;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: options.map((opt) {
                    final isSel = _selectedDegreeLevelFilter == opt;
                    return FilterChip(
                      selected: isSel,
                      label: Text(opt),
                      selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                      backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5FA),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSel
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                      ),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedDegreeLevelFilter = opt;
                          _selectedFilterIndex = opt == 'All' ? 0 : 2;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSalaryFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ['All', '£25k - £35k', '£35k - £50k', '£50k+ / High Salary'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Salary Range',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF002444),
                      ),
                    ),
                    if (_selectedSalaryFilter != 'All')
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedSalaryFilter = 'All';
                            _selectedFilterIndex = 0;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: options.map((opt) {
                    final isSel = _selectedSalaryFilter == opt;
                    return FilterChip(
                      selected: isSel,
                      label: Text(opt),
                      selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                      backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5FA),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSel
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                      ),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedSalaryFilter = opt;
                          _selectedFilterIndex = opt == 'All' ? 0 : 3;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFundingFilterModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = ['All', 'Full Tuition', 'Full Tuition + Stipend', 'Return Airfare'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by Scholarship Funding',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF002444),
                      ),
                    ),
                    if (_selectedFundingFilter != 'All')
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFundingFilter = 'All';
                            _selectedFilterIndex = 0;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: options.map((opt) {
                    final isSel = _selectedFundingFilter == opt;
                    return FilterChip(
                      selected: isSel,
                      label: Text(opt),
                      selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
                      backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5FA),
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSel
                            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                            : (isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
                      ),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedFundingFilter = opt;
                          _selectedFilterIndex = opt == 'All' ? 0 : 3;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSortModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        final options = [
          'Recommended',
          'Newest',
          'Highest Compensation',
          'Quickest Processing',
        ];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Listings',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF002444),
                  ),
                ),
                SizedBox(height: 10.h),
                for (final opt in options)
                  ListTile(
                    title: Text(
                      opt,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        fontWeight: _selectedSort == opt
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    trailing: _selectedSort == opt
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF002444),
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedSort = opt);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 5. UNLOCKED LISTING SECTION (Matches media_1790623542673.png)
  // ===========================================================================
  Widget _buildUnlockedListingSection(BuildContext context) {
    if (widget.isScholarship) {
      final items = _filteredScholarships;
      if (items.isEmpty) {
        return _buildEmptyStateCard(context);
      }
      return Column(
        children: [
          for (final scholarship in items)
            _buildScholarshipCard(context, scholarship),
        ],
      );
    }

    final items = _filteredJobs;
    if (items.isEmpty) {
      return _buildEmptyStateCard(context);
    }
    return Column(
      children: [
        for (final job in items) _buildJobCard(context, job),
      ],
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      margin: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48.sp,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          SizedBox(height: 12.h),
          Text(
            widget.isScholarship
                ? 'No scholarships match your filters'
                : 'No sponsored jobs match your filters',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF002444),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Try adjusting your search query, country selection, or compensation filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            ),
            onPressed: _resetAllFilters,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'Reset All Filters',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, _DirectoryJobItem job) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        final detail = _convertJobToDetailItem(job);
        context.push(AppRoutes.visaDetail, extra: detail);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B3A5C).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Title & Company + Bookmark
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Color(job.avatarBgColor),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      job.avatarInitials,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF171C21),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${job.company} • ${job.flag} ${job.location}',
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () {
                    setState(() {
                      job.isBookmarked = !job.isBookmarked;
                    });
                    showGlobalToast(
                      message: job.isBookmarked
                          ? '${job.title} saved to bookmarks'
                          : '${job.title} removed from bookmarks',
                      status: 'info',
                    );
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      job.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: job.isBookmarked
                          ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A)),
                      size: 22.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Salary & Post date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: job.salary,
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF171C21),
                          ),
                        ),
                        TextSpan(
                          text: ' ${job.salaryPeriod}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                          ),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  job.postedTime,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF73777F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Tags Row (Wrap prevents any overflow)
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _buildJobTag(
                  label: job.employmentType,
                  backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF0F4FA),
                  textColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF43474E),
                ),
                _buildJobTag(
                  label: 'Sponsored',
                  icon: Icons.bolt_rounded,
                  backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFD0E4FF),
                  textColor: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF002444),
                ),
                _buildJobTag(
                  label: 'Visa Sponsored',
                  icon: Icons.check_circle_outline_rounded,
                  backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFD0E4FF),
                  textColor: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF002444),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F4F8)),
            SizedBox(height: 10.h),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14.sp,
                      color: const Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Verified Employer',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        final detail = _convertJobToDetailItem(job);
                        context.push(AppRoutes.visaDetail, extra: detail);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.5.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF3F9),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF002444),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await _launchExternalJobUrl(context, job.externalUrl);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF002444),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Apply on Site',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScholarshipCard(
      BuildContext context, _DirectoryScholarshipItem s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        final detail = _convertScholarshipToDetailItem(s);
        context.push(AppRoutes.visaDetail, extra: detail);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B3A5C).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Color(s.avatarBgColor),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      s.avatarInitials,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF171C21),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${s.institution} • ${s.flag} ${s.location}',
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                InkWell(
                  onTap: () {
                    setState(() => s.isBookmarked = !s.isBookmarked);
                    showGlobalToast(
                      message: s.isBookmarked
                          ? '${s.title} saved'
                          : '${s.title} removed',
                      status: 'info',
                    );
                  },
                  borderRadius: BorderRadius.circular(20.r),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      s.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: s.isBookmarked
                          ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A)),
                      size: 22.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Funding & Post date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    s.funding,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  s.postedTime,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF73777F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Tags
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _buildJobTag(
                  label: s.degreeLevel,
                  backgroundColor: isDark ? const Color(0xFF18181B) : const Color(0xFFF0F4FA),
                  textColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF43474E),
                ),
                _buildJobTag(
                  label: 'Fully Funded',
                  icon: Icons.workspace_premium_rounded,
                  backgroundColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFE8F5E9),
                  textColor: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF2E7D32),
                ),
                _buildJobTag(
                  label: 'Direct Admission',
                  icon: Icons.verified_user_outlined,
                  backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFD0E4FF),
                  textColor: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF002444),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F4F8)),
            SizedBox(height: 10.h),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14.sp,
                      color: const Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Verified University',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        final detail = _convertScholarshipToDetailItem(s);
                        context.push(AppRoutes.visaDetail, extra: detail);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.5.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDF3F9),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF002444),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await _launchExternalJobUrl(context, s.externalUrl);
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF002444),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Apply on Site',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTag({
    required String label,
    IconData? icon,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.sp, color: textColor),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  DetailItemModel _convertJobToDetailItem(_DirectoryJobItem job) {
    return DetailItemModel(
      id: job.id,
      type: 'job',
      title: job.title,
      subtitle: '${job.company} • ${job.location}',
      categoryTag: 'Sponsored Jobs',
      countryName: job.location,
      countryFlag: job.flag,
      statusBadge: 'Verified Sponsor',
      heroImageUrl:
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1000',
      processingTime: '2-4 wks',
      validity: 'Full-time Visa Sponsored',
      successRate: '98%',
      applicantsCount: '480 applicants',
      aboutTitle: 'About this verified role',
      aboutDescription:
          '${job.company} holds an approved overseas sponsorship license for international candidates. Candidates selected for ${job.title} receive an official certificate of sponsorship, legal visa processing by accredited consultants, and full flight/relocation allowances as per standard employment regulations.',
      timelineSteps: const [
        TimelineStepItem(
          title: 'Application & CV Screen',
          duration: '2-3 days',
          description:
              'Employer HR validates your qualification and work experience.',
          icon: Icons.fact_check_rounded,
        ),
        TimelineStepItem(
          title: 'Direct Video Interview',
          duration: '1 wk',
          description:
              'Interview with destination country department head.',
          icon: Icons.video_camera_front_rounded,
        ),
        TimelineStepItem(
          title: 'Sponsorship Certificate & Visa',
          duration: '2-3 wks',
          description:
              'Issuance of official CoS/LMIA work permit authorization.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: const [
        'Minimum 1-2 years relevant experience or professional diploma/degree',
        'Basic English communication proficiency (IELTS or equivalent if required by employer)',
        'Valid national passport with minimum 12 months validity',
        'Clean police record and medical fitness clearance',
      ],
      mandatoryDocuments: const [
        DocumentItem(
          title: 'Updated CV / Resume',
          note: 'International standard format',
          icon: Icons.description_outlined,
        ),
        DocumentItem(
          title: 'Educational Certificates',
          note: 'Attested degree or diploma',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: 'Experience Certificates',
          note: 'Proof of past employment',
          icon: Icons.work_outline_rounded,
        ),
      ],
      feeBreakdown: const [],
      totalPayable: '',
      serviceFeeLabel: '',
      serviceFeeValue: '',
      salary: '${job.salary} ${job.salaryPeriod}',
      externalUrl: job.externalUrl,
    );
  }

  DetailItemModel _convertScholarshipToDetailItem(
      _DirectoryScholarshipItem s) {
    return DetailItemModel(
      id: s.id,
      type: 'scholarship',
      title: s.title,
      subtitle: '${s.institution} • ${s.location}',
      categoryTag: 'Scholarships',
      countryName: s.location,
      countryFlag: s.flag,
      statusBadge: 'Fully Funded',
      heroImageUrl:
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=1000',
      processingTime: '4-8 wks',
      validity: s.degreeLevel,
      successRate: '92%',
      applicantsCount: '890 applicants',
      aboutTitle: 'About this scholarship',
      aboutDescription:
          '${s.title} is an accredited international scholarship provided by ${s.institution}. It covers comprehensive tuition waivers, living allowances, return airfares, and health insurance for eligible candidates demonstrating strong academic or leadership merit.',
      timelineSteps: const [
        TimelineStepItem(
          title: 'Application Submission',
          duration: '1-2 wks',
          description:
              'Submission of personal statement, references, and research proposal.',
          icon: Icons.assignment_rounded,
        ),
        TimelineStepItem(
          title: 'Faculty / Board Review',
          duration: '3-4 wks',
          description:
              'Independent evaluation by the university admissions committee.',
          icon: Icons.school_rounded,
        ),
        TimelineStepItem(
          title: 'Award Letter & Visa Issuance',
          duration: '2-3 wks',
          description:
              'Issuance of official scholarship award letter and student visa filing.',
          icon: Icons.verified_user_rounded,
        ),
      ],
      eligibilityCriteria: const [
        'Strong academic transcripts from accredited institutions',
        'Proof of language proficiency (IELTS, TOEFL, or English Medium of Instruction)',
        'Two academic or professional reference letters',
        'Compelling personal statement and leadership vision',
      ],
      mandatoryDocuments: const [
        DocumentItem(
          title: 'Academic Transcripts & Degrees',
          note: 'Attested color scans',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: 'Statement of Purpose (SOP)',
          note: '500-1000 words essay',
          icon: Icons.description_outlined,
        ),
        DocumentItem(
          title: 'Letters of Recommendation',
          note: 'From university professors or managers',
          icon: Icons.badge_outlined,
        ),
      ],
      feeBreakdown: const [],
      totalPayable: '',
      serviceFeeLabel: '',
      serviceFeeValue: '',
      externalUrl: s.externalUrl,
    );
  }

  // ===========================================================================
  // PAYMENT UNDER VERIFICATION SECTION
  // ===========================================================================
  Widget _buildPaymentPendingSection(
    BuildContext context,
    Map<String, dynamic> pending,
    bool isDark,
  ) {
    final refNumber = pending['reference_id']?.toString() ??
        pending['reference_number']?.toString() ??
        'SB-PAY-${pending['id']?.toString().substring(0, 8).toUpperCase() ?? "PENDING"}';
    final rawAmount = pending['amount']?.toString() ??
        (widget.isScholarship ? '25,000' : '15,000');
    final amountText = rawAmount.startsWith('PKR') ? rawAmount : 'PKR $rawAmount';

    return Stack(
      children: [
        _buildBlurredTeaserLayer(),
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131518) : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Column(
              children: [
                // Top Multi-color Amber Accent Bar
                Container(
                  height: 5.h,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFD97706),
                        Color(0xFFF59E0B),
                        Color(0xFFFCD34D),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 22.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Amber Hourglass Icon
                      Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF2E1C08) : const Color(0xFFFEF3C7),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.hourglass_top_rounded,
                            color: const Color(0xFFD97706),
                            size: 36.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD97706),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'PAYMENT UNDER VERIFICATION',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Headline
                      Text(
                        'Payment Received & Awaiting Approval',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF002444),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Subtext
                      Text(
                        'Your payment receipt has been submitted. Our case management team is currently validating your transaction.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF43474E),
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // Transaction Summary Box
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2024) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3F341C)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildPendingDetailRow(
                              'Directory Pass',
                              widget.isScholarship
                                  ? 'Scholarships Database'
                                  : 'Sponsored Jobs Directory',
                              isDark,
                            ),
                            SizedBox(height: 8.h),
                            _buildPendingDetailRow('Reference ID', refNumber, isDark),
                            SizedBox(height: 8.h),
                            _buildPendingDetailRow('Amount Paid', amountText, isDark, isHighlight: true),
                            SizedBox(height: 8.h),
                            _buildPendingDetailRow('Method', 'Bank Transfer (IBFT)', isDark),
                            SizedBox(height: 8.h),
                            _buildPendingDetailRow('Current Status', 'Awaiting Admin Approval', isDark, isStatus: true),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Real-time Live Sync Callout
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF142438) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: const Color(0xFF2563EB),
                              size: 22.sp,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'Instant Auto-Unlock: Keep this screen open! As soon as the admin verifies your payment, this page will unlock and display the listings automatically.',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Manual Refresh Button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.sync_rounded,
                            size: 18.sp,
                            color: Colors.white,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Check Status Now',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B3A5C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () async {
                            await syncDirectoryUnlocks(ref);
                            if (context.mounted) {
                              showToast(
                                context,
                                message: 'Checking verification status with server...',
                                status: 'info',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isStatus = false,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: isStatus
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  )
                : Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                      color: isHighlight
                          ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. LOCKED PAYWALL SECTION (Matches media_1790622659495.png)
  // ===========================================================================
  Widget _buildLockedPaywallSection(BuildContext context) {
    return Stack(
      children: [
        // Background Teaser Layer (Blurred realistic cards)
        _buildBlurredTeaserLayer(),

        // Foreground Floating Paywall Access Card
        _buildFloatingPaywallCard(context),
      ],
    );
  }

  Widget _buildBlurredTeaserLayer() {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: Opacity(
        opacity: 0.65,
        child: Column(
          children: [
            _buildMockJobCard(
              avatarInitials: 'NHS',
              avatarBg: const Color(0xFF1B3A5C),
              title: widget.isScholarship
                  ? 'Oxford Clarendon Full Research Grant'
                  : 'NHS Senior Band 6 Specialist Nurse',
              company: widget.isScholarship
                  ? 'University of Oxford • 🇬🇧 Oxford, UK'
                  : 'St. Jude NHS Trust • 🇬🇧 Birmingham, UK',
              salary: widget.isScholarship
                  ? '£24,000 / yr + Tuition'
                  : '£38,500 – £44,000 / yr',
              tags: const ['Full-time', 'Sponsored', 'Visa Sponsored'],
            ),
            SizedBox(height: 12.h),
            _buildMockJobCard(
              avatarInitials: 'CA',
              avatarBg: const Color(0xFF002444),
              title: widget.isScholarship
                  ? 'Toronto Lester B. Pearson Merit Fellowship'
                  : 'Lead DevOps Cloud Infrastructure Engineer',
              company: widget.isScholarship
                  ? 'University of Toronto • 🇨🇦 Toronto, Canada'
                  : 'NorthStar Cloud Systems • 🇨🇦 Vancouver, Canada',
              salary: widget.isScholarship
                  ? r'CAD$36,000 / yr + Health'
                  : r'CAD$95,000 – $110,000 / yr',
              tags: const ['Full-time', 'Sponsored', 'Visa Sponsored'],
            ),
            SizedBox(height: 12.h),
            _buildMockJobCard(
              avatarInitials: 'DE',
              avatarBg: const Color(0xFF2C3136),
              title: widget.isScholarship
                  ? 'TUM Graduate School International Scholarship'
                  : 'Bavaria Rail Automation Controls Technician',
              company: widget.isScholarship
                  ? 'Technical University Munich • 🇩🇪 Munich, Germany'
                  : 'Bavaria Rail Systems • 🇩🇪 Munich, Germany',
              salary: widget.isScholarship
                  ? '€1,200 / mo + Semester Ticket'
                  : '€52,000 – €60,000 / yr',
              tags: const ['Full-time', 'Sponsored', 'Visa Sponsored'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockJobCard({
    required String avatarInitials,
    required Color avatarBg,
    required String title,
    required String company,
    required String salary,
    required List<String> tags,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    avatarInitials,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF171C21),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      company,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFB0D5FF),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    salary,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF001D34),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 4.h,
            children: [
              for (final tag in tags)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : const Color(0xFFEAEFF5),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF43474E),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingPaywallCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002444).withValues(alpha: 0.16),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: Column(
          children: [
            // Top Multi-color Accent Bar
            Container(
              height: 5.h,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B3A5C),
                    Color(0xFF385C81),
                    Color(0xFFABC9F2),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Golden Lock Icon with Green Checkmark
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF002444),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF002444)
                                  .withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock_rounded,
                            color: const Color(0xFFFFD700),
                            size: 34.sp,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  // Headline
                  Text(
                    widget.isScholarship
                        ? 'Unlock Verified Scholarships'
                        : 'Unlock Sponsored Jobs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF002444),
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Subtext
                  Text(
                    widget.isScholarship
                        ? 'Access 80+ fully funded international scholarships with direct faculty links, Caseworker evaluation, and grant tracking.'
                        : 'Direct access to overseas employers actively sponsoring work visas. Bypass general job boards and connect with accredited recruiters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF43474E),
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Value Proposition Checklist
                  Column(
                    children: [
                      _buildValuePropRow(
                        widget.isScholarship
                            ? 'Direct university scholarship links & eligibility criteria'
                            : 'Direct employer contact details & sponsorship license numbers',
                        isDark,
                      ),
                      SizedBox(height: 10.h),
                      _buildValuePropRow(
                        widget.isScholarship
                            ? 'Fast-track application evaluation with assigned RCIC consultants'
                            : 'Fast-track application status review with assigned RCIC lawyers',
                        isDark,
                      ),
                      SizedBox(height: 10.h),
                      _buildValuePropRow(
                        widget.isScholarship
                            ? 'Real-time instant notification on new scholarship quotas'
                            : 'Real-time instant notification on new sponsorship quota openings',
                        isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 22.h),

                  // Pricing Badge Container (FittedBox prevents any overflow)
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18181B) : const Color(0xFFEAEFF5),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ONE-TIME ACCESS FEE',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                                letterSpacing: 0.6,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Lifetime Access Included',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                widget.isScholarship ? 'PKR 35,000' : 'PKR 25,000',
                                style: TextStyle(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF73777F),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                widget.isScholarship ? 'PKR 25,000' : 'PKR 15,000',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF002444),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Primary Action Button (Unlock Access)
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3A5C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        shadowColor:
                            const Color(0xFF1B3A5C).withValues(alpha: 0.35),
                      ),
                      onPressed: _handleUnlockTapped,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isUnlocking)
                            SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          else ...[
                            const Icon(
                              Icons.lock_open_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Unlock Access',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Security statement footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 14.sp,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          'All your info is secure • Instant activation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValuePropRow(String text, [bool isDark = false]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 17.sp,
          color: const Color(0xFF2E7D32),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF171C21),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUnlockTapped() async {
    final user = SupabaseDatabaseService.instance.client.auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        showToast(
          context,
          message:
              'Please log in or sign up first to unlock lifetime directory access.',
          status: 'info',
        );
        context.push(AppRoutes.login);
      }
      return;
    }

    if (_isUnlocking) return;
    setState(() => _isUnlocking = true);

    showToast(
      context,
      message: widget.isScholarship
          ? 'Initiating scholarship directory unlock checkout'
          : 'Initiating sponsored jobs directory unlock checkout',
      status: 'info',
    );

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isUnlocking = false);

    // Pre-fill a dedicated detail model with scholarship (PKR 25,000) or job (PKR 15,000) fee
    final unlockItem = DetailItemModel(
      id: widget.isScholarship
          ? 'unlock-scholarships-pass'
          : 'unlock-jobs-pass',
      type: widget.isScholarship ? 'scholarship' : 'job',
      title: widget.isScholarship
          ? 'Scholarships Database Lifetime Access'
          : 'Sponsored Jobs Directory Lifetime Access',
      subtitle: widget.isScholarship
          ? 'Direct verified universities in UK, Canada, Australia & Europe'
          : 'Direct visa-sponsored employer registry in UK, Canada & UAE',
      categoryTag: widget.isScholarship ? 'Scholarships' : 'Sponsored Jobs',
      countryName: 'International',
      countryFlag: '🌐',
      statusBadge: 'Verified Directory',
      heroImageUrl:
          'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=800',
      processingTime: 'Instant Activation',
      validity: 'Lifetime Pass',
      successRate: '99%',
      applicantsCount: '1,420+ active applicants',
      aboutTitle: 'About this verified directory pass',
      aboutDescription: widget.isScholarship
          ? 'Gain instant, unrestricted access to 80+ fully funded international scholarships with direct links to admission departments and quota listings.'
          : 'Gain instant, unrestricted access to 120+ verified overseas employers actively holding sponsorship licenses with direct contact personnel.',
      timelineSteps: [
        TimelineStepItem(
          title: 'Encrypted Checkout',
          duration: '1-2 mins',
          description:
              'Complete one-time lifetime payment of ${widget.isScholarship ? "PKR 25,000" : "PKR 15,000"} via Card or Mobile Wallet.',
          icon: Icons.payment_rounded,
        ),
        const TimelineStepItem(
          title: 'Instant Activation',
          duration: 'Immediate',
          description:
              'Directory unlock badge activated on your verified applicant profile.',
          icon: Icons.verified_user_rounded,
        ),
        const TimelineStepItem(
          title: 'Direct Listings Access',
          duration: 'Unrestricted',
          description:
              'Full access to employer contact credentials and sponsorship licenses.',
          icon: Icons.lock_open_rounded,
        ),
      ],
      eligibilityCriteria: const [],
      mandatoryDocuments: const [
        DocumentItem(
          title: 'Digital Verification Receipt',
          note: 'Issued automatically to your email upon payment',
          icon: Icons.receipt_long_rounded,
        ),
      ],
      feeBreakdown: const [],
      totalPayable: widget.isScholarship ? 'PKR 25,000' : 'PKR 15,000',
      serviceFeeLabel: 'ONE-TIME ACCESS FEE',
      serviceFeeValue: widget.isScholarship ? 'PKR 25,000' : 'PKR 15,000',
    );

    if (!mounted) return;
    context.push(AppRoutes.applicantDetails, extra: unlockItem);
  }

  Future<void> _launchExternalJobUrl(BuildContext context, String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      showToast(
        context,
        message: 'No external application link specified for this position.',
        status: 'warning',
      );
      return;
    }

    final res = await UrlLauncherService.instance.launch(cleanUrl);
    res.fold(
      (failure) {
        if (context.mounted) {
          showToast(
            context,
            message: 'Unable to open link. Please check your browser or network.',
            status: 'error',
          );
        }
      },
      (_) {},
    );
  }

  // ===========================================================================
  // 7. BOTTOM NAVIGATION BAR (Matches persistent app navigation)
  // ===========================================================================
}

/// Multi-page scrolling carousel for sponsored jobs and scholarships.
/// Displays 1 banner if 1 enabled; displays all (up to 5+) in a swipeable PageView with indicator dots.
class _JobsFeaturedPromotionCarousel extends StatefulWidget {
  const _JobsFeaturedPromotionCarousel({
    required this.banners,
    required this.isScholarship,
  });

  final List<Map<String, String>> banners;
  final bool isScholarship;

  @override
  State<_JobsFeaturedPromotionCarousel> createState() =>
      _JobsFeaturedPromotionCarouselState();
}

class _JobsFeaturedPromotionCarouselState
    extends State<_JobsFeaturedPromotionCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
      final parsed = int.tryParse(hexString);
      if (parsed != null) return Color(parsed);
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = widget.banners.isEmpty ? 1 : widget.banners.length;

    return Column(
      children: [
        SizedBox(
          height: 195.h,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            itemBuilder: (context, index) {
              final banner =
                  widget.banners.isNotEmpty ? widget.banners[index] : null;

              final badge = (banner != null && (banner['badge']?.trim().isNotEmpty ?? false))
                  ? banner['badge']!.trim()
                  : 'FEATURED';
              final headline = (banner != null && (banner['title']?.trim().isNotEmpty ?? false))
                  ? banner['title']!.trim()
                  : (widget.isScholarship
                      ? 'Study abroad with fully funded scholarships'
                      : 'Get hired abroad with visa sponsorship');
              final rawSubtitle = (banner != null && (banner['subtitle']?.trim().isNotEmpty ?? false))
                  ? banner['subtitle']!.trim()
                  : (widget.isScholarship
                      ? 'Verified universities in UK, Canada, UAE & Germany'
                      : 'Verified employers in UK, Canada, UAE & Germany');
              final subtitle = rawSubtitle.replaceAll('\n', ' • ');
              final actionText = (banner != null && (banner['actionText']?.trim().isNotEmpty ?? false))
                  ? banner['actionText']!.trim()
                  : 'Explore';
              final actionUrl = banner?['actionUrl']?.trim();

              final startColor = _parseColor(banner?['gradientStart'], const Color(0xFF1B3A5C));
              final endColor = _parseColor(banner?['gradientEnd'], const Color(0xFF2F5885));

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      startColor,
                      Color.lerp(startColor, endColor, 0.5) ?? startColor,
                      endColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: startColor.withValues(alpha: 0.28),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background Watermark Wireframe Compass/Globe
                    Positioned(
                      right: -10.w,
                      bottom: -20.h,
                      child: Icon(
                        Icons.language_rounded,
                        size: 140.sp,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top Tag Pill
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 3.5.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: Color(0xFFD0E4FF),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  badge,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFD0E4FF),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),

                          // Headline
                          Text(
                            headline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 4.h),

                          // Subtitle
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: const Color(0xFFD0E4FF).withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Bottom Action: White Explore Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: startColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 7.h),
                            ),
                            onPressed: () {
                              if (actionUrl != null &&
                                  actionUrl.isNotEmpty &&
                                  actionUrl.startsWith('/')) {
                                context.push(actionUrl);
                              } else {
                                showToast(
                                  context,
                                  message:
                                      'Viewing verified international partners',
                                  status: 'info',
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  actionText,
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: startColor,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: startColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (count > 1) ...[
          SizedBox(height: 12.h),
          SmoothPageIndicator(
            controller: _controller,
            count: count,
            effect: ExpandingDotsEffect(
              activeDotColor:
                  isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
              dotColor:
                  isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              dotHeight: 4.h,
              dotWidth: 5.w,
              expansionFactor: 3.5,
              spacing: 5.w,
            ),
            onDotClicked: (index) {
              _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ],
    );
  }
}
