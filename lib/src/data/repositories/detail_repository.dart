import 'package:flutter/material.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/data/models/sponsored_job_model.dart';
import 'package:flutter_sd_consultant/src/data/models/visa_listing_model.dart';

class DetailRepository {
  // ===========================================================================
  // 1. UK STUDENT VISA (TIER 4) - Exact match to user screenshot (Image 2)
  // ===========================================================================
  static DetailItemModel getUkStudentVisaDetail() {
    return const DetailItemModel(
      id: 'uk-student-visa',
      type: 'visa',
      title: 'UK Student Visa',
      subtitle: '(Tier 4 / Student Route)',
      categoryTag: 'Study Visa',
      countryName: 'United Kingdom',
      countryFlag: '🇬🇧',
      statusBadge: 'Available',
      heroImageUrl:
          'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=1000',
      processingTime: '3-4 wks',
      validity: 'Up to 3 yrs',
      successRate: '96%',
      applicantsCount: '1,240',
      aboutTitle: 'About this visa',
      aboutDescription:
          'The UK Student Visa allows international students to live, study, and work part-time in the United Kingdom while enrolled at an accredited Higher Education Institution (HEI). SB Consultants assists you with Confirmation of Acceptance for Studies (CAS) validation, financial sponsorship verification, and end-to-end embassy filing.',
      timelineSteps: [
        TimelineStepItem(
          title: 'University Offer & CAS',
          duration: '1-2 wks',
          description:
              'Receive official CAS from a licensed UK sponsor after preliminary screening.',
          icon: Icons.school_rounded,
        ),
        TimelineStepItem(
          title: 'Financial Proof & Biometrics',
          duration: '1 wk',
          description:
              '28-day bank balance holding certificate & VFS appointment scheduling.',
          icon: Icons.account_balance_rounded,
        ),
        TimelineStepItem(
          title: 'Decision & Visa Stamp',
          duration: '3-4 wks',
          description:
              'Standard UKVI processing or Priority clearance (within 5 working days).',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Unconditional offer letter & valid CAS issued by an approved UK sponsor.',
        'English language proficiency (IELTS UKVI min 6.0 overall or equivalent score).',
        'Proof of funds for course fees and living costs (min £1,334/mo inside London, £1,023/mo outside).',
        'Valid ATAS clearance certificate (if applicable for sensitive technical or engineering courses).',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Current Valid Passport',
          note: 'With blank stamp pages',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Academic Transcripts',
          note: 'Original degrees & certificates',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: 'CAS Letter',
          note: 'From UK institution',
          icon: Icons.description_outlined,
        ),
        DocumentItem(
          title: 'Bank Statement',
          note: '28-day holding record',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'IELTS Certificate',
          note: 'UKVI accredited test',
          icon: Icons.translate_rounded,
        ),
        DocumentItem(
          title: 'Biometric Photos',
          note: 'Standard UKVI specification',
          icon: Icons.camera_alt_outlined,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Consultation & University Filing',
          amount: 'PKR 25,000',
          subNote: 'File preparation, CAS validation & interview prep',
        ),
        FeeItem(
          label: 'University Application & Admission Fee',
          amount: '£50 - £150',
          subNote: 'Paid directly to UK university portal',
        ),
        FeeItem(
          label: 'University Tuition Fee Deposit',
          amount: 'As per CAS',
          subNote: 'Directly paid to licensed UK HEI sponsor',
        ),
        FeeItem(
          label: 'UKVI Student Visa & Biometrics Fee',
          amount: '£490',
          subNote: 'Official UKVI visa processing fee',
        ),
        FeeItem(
          label: 'Immigration Health Surcharge (IHS)',
          amount: '£776/yr',
          tag: 'Pay to UKVI',
          subNote: 'Official health insurance levy',
        ),
      ],
      totalPayable: 'PKR 25,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 25,000',
    );
  }

  // ===========================================================================
  // 2. UK SKILLED WORKER VISA (TIER 2)
  // ===========================================================================
  static DetailItemModel getUkSkilledWorkerVisaDetail() {
    return const DetailItemModel(
      id: 'uk-skilled-worker-visa',
      type: 'visa',
      title: 'UK Skilled Worker Visa',
      subtitle: '(Tier 2 / Certificate of Sponsorship Route)',
      categoryTag: 'Work Visa',
      countryName: 'United Kingdom',
      countryFlag: '🇬🇧',
      statusBadge: 'High Demand',
      heroImageUrl:
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1000',
      processingTime: '3-4 wks',
      validity: 'Up to 5 yrs',
      successRate: '97%',
      applicantsCount: '2,150',
      aboutTitle: 'About this visa',
      aboutDescription:
          'The UK Skilled Worker Visa allows eligible foreign professionals to work in the UK with an approved Home Office licensed sponsor employer. This route leads directly to Indefinite Leave to Remain (ILR / Permanent Residency) after 5 years of continuous residence.',
      timelineSteps: [
        TimelineStepItem(
          title: 'Job Offer & CoS Issuance',
          duration: '1-2 wks',
          description:
              'Secure defined/undefined Certificate of Sponsorship (CoS) from a licensed UK employer.',
          icon: Icons.work_outline_rounded,
        ),
        TimelineStepItem(
          title: 'Points & Salary Assessment',
          duration: '3-5 days',
          description:
              'Verification of minimum salary threshold (£38,700 or relevant going rate) and B1 English qualification.',
          icon: Icons.fact_check_rounded,
        ),
        TimelineStepItem(
          title: 'VFS Biometrics & Submission',
          duration: '1 wk',
          description:
              'Biometric appointment at VFS Global and TB medical clearance submission.',
          icon: Icons.calendar_month_rounded,
        ),
        TimelineStepItem(
          title: 'Home Office Decision & BRP',
          duration: '3 wks',
          description:
              'Passport collection with entry vignette and digital e-Visa / BRP clearance.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Confirmed job offer from a Home Office approved licensed UK sponsor.',
        'Valid Certificate of Sponsorship (CoS) reference number.',
        'Meets minimum salary requirement (£38,700/year or going rate for the occupation code).',
        'English language proficiency at minimum CEFR B1 level (IELTS Life Skills or Academic).',
        'Proof of maintenance funds (£1,270 in bank account for 28 consecutive days unless employer certified).',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Valid International Passport',
          note: 'Original with blank pages',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Certificate of Sponsorship (CoS)',
          note: 'Assigned by UK licensed employer',
          icon: Icons.work_outline_rounded,
        ),
        DocumentItem(
          title: 'Bank Maintenance Proof',
          note: '28-day holding record (£1,270)',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'English Language Certificate',
          note: 'SELT UKVI accredited test (B1)',
          icon: Icons.translate_rounded,
        ),
        DocumentItem(
          title: 'TB Screening Certificate',
          note: 'IOM approved medical clinic',
          icon: Icons.health_and_safety_outlined,
        ),
        DocumentItem(
          title: 'Police Clearance Certificate',
          note: 'For education, healthcare & security codes',
          icon: Icons.gavel_rounded,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Advisory & Legal Filing Fee',
          amount: 'PKR 40,000',
        ),
        FeeItem(
          label: 'UKVI Official Application Fee',
          amount: '£719 - £1,420',
          subNote: 'Depends on CoS duration (up to 3 yrs vs 5 yrs)',
        ),
        FeeItem(
          label: 'Immigration Health Surcharge (IHS)',
          amount: '£1,035/yr',
          tag: 'Pay to UKVI',
          subNote: 'Official NHS healthcare surcharge',
        ),
      ],
      totalPayable: 'PKR 40,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 40,000',
    );
  }

