import 'package:flutter/material.dart';

/// Field type for dynamic applicant requirement inputs.
enum RequirementFieldType {
  text,
  dropdown,
  date,
}

/// Model representing an individual requirement field in the application form.
class RequirementField {
  const RequirementField({
    required this.id,
    required this.label,
    required this.hint,
    required this.defaultValue,
    this.type = RequirementFieldType.text,
    this.dropdownOptions = const [],
    this.isHalfWidth = false,
    this.icon,
  });

  final String id;
  final String label;
  final String hint;
  final String defaultValue;
  final RequirementFieldType type;
  final List<String> dropdownOptions;
  final bool isHalfWidth;
  final IconData? icon;
}

/// ============================================================================
/// WHERE TO CHANGE REQUIREMENTS MANUALLY IN FUTURE:
///
/// To add, modify, or remove requirement fields for any visa category, edit the
/// configurations in this file:
/// - Study Visas & Scholarships: [studyVisaConfig]
/// - Work Visas & Sponsored Jobs: [workVisaConfig]
/// - Business Visas & Golden Visas: [businessVisaConfig]
/// - Visit Visas & Tourist Visas: [visitVisaConfig]
/// - General / Fallback Visas: [defaultVisaConfig]
/// ============================================================================
class ApplicantFormConfig {
  const ApplicantFormConfig({
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.sectionIcon,
    required this.badgeText,
    required this.fields,
  });

  final String sectionTitle;
  final String sectionSubtitle;
  final IconData sectionIcon;
  final String badgeText;
  final List<RequirementField> fields;

