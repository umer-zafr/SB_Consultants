class ReferenceCodeGenerator {
  static int _counter = 0;

  /// Generates a standardized, clean reference code distinguishing visa categories
  /// Examples: SB-VV-01 (Visit Visa), SB-SV-01 (Study Visa), SB-WV-01 (Work Visa),
  /// SB-BV-01 (Business Visa), SB-PR-01 (PR Visa), SB-FV-01 (Family Visa), SB-SC-01 (Scholarship), SB-CS-01 (Consultancy)
  static String generate({
    String? category,
    String? title,
    String? listingId,
  }) {
    _counter++;
    final cat = (category ?? '').toUpperCase();
    final t = (title ?? '').toUpperCase();
    final lid = (listingId ?? '').toUpperCase();

    String prefix = 'SB-VV'; // Default Visit Visa

    if (cat.contains('STUDY') ||
        cat.contains('STUDENT') ||
        t.contains('STUDY') ||
        t.contains('STUDENT') ||
        lid.contains('STUDY')) {
      prefix = 'SB-SV'; // Student / Study Visa
    } else if (cat.contains('WORK') ||
        cat.contains('JOB') ||
        cat.contains('EMPLOY') ||
        t.contains('WORK') ||
        t.contains('JOB') ||
        lid.contains('WORK')) {
      prefix = 'SB-WV'; // Work Visa
    } else if (cat.contains('BUSINESS') ||
        cat.contains('INVEST') ||
        t.contains('BUSINESS') ||
        t.contains('INVEST') ||
        lid.contains('BUSINESS')) {
      prefix = 'SB-BV'; // Business Visa
    } else if (cat.contains('PERMANENT') ||
        cat.contains('PR') ||
        cat.contains('SETTLE') ||
        t.contains('PR ') ||
        t.contains('PERMANENT') ||
        lid.contains('PR')) {
      prefix = 'SB-PR'; // Permanent Residency
    } else if (cat.contains('FAMILY') ||
        cat.contains('SPOUSE') ||
        t.contains('FAMILY') ||
        t.contains('SPOUSE')) {
      prefix = 'SB-FV'; // Family Visa
    } else if (cat.contains('SCHOLARSHIP') ||
        t.contains('SCHOLARSHIP') ||
        lid.contains('SCHOLARSHIP')) {
      prefix = 'SB-SC'; // Scholarship
    } else if (cat.contains('CONSULT') ||
        t.contains('CONSULT') ||
        lid.contains('CONSULT')) {
      prefix = 'SB-CS'; // Consultancy Service
    } else if (cat.contains('VISIT') ||
        cat.contains('TOUR') ||
        t.contains('VISIT') ||
        t.contains('TOURIST')) {
      prefix = 'SB-VV'; // Visit Visa
    }

    final seq = (_counter % 99) + 1;
    final seqStr = seq.toString().padLeft(2, '0');
    return '$prefix-$seqStr';
  }
}