  // ===========================================================================
  // 3. CANADA STUDY PERMIT (SDS & NON-SDS)
  // ===========================================================================
  static DetailItemModel getCanadaStudyPermitDetail() {
    return const DetailItemModel(
      id: 'canada-study-permit',
      type: 'visa',
      title: 'Canada Study Permit (SDS)',
      subtitle: 'Student Direct Stream & PGWP Route',
      categoryTag: 'Study Visa',
      countryName: 'Canada',
      countryFlag: '🇨🇦',
      statusBadge: 'Popular',
      heroImageUrl:
          'https://images.unsplash.com/photo-1517935703635-27c946452576?w=1000',
      processingTime: '4-6 wks',
      validity: 'Course Duration + 90 Days',
      successRate: '94%',
      applicantsCount: '1,890',
      aboutTitle: 'About this permit',
      aboutDescription:
          'The Canadian Study Permit allows international students to attend Designated Learning Institutions (DLIs) across Canada. Under the Student Direct Stream (SDS), applications receive expedited processing with eligible Post-Graduation Work Permit (PGWP) rights up to 3 years.',
      timelineSteps: [
        TimelineStepItem(
          title: 'DLI Letter of Acceptance & PAL',
          duration: '1-2 wks',
          description:
              'Obtain unconditional offer letter and Provincial Attestation Letter (PAL) from designated Canadian college/university.',
          icon: Icons.school_rounded,
        ),
        TimelineStepItem(
          title: 'GIC & Tuition Payment',
          duration: '1-2 wks',
          description:
              r'Deposit $20,635 CAD into Scotiabank/CIBC Guaranteed Investment Certificate (GIC) and pay 1st year tuition.',
          icon: Icons.account_balance_rounded,
        ),
        TimelineStepItem(
          title: 'Upfront Medical & IRCC Filing',
          duration: '1 wk',
          description:
              'Undergo panel physician exam and complete online IRCC biometric scheduling.',
          icon: Icons.calendar_month_rounded,
        ),
        TimelineStepItem(
          title: 'Passport Request (PPR) & Stamp',
          duration: '3-4 wks',
          description:
              'Official IRCC visa counterfoil stamp and Point of Entry (POE) Introduction Letter.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Letter of Acceptance (LOA) from an accredited Canadian Designated Learning Institution (DLI).',
        'Valid Provincial Attestation Letter (PAL) from the host province.',
        r'Guaranteed Investment Certificate (GIC) of at least $20,635 CAD.',
        'Receipt of first-year tuition fee payment to the college or university.',
        'IELTS Academic overall 6.0 (SDS stream) or PTE Academic / TOEFL score.',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Current Valid Passport',
          note: 'Valid for full duration of study',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'DLI Acceptance Letter & PAL',
          note: 'Official institutional offer',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: r'GIC Certificate ($20,635 CAD)',
          note: 'From Scotiabank / CIBC / ICICI',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'Tuition Fee Receipt',
          note: 'Official university invoice proof',
          icon: Icons.receipt_long_outlined,
        ),
        DocumentItem(
          title: 'IELTS / Language Test',
          note: 'SDS compliant score sheet',
          icon: Icons.translate_rounded,
        ),
        DocumentItem(
          title: 'Upfront Medical Exam',
          note: 'eMedical panel physician sheet',
          icon: Icons.health_and_safety_outlined,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Consultation & University Filing',
          amount: 'PKR 30,000',
          subNote: 'SOP, university admission & visa file preparation',
        ),
        FeeItem(
          label: 'University Admission & Tuition Deposit',
          amount: 'As per DLI Offer',
          subNote: 'Paid directly to Designated Learning Institution (DLI)',
        ),
        FeeItem(
          label: 'IRCC Study Permit Official Fee',
          amount: r'CAD $150',
          subNote: 'Paid directly to Government of Canada',
        ),
        FeeItem(
          label: 'Biometrics Collection Fee',
          amount: r'CAD $85',
          tag: 'Pay to IRCC',
          subNote: 'Mandatory fingerprint & digital photo levy',
        ),
      ],
      totalPayable: 'PKR 30,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 30,000',
    );
  }

  // ===========================================================================
  // 4. CANADA LMIA WORK PERMIT / EXPRESS ENTRY
  // ===========================================================================
  static DetailItemModel getCanadaWorkPermitDetail() {
    return const DetailItemModel(
      id: 'canada-work-permit',
      type: 'visa',
      title: 'Canada LMIA Work Permit',
      subtitle: 'Global Talent Stream & Express Entry PR Route',
      categoryTag: 'Work Visa',
      countryName: 'Canada',
      countryFlag: '🇨🇦',
      statusBadge: 'Popular',
      heroImageUrl:
          'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=1000',
      processingTime: '4-6 wks',
      validity: '2-3 Years Renewable',
      successRate: '95%',
      applicantsCount: '1,420',
      aboutTitle: 'About this work permit',
      aboutDescription:
          'The Canadian LMIA Work Permit grants temporary foreign workers legal authorization to work for Canadian employers who hold an approved Labour Market Impact Assessment (LMIA). This stream provides valuable Canadian work experience that dramatically increases Comprehensive Ranking System (CRS) scores for Express Entry Permanent Residency.',
      timelineSteps: [
        TimelineStepItem(
          title: 'Job Offer & LMIA Approval',
          duration: '2-4 wks',
          description:
              'Employer secures positive LMIA from Employment and Social Development Canada (ESDC).',
          icon: Icons.work_outline_rounded,
        ),
        TimelineStepItem(
          title: 'Credentials & ECA Evaluation',
          duration: '1-2 wks',
          description:
              'Educational Credential Assessment (ECA via WES/ICAS) and work experience verification.',
          icon: Icons.fact_check_rounded,
        ),
        TimelineStepItem(
          title: 'IRCC Work Permit Submission',
          duration: '1 wk',
          description:
              'Online application filing on IRCC portal and biometric booking at VFS.',
          icon: Icons.calendar_month_rounded,
        ),
        TimelineStepItem(
          title: 'Visa Stamping & POE Work Permit',
          duration: '4-6 wks',
          description:
              'Passport counterfoil issuance and Work Permit printout at Canadian port of entry.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Genuine job offer from a Canadian employer with positive or fee-exempt LMIA.',
        'Relevant educational credentials and minimum 1-2 years verifiable work experience.',
        'Language proficiency meeting NOC skill tier standards (CLB 5+ for TEER 2/3, CLB 7+ for TEER 0/1).',
        'Police clearance certificate with clean criminal history.',
        'Passing immigration medical examination by an approved IRCC panel physician.',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Original Valid Passport',
          note: '2+ years remaining validity',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Positive LMIA Letter',
          note: 'ESDC confirmation number',
          icon: Icons.work_outline_rounded,
        ),
        DocumentItem(
          title: 'Employment Contract',
          note: 'Signed by Canadian employer',
          icon: Icons.description_outlined,
        ),
        DocumentItem(
          title: 'WES / ECA Report',
          note: 'Verified degree equivalency',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: 'IELTS General Training',
          note: 'CLB accredited score card',
          icon: Icons.translate_rounded,
        ),
        DocumentItem(
          title: 'Police Clearance Record',
          note: 'Original character certificate',
          icon: Icons.gavel_rounded,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Advisory & Legal Representation',
          amount: 'PKR 40,000',
        ),
        FeeItem(
          label: 'IRCC Work Permit Application Fee',
          amount: r'CAD $155',
          subNote: 'Standard Canadian work authorization fee',
        ),
        FeeItem(
          label: 'Biometrics Fee',
          amount: r'CAD $85',
          tag: 'Pay to IRCC',
          subNote: 'Fingerprints & digital photo at VFS center',
        ),
      ],
      totalPayable: 'PKR 40,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 40,000',
    );
  }

  // ===========================================================================
  // 5. AUSTRALIA STUDENT VISA (SUBCLASS 500)
  // ===========================================================================
  static DetailItemModel getAustraliaStudentVisaDetail() {
    return const DetailItemModel(
      id: 'australia-student-visa',
      type: 'visa',
      title: 'Australia Student Visa (Subclass 500)',
      subtitle: 'CRICOS Registered Course & 48-Hour Work Rights',
      categoryTag: 'Study Visa',
      countryName: 'Australia',
      countryFlag: '🇦🇺',
      statusBadge: 'Direct PR Route',
      heroImageUrl:
          'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=1000',
      processingTime: '3-5 wks',
      validity: 'Up to 5 Years',
      successRate: '95%',
      applicantsCount: '1,320',
      aboutTitle: 'About this visa',
      aboutDescription:
          'The Australian Subclass 500 Student Visa allows international students to study full-time at accredited universities, vocational institutes, and colleges across Australia. It permits up to 48 hours of work per fortnight during academic terms and unlimited hours during semester breaks, with direct pathways to Temporary Graduate (Subclass 485) visas.',
      timelineSteps: [
        TimelineStepItem(
          title: 'Offer Letter & Confirmation (CoE)',
          duration: '1-2 wks',
          description:
              'University admission letter, initial semester tuition payment, and official CoE generation.',
          icon: Icons.school_rounded,
        ),
        TimelineStepItem(
          title: 'OSHC Health Cover & Financials',
          duration: '3-5 days',
          description:
              'Purchase Overseas Student Health Cover (OSHC) and organize 3-month living cost maintenance funds.',
          icon: Icons.health_and_safety_outlined,
        ),
        TimelineStepItem(
          title: 'Genuine Student (GS) Statement',
          duration: '3-5 days',
          description:
              'SB Consultants drafts tailored GS assessment statement matching Department of Home Affairs guidelines.',
          icon: Icons.fact_check_rounded,
        ),
        TimelineStepItem(
          title: 'ImmiAccount Filing & Grant',
          duration: '3-4 wks',
          description:
              'Online lodging on Department of Home Affairs portal and Subclass 500 electronic visa grant.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Enrolment in a registered CRICOS course with a valid Confirmation of Enrolment (CoE).',
        'Meet the Genuine Student (GS) assessment criteria.',
        r'Adequate financial capacity for 12 months tuition, return travel, and AUD $29,710 living costs.',
        'Continuous Overseas Student Health Cover (OSHC) for the intended duration of stay.',
        'English proficiency: IELTS Academic min 6.0 or PTE Academic min 50.',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Valid Passport',
          note: 'Original with 6+ months validity',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Official CoE Certificate',
          note: 'Issued via PRISMS system',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: 'Bank Statement / Loan Proof',
          note: 'Covering 1-year living & tuition',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'OSHC Policy Certificate',
          note: 'Bupa / Medibank / Allianz cover',
          icon: Icons.health_and_safety_outlined,
        ),
        DocumentItem(
          title: 'English Language Score',
          note: 'IELTS Academic or PTE test report',
          icon: Icons.translate_rounded,
        ),
        DocumentItem(
          title: 'Academic Transcripts',
          note: 'Notarized high school/degree documents',
          icon: Icons.description_outlined,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Consultation & University Filing',
          amount: 'PKR 30,000',
          subNote: 'SOP, university admission & visa file preparation',
        ),
        FeeItem(
          label: 'University Admission & Tuition Deposit',
          amount: 'As per CoE',
          subNote: 'Paid directly to accredited Australian CRICOS provider',
        ),
        FeeItem(
          label: 'Home Affairs Subclass 500 Visa Fee',
          amount: r'AUD $710',
          subNote: 'Official Department of Home Affairs fee',
        ),
        FeeItem(
          label: 'Biometrics & Health Examination',
          amount: r'AUD $120',
          tag: 'Direct Clinic',
          subNote: 'Panel physician health screening',
        ),
      ],
      totalPayable: 'PKR 30,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 30,000',
    );
  }