  /// Builds a dynamic form configuration directly from the visa's live application requirements & custom questions.
  static ApplicantFormConfig fromApplicationRequirements(
    dynamic reqs,
    String categoryTag, {
    String? visaTitle,
  }) {
    if (reqs is! Map) {
      return getConfigForCategory(categoryTag, visaTitle: visaTitle);
    }

    final fields = <RequirementField>[];

    // 1. Age Requirement
    final ageReq = reqs['age_requirement'];
    if (ageReq is Map && ageReq['enabled'] == true) {
      final minAge = ageReq['min_age'] ?? 18;
      final maxAge = ageReq['max_age'] ?? 35;
      final bracket = ageReq['bracket']?.toString() ?? '$minAge - $maxAge Years';
      fields.add(
        RequirementField(
          id: 'applicant_age',
          label: 'Applicant Age ($minAge - $maxAge yrs)',
          hint: 'e.g. 24 ($bracket)',
          defaultValue: '',
          isHalfWidth: true,
          icon: Icons.cake_rounded,
        ),
      );
    }

    // 2. Education Requirement
    final eduReq = reqs['education_requirement'];
    if (eduReq is Map && eduReq['enabled'] == true) {
      final minQual = eduReq['min_qualification']?.toString() ?? "Bachelor's Degree";
      final marks = eduReq['min_cgpa_or_marks']?.toString() ?? '';
      final fieldOfStudy = eduReq['field_of_study']?.toString() ?? '';
      fields.add(
        RequirementField(
          id: 'highest_qualification',
          label: 'Highest Qualification (Min: $minQual)',
          hint: 'e.g. $minQual ${fieldOfStudy.isNotEmpty ? "in $fieldOfStudy" : ""}',
          defaultValue: '',
          icon: Icons.school_rounded,
        ),
      );
      if (marks.isNotEmpty) {
        fields.add(
          RequirementField(
            id: 'academic_marks',
            label: 'Academic Marks / CGPA (Min: $marks)',
            hint: 'e.g. $marks',
            defaultValue: '',
            isHalfWidth: true,
            icon: Icons.grade_rounded,
          ),
        );
      }
    }

    // 3. Language Requirement
    final langReq = reqs['language_requirement'];
    if (langReq is Map && langReq['enabled'] == true) {
      final test = langReq['test_type']?.toString() ?? 'IELTS';
      final minScore = langReq['min_score']?.toString() ?? '6.5';
      final isMandatory = langReq['is_mandatory'] != false;
      fields.add(
        RequirementField(
          id: 'language_test_score',
          label: '$test Test Score (${isMandatory ? "Mandatory" : "Optional"} Min: $minScore)',
          hint: 'e.g. Overall $minScore or band scores',
          defaultValue: '',
          icon: Icons.translate_rounded,
        ),
      );
    }

    // 4. Experience Requirement
    final expReq = reqs['experience_requirement'];
    if (expReq is Map && expReq['enabled'] == true) {
      final minYears = expReq['min_years']?.toString() ?? '2';
      final role = expReq['role_level']?.toString() ?? '';
      fields.add(
        RequirementField(
          id: 'work_experience_years',
          label: 'Relevant Experience (Min: $minYears Years)',
          hint: 'e.g. $minYears Years ${role.isNotEmpty ? "($role level)" : ""}',
          defaultValue: '',
          icon: Icons.work_outline_rounded,
        ),
      );
    }

    // 5. Financial Requirement
    final finReq = reqs['financial_requirement'];
    if (finReq is Map && finReq['enabled'] == true) {
      final balance = finReq['min_bank_balance']?.toString() ?? '';
      final period = finReq['holding_period']?.toString() ?? '';
      final proof = finReq['proof_type']?.toString() ?? 'Bank Statement';
      fields.add(
        RequirementField(
          id: 'bank_statement_balance',
          label: 'Bank Balance Proof (Required: $balance)',
          hint: 'e.g. $balance ($proof holding $period)',
          defaultValue: '',
          icon: Icons.account_balance_rounded,
        ),
      );
    }

    // 6. Security & Travel Checkpoints
    final travelReq = reqs['travel_history_requirement'];
    if (travelReq is Map) {
      if (travelReq['prior_travel_required'] == true) {
        fields.add(
          const RequirementField(
            id: 'prior_travel_history',
            label: 'International Travel History',
            hint: 'List previous countries visited (or None)',
            defaultValue: '',
            icon: Icons.flight_takeoff_rounded,
          ),
        );
      }
      if (travelReq['rejection_declaration_required'] == true) {
        fields.add(
          const RequirementField(
            id: 'rejection_declaration',
            label: 'Previous Visa Rejection History',
            hint: 'Declare any past visa refusals (Country, Year, Reason)',
            defaultValue: 'No previous visa rejections',
            icon: Icons.gavel_rounded,
          ),
        );
      }
      if (travelReq['police_certificate_required'] == true) {
        fields.add(
          const RequirementField(
            id: 'police_certificate',
            label: 'Police Character Certificate Status',
            hint: 'e.g. Valid / Issued within last 6 months',
            defaultValue: 'Issued & Available',
            icon: Icons.verified_user_rounded,
          ),
        );
      }
      if (travelReq['medical_check_required'] == true) {
        fields.add(
          const RequirementField(
            id: 'medical_check',
            label: 'Medical Fitness / TB Screening',
            hint: 'e.g. Fit to travel / Clinic report ready',
            defaultValue: 'Fit to Travel',
            icon: Icons.health_and_safety_rounded,
          ),
        );
      }
    }

    // 7. Custom Dynamic Applicant Questions
    final customQuestions = reqs['custom_questions'];
    if (customQuestions is List) {
      for (int i = 0; i < customQuestions.length; i++) {
        final q = customQuestions[i];
        if (q is Map) {
          final qText = q['question']?.toString().trim() ?? '';
          if (qText.isEmpty) continue;
          final qId = q['id']?.toString() ?? 'custom_q_$i';
          final qType = q['type']?.toString().toLowerCase() ?? 'text';
          final optionsStr = q['options']?.toString() ?? '';
          final isRequired = q['is_required'] != false;

          if (qType == 'dropdown' && optionsStr.isNotEmpty) {
            final opts = optionsStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            fields.add(
              RequirementField(
                id: qId,
                label: '$qText${isRequired ? " *" : ""}',
                hint: 'Select an option',
                defaultValue: opts.isNotEmpty ? opts.first : '',
                type: RequirementFieldType.dropdown,
                dropdownOptions: opts,
                icon: Icons.help_outline_rounded,
              ),
            );
          } else {
            fields.add(
              RequirementField(
                id: qId,
                label: '$qText${isRequired ? " *" : ""}',
                hint: 'Enter your answer',
                defaultValue: '',
                icon: Icons.help_outline_rounded,
              ),
            );
          }
        }
      }
    }

    if (fields.isEmpty) {
      return getConfigForCategory(categoryTag, visaTitle: visaTitle);
    }

    return ApplicantFormConfig(
      sectionTitle: 'Tailored Visa Requirements & Checkpoints',
      sectionSubtitle: 'Specific eligibility criteria and mandatory declarations configured for this visa',
      sectionIcon: Icons.checklist_rounded,
      badgeText: 'Verified Criteria',
      fields: fields,
    );
  }