  // ===========================================================================
  // 6. GERMANY OPPORTUNITY CARD (CHANCENKARTE)
  // ===========================================================================
  static DetailItemModel getGermanyChancenkarteDetail() {
    return const DetailItemModel(
      id: 'germany-opportunity-card',
      type: 'visa',
      title: 'Germany Opportunity Card (Chancenkarte)',
      subtitle: 'Points-Based Job Search & EU Blue Card Gateway',
      categoryTag: 'Work Visa',
      countryName: 'Germany',
      countryFlag: '🇩🇪',
      statusBadge: 'New 2026 Quota',
      heroImageUrl:
          'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=1000',
      processingTime: '3-6 wks',
      validity: '1 Year Search Permit',
      successRate: '96%',
      applicantsCount: '1,650',
      aboutTitle: 'About this program',
      aboutDescription:
          'The Chancenkarte (Opportunity Card) is Germany’s modern points-based immigration system launched under the Skilled Immigration Act. It enables qualified professionals to reside in Germany for up to one year to find qualified employment or start a business, with authorized part-time work rights up to 20 hours per week and trial work periods.',
      timelineSteps: [
        TimelineStepItem(
          title: 'Points Calculation & ZAB Verification',
          duration: '1-2 wks',
          description:
              'Calculate points (min 6 points required based on age, education, language, and experience) and initiate ZAB degree equivalence.',
          icon: Icons.fact_check_rounded,
        ),
        TimelineStepItem(
          title: 'Blocked Account (Sperrkonto)',
          duration: '3-5 days',
          description:
              'Deposit €11,208 into a verified German blocked account (Expatrio / Coracle / Fintiba) for 12 months subsistence proof.',
          icon: Icons.account_balance_rounded,
        ),
        TimelineStepItem(
          title: 'German Embassy / VFS Submission',
          duration: '1-2 wks',
          description:
              'Schedule consular appointment at German mission/VFS with complete dossier and motivation statement.',
          icon: Icons.calendar_month_rounded,
        ),
        TimelineStepItem(
          title: 'Opportunity Card Visa Stamp',
          duration: '3-4 wks',
          description:
              'National Visa Type D issuance enabling travel to Germany and local Foreigners Authority registration.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Recognized academic degree or vocational training qualification (minimum 2 years training).',
        'Achieve minimum 6 points on the German Chancenkarte points grid.',
        'Basic German language (A1) or English language proficiency (B2).',
        'Secured livelihood proof via Blocked Account (€1,027/month = €11,208 total) or declaration of commitment.',
        'Incoming health insurance covering travel to Germany and initial stay.',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Valid Passport',
          note: 'Original with 1+ year validity',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Blocked Account Certificate',
          note: '€11,208 confirmation (Expatrio)',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'University Degree / Diploma',
          note: 'With ZAB / anabin verification',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: 'Language Certificate',
          note: 'Goethe/ÖSD (A1) or IELTS (B2)',
          icon: Icons.translate_rounded,
        ),
        DocumentItem(
          title: 'Detailed EuroPass CV',
          note: 'Comprehensive career breakdown',
          icon: Icons.description_outlined,
        ),
        DocumentItem(
          title: 'Motivation Statement',
          note: 'Target job search strategy in Germany',
          icon: Icons.assignment_outlined,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Advisory & Points Dossier Preparation',
          amount: 'PKR 40,000',
        ),
        FeeItem(
          label: 'German Consular National Visa Fee',
          amount: '€75',
          subNote: 'Official German Embassy application levy',
        ),
        FeeItem(
          label: 'ZAB Qualification Statement (if needed)',
          amount: '€208',
          tag: 'Official ZAB',
          subNote: 'Degree recognition certificate from Bonn',
        ),
      ],
      totalPayable: 'PKR 40,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 40,000',
    );
  }

  // ===========================================================================
  // 7. DUBAI 10-YEAR GOLDEN VISA
  // ===========================================================================
  static DetailItemModel getDubaiGoldenVisaDetail() {
    return const DetailItemModel(
      id: 'dubai-golden-visa',
      type: 'visa',
      title: 'Dubai 10-Year Golden Visa',
      subtitle: 'Long-Term Self-Sponsored UAE Residency',
      categoryTag: 'Golden Visa',
      countryName: 'United Arab Emirates',
      countryFlag: '🇦🇪',
      statusBadge: 'Popular',
      heroImageUrl:
          'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=1000',
      processingTime: '7-14 days',
      validity: '10 Years Renewable',
      successRate: '99%',
      applicantsCount: '3,840',
      aboutTitle: 'About this residency',
      aboutDescription:
          'The UAE 10-Year Golden Visa grants foreign investors, entrepreneurs, executives, specialized talents, and top graduates 100% self-sponsored residency in Dubai and across the United Arab Emirates. It includes family sponsorship (spouse, children of any age) and domestic staff, with zero requirement for an in-country national sponsor or minimum stay limit.',
      timelineSteps: [
        TimelineStepItem(
          title: 'ICP / GDRFA Initial Nomination',
          duration: '2-3 days',
          description:
              'Eligibility validation via real estate asset (AED 2M+), executive salary (AED 30K/mo+), or specialized talent endorsement.',
          icon: Icons.fact_check_rounded,
        ),
        TimelineStepItem(
          title: 'Entry Permit & VIP Medical Fitness',
          duration: '2-4 days',
          description:
              'Issuance of 6-month multiple-entry permit and expedited blood test / chest X-ray screening.',
          icon: Icons.health_and_safety_outlined,
        ),
        TimelineStepItem(
          title: 'Emirates ID Biometrics',
          duration: '1-2 days',
          description:
              'Fast-track fingerprint scanning at Federal Authority for Identity and Citizenship (ICP) center.',
          icon: Icons.fingerprint_rounded,
        ),
        TimelineStepItem(
          title: '10-Year Residency Stamp & Card',
          duration: '2-3 days',
          description:
              'Passport residency stamp and delivery of prestigious 10-Year Golden Emirates ID card.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Real Estate Investor: Property title deed in UAE valued at AED 2,000,000 or more.',
        'Executive / Skilled Talent: Minimum bachelor degree with basic salary of AED 30,000/month and attested contract.',
        'Entrepreneur: Ownership of an innovative project with evaluation of AED 500,000+ approved by economy department.',
        'Outstanding Students & Graduates: High GPA from UAE accredited universities or top 100 global universities.',
        'Valid passport with minimum 6 months remaining validity.',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Original International Passport',
          note: 'Clear color copy with 6+ months validity',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Title Deed or Salary Certificate',
          note: 'AED 2M property or AED 30K salary proof',
          icon: Icons.home_work_outlined,
        ),
        DocumentItem(
          title: 'Attested University Degree',
          note: 'MOFA & UAE embassy attested certificate',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: '6-Month Bank Statement',
          note: 'Verified salary credits or bank balance',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'UAE Medical Fitness Test',
          note: 'Government clinic blood & X-ray cert',
          icon: Icons.health_and_safety_outlined,
        ),
        DocumentItem(
          title: 'High-Res Passport Photos',
          note: 'White background digital specification',
          icon: Icons.camera_alt_outlined,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Advisory & VIP Concierge Filing',
          amount: 'PKR 40,000',
        ),
        FeeItem(
          label: 'GDRFA / ICP Golden Visa Issuance Fee',
          amount: 'AED 2,800',
          subNote: 'Official UAE government residency issuance',
        ),
        FeeItem(
          label: 'VIP Medical & 10-Year Emirates ID',
          amount: 'AED 1,150',
          tag: 'Official ICP',
          subNote: 'Includes fast-track biometrics & physical card',
        ),
      ],
      totalPayable: 'PKR 40,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 40,000',
    );
  }

  // ===========================================================================
  // 8. USA B1/B2 VISITOR VISA
  // ===========================================================================
  static DetailItemModel getUsaVisitorVisaDetail() {
    return const DetailItemModel(
      id: 'usa-b1-b2-visa',
      type: 'visa',
      title: 'USA B1/B2 Visitor Visa',
      subtitle: 'Business, Tourism & Family Visit Stream',
      categoryTag: 'Visit Visa',
      countryName: 'United States',
      countryFlag: '🇺🇸',
      statusBadge: 'Popular',
      heroImageUrl:
          'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?w=1000',
      processingTime: '2-4 wks',
      validity: 'Up to 5-10 Years',
      successRate: '92%',
      applicantsCount: '2,900',
      aboutTitle: 'About this visa',
      aboutDescription:
          'The US B1/B2 Non-Immigrant Visa is designed for individuals traveling to the United States for temporary business (B-1) or tourism, vacation, medical treatment, and visiting friends or family (B-2). SB Consultants provides end-to-end assistance with CEAC DS-160 application drafting, appointment scheduling, and comprehensive consular mock interviews.',
      timelineSteps: [
        TimelineStepItem(
          title: 'DS-160 Legal Drafting',
          duration: '2-3 days',
          description:
              'Accurate completion of electronic CEAC DS-160 form matching consular standards.',
          icon: Icons.description_outlined,
        ),
        TimelineStepItem(
          title: 'MRV Fee & Appointment Scheduling',
          duration: '3-5 days',
          description:
              r'Payment of $185 MRV consular fee and appointment booking via CGI Federal / US Travel Docs portal.',
          icon: Icons.calendar_month_rounded,
        ),
        TimelineStepItem(
          title: 'SB 1-on-1 Consular Mock Interview',
          duration: '2-3 days',
          description:
              'In-depth interview preparation with former visa officers covering ties to home country and travel intentions.',
          icon: Icons.record_voice_over_rounded,
        ),
        TimelineStepItem(
          title: 'Embassy Interview & Visa Stamping',
          duration: '1-2 wks',
          description:
              'In-person consular interview, biometrics capture, and passport delivery with 5/10-year visa foil.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Clear, legitimate purpose of travel for temporary business, tourism, or family visits.',
        'Demonstrable economic, family, and professional ties to home country that guarantee departure.',
        'Proof of adequate financial funds to cover all travel and accommodation expenses in the USA.',
        'Valid passport with at least 6 months validity beyond the intended period of stay.',
        'No prior immigration violations or adverse consular records.',
      ],
      mandatoryDocuments: [
        DocumentItem(
          title: 'Original Valid Passport',
          note: 'With 6+ months validity & blank pages',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'DS-160 Confirmation Barcode',
          note: 'Official CEAC submission confirmation',
          icon: Icons.receipt_long_outlined,
        ),
        DocumentItem(
          title: 'Bank Statement (6 Months)',
          note: 'Verified closing balance & source of funds',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'Employment / Business Proof',
          note: 'Job letter, salary slips, or NTN registration',
          icon: Icons.work_outline_rounded,
        ),
        DocumentItem(
          title: 'US Travel Itinerary',
          note: 'Flight reservations & hotel booking proof',
          icon: Icons.flight_takeoff_rounded,
        ),
        DocumentItem(
          title: 'US Visa Photo (2x2 Inches)',
          note: 'Square format white background picture',
          icon: Icons.camera_alt_outlined,
        ),
      ],
      feeBreakdown: [
        FeeItem(
          label: 'SB Advisory & Consular Mock Interview Fee',
          amount: 'PKR 30,000',
        ),
        FeeItem(
          label: 'US Department of State MRV Fee',
          amount: r'USD $185',
          subNote: 'Official non-immigrant consular fee (approx PKR 52,000)',
        ),
      ],
      totalPayable: 'PKR 30,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 30,000',
    );
  }

  // ===========================================================================
  // 9. SCHENGEN TOURIST / BUSINESS VISA (FRANCE, ITALY, SPAIN, GERMANY)
  // ===========================================================================
  static DetailItemModel getSchengenVisaDetail({
    String countryName = 'France',
    String countryFlag = '🇫🇷',
    String? heroImageUrl,
  }) {
    return DetailItemModel(
      id: 'schengen-visa-${countryName.toLowerCase()}',
      type: 'visa',
      title: '$countryName Schengen Tourist Visa',
      subtitle: 'Short Stay Uniform Schengen Visa (Type C)',
      categoryTag: 'Visit Visa',
      countryName: countryName,
      countryFlag: countryFlag,
      statusBadge: 'Popular',
      heroImageUrl: heroImageUrl ??
          'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=1000',
      processingTime: '3-4 wks',
      validity: 'Up to 90 Days',
      successRate: '95%',
      applicantsCount: '2,400',
      aboutTitle: 'About this visa',
      aboutDescription:
          'The Uniform Schengen Visa (Type C) allows holders to travel freely across all 29 member states of the Schengen Area for tourism, visiting family, or business meetings for up to 90 days within any 180-day period. SB Consultants assists you with dossier preparation, VFS/BLS slot booking, travel insurance, and flight itinerary confirmations.',
      timelineSteps: const [
        TimelineStepItem(
          title: 'File Preparation & Itinerary',
          duration: '3-5 days',
          description:
              'Drafting cover letter, day-by-day travel plan, flight reservation, and verified hotel vouchers.',
          icon: Icons.description_outlined,
        ),
        TimelineStepItem(
          title: 'VFS / BLS Appointment Booking',
          duration: '1 wk',
          description:
              'Monitoring biometric slots at VFS Global / BLS International and appointment confirmation.',
          icon: Icons.calendar_month_rounded,
        ),
        TimelineStepItem(
          title: 'Biometric Submission & Interview',
          duration: '1 day',
          description:
              'In-person submission of complete documents dossier and digital fingerprint capture.',
          icon: Icons.fingerprint_rounded,
        ),
        TimelineStepItem(
          title: 'Consular Assessment & Passport Release',
          duration: '15 working days',
          description:
              'Official processing by destination embassy and passport collection with Schengen visa sticker.',
          icon: Icons.verified_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Valid passport with at least two blank pages, issued within the last 10 years and valid 3+ months beyond intended stay.',
        'Proof of accommodation (confirmed hotel booking or formal invitation letter).',
        'Valid Schengen travel medical insurance with minimum coverage of €30,000.',
        'Sufficient financial means: Last 6 months bank statement showing minimum €45-€120 per day of stay.',
        'Strong socio-economic ties to home country (employment letter, tax returns, property documents).',
      ],
      mandatoryDocuments: const [
        DocumentItem(
          title: 'Current Valid Passport',
          note: 'Plus copies of previous visas',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Schengen Travel Insurance',
          note: '€30,000 emergency medical cover',
          icon: Icons.health_and_safety_outlined,
        ),
        DocumentItem(
          title: 'Bank Statement (6 Months)',
          note: 'Bank verified and stamped record',
          icon: Icons.account_balance_outlined,
        ),
        DocumentItem(
          title: 'Employment NOC / Salary Slips',
          note: 'Last 3 months salary records',
          icon: Icons.work_outline_rounded,
        ),
        DocumentItem(
          title: 'Flight & Hotel Reservation',
          note: 'Confirmed return travel itinerary',
          icon: Icons.flight_takeoff_rounded,
        ),
        DocumentItem(
          title: 'Biometric Photos (35x45mm)',
          note: 'Schengen standard light grey background',
          icon: Icons.camera_alt_outlined,
        ),
      ],
      feeBreakdown: const [
        FeeItem(
          label: 'SB Advisory & File Preparation Fee',
          amount: 'PKR 30,000',
        ),
        FeeItem(
          label: 'Schengen Consular Visa Fee',
          amount: '€80 - €90',
          subNote: 'Official EU consular processing fee',
        ),
        FeeItem(
          label: 'VFS / BLS Service Fee',
          amount: 'PKR 8,500',
          tag: 'Direct VFS',
          subNote: 'Biometric and center logistics charge',
        ),
      ],
      totalPayable: 'PKR 30,000',
      serviceFeeLabel: 'SERVICE FEE',
      serviceFeeValue: 'PKR 30,000',
    );
  }

  // ===========================================================================
  // 10. INTELLIGENT DISPATCHER: GET DETAIL FOR VISA (Database / Live Stream)
  // ===========================================================================
  static IconData _parseIcon(dynamic icon) {
    if (icon is IconData) return icon;
    final str = icon?.toString().toLowerCase() ?? '';
    if (str.contains('school') || str.contains('uni') || str.contains('degree') || str.contains('academic')) {
      return Icons.school_rounded;
    }
    if (str.contains('balance') || str.contains('bank') || str.contains('money') || str.contains('fund') || str.contains('finance')) {
      return Icons.account_balance_rounded;
    }
    if (str.contains('verify') || str.contains('stamp') || str.contains('check') || str.contains('approved') || str.contains('success')) {
      return Icons.verified_rounded;
    }
    if (str.contains('work') || str.contains('job') || str.contains('career') || str.contains('business')) {
      return Icons.work_rounded;
    }
    if (str.contains('flight') || str.contains('plane') || str.contains('travel') || str.contains('tourist')) {
      return Icons.flight_takeoff_rounded;
    }
    if (str.contains('gavel') || str.contains('court') || str.contains('law') || str.contains('legal')) {
      return Icons.gavel_rounded;
    }
    if (str.contains('health') || str.contains('medical') || str.contains('doctor')) {
      return Icons.health_and_safety_rounded;
    }
    if (str.contains('badge') || str.contains('id') || str.contains('passport')) {
      return Icons.badge_rounded;
    }
    if (str.contains('camera') || str.contains('photo')) {
      return Icons.camera_alt_rounded;
    }
    if (str.contains('translate') || str.contains('ielts') || str.contains('english') || str.contains('lang')) {
      return Icons.translate_rounded;
    }
    return Icons.fact_check_rounded;
  }

  // ===========================================================================
  // 10. INTELLIGENT DISPATCHER: GET DETAIL FOR VISA (Database / Live Stream)
  // ===========================================================================
  static DetailItemModel getDetailForVisa(VisaListingModel visa) {
    final country = visa.countryName.trim().isNotEmpty ? visa.countryName.trim() : 'International';
    final flag = _resolveFlag(country, visa.title);
    final category = visa.categoryName.trim().isNotEmpty ? visa.categoryName.trim() : 'Visa Consultation';
    final hero = visa.imageUrl.trim().isNotEmpty
        ? visa.imageUrl.trim()
        : _resolveHeroImage(country, false, false, false);

    // 1. Live Timeline Steps from database
    List<TimelineStepItem> steps = [];
    if (visa.timelineSteps is List && (visa.timelineSteps as List).isNotEmpty) {
      for (final s in visa.timelineSteps as List) {
        if (s is Map) {
          final t = s['title']?.toString().trim() ?? '';
          if (t.isNotEmpty) {
            steps.add(TimelineStepItem(
              title: t,
              duration: s['duration']?.toString().trim() ?? '',
              description: s['description']?.toString().trim() ?? '',
              icon: _parseIcon(s['icon']),
            ));
          }
        }
      }
    }
    if (steps.isEmpty) {
      final gen = getDetailFromGeneric(
        id: visa.id,
        title: visa.title,
        subtitle: visa.subtitle,
        countryName: country,
        categoryTag: category,
        duration: visa.processingTime,
        validity: visa.validity,
        approvalRate: visa.successRate,
      );
      steps = gen.timelineSteps;
    }

    // 2. Live Eligibility Criteria from database
    List<String> eligibility = [];
    if (visa.eligibilityCriteria is List && (visa.eligibilityCriteria as List).isNotEmpty) {
      for (final e in visa.eligibilityCriteria as List) {
        final str = e?.toString().trim() ?? '';
        if (str.isNotEmpty) eligibility.add(str);
      }
    }
    if (eligibility.isEmpty) {
      final gen = getDetailFromGeneric(
        id: visa.id,
        title: visa.title,
        subtitle: visa.subtitle,
        countryName: country,
        categoryTag: category,
      );
      eligibility = gen.eligibilityCriteria;
    }

    // 3. Live Mandatory Documents from database
    List<DocumentItem> documents = [];
    if (visa.mandatoryDocuments is List && (visa.mandatoryDocuments as List).isNotEmpty) {
      for (final d in visa.mandatoryDocuments as List) {
        if (d is Map) {
          final t = d['title']?.toString().trim() ?? '';
          if (t.isNotEmpty) {
            documents.add(DocumentItem(
              title: t,
              note: d['note']?.toString().trim() ?? '',
              icon: _parseIcon(d['icon'] ?? 'description'),
            ));
          }
        }
      }
    }
    if (documents.isEmpty) {
      final gen = getDetailFromGeneric(
        id: visa.id,
        title: visa.title,
        subtitle: visa.subtitle,
        countryName: country,
        categoryTag: category,
      );
      documents = gen.mandatoryDocuments;
    }

    // 4. Custom Fee Breakdown
    List<FeeItem> fees = [];
    if (visa.feeBreakdown is List && (visa.feeBreakdown as List).isNotEmpty) {
      for (final f in visa.feeBreakdown as List) {
        if (f is Map) {
          final l = f['label']?.toString().trim() ?? '';
          if (l.isNotEmpty) {
            fees.add(FeeItem(
              label: l,
              amount: f['amount']?.toString().trim() ?? '',
              subNote: f['subNote']?.toString().trim(),
              tag: f['tag']?.toString().trim(),
            ));
          }
        }
      }
    }

    final effectiveFee = (visa.serviceFeeValue != null && visa.serviceFeeValue!.trim().isNotEmpty)
        ? visa.serviceFeeValue!.trim()
        : (visa.totalPayable != null && visa.totalPayable!.trim().isNotEmpty)
            ? visa.totalPayable!.trim()
            : (visa.fee.trim().isNotEmpty ? visa.fee.trim() : 'PKR 25,000');

    if (fees.isEmpty) {
      fees = [
        FeeItem(
          label: (visa.serviceFeeLabel != null && visa.serviceFeeLabel!.trim().isNotEmpty)
              ? visa.serviceFeeLabel!.trim()
              : 'SB Consultation & Embassy Advisory',
          amount: effectiveFee,
          subNote: 'Professional application audit, verification & appointment filing',
          tag: 'Payable to SB Consultants',
        ),
      ];
    }

    final aboutTitle = (visa.aboutTitle != null && visa.aboutTitle!.trim().isNotEmpty)
        ? visa.aboutTitle!.trim()
        : 'About this visa';

    final aboutDesc = (visa.aboutDescription != null && visa.aboutDescription!.trim().isNotEmpty)
        ? visa.aboutDescription!.trim()
        : '${visa.title} provides authorized entry and legal residency for $country. SB Consultants assists applicants with verified document assessment, appointment scheduling, and end-to-end consular filing.';

    return DetailItemModel(
      id: visa.id,
      type: (category.toLowerCase().contains('job') || visa.title.toLowerCase().contains('job')) ? 'job' : 'visa',
      title: visa.title,
      subtitle: visa.subtitle,
      categoryTag: category,
      countryName: country,
      countryFlag: flag,
      statusBadge: (visa.statusBadge != null && visa.statusBadge!.trim().isNotEmpty)
          ? visa.statusBadge!.trim()
          : 'Available',
      heroImageUrl: hero,
      processingTime: visa.processingTime.trim().isNotEmpty ? visa.processingTime.trim() : '15-20 Working Days',
      validity: (visa.validity != null && visa.validity!.trim().isNotEmpty) ? visa.validity!.trim() : '1 Year',
      successRate: (visa.successRate != null && visa.successRate!.trim().isNotEmpty) ? visa.successRate!.trim() : '98%',
      applicantsCount: (visa.applicantsCount != null && visa.applicantsCount!.trim().isNotEmpty) ? visa.applicantsCount!.trim() : '500+ Applicants',
      aboutTitle: aboutTitle,
      aboutDescription: aboutDesc,
      timelineSteps: steps,
      eligibilityCriteria: eligibility,
      mandatoryDocuments: documents,
      feeBreakdown: fees,
      totalPayable: (visa.totalPayable != null && visa.totalPayable!.trim().isNotEmpty) ? visa.totalPayable!.trim() : effectiveFee,
      serviceFeeLabel: (visa.serviceFeeLabel != null && visa.serviceFeeLabel!.trim().isNotEmpty) ? visa.serviceFeeLabel!.trim() : 'SERVICE FEE',
      serviceFeeValue: effectiveFee,
      externalUrl: visa.externalUrl,
      applicationRequirements: visa.applicationRequirements,
      salary: visa.salary ?? visa.salaryOrFunding,
    );
  }

  // ===========================================================================
  // 11. UNIVERSAL INTELLIGENT BUILDER: GET DETAIL FROM GENERIC (Varies for Every Visa)
  // ===========================================================================
  static DetailItemModel getDetailFromGeneric({
    String? id,
    required String title,
    String? subtitle,
    String? countryName,
    String? categoryTag,
    String? fee,
    String? duration,
    String? validity,
    String? approvalRate,
    String? aboutTitle,
    String? aboutDescription,
    String? applicantsCount,
    String? statusBadge,
    String? heroImageUrl,
    dynamic timelineSteps,
    dynamic eligibilityCriteria,
    dynamic applicationRequirements,
    String? salary,
  }) {
    final t = title.toLowerCase();
    final c = (countryName ?? '').toLowerCase();
    final cat = (categoryTag ?? '').toLowerCase();

    // Only return exact static templates if caller did not provide custom database description
    if (aboutDescription == null || aboutDescription.trim().isEmpty) {
      if (t == 'uk student visa' || (t.contains('student') && c == 'united kingdom' && t == 'uk student visa (tier 4)')) {
        return getUkStudentVisaDetail();
      }
      if (t == 'uk skilled worker visa') {
        return getUkSkilledWorkerVisaDetail();
      }
      if (t == 'canada study permit' || t == 'canada study permit (sds)') {
        return getCanadaStudyPermitDetail();
      }
      if (t == 'canada work permit') {
        return getCanadaWorkPermitDetail();
      }
      if (t == 'australia student visa' || t == 'australia student visa (subclass 500)') {
        return getAustraliaStudentVisaDetail();
      }
      if (t == 'germany opportunity card' || t == 'germany chancenkarte') {
        return getGermanyChancenkarteDetail();
      }
      if (t == 'dubai golden visa' || t == 'dubai 10-year golden visa') {
        return getDubaiGoldenVisaDetail();
      }
      if (t == 'usa visitor visa' || t == 'usa b1/b2 visitor visa') {
        return getUsaVisitorVisaDetail();
      }
    }
    // -------------------------------------------------------------------------
    // DYNAMIC TAILORING ENGINE: Generates customized details matching the visa!
    // -------------------------------------------------------------------------
    final isJob = cat.contains('job') || t.contains('job') || t.contains('engineer') || t.contains('nurse');
    final isStudy = cat.contains('study') || t.contains('student') || t.contains('admission');
    final isWork = cat.contains('work') || t.contains('work') || t.contains('skilled') || t.contains('labour');
    final isGolden = cat.contains('golden') || t.contains('golden') || t.contains('residence') || t.contains('investor');
    final isBusiness = cat.contains('business') || t.contains('business') || t.contains('innovator') || t.contains('founder');

    final String resolvedCountry = (countryName != null && countryName.isNotEmpty) ? countryName : 'International';
    final String resolvedFlag = _resolveFlag(resolvedCountry, t);

    // Resolve fee:
    final String resolvedFee;
    if (isJob) {
      resolvedFee = 'PKR 15,000';
    } else if (cat.contains('scholarship') || t.contains('scholarship')) {
      resolvedFee = 'PKR 25,000';
    } else if (isWork || isGolden) {
      resolvedFee = 'PKR 40,000';
    } else {
      resolvedFee = 'PKR 30,000';
    }

    // Resolved hero image:
    final String heroImg = _resolveHeroImage(resolvedCountry, isStudy, isWork, isGolden);

    // Tailored processing time & validity
    final String resDuration = duration ?? (isGolden ? '2-4 wks' : isStudy ? '3-5 wks' : isWork ? '4-6 wks' : isBusiness ? '4-8 wks' : '2-3 wks');
    final String resValidity = validity ?? (isGolden ? '5-10 Years' : isStudy ? 'Course Duration' : isWork ? '2-3 Years' : isBusiness ? '3-5 Years' : 'Up to 6 Months');
    final String resRate = approvalRate ?? (isGolden ? '98%' : isStudy ? '95%' : isWork ? '96%' : isBusiness ? '93%' : '94%');
    final String applicants = isStudy ? '1,540' : isWork ? '2,100' : isGolden ? '860' : isBusiness ? '940' : '1,980';

    // Tailored Timeline Steps
    final List<TimelineStepItem> steps;
    if (isStudy) {
      steps = [
        TimelineStepItem(
          title: 'Admission Offer & Eligibility',
          duration: '1-2 wks',
          description: 'Secure formal acceptance letter from certified university or college in $resolvedCountry.',
          icon: Icons.school_rounded,
        ),
        const TimelineStepItem(
          title: 'Financial Solvency & Visa File',
          duration: '1 wk',
          description: 'Document 28-day holding funds, tuition receipts, and embassy-compliant sponsorship affidavit.',
          icon: Icons.account_balance_rounded,
        ),
        TimelineStepItem(
          title: 'Biometrics & Consular Review',
          duration: resDuration,
          description: 'Appointment at visa application center (VFS/consulate) and official student visa issuance.',
          icon: Icons.verified_rounded,
        ),
      ];
    } else if (isWork) {
      steps = [
        TimelineStepItem(
          title: 'Job Offer & Sponsorship Verification',
          duration: '1-2 wks',
          description: 'Credentials assessment and employer sponsorship approval validation for $resolvedCountry.',
          icon: Icons.work_outline_rounded,
        ),
        const TimelineStepItem(
          title: 'Work Authorization Filing',
          duration: '1-2 wks',
          description: 'Submission of labor department dossier, police clearance, and medical health screening.',
          icon: Icons.fact_check_rounded,
        ),
        TimelineStepItem(
          title: 'Visa Stamping & Work Permit',
          duration: resDuration,
          description: 'Passport submission for official work entry vignette and biometric clearance.',
          icon: Icons.verified_rounded,
        ),
      ];
    } else if (isGolden) {
      steps = [
        const TimelineStepItem(
          title: 'Investment / Qualification Audit',
          duration: '3-5 days',
          description: 'Pre-approval screening of property deed, capital deposit, or exceptional talent portfolio.',
          icon: Icons.account_balance_wallet_rounded,
        ),
        const TimelineStepItem(
          title: 'Government Nomination & Entry Permit',
          duration: '1 wk',
          description: 'Issuance of official long-term residency authorization letter by immigration authorities.',
          icon: Icons.verified_user_rounded,
        ),
        TimelineStepItem(
          title: 'Residency Card Delivery',
          duration: resDuration,
          description: 'Biometrics registration, medical checkup, and delivery of renewable residency card.',
          icon: Icons.credit_card_rounded,
        ),
      ];
    } else if (isBusiness) {
      steps = [
        TimelineStepItem(
          title: 'Business Plan & Corporate Endorsement',
          duration: '1-2 wks',
          description: 'Review of innovative business plan and verification by an approved endorsing body in $resolvedCountry.',
          icon: Icons.business_center_rounded,
        ),
        const TimelineStepItem(
          title: 'Investment Capital Verification',
          duration: '1 wk',
          description: 'Corporate bank audit, shareholder registry, and legal commercial registration documentation.',
          icon: Icons.account_balance_rounded,
        ),
        TimelineStepItem(
          title: 'Visa Lodging & Commercial Approval',
          duration: resDuration,
          description: 'Consular processing and issuance of entrepreneur residency authorization.',
          icon: Icons.verified_rounded,
        ),
      ];
    } else {
      steps = [
        const TimelineStepItem(
          title: 'Dossier Preparation & Cover Letter',
          duration: '2-4 days',
          description: 'Custom travel itinerary, flight bookings, accommodation vouchers, and strong tie documents.',
          icon: Icons.description_outlined,
        ),
        const TimelineStepItem(
          title: 'Embassy / VFS Appointment',
          duration: '1 wk',
          description: 'Appointment booking, consular fee submission, and biometric fingerprint capture.',
          icon: Icons.calendar_month_rounded,
        ),
        TimelineStepItem(
          title: 'Visa Grant & Stamping',
          duration: resDuration,
          description: 'Consular processing and passport collection with multiple-entry travel visa sticker.',
          icon: Icons.verified_rounded,
        ),
      ];
    }

    // Tailored Criteria
    final List<String> criteria;
    if (isStudy) {
      criteria = [
        'Official unconditional offer letter from an accredited institution in $resolvedCountry.',
        'Proof of adequate financial maintenance for tuition and living accommodation costs.',
        'English or host language proficiency certification matching university standards.',
        'Valid original passport with at least 6 months validity from course start date.',
        'Clean immigration background and passed medical fitness examination.',
      ];
    } else if (isWork) {
      criteria = [
        'Confirmed employment offer or approved sponsorship contract from employer in $resolvedCountry.',
        'Verified educational credentials and minimum 1-2 years relevant professional experience.',
        'Language competency meeting the minimum legal standards for the profession.',
        'Police character clearance certificate issued within the past 6 months.',
        'Medical fitness certificate certified by an authorized panel physician.',
      ];
    } else if (isGolden) {
      criteria = [
        'Qualifying real estate ownership, direct government capital deposit, or verified executive income.',
        'Proof of legal source of investment funds and clean global financial background.',
        'Comprehensive health insurance policy covering primary applicant and dependent family.',
        'Valid original passport with minimum 6 months remaining validity.',
      ];
    } else {
      criteria = [
        'Valid original international passport with minimum 6 months validity and 2 blank pages.',
        'Bank statement showing consistent balance and sufficient funds for the planned duration.',
        'Proof of employment, business ownership, or established family ties to home country.',
        'Confirmed travel itinerary including return flights and verifiable accommodation bookings.',
        'Clean legal and immigration record with no history of previous overstays.',
      ];
    }

    // Tailored Documents (6 cards)
    final List<DocumentItem> docs;
    if (isStudy) {
      docs = [
        const DocumentItem(title: 'Valid International Passport', note: 'Blank stamp pages', icon: Icons.badge_rounded),
        const DocumentItem(title: 'Admission Offer Letter', note: 'From accredited university', icon: Icons.school_outlined),
        const DocumentItem(title: 'Academic Transcripts', note: 'Original degrees & certificates', icon: Icons.description_outlined),
        const DocumentItem(title: 'Bank Statement', note: 'Proof of funds for 1 year', icon: Icons.account_balance_outlined),
        const DocumentItem(title: 'Language Test Certificate', note: 'IELTS / PTE / TOEFL report', icon: Icons.translate_rounded),
        const DocumentItem(title: 'Medical & Biometric Photos', note: 'Embassy photo specification', icon: Icons.camera_alt_outlined),
      ];
    } else if (isWork) {
      docs = [
        const DocumentItem(title: 'Original Valid Passport', note: 'With 1+ year validity', icon: Icons.badge_rounded),
        const DocumentItem(title: 'Employment Offer Letter', note: 'Signed employment contract', icon: Icons.work_outline_rounded),
        const DocumentItem(title: 'Experience Certificates', note: 'Verified past service letters', icon: Icons.assignment_turned_in_outlined),
        const DocumentItem(title: 'Educational Degrees', note: 'Attested certificates & diplomas', icon: Icons.school_outlined),
        const DocumentItem(title: 'Police Clearance Record', note: 'Clean character certificate', icon: Icons.gavel_rounded),
        const DocumentItem(title: 'Biometric Photos', note: 'White background standard', icon: Icons.camera_alt_outlined),
      ];
    } else if (isGolden) {
      docs = [
        const DocumentItem(title: 'Original Valid Passport', note: 'Color copies of all pages', icon: Icons.badge_rounded),
        const DocumentItem(title: 'Proof of Investment / Assets', note: 'Title deed or capital proof', icon: Icons.account_balance_wallet_outlined),
        const DocumentItem(title: 'Bank Reference Letter', note: 'Verified source of funds', icon: Icons.account_balance_outlined),
        const DocumentItem(title: 'Health Insurance Policy', note: 'Comprehensive private cover', icon: Icons.health_and_safety_outlined),
        const DocumentItem(title: 'Family Documents (If Any)', note: 'Attested marriage & birth certs', icon: Icons.people_outline_rounded),
        const DocumentItem(title: 'High-Res Digital Photos', note: 'Government ID specification', icon: Icons.camera_alt_outlined),
      ];
    } else {
      docs = [
        const DocumentItem(title: 'Current Valid Passport', note: 'Original with blank pages', icon: Icons.badge_rounded),
        const DocumentItem(title: 'Bank Statement (6 Months)', note: 'Bank verified and stamped', icon: Icons.account_balance_outlined),
        const DocumentItem(title: 'Employment / Business Proof', note: 'Salary slips or NTN certificate', icon: Icons.work_outline_rounded),
        const DocumentItem(title: 'Confirmed Return Itinerary', note: 'Flight & hotel booking proof', icon: Icons.flight_takeoff_rounded),
        const DocumentItem(title: 'Travel Medical Insurance', note: 'Valid for duration of stay', icon: Icons.health_and_safety_outlined),
        const DocumentItem(title: 'Biometric Passport Photos', note: 'White background standard', icon: Icons.camera_alt_outlined),
      ];
    }

    final isScholarship = cat.contains('scholarship') || t.contains('scholarship');

    // Tailored Fee Breakdown
    final List<FeeItem> fees;
    if (isScholarship || isJob) {
      fees = const [];
    } else if (isStudy) {
      fees = [
        FeeItem(
          label: 'SB Consultation & University Filing',
          amount: resolvedFee,
          subNote: 'Application file preparation & CAS/I-20 guidance',
        ),
        const FeeItem(
          label: 'University Application & Admission Fee',
          amount: 'Direct to Uni',
          subNote: 'Paid directly to accredited university portal',
        ),
        const FeeItem(
          label: 'University Tuition Fee Deposit',
          amount: 'As per Offer',
          subNote: 'Directly applicable as per admission letter',
        ),
        const FeeItem(
          label: 'Student Visa & CAS / SEVIS Processing',
          amount: 'Govt Portal',
          subNote: 'Official student visa & immigration processing',
        ),
      ];
    } else if (isWork) {
      fees = [
        FeeItem(
          label: 'SB Work Visa Case Dossier & Filing',
          amount: resolvedFee,
          subNote: 'Legal case preparation & employer compliance review',
        ),
        const FeeItem(
          label: 'Work Permit & LMIA / Sponsorship Endorsement',
          amount: 'By Sponsor/Govt',
          subNote: 'Employer Certificate of Sponsorship (CoS) / permit levy',
        ),
        const FeeItem(
          label: 'Government Work Visa & Biometrics Fee',
          amount: 'Govt Portal',
          subNote: 'Official work visa processing & biometrics verification',
        ),
      ];
    } else if (isGolden || isBusiness) {
      fees = [
        FeeItem(
          label: 'SB Executive Residency Advisory Fee',
          amount: resolvedFee,
          subNote: 'Comprehensive investor portfolio & legal representation',
        ),
        const FeeItem(
          label: 'Government Golden Visa / Investor Registration',
          amount: 'Official Authority',
          subNote: 'Directly payable to government residency authority',
        ),
        const FeeItem(
          label: 'Commercial Audit & Due Diligence Clearance',
          amount: 'Certified Body',
          subNote: 'Background check & verified asset audit clearance',
        ),
      ];
    } else {
      fees = [
        FeeItem(
          label: 'SB Visa Consultation & File Preparation',
          amount: resolvedFee,
          subNote: 'Dossier preparation, SOP & appointment scheduling',
        ),
        const FeeItem(
          label: 'Government Visa Application Fee',
          amount: 'Govt Portal',
          subNote: 'Official visa application fee paid on consular portal',
        ),
        const FeeItem(
          label: 'Biometrics & VFS Center Appointment',
          amount: 'VFS / Gerrys',
          subNote: 'Biometric capture & physical document submission',
        ),
      ];
    }

    return DetailItemModel(
      id: id ?? title.toLowerCase().replaceAll(' ', '-'),
      type: isJob ? 'job' : (isScholarship ? 'scholarship' : 'visa'),
      title: title,
      subtitle: subtitle ?? (isStudy ? 'Higher Education Route' : isWork ? 'Professional Employment Pathway' : isGolden ? 'Long-Term Residence Permit' : 'Official Consular Advisory'),
      categoryTag: categoryTag ?? (isStudy ? 'Study Visa' : isWork ? 'Work Visa' : isGolden ? 'Golden Visa' : 'Visit Visa'),
      countryName: resolvedCountry,
      countryFlag: resolvedFlag,
      statusBadge: isJob ? 'Actively Hiring' : 'Available',
      heroImageUrl: heroImg,
      processingTime: resDuration,
      validity: resValidity,
      successRate: resRate,
      applicantsCount: applicants,
      aboutTitle: 'About this program',
      aboutDescription:
          '$title provides legal authorization for travel, study, or settlement in $resolvedCountry. SB Consultants handles complete preliminary qualification assessment, financial document verification, case dossier preparation, appointment scheduling, and end-to-end embassy filing.',
      timelineSteps: steps,
      eligibilityCriteria: criteria,
      mandatoryDocuments: docs,
      feeBreakdown: fees,
      totalPayable: (isScholarship || isJob) ? '' : resolvedFee,
      serviceFeeLabel: (isScholarship || isJob) ? '' : 'SERVICE FEE',
      serviceFeeValue: (isScholarship || isJob) ? '' : resolvedFee,
    );
  }

  static String _resolveFlag(String country, String title) {
    final c = country.toLowerCase();
    final t = title.toLowerCase();
    if (c.contains('united kingdom') || c.contains('uk') || t.contains('uk')) return '🇬🇧';
    if (c.contains('canada') || t.contains('canada')) return '🇨🇦';
    if (c.contains('australia') || t.contains('australia')) return '🇦🇺';
    if (c.contains('germany') || t.contains('germany')) return '🇩🇪';
    if (c.contains('united states') || c.contains('usa') || t.contains('usa') || t.contains('us ')) return '🇺🇸';
    if (c.contains('dubai') || c.contains('uae') || c.contains('united arab') || t.contains('dubai')) return '🇦🇪';
    if (c.contains('portugal')) return '🇵🇹';
    if (c.contains('greece')) return '🇬🇷';
    if (c.contains('spain')) return '🇪🇸';
    if (c.contains('malta')) return '🇲🇹';
    if (c.contains('saudi')) return '🇸🇦';
    if (c.contains('ireland')) return '🇮🇪';
    if (c.contains('france')) return '🇫🇷';
    if (c.contains('italy')) return '🇮🇹';
    if (c.contains('turkey')) return '🇹🇷';
    if (c.contains('malaysia')) return '🇲🇾';
    return '🌍';
  }

  static String _resolveHeroImage(String country, bool isStudy, bool isWork, bool isGolden) {
    final c = country.toLowerCase();
    if (c.contains('uk') || c.contains('united kingdom')) {
      return 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=1000';
    }
    if (c.contains('canada')) {
      return isStudy
          ? 'https://images.unsplash.com/photo-1517935703635-27c946452576?w=1000'
          : 'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=1000';
    }
    if (c.contains('australia')) {
      return 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=1000';
    }
    if (c.contains('germany')) {
      return 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=1000';
    }
    if (c.contains('united states') || c.contains('usa')) {
      return 'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?w=1000';
    }
    if (c.contains('dubai') || c.contains('uae') || c.contains('united arab')) {
      return 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=1000';
    }
    if (c.contains('portugal')) {
      return 'https://images.unsplash.com/photo-1555881400-74d7acaacd81?w=1000';
    }
    if (c.contains('greece')) {
      return 'https://images.unsplash.com/photo-1533105079780-92b9be482077?w=1000';
    }
    if (c.contains('spain')) {
      return 'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=1000';
    }
    if (c.contains('malta')) {
      return 'https://images.unsplash.com/photo-1514896856000-91cb6de818e0?w=1000';
    }
    if (c.contains('saudi')) {
      return 'https://images.unsplash.com/photo-1586724237569-f3d0c1dee8c6?w=1000';
    }
    if (c.contains('ireland')) {
      return 'https://images.unsplash.com/photo-1549918864-48ac978761a4?w=1000';
    }
    return 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=1000';
  }

  static DetailItemModel getDetailForJob(SponsoredJobModel job) {
    return DetailItemModel(
      id: job.id,
      type: 'job',
      title: job.jobTitle,
      subtitle: '${job.companyName} · ${job.location}',
      categoryTag: 'Sponsored Job',
      countryName: job.location,
      countryFlag: job.countryFlag,
      statusBadge: 'Actively Hiring',
      heroImageUrl:
          'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1000',
      processingTime: '2-4 wks',
      validity: 'Full-time / PR',
      successRate: '98%',
      applicantsCount: '480',
      aboutTitle: 'About this role',
      aboutDescription:
          '${job.companyName} is hiring a qualified ${job.jobTitle} based in ${job.location}. This certified employer provides an official Certificate of Sponsorship (CoS) and complete visa sponsorship assistance through SB Consultants, including work authorization filing and family visa options.',
      timelineSteps: const [
        TimelineStepItem(
          title: 'CV Screening & Shortlisting',
          duration: '3-5 days',
          description:
              'Initial candidate assessment and credentials verification by HR.',
          icon: Icons.assignment_ind_rounded,
        ),
        TimelineStepItem(
          title: 'Technical Interview',
          duration: '1 wk',
          description:
              'Direct online interview with the hiring manager in the destination country.',
          icon: Icons.video_call_rounded,
        ),
        TimelineStepItem(
          title: 'Sponsorship Letter & Visa',
          duration: '2-3 wks',
          description:
              'Issuance of official CoS / LMIA work permit and visa stamp filing.',
          icon: Icons.verified_user_rounded,
        ),
      ],
      eligibilityCriteria: [
        'Relevant professional qualifications or minimum 1-2 years experience in the field.',
        'Basic English language proficiency required for workplace safety standards.',
        'Clean police clearance certificate and valid international travel passport.',
        'Commitment to a minimum 12-month employment contract with ${job.companyName}.',
      ],
      mandatoryDocuments: const [
        DocumentItem(
          title: 'Updated Resume / CV',
          note: 'EuroPass or standard format',
          icon: Icons.description_outlined,
        ),
        DocumentItem(
          title: 'Experience Letters',
          note: 'From previous employers',
          icon: Icons.work_outline_rounded,
        ),
        DocumentItem(
          title: 'Educational Degrees',
          note: 'Verified copies',
          icon: Icons.school_outlined,
        ),
        DocumentItem(
          title: 'Passport Copy',
          note: 'Minimum 1 year validity',
          icon: Icons.badge_rounded,
        ),
        DocumentItem(
          title: 'Police Clearance',
          note: 'Issued within 6 months',
          icon: Icons.gavel_rounded,
        ),
        DocumentItem(
          title: 'Medical Certificate',
          note: 'Fit-to-work fitness check',
          icon: Icons.health_and_safety_outlined,
        ),
      ],
      feeBreakdown: const [],
      totalPayable: '',
      serviceFeeLabel: '',
      serviceFeeValue: '',
      salary: (job.salary != null && job.salary!.isNotEmpty)
          ? '${job.salary} ${job.salaryPeriod ?? "/ yr"}'
          : (job.salaryRange != null && job.salaryRange!.isNotEmpty
              ? '${job.salaryRange} / yr'
              : '£36,000 – £44,000 / yr'),
      externalUrl: job.externalUrl ?? 'https://uk.indeed.com',
    );
  }

  // ===========================================================================
  // 13. RESOLVE DETAIL BY ID OR SLUG (DYNAMIC RESOLVER — NEVER DEFAULT TO UK)
  // ===========================================================================
  static DetailItemModel getDetailByIdOrSlug(String? idOrSlug) {
    if (idOrSlug == null || idOrSlug.trim().isEmpty) {
      return getUkStudentVisaDetail();
    }

    final slug = idOrSlug.trim().toLowerCase();

    // 1. Exact preset IDs
    if (slug == 'uk-student-visa') return getUkStudentVisaDetail();
    if (slug == 'uk-skilled-worker-visa') return getUkSkilledWorkerVisaDetail();
    if (slug == 'canada-study-permit') return getCanadaStudyPermitDetail();
    if (slug == 'canada-work-permit') return getCanadaWorkPermitDetail();
    if (slug == 'australia-student-visa') return getAustraliaStudentVisaDetail();
    if (slug == 'germany-chancenkarte') return getGermanyChancenkarteDetail();
    if (slug == 'dubai-golden-visa') return getDubaiGoldenVisaDetail();
    if (slug == 'usa-b1-b2-visa') return getUsaVisitorVisaDetail();

    // 2. Keyword & Region Matching
    if (slug.contains('dubai') || slug.contains('uae') || slug.contains('emirates')) {
      if (slug.contains('visit') || slug.contains('tourist') || slug.contains('3') || slug.contains('1')) {
        return getDetailFromGeneric(
          id: idOrSlug,
          title: 'Dubai Express Tourist & Visit Visa',
          subtitle: 'Electronic tourist entry clearance with fast verification',
          countryName: 'United Arab Emirates',
          categoryTag: 'Visit Visa',
          fee: r'USD $190',
        );
      }
      return getDubaiGoldenVisaDetail();
    }

    if (slug.contains('canada')) {
      if (slug.contains('study') || slug.contains('student')) {
        return getCanadaStudyPermitDetail();
      }
      return getCanadaWorkPermitDetail();
    }

    if (slug.contains('australia') || slug.contains('aus')) {
      return getAustraliaStudentVisaDetail();
    }

    if (slug.contains('germany') || slug.contains('chancenkarte') || slug.contains('opportunity')) {
      return getGermanyChancenkarteDetail();
    }

    if (slug.contains('schengen') || slug.contains('france') || slug.contains('italy') || slug.contains('spain')) {
      return getSchengenVisaDetail();
    }

    if (slug.contains('us') || slug.contains('usa') || slug.contains('america') || slug.contains('b1') || slug.contains('b2')) {
      return getUsaVisitorVisaDetail();
    }

    if (slug.contains('skilled') || slug.contains('work')) {
      return getUkSkilledWorkerVisaDetail();
    }

    if (slug.contains('student') || slug.contains('study')) {
      return getUkStudentVisaDetail();
    }

    // 3. Fallback for raw timestamp IDs or unformatted digit strings (e.g. visa-1793178377335)
    final hasTimestampOrDigits = RegExp(r'\d{5,}').hasMatch(slug);
    if (hasTimestampOrDigits || (slug.startsWith('visa-') && !slug.contains('tier') && !slug.contains('student') && !slug.contains('work'))) {
      final category = slug.contains('visit')
          ? 'Visit Visa'
          : slug.contains('work')
              ? 'Work Visa'
              : slug.contains('business')
                  ? 'Business Visa'
                  : slug.contains('study')
                      ? 'Study Visa'
                      : 'Visa Consultation';

      return getDetailFromGeneric(
        id: idOrSlug,
        title: '$category Application & Filing',
        subtitle: 'Comprehensive immigration evaluation, documentation prep & embassy filing',
        categoryTag: category,
        fee: 'PKR 25,000',
      );
    }

    // 4. Dynamic Humanized Title Fallback
    final formattedTitle = idOrSlug
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');

    return getDetailFromGeneric(
      id: idOrSlug,
      title: formattedTitle,
      categoryTag: slug.contains('visit')
          ? 'Visit Visa'
          : slug.contains('work')
              ? 'Work Visa'
              : slug.contains('business')
                  ? 'Business Visa'
                  : slug.contains('study')
                      ? 'Study Visa'
                      : 'Visa Consultation',
    );
  }
}