  /// Returns the tailored requirement configuration for any visa category.
  static ApplicantFormConfig getConfigForCategory(
    String categoryTag, {
    String? visaTitle,
  }) {
    final cat = '$categoryTag ${visaTitle ?? ''}'.toLowerCase();

    if (cat.contains('scholarship')) {
      return scholarshipConfig;
    } else if (cat.contains('study') || cat.contains('tier 4') || cat.contains('student')) {
      return studyVisaConfig;
    } else if (cat.contains('sponser') || cat.contains('sponsor') || (cat.contains('job') && !cat.contains('study'))) {
      return sponsoredJobConfig;
    } else if (cat.contains('work') || cat.contains('job') || cat.contains('skilled')) {
      return workVisaConfig;
    } else if (cat.contains('golden')) {
      return goldenVisaConfig;
    } else if (cat.contains('business') || cat.contains('investor') || cat.contains('invest')) {
      return businessVisaConfig;
    } else if (cat.contains('visit') || cat.contains('tourist') || cat.contains('holiday') || cat.contains('family')) {
      return visitVisaConfig;
    }

    return defaultVisaConfig;
  }

  // --------------------------------------------------------------------------
  // 1A. SCHOLARSHIPS CONFIGURATION (Age & Marks Specific)
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig scholarshipConfig = ApplicantFormConfig(
    sectionTitle: 'Scholarship Eligibility & Academic Scores',
    sectionSubtitle: 'Applicant age limit verification and academic marks / CGPA criteria',
    sectionIcon: Icons.military_tech_rounded,
    badgeText: 'Merit & Age',
    fields: [
      RequirementField(
        id: 'scholarship_age',
        label: 'Applicant Age (Years)',
        hint: 'e.g. 24',
        defaultValue: '24 Years',
        isHalfWidth: true,
        icon: Icons.cake_rounded,
      ),
      RequirementField(
        id: 'age_limit_bracket',
        label: 'Age Eligibility Category',
        hint: 'Select age group',
        defaultValue: '18 - 25 Years (Full Scholarship Eligibility)',
        isHalfWidth: true,
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          '18 - 25 Years (Full Scholarship Eligibility)',
          '26 - 30 Years (Standard Grant Scheme)',
          '31 - 35 Years (Postgraduate Fellow)',
          '35+ Years (Special Merit Exemption)',
        ],
      ),
      RequirementField(
        id: 'degree_marks_cgpa',
        label: 'Academic Marks / CGPA',
        hint: 'e.g. 3.82 / 4.00 CGPA (86%)',
        defaultValue: '3.82 / 4.00 CGPA (86%)',
        isHalfWidth: true,
        icon: Icons.grade_rounded,
      ),
      RequirementField(
        id: 'grading_division',
        label: 'Honours / Division Class',
        hint: 'Select classification',
        defaultValue: 'First Class Honours (Distinction)',
        isHalfWidth: true,
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'First Class Honours (Distinction)',
          'First Division (3.5 - 4.0 CGPA)',
          'Second Division (Upper 3.0 - 3.49)',
          'Grade A (80%+ Equivalent)',
        ],
      ),
      RequirementField(
        id: 'english_test_score',
        label: 'Language Proficiency Test Marks',
        hint: 'Select score',
        defaultValue: 'IELTS Academic: 7.5 Overall Band',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'IELTS Academic: 7.5 Overall Band',
          'IELTS Academic: 8.0+ Superior Band',
          'TOEFL iBT: 102+ Score',
          'PTE Academic: 76+ Score',
          'Exempted (English Medium Degree)',
        ],
      ),
      RequirementField(
        id: 'target_scholarship',
        label: 'Target Scholarship Scheme & Institution',
        hint: 'e.g. Fully Funded Master\'s Scholarship',
        defaultValue: 'Fully Funded International Master\'s Scholarship',
        icon: Icons.school_rounded,
      ),
    ],
  );

  // --------------------------------------------------------------------------
  // 1B. SPONSORED JOBS CONFIGURATION (Age & Marks Specific)
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig sponsoredJobConfig = ApplicantFormConfig(
    sectionTitle: 'Age & Qualification Marks Assessment',
    sectionSubtitle: 'Point-based age scoring, degree marks, and sponsorship qualification',
    sectionIcon: Icons.work_rounded,
    badgeText: 'Points Test',
    fields: [
      RequirementField(
        id: 'job_applicant_age',
        label: 'Applicant Age (Points Allocation)',
        hint: 'e.g. 28',
        defaultValue: '28 Years',
        isHalfWidth: true,
        icon: Icons.cake_rounded,
      ),
      RequirementField(
        id: 'age_points_bracket',
        label: 'Immigration Points Age Bracket',
        hint: 'Select age bracket',
        defaultValue: '25 - 32 Years (Maximum 30 Points)',
        isHalfWidth: true,
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          '25 - 32 Years (Maximum 30 Points)',
          '18 - 24 Years (25 Points)',
          '33 - 39 Years (25 Points)',
          '40 - 44 Years (15 Points)',
          '45+ Years (Executive / Endorsement)',
        ],
      ),
      RequirementField(
        id: 'degree_marks',
        label: 'Degree Marks / CGPA / Grade',
        hint: 'e.g. 3.70 CGPA / 82% First Class',
        defaultValue: '3.70 CGPA / 82% First Class',
        isHalfWidth: true,
        icon: Icons.grade_rounded,
      ),
      RequirementField(
        id: 'job_experience_years',
        label: 'Total Professional Experience',
        hint: 'Select experience',
        defaultValue: '5 - 7 Years (Senior Level)',
        isHalfWidth: true,
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          '1 - 2 Years',
          '3 - 5 Years (Mid Level)',
          '5 - 7 Years (Senior Level)',
          '8+ Years (Lead / Director)',
        ],
      ),
      RequirementField(
        id: 'english_test_marks',
        label: 'Language Competency Marks (UKVI / PTE)',
        hint: 'Select score',
        defaultValue: 'IELTS for UKVI: 7.0 Overall (B2/C1 Met)',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'IELTS for UKVI: 7.0 Overall (B2/C1 Met)',
          'IELTS for UKVI: 6.5 Overall (B2 Met)',
          'PTE Academic UKVI: 68 Score',
          'Degree Taught in English (ECCTIS Verified)',
        ],
      ),
      RequirementField(
        id: 'target_sponsored_designation',
        label: 'Target Sponsored Designation & Role',
        hint: 'e.g. Senior Software Engineer',
        defaultValue: 'Senior Software Engineer / Tech Lead',
        icon: Icons.badge_rounded,
      ),
    ],
  );

  // --------------------------------------------------------------------------
  // 1. STUDY VISA & SCHOLARSHIPS CONFIGURATION
  // (Change education fields below)
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig studyVisaConfig = ApplicantFormConfig(
    sectionTitle: 'Academic Credentials & Program Track',
    sectionSubtitle: 'Intended degree course, previous academic background, and institution verification',
    sectionIcon: Icons.school_rounded,
    badgeText: 'Academic',
    fields: [
      RequirementField(
        id: 'target_country',
        label: 'Target Destination Country',
        hint: 'e.g. United Kingdom, Canada, Australia',
        defaultValue: 'United Kingdom',
        icon: Icons.public_rounded,
      ),
      RequirementField(
        id: 'preferred_course',
        label: 'Intended Program (or Explain)',
        hint: 'e.g. MSc Advanced Computer Science / Seeking Fall Admission',
        defaultValue: 'MSc Advanced Computer Science with Placement',
        icon: Icons.school_outlined,
      ),
      RequirementField(
        id: 'highest_qualification',
        label: 'Last Completed Degree',
        hint: 'Select or specify highest degree',
        defaultValue: 'Bachelor of Science in Computer Science (4-Year BS)',
        isHalfWidth: true,
        icon: Icons.workspace_premium_rounded,
      ),
      RequirementField(
        id: 'grad_result',
        label: 'Marks / CGPA Obtained',
        hint: 'e.g. 3.65 CGPA / 82%',
        defaultValue: '3.65 CGPA / 82%',
        isHalfWidth: true,
        icon: Icons.grade_rounded,
      ),
      RequirementField(
        id: 'institution_name',
        label: 'University / Board Name of Last Degree',
        hint: 'e.g. NUST, FAST, LUMS, University of the Punjab',
        defaultValue: 'National University of Sciences & Technology (NUST)',
        icon: Icons.account_balance_rounded,
      ),
    ],
  );

  // --------------------------------------------------------------------------
  // 2. WORK VISA & SPONSORED JOBS CONFIGURATION
  // (Change employment & profession fields below)
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig workVisaConfig = ApplicantFormConfig(
    sectionTitle: 'Professional Background',
    sectionSubtitle: 'Current employment, experience, and target job role',
    sectionIcon: Icons.work_rounded,
    badgeText: 'Employment',
    fields: [
      RequirementField(
        id: 'job_title',
        label: 'Current Job Title / Designation',
        hint: 'e.g. Senior Software Engineer',
        defaultValue: 'Senior Software Engineer',
        icon: Icons.badge_rounded,
      ),
      RequirementField(
        id: 'experience_years',
        label: 'Total Professional Experience',
        hint: 'Select years of experience',
        defaultValue: '5 - 7 Years',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          '1 - 2 Years',
          '3 - 5 Years',
          '5 - 7 Years',
          '8 - 10 Years',
          '10+ Years',
        ],
      ),
      RequirementField(
        id: 'current_company',
        label: 'Current Employer / Organization',
        hint: 'Company name',
        defaultValue: 'Techlogix Systems Pvt Ltd',
        icon: Icons.business_rounded,
      ),
      RequirementField(
        id: 'target_field',
        label: 'Target Industry / Field',
        hint: 'Select sector',
        defaultValue: 'Information Technology & Software',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Information Technology & Software',
          'Healthcare & Medical Services',
          'Engineering & Construction',
          'Finance & Accounting',
          'Hospitality & Tourism',
        ],
      ),
    ],
  );

  // --------------------------------------------------------------------------
  // 3. BUSINESS & GOLDEN VISA CONFIGURATION
  // (Change investor & company fields below)
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig businessVisaConfig = ApplicantFormConfig(
    sectionTitle: 'Business Credentials & Verification',
    sectionSubtitle: 'Enterprise establishment, FBR registration, NTN, invitation letter, and Chamber accreditation',
    sectionIcon: Icons.business_center_rounded,
    badgeText: 'Commercial Profile',
    fields: [
      RequirementField(
        id: 'has_business_status',
        label: 'Do you currently own or operate any business?',
        hint: 'Select status',
        defaultValue: 'Yes, Active Business',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Yes, Active Business',
          'No Business',
        ],
      ),
      RequirementField(
        id: 'business_details',
        label: 'Share Business & Company Details',
        hint: 'Registered company name, industry, years active, and role',
        defaultValue: 'Apex Logistics & Trade International — Managing Director (8 Years Active Operations)',
        icon: Icons.store_rounded,
      ),
      RequirementField(
        id: 'fbr_registered',
        label: 'Is your business registered with FBR?',
        hint: 'Select registration status',
        defaultValue: 'Yes, Registered with FBR',
        type: RequirementFieldType.dropdown,
        isHalfWidth: true,
        dropdownOptions: [
          'Yes, Registered with FBR',
          'No, Not Registered',
        ],
      ),
      RequirementField(
        id: 'has_ntn_number',
        label: 'Do you have an active NTN number?',
        hint: 'Select NTN status',
        defaultValue: 'Yes, Have NTN',
        type: RequirementFieldType.dropdown,
        isHalfWidth: true,
        dropdownOptions: [
          'Yes, Have NTN',
          'No NTN',
        ],
      ),
      RequirementField(
        id: 'ntn_number',
        label: 'Write Your 7-Digit NTN Number',
        hint: 'e.g. 2847591-3',
        defaultValue: '2847591-3',
        icon: Icons.tag_rounded,
      ),
      RequirementField(
        id: 'has_invitation_letter',
        label: 'Do you have a business invitation letter?',
        hint: 'Select invitation status',
        defaultValue: 'Yes, Have Invitation',
        type: RequirementFieldType.dropdown,
        isHalfWidth: true,
        dropdownOptions: [
          'Yes, Have Invitation',
          'No Invitation Letter',
        ],
      ),
      RequirementField(
        id: 'is_chamber_member',
        label: 'Are you a member of Chamber of Commerce?',
        hint: 'Select membership status',
        defaultValue: 'Yes, Active Member',
        type: RequirementFieldType.dropdown,
        isHalfWidth: true,
        dropdownOptions: [
          'Yes, Active Member',
          'No Membership',
        ],
      ),
    ],
  );

  // --------------------------------------------------------------------------
  // 3B. GOLDEN VISA & LONG TERM RESIDENCY CONFIGURATION
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig goldenVisaConfig = ApplicantFormConfig(
    sectionTitle: 'Golden Visa Applicant Details',
    sectionSubtitle: 'Official long-term residency qualification parameters for commercial investors',
    sectionIcon: Icons.workspace_premium_rounded,
    badgeText: 'Golden Residency',
    fields: [
      RequirementField(
        id: 'golden_age',
        label: 'Applicant Age (Years)',
        hint: 'e.g. 38',
        defaultValue: '38',
        isHalfWidth: true,
        icon: Icons.cake_rounded,
      ),
      RequirementField(
        id: 'golden_business',
        label: 'Business Information & Enterprise Profile',
        hint: 'Enterprise name, sector, commercial operations, and executive role',
        defaultValue: 'Apex Holdings & Global Investments — Chairman & Majority Shareholder',
        icon: Icons.business_center_rounded,
      ),
      RequirementField(
        id: 'yearly_income',
        label: 'Yearly Income in Numbers (PKR / USD)',
        hint: 'e.g. 75,000,000',
        defaultValue: '75,000,000',
        icon: Icons.payments_rounded,
      ),
      RequirementField(
        id: 'fbr_status',
        label: 'FBR Taxpayer Status (Tax Filer / Non-Filer)',
        hint: 'Select status',
        defaultValue: 'Yes, Active FBR Payer',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Yes, Active FBR Payer',
          'No, Not FBR Payer',
        ],
      ),
    ],
  );
  // 4. VISIT VISA & TOURIST VISA CONFIGURATION
  // (Change travel purpose & duration fields below)
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig visitVisaConfig = ApplicantFormConfig(
    sectionTitle: 'Travel, Background & Verification',
    sectionSubtitle: 'Visitor itinerary, employment history, bank statement, and refusal check',
    sectionIcon: Icons.flight_takeoff_rounded,
    badgeText: 'Travel & Background',
    fields: [
      RequirementField(
        id: 'visit_applicant_age',
        label: 'Applicant Age (Years)',
        hint: 'e.g. 28',
        defaultValue: '28 Years',
        isHalfWidth: true,
        icon: Icons.cake_rounded,
      ),
      RequirementField(
        id: 'age_travel_bracket',
        label: 'Traveler Age Category',
        hint: 'Select category',
        defaultValue: '18 - 35 Years (Prime Adult Tourist)',
        isHalfWidth: true,
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          '18 - 35 Years (Prime Adult Tourist)',
          '36 - 55 Years (Established Traveler)',
          '55+ Years (Senior Citizen / Super Visa)',
          'Under 18 Years (Minor with Guardian)',
        ],
      ),
      RequirementField(
        id: 'work_history_status',
        label: 'Previous Work / Employment Status',
        hint: 'Select work status',
        defaultValue: 'Yes, Active Employment / Business Experience',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Yes, Active Employment / Business Experience',
          'No Formal Work History (Student / Homemaker / Dependent)',
          'Self-Employed / Freelance Professional',
          'Retired Senior Citizen',
        ],
      ),
      RequirementField(
        id: 'work_details',
        label: 'Previous Employer & Role Details',
        hint: 'Company name, designation, tenure',
        defaultValue: 'Senior Software Engineer at Systems Ltd (4 Years Experience)',
        icon: Icons.work_rounded,
      ),
      RequirementField(
        id: 'bank_history_status',
        label: 'Bank Statement & Transaction History',
        hint: 'Select banking status',
        defaultValue: 'Yes, Active Bank Account (> 6 Months Statement)',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Yes, Active Bank Account (> 6 Months Statement)',
          'No Personal Bank History (3rd-Party Sponsorship Required)',
          'Company / Business Corporate Bank Statement',
        ],
      ),
      RequirementField(
        id: 'bank_statement_details',
        label: 'Bank & Financial Funds Details',
        hint: 'Bank name, closing balance, turnover',
        defaultValue: 'Habib Bank Ltd (HBL) - 6-month statement, avg PKR 2.8M balance',
        icon: Icons.account_balance_rounded,
      ),
      RequirementField(
        id: 'visa_refusal_status',
        label: 'Previous Visa Rejection / Refusal Status',
        hint: 'Select refusal history',
        defaultValue: 'Clean Record (0 Previous Visa Refusals)',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Clean Record (0 Previous Visa Refusals)',
          'Yes, Prior Visa Refusal (Legal Appeal / Rebuttal Needed)',
        ],
      ),
      RequirementField(
        id: 'visa_refusal_details',
        label: 'Visa Rejection Details (If Applicable)',
        hint: 'Country, year, visa category, and refusal grounds',
        defaultValue: 'None (Clean Immigration History)',
        icon: Icons.gavel_rounded,
      ),
      RequirementField(
        id: 'visit_purpose',
        label: 'Primary Purpose of Visit',
        hint: 'Select visit reason',
        defaultValue: 'Tourism & Sightseeing',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Tourism & Sightseeing',
          'Family & Friends Visit',
          'Business Meeting & Conference',
          'Medical Treatment / Consultation',
          'Short Study / Cultural Exchange',
        ],
      ),
      RequirementField(
        id: 'duration_stay',
        label: 'Intended Duration of Stay',
        hint: 'Select duration',
        defaultValue: '30 Days (Single Entry)',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          '14 Days (Single Entry)',
          '30 Days (Single Entry)',
          '60 Days (Single / Multiple)',
          '90 Days (Multiple Entry)',
          '180 Days (Long-term Visitor)',
        ],
      ),
      RequirementField(
        id: 'planned_travel_date',
        label: 'Expected Date of Travel',
        hint: 'DD / MM / YYYY',
        defaultValue: '20 / 11 / 2026',
        icon: Icons.calendar_month_rounded,
      ),
      RequirementField(
        id: 'accommodation_type',
        label: 'Planned Accommodation',
        hint: 'Select accommodation type',
        defaultValue: 'Hotel Booking (Confirmed / Reserved)',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Hotel Booking (Confirmed / Reserved)',
          'Host / Relative Residence (Invitation Letter)',
          'Serviced Apartment / Airbnb',
          'Company Provided Corporate Housing',
        ],
      ),
    ],
  );

  // --------------------------------------------------------------------------
  // 5. DEFAULT / GENERAL VISA CONFIGURATION
  // (Change fallback fields below)
  // --------------------------------------------------------------------------
  static const ApplicantFormConfig defaultVisaConfig = ApplicantFormConfig(
    sectionTitle: 'Application Requirements',
    sectionSubtitle: 'Essential details for preliminary assessment',
    sectionIcon: Icons.assignment_rounded,
    badgeText: 'Required',
    fields: [
      RequirementField(
        id: 'primary_objective',
        label: 'Primary Objective',
        hint: 'State your goal',
        defaultValue: 'Immigration & Relocation Advisory',
        icon: Icons.flag_rounded,
      ),
      RequirementField(
        id: 'preferred_timeline',
        label: 'Preferred Application Processing Route',
        hint: 'Select processing speed',
        defaultValue: 'Standard Processing',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'Standard Processing',
          'Fast-Track / Priority Processing',
          'Super Priority Express',
        ],
      ),
      RequirementField(
        id: 'travel_status',
        label: 'Previous International Travel History',
        hint: 'Select history status',
        defaultValue: 'Yes, Traveled to 2+ Countries',
        type: RequirementFieldType.dropdown,
        dropdownOptions: [
          'First Time International Applicant',
          'Yes, Traveled to 1-2 Countries',
          'Frequent International Traveler (5+ Countries)',
        ],
      ),
    ],
  );
}
