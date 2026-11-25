import 'package:flutter_sd_consultant/src/shared/helpers/reference_generator.dart';
import 'package:flutter_sd_consultant/src/data/models/applicant_form_config.dart';
import 'package:flutter_sd_consultant/src/data/models/detail_item_model.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';
import 'package:flutter_sd_consultant/src/services/supabase_database_service.dart';

/// Complete Applicant Information screen matching the uploaded design reference.
///
/// NOTE: As requested by the user:
/// - "Passport Information" section has been EXCLUDED.
/// - "Mandatory Documents" upload section has been EXCLUDED.
/// - Tailored and integrated for all visa categories (Study, Work, Business, Visit, etc.).
/// - Requirements can be manually customized in `lib/src/data/models/applicant_form_config.dart`.
class ApplicantDetailsScreen extends StatefulWidget {
  const ApplicantDetailsScreen({
    super.key,
    required this.item,
  });

  final DetailItemModel item;

  @override
  State<ApplicantDetailsScreen> createState() => _ApplicantDetailsScreenState();
}

class _ApplicantDetailsScreenState extends State<ApplicantDetailsScreen> {
  // Stepper state (1: Details, 2: Payment, 3: Confirm)
  int _currentStep = 1;
  bool _isSubmitting = false;

  // Personal Information Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  String _selectedGender = 'Male';
  String _selectedNationality = '🇵🇰 Pakistan';
  String _selectedMaritalStatus = 'Single';

  // Contact Information Controllers
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;

  // Additional Notes
  late final TextEditingController _notesController;
  int _notesCharCount = 0;

  // Dynamic Requirement Form Values
  late final ApplicantFormConfig _config;
  final Map<String, TextEditingController> _dynamicFieldControllers = {};
  final Map<String, String> _dynamicDropdownValues = {};


  // Specialized Travel Background State for Visit Visa
  String _visitPurpose = 'Tourism, Leisure & Sightseeing';
  String _visitDuration = '30 Days (Single Entry)';
  late final TextEditingController _visitTravelDateController;
  late final TextEditingController _visitVisaAgeController;
  String _visitVisaAgeBracket = '18 - 35 Years (Prime Adult Tourist)';
  bool _hasVisitPreviousWork = true;
  late final TextEditingController _visitPreviousWorkController;
  bool _hasVisitTransactionHistory = true;
  late final TextEditingController _visitTransactionHistoryController;
  bool _hasVisitVisaRejection = false;
  late final TextEditingController _visitVisaRejectionController;

  // Specialized Golden Visa State
  late final TextEditingController _goldenAgeController;
  late final TextEditingController _goldenBusinessInfoController;
  late final TextEditingController _goldenYearlyIncomeController;
  bool _isGoldenFbrPayer = true;

  // Specialized Business Visa State
  late final TextEditingController _businessAgeController;
  bool _hasBusiness = true;
  late final TextEditingController _businessDetailsController;
  bool _isFbrRegistered = true;
  bool _hasNtnNumber = true;
  late final TextEditingController _businessNtnController;
  bool _hasInvitationLetter = true;
  bool _isChamberMember = true;

  // Specialized Study Visa State (when no admission secured)
  late final TextEditingController _studyAgeController;
  late final TextEditingController _studyCountryController;
  late final TextEditingController _studyProgramExplainController;
  late final TextEditingController _studyLastDegreeController;
  late final TextEditingController _studyMarksController;
  late final TextEditingController _studyLastUniController;

  // Specialized Work Visa State (when browsing work visas)
  late final TextEditingController _workAgeController;
  late final TextEditingController _workCountryController;
  late final TextEditingController _workProgramExplainController;
  late final TextEditingController _workLastDegreeController;
  late final TextEditingController _workMarksController;
  late final TextEditingController _workLastUniController;

  // Payment Selection (Step 2)
  String _selectedPaymentMethod = 'card';

  bool get _isGoldenVisa {
    final cat = '${widget.item.categoryTag} ${widget.item.title}'.toLowerCase();
    return cat.contains('golden');
  }

  bool get _isScholarship {
    final type = widget.item.type.toLowerCase();
    final cat = '${widget.item.categoryTag} ${widget.item.title}'.toLowerCase();
    return type == 'scholarship' ||
        cat.contains('scholarship') ||
        cat.contains('fellowship') ||
        cat.contains('grant');
  }

  bool get _isSponsoredJob {
    final type = widget.item.type.toLowerCase();
    final cat = '${widget.item.categoryTag} ${widget.item.title}'.toLowerCase();
    return type == 'job' ||
        widget.item.categoryTag.toLowerCase().contains('job') ||
        cat.contains('sponsored job') ||
        cat.contains('job');
  }

  bool get _isScholarshipOrJob => _isScholarship || _isSponsoredJob;

  bool get _isStudyVisa {
    if (_isScholarshipOrJob) return false;
    final cat = '${widget.item.categoryTag} ${widget.item.title}'.toLowerCase();
    return cat.contains('study') ||
        cat.contains('tier 4') ||
        cat.contains('student') ||
        cat.contains('academic') ||
        cat.contains('degree');
  }

  bool get _isWorkVisa {
    if (_isScholarshipOrJob ||
        _isStudyVisa ||
        _isGoldenVisa ||
        _isBusinessVisa ||
        _isVisitVisa) {
      return false;
    }
    final cat = '${widget.item.categoryTag} ${widget.item.title}'.toLowerCase();
    return widget.item.categoryTag.toLowerCase() == 'work visa' ||
        cat.contains('work visa') ||
        cat.contains('work permit') ||
        cat.contains('skilled worker') ||
        cat.contains('lmia') ||
        cat.contains('chancenkarte');
  }

  bool get _isVisitVisa {
    final cat = '${widget.item.categoryTag} ${widget.item.title}'.toLowerCase();
    return cat.contains('visit') ||
        cat.contains('tourist') ||
        cat.contains('holiday') ||
        cat.contains('visitor');
  }

  bool get _isBusinessVisa {
    final cat = '${widget.item.categoryTag} ${widget.item.title}'.toLowerCase();
    if (_isGoldenVisa) return false;
    return cat.contains('business') ||
        cat.contains('investor') ||
        cat.contains('invest') ||
        cat.contains('entrepreneur') ||
        cat.contains('trade') ||
        cat.contains('commercial');
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    final currentUser = SupabaseDatabaseService.instance.client.auth.currentUser;
    final prefilledName = currentUser?.userMetadata?['full_name'] as String? ?? '';
    final prefilledEmail = currentUser?.email ?? '';
    final prefilledPhone = currentUser?.phone ?? '';

    _nameController = TextEditingController(text: prefilledName);
    _dobController = TextEditingController();

    _phoneController = TextEditingController(text: prefilledPhone);
    _emailController = TextEditingController(text: prefilledEmail);
    _addressController = TextEditingController();
    _cityController = TextEditingController();

    _notesController = TextEditingController();


    // Initialize specialized visit visa controllers
    _visitTravelDateController = TextEditingController();
    _visitVisaAgeController = TextEditingController();
    _visitPreviousWorkController = TextEditingController();
    _visitTransactionHistoryController = TextEditingController();
    _visitVisaRejectionController = TextEditingController();

    // Initialize specialized golden visa controllers
    _goldenAgeController = TextEditingController();
    _goldenBusinessInfoController = TextEditingController();
    _goldenYearlyIncomeController = TextEditingController();

    // Initialize specialized business visa controllers
    _businessAgeController = TextEditingController();
    _businessDetailsController = TextEditingController();
    _businessNtnController = TextEditingController();

    // Initialize specialized study visa controllers
    _studyAgeController = TextEditingController();
    _studyCountryController = TextEditingController(
      text: widget.item.countryName.isNotEmpty &&
              widget.item.countryName != 'International'
          ? widget.item.countryName
          : '',
    );
    _studyProgramExplainController = TextEditingController();
    _studyLastDegreeController = TextEditingController();
    _studyMarksController = TextEditingController();
    _studyLastUniController = TextEditingController();

    // Initialize specialized work visa controllers
    _workAgeController = TextEditingController();
    _workCountryController = TextEditingController(
      text: widget.item.countryName.isNotEmpty &&
              widget.item.countryName != 'International'
          ? widget.item.countryName
          : '',
    );
    _workProgramExplainController = TextEditingController();
    _workLastDegreeController = TextEditingController();
    _workMarksController = TextEditingController();
    _workLastUniController = TextEditingController();

    // Load dynamic requirement configuration from live visa requirements if available
    _config = ApplicantFormConfig.fromApplicationRequirements(
      widget.item.applicationRequirements,
      widget.item.categoryTag,
      visaTitle: widget.item.title,
    );

    // Initialize dynamic requirement inputs
    for (final field in _config.fields) {
      if (field.type == RequirementFieldType.dropdown) {
        _dynamicDropdownValues[field.id] = field.defaultValue;
      } else {
        _dynamicFieldControllers[field.id] =
            TextEditingController(text: field.defaultValue);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _visitTravelDateController.dispose();
    _visitVisaAgeController.dispose();
    _visitPreviousWorkController.dispose();
    _visitTransactionHistoryController.dispose();
    _visitVisaRejectionController.dispose();
    _goldenAgeController.dispose();
    _goldenBusinessInfoController.dispose();
    _goldenYearlyIncomeController.dispose();
    _businessAgeController.dispose();
    _businessDetailsController.dispose();
    _businessNtnController.dispose();
    _studyAgeController.dispose();
    _studyCountryController.dispose();
    _studyProgramExplainController.dispose();
    _studyLastDegreeController.dispose();
    _studyMarksController.dispose();
    _studyLastUniController.dispose();
    _workAgeController.dispose();
    _workCountryController.dispose();
    _workProgramExplainController.dispose();
    _workLastDegreeController.dispose();
    _workMarksController.dispose();
    _workLastUniController.dispose();
    for (final c in _dynamicFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _resolvedServiceFee {
    final cat = widget.item.categoryTag.toLowerCase();
    final title = widget.item.title.toLowerCase();
    final type = widget.item.type.toLowerCase();

    // 1. Sponsored Jobs fee is PKR 15,000
    if (cat.contains('job') ||
        title.contains('job') ||
        type.contains('job') ||
        title.contains('employer') ||
        title.contains('license')) {
      return 'PKR 15,000';
    }

    // 2. Scholarships fee is PKR 25,000
    if (cat.contains('scholarship') ||
        title.contains('scholarship') ||
        type.contains('scholarship')) {
      return 'PKR 25,000';
    }

    // 3. Work Visa & Golden Visa fee is PKR 40,000
    if (cat.contains('work') ||
        title.contains('work') ||
        cat.contains('golden') ||
        title.contains('golden')) {
      return 'PKR 40,000';
    }

    // 4. Visit, Business, and Study Visa fee is PKR 30,000
    if (cat.contains('visit') ||
        title.contains('visit') ||
        cat.contains('tourist') ||
        title.contains('tourist') ||
        cat.contains('business') ||
        title.contains('business') ||
        cat.contains('investor') ||
        title.contains('investor') ||
        cat.contains('study') ||
        title.contains('study') ||
        cat.contains('student') ||
        title.contains('student')) {
      return 'PKR 30,000';
    }

    final raw = widget.item.serviceFeeValue;
    if (raw.isNotEmpty &&
        !raw.toLowerCase().contains('tuition') &&
        raw.length <= 15) {
      return raw;
    }
    return 'PKR 30,000';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF7F9FF),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: _currentStep == 1
                  ? _buildStep1Details()
                  : _currentStep == 2
                      ? _buildStep2Payment()
                      : _buildStep3Confirmation(),
            ),
          ),
          _buildBottomStickyBar(context),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. TOP APP BAR
  // ===========================================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    return AppBar(
      backgroundColor: _isDark ? const Color(0xFF121212) : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 54.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 12.w),
        child: Center(
          child: InkWell(
            onTap: () {
              if (_currentStep > 1) {
                setState(() => _currentStep--);
              } else {
                Navigator.of(context).maybePop();
              }
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8),
                shape: BoxShape.circle,
                border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: titleColor,
                size: 19,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'Applicant Details',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: titleColor,
          letterSpacing: -0.2,
        ),
      ),
      centerTitle: true,
    );
  }

  // ===========================================================================
  // STEP 1 VALIDATION (Required / Mandatory fields check)
  // ===========================================================================
  bool _validateStep1() {
    // 1. Common Name check
    if (_nameController.text.trim().isEmpty) {
      showGlobalToast(
        message: 'Please enter your Full Legal Name as per Passport',
        status: 'warning',
      );
      return false;
    }

    // 2. Visa Category specific validation
    if (_isGoldenVisa) {
      if (_goldenAgeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Age',
          status: 'warning',
        );
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Official Contact Number',
          status: 'warning',
        );
        return false;
      }
      if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
        showGlobalToast(
          message: 'Please enter a valid Registered Email Address',
          status: 'warning',
        );
        return false;
      }
      if (_goldenBusinessInfoController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Business Information & Enterprise Profile',
          status: 'warning',
        );
        return false;
      }
      if (_goldenYearlyIncomeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Yearly Income in numbers',
          status: 'warning',
        );
        return false;
      }
      return true;
    }

    if (_isBusinessVisa) {
      if (_businessAgeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Applicant Age',
          status: 'warning',
        );
        return false;
      }
      if (_cityController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your City of Residence',
          status: 'warning',
        );
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Official Contact Number',
          status: 'warning',
        );
        return false;
      }
      if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
        showGlobalToast(
          message: 'Please enter a valid Corporate / Registered Email',
          status: 'warning',
        );
        return false;
      }
      if (_hasBusiness && _businessDetailsController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Business & Company Details',
          status: 'warning',
        );
        return false;
      }
      if (_hasNtnNumber && _businessNtnController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your 7-Digit NTN Number',
          status: 'warning',
        );
        return false;
      }
      return true;
    }

    if (_isStudyVisa) {
      if (_studyAgeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Age',
          status: 'warning',
        );
        return false;
      }
      if (_cityController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Current City',
          status: 'warning',
        );
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Contact Number',
          status: 'warning',
        );
        return false;
      }
      if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
        showGlobalToast(
          message: 'Please enter a valid Registered Email',
          status: 'warning',
        );
        return false;
      }
      if (_studyCountryController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Target Study Country',
          status: 'warning',
        );
        return false;
      }
      if (_studyProgramExplainController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please specify your Intended Program or educational goals',
          status: 'warning',
        );
        return false;
      }
      if (_studyLastDegreeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Last Completed Degree',
          status: 'warning',
        );
        return false;
      }
      if (_studyMarksController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Marks / CGPA Obtained',
          status: 'warning',
        );
        return false;
      }
      if (_studyLastUniController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter the University Name of your last degree',
          status: 'warning',
        );
        return false;
      }
      return true;
    }

    if (_isWorkVisa) {
      if (_workAgeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Age',
          status: 'warning',
        );
        return false;
      }
      if (_cityController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Current City',
          status: 'warning',
        );
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Contact Number',
          status: 'warning',
        );
        return false;
      }
      if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
        showGlobalToast(
          message: 'Please enter a valid Registered Email',
          status: 'warning',
        );
        return false;
      }
      if (_workCountryController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Target Work Destination Country',
          status: 'warning',
        );
        return false;
      }
      if (_workProgramExplainController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please specify your Target Job Role / Profession',
          status: 'warning',
        );
        return false;
      }
      if (_workLastDegreeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Last Completed Degree / Qualification',
          status: 'warning',
        );
        return false;
      }
      if (_workMarksController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Marks / Grade / Experience',
          status: 'warning',
        );
        return false;
      }
      if (_workLastUniController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your University / Institute Name',
          status: 'warning',
        );
        return false;
      }
      return true;
    }

    // Pre-lock Info / Scholarships & Sponsored Jobs: ONLY Personal & Contact Info
    if (_isScholarshipOrJob) {
      if (_nameController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Full Legal Name',
          status: 'warning',
        );
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Contact Phone number',
          status: 'warning',
        );
        return false;
      }
      if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
        showGlobalToast(
          message: 'Please enter a valid Registered Email',
          status: 'warning',
        );
        return false;
      }
      if (_cityController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your City of Residence',
          status: 'warning',
        );
        return false;
      }
      return true;
    }

    // Default / Visit Visa
    if (_dobController.text.trim().isEmpty) {
      showGlobalToast(
        message: 'Please select your Date of Birth',
        status: 'warning',
      );
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      showGlobalToast(
        message: 'Please enter your Mobile Telephone number',
        status: 'warning',
      );
      return false;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      showGlobalToast(
        message: 'Please enter a valid Registered Email',
        status: 'warning',
      );
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      showGlobalToast(
        message: 'Please enter your Current Residential Address',
        status: 'warning',
      );
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      showGlobalToast(
        message: 'Please enter your City & Region',
        status: 'warning',
      );
      return false;
    }

    if (_isVisitVisa) {
      if (_visitTravelDateController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please select your Intended Travel Date',
          status: 'warning',
        );
        return false;
      }
      if (_visitVisaAgeController.text.trim().isEmpty) {
        showGlobalToast(
          message: 'Please enter your Applicant Age',
          status: 'warning',
        );
        return false;
      }
    }

    return true;
  }

  // ===========================================================================
  // STEP 1 CONTENT: APPLICANT DETAILS FORM
  // ===========================================================================
  Widget _buildStep1Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Card with Step Indicator and Category Icon
        _buildHeroHeader(),
        SizedBox(height: 12.h),

        // 2. 3-Step Milestone Progress Bar
        _buildMilestoneStepper(),
        SizedBox(height: 14.h),

        // 3. Pre-filled Verified Registry Banner
        _buildVerifiedBanner(),
        SizedBox(height: 16.h),

        if (_isGoldenVisa) ...[
          // Prominent Golden Visa Applicant Profile Card (Name, Age, Contact, Business Information, Yearly Income in Numbers, FBR Payer or No)
          _buildGoldenVisaApplicantCard(),
          SizedBox(height: 16.h),
        ] else if (_isBusinessVisa) ...[
          // Tailored Business Visa Applicant Info Card (Name, Age, Contact, City)
          _buildBusinessApplicantInfoCard(),
          SizedBox(height: 16.h),

          // Prominent Business Credentials & Verification Card
          _buildBusinessCredentialsCard(),
          SizedBox(height: 16.h),
        ] else if (_isStudyVisa) ...[
          // Prominent Study Visa Applicant Profile Card (Name, Age, Country, Contact, City, Program or Explain, Last Degree, Marks, Uni Name of Last Degree)
          _buildStudyVisaApplicantCard(),
          SizedBox(height: 16.h),
        ] else if (_isWorkVisa) ...[
          // Prominent Work Visa Applicant Profile Card (Name, Age, Country, Contact, City, Job Role or Explain, Last Degree, Marks, Uni Name of Last Degree)
          _buildWorkVisaApplicantCard(),
          SizedBox(height: 16.h),
        ] else if (_isScholarshipOrJob) ...[
          // Scholarships and Sponsored Jobs: ONLY Personal & Contact Information!
          _buildPersonalInformationCard(),
          SizedBox(height: 16.h),

          _buildContactInformationCard(),
          SizedBox(height: 16.h),
        ] else ...[
          // 4. Section 1: Personal Information Card
          _buildPersonalInformationCard(),
          SizedBox(height: 16.h),

          // 5. Section 2: Contact Information Card
          _buildContactInformationCard(),
          SizedBox(height: 16.h),

          // Travel Background Section for Visit Visa OR Dynamic Requirements Card for other categories
          if (_isVisitVisa) ...[
            _buildTravelBackgroundCard(),
            SizedBox(height: 16.h),
          ] else ...[
            _buildDynamicRequirementsCard(),
            SizedBox(height: 16.h),
          ],
        ],

        // 7. Section 4: Additional Notes (Optional)
        if (!_isScholarshipOrJob) ...[
          _buildAdditionalNotesCard(),
          SizedBox(height: 24.h),
        ],
      ],
    );
  }

  // ===========================================================================
  // HERO HEADER CARD
  // ===========================================================================
  Widget _buildHeroHeader() {
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final subtextColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF4FA),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    _isScholarshipOrJob
                        ? (_currentStep == 1 ? 'STEP 1 OF 2' : 'STEP 2 OF 2')
                        : 'STEP $_currentStep OF 3',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                      color: _isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1B3A5C),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Your Information',
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  widget.item.title,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: subtextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8),
              shape: BoxShape.circle,
              border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF)),
            ),
            child: Icon(
              _config.sectionIcon,
              color: _isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444),
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3-STEP / 2-STEP MILESTONE STEPPER
  // ===========================================================================
  Widget _buildMilestoneStepper() {
    if (_isScholarshipOrJob) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF121212) : const Color(0xFF002244),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _isDark ? const Color(0xFF27272A) : const Color(0xFF003366),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildStepperNode(
                  stepNumber: 1,
                  isCompleted: _currentStep > 1,
                  isActive: _currentStep == 1,
                ),
                Expanded(
                  child: Container(
                    height: 2.h,
                    color: _currentStep >= 3
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                _buildStepperNode(
                  stepNumber: 2,
                  isCompleted: _currentStep == 3,
                  isActive: _currentStep == 3,
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Details',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: _currentStep == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: _currentStep == 1 ? Colors.white : const Color(0xFF90A8C0),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Confirmation',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: _currentStep == 3 ? FontWeight.w700 : FontWeight.w500,
                      color: _currentStep == 3 ? Colors.white : const Color(0xFF6F8FA8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF121212) : const Color(0xFF002244),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isDark ? const Color(0xFF27272A) : const Color(0xFF003366),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stepper Nodes and Connecting Lines Row
          Row(
            children: [
              _buildStepperNode(
                stepNumber: 1,
                isCompleted: _currentStep > 1,
                isActive: _currentStep == 1,
              ),
              Expanded(
                child: Container(
                  height: 2.h,
                  color: _currentStep >= 2
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.22),
                ),
              ),
              _buildStepperNode(
                stepNumber: 2,
                isCompleted: _currentStep > 2,
                isActive: _currentStep == 2,
              ),
              Expanded(
                child: Container(
                  height: 2.h,
                  color: _currentStep >= 3
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.22),
                ),
              ),
              _buildStepperNode(
                stepNumber: 3,
                isCompleted: _currentStep > 3,
                isActive: _currentStep == 3,
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Step Labels Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Details',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: _currentStep == 1 ? FontWeight.w700 : FontWeight.w500,
                    color: _currentStep == 1 ? Colors.white : const Color(0xFF90A8C0),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Payment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: _currentStep == 2 ? FontWeight.w700 : FontWeight.w500,
                    color: _currentStep == 2 ? Colors.white : const Color(0xFF90A8C0),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Confirmation',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: _currentStep == 3 ? FontWeight.w700 : FontWeight.w500,
                    color: _currentStep == 3 ? Colors.white : const Color(0xFF6F8FA8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperNode({
    required int stepNumber,
    required bool isCompleted,
    required bool isActive,
  }) {
    final Widget content;
    final Color nodeColor;
    Color? borderColor;

    if (isCompleted) {
      nodeColor = Colors.white;
      content = const Icon(
        Icons.check_rounded,
        color: Color(0xFF002244),
        size: 16,
      );
    } else if (isActive) {
      nodeColor = Colors.white;
      content = Text(
        '$stepNumber',
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF002244),
        ),
      );
    } else {
      nodeColor = const Color(0xFF0A2E52);
      borderColor = Colors.white.withValues(alpha: 0.25);
      content = Text(
        '$stepNumber',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8FAEC9),
        ),
      );
    }

    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: nodeColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
        boxShadow: isActive || isCompleted
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Center(child: content),
    );
  }

  // ===========================================================================
  // PRE-FILLED VERIFIED BANNER
  // ===========================================================================
  Widget _buildVerifiedBanner() {
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final subtextColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF121212) : const Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFDEE7F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF1E3A8A) : const Color(0xFF1B3A5C).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1B3A5C),
              size: 16.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pre-filled from applicant profile',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Please review your details carefully. You may update any field before proceeding.',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: subtextColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: PERSONAL INFORMATION CARD
  // ===========================================================================
  Widget _buildPersonalInformationCard() {
    return _buildCardWrapper(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      badgeText: 'Primary',
      children: [
        // Full Legal Name
        _buildInputLabel('Full Legal Name (as per Passport / ID)', isRequired: true),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _nameController,
          suffixIcon: Icons.edit_outlined,
        ),
        SizedBox(height: 14.h),

        if (!_isScholarshipOrJob) ...[
          // Date of Birth
          _buildInputLabel('Date of Birth', isRequired: true),
          SizedBox(height: 6.h),
          _buildTextField(
            controller: _dobController,
            suffixIcon: Icons.calendar_today_rounded,
            readOnly: true,
            onTap: () => _pickDate(context, _dobController),
          ),
          SizedBox(height: 6.h),

          // Calculated Age Pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 13.sp,
                  color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
                ),
                SizedBox(width: 5.w),
                Text(
                  _dobController.text.isNotEmpty
                      ? 'Selected DOB: ${_dobController.text}'
                      : 'Please select Date of Birth',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF43474E),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
        ],

        // Gender & Nationality Row
        Row(
          children: [
            if (!_isScholarshipOrJob) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('Gender', isRequired: true),
                    SizedBox(height: 6.h),
                    _buildDropdownButton(
                      value: _selectedGender,
                      items: const ['Male', 'Female', 'Other'],
                      onChanged: (val) => setState(() => _selectedGender = val!),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Nationality', isRequired: true),
                  SizedBox(height: 6.h),
                  _buildDropdownButton(
                    value: _selectedNationality,
                    items: const [
                      '🇵🇰 Pakistan',
                      '🇦🇪 UAE',
                      '🇬🇧 UK',
                      '🇨🇦 Canada',
                      '🇺🇸 USA',
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedNationality = val!),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (!_isScholarshipOrJob) ...[
          SizedBox(height: 14.h),

          // Marital Status
          _buildInputLabel('Marital Status', isRequired: true),
          SizedBox(height: 6.h),
          _buildDropdownButton(
            value: _selectedMaritalStatus,
            items: const ['Single', 'Married', 'Divorced', 'Widowed'],
            onChanged: (val) => setState(() => _selectedMaritalStatus = val!),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // SECTION 2: CONTACT INFORMATION CARD
  // ===========================================================================
  Widget _buildContactInformationCard() {
    return _buildCardWrapper(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        // Mobile Telephone
        _buildInputLabel('Mobile Telephone', isRequired: true),
        SizedBox(height: 6.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Text('🇵🇰', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      '+92',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                    hintText: '300 1234567',
                    suffixIcon: const Icon(
                      Icons.phone_android_rounded,
                      size: 18,
                      color: Color(0xFF5B7FA5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Registered Email with Verified Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputLabel('Registered Email', isRequired: true),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 11,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _emailController,
          suffixIcon: Icons.lock_outline_rounded,
        ),
        SizedBox(height: 14.h),

        if (!_isScholarshipOrJob) ...[
          // Residential Address
          _buildInputLabel('Current Residential Address', isRequired: true),
          SizedBox(height: 6.h),
          _buildTextField(
            controller: _addressController,
            suffixIcon: Icons.home_outlined,
          ),
          SizedBox(height: 14.h),
        ],

        // City & Region
        _buildInputLabel('City & Region', isRequired: true),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _cityController,
          suffixIcon: Icons.location_city_rounded,
        ),
      ],
    );
  }

  // ===========================================================================
  // SPECIALIZED SECTION: TRAVEL BACKGROUND FOR VISIT VISA
  // ===========================================================================
  Widget _buildTravelBackgroundCard() {
    final bool isCleanAndStrong = !_hasVisitVisaRejection &&
        _hasVisitTransactionHistory &&
        _hasVisitPreviousWork;

    return _buildCardWrapper(
      title: 'Travel Background',
      icon: Icons.flight_takeoff_rounded,
      badgeText: 'Traveler Profile',
      children: [
        // Subtitle note
        Text(
          'Embassy evaluation parameters for tourist itinerary, travel readiness, employment ties, financial records, and immigration history.',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.35,
          ),
        ),
        SizedBox(height: 14.h),

        // 1. Travel Details: Primary Purpose & Planned Stay Duration
        _buildInputLabel('Primary Purpose of Visit', isRequired: true),
        SizedBox(height: 6.h),
        _buildDropdownButton(
          value: _visitPurpose,
          items: const [
            'Tourism, Leisure & Sightseeing',
            'Family / Friend Visit',
            'Business Conference & Meeting',
            'Medical Treatment / Wellness',
            'Short Educational / Cultural Tour',
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _visitPurpose = val);
            }
          },
        ),
        SizedBox(height: 12.h),

        _buildInputLabel('Planned Stay Duration', isRequired: true),
        SizedBox(height: 6.h),
        _buildDropdownButton(
          value: _visitDuration,
          items: const [
            '15 Days (Single Entry)',
            '30 Days (Single Entry)',
            '60 Days (Double Entry)',
            '90 Days (Multiple Entry)',
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _visitDuration = val);
            }
          },
        ),
        SizedBox(height: 12.h),

        // 2. Intended Travel Date & Applicant Age Row
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Intended Travel Date', isRequired: true),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _visitTravelDateController,
                    suffixIcon: Icons.calendar_month_rounded,
                    readOnly: true,
                    onTap: () =>
                        _pickTravelDate(context, _visitTravelDateController),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Applicant Age', isRequired: true),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _visitVisaAgeController,
                    suffixIcon: Icons.cake_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Traveler Age Category dropdown
        _buildInputLabel('Traveler Age Category', isRequired: true),
        SizedBox(height: 6.h),
        _buildDropdownButton(
          value: _visitVisaAgeBracket,
          items: const [
            '18 - 35 Years (Prime Adult Tourist)',
            '36 - 55 Years (Established Traveler)',
            '55+ Years (Senior Citizen / Super Visa)',
            'Under 18 Years (Minor with Guardian)',
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _visitVisaAgeBracket = val);
            }
          },
        ),
        SizedBox(height: 8.h),

        // Age Verified Banner
        DecoratedBox(
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: _isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 15.sp,
                  color: _isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '✓ Age Verified: Fully eligible for independent visitor visa application.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: _isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // 3. Previous Work / Employment History
        _buildInputLabel('Previous Work / Employment History'),
        SizedBox(height: 2.h),
        Text(
          'Do you have any previous or current employment, business, or freelance work experience?',
          style: TextStyle(
            fontSize: 11.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.3,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Have Work History',
                icon: Icons.work_rounded,
                isSelected: _hasVisitPreviousWork,
                onTap: () => setState(() => _hasVisitPreviousWork = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No Work History',
                icon: Icons.person_outline_rounded,
                isSelected: !_hasVisitPreviousWork,
                onTap: () => setState(() => _hasVisitPreviousWork = false),
              ),
            ),
          ],
        ),
        if (_hasVisitPreviousWork) ...[
          SizedBox(height: 10.h),
          _buildInputLabel('Share Previous Work Details'),
          SizedBox(height: 6.h),
          _buildVisitTextArea(
            controller: _visitPreviousWorkController,
            hint:
                'Employer/Company name, job title, years of experience, and monthly income...',
          ),
        ] else ...[
          SizedBox(height: 8.h),
          _buildVisitCleanPill(
            '✓ Applying without formal employment — supported as student, homemaker, or self-funded visitor.',
            const Color(0xFFEFF4FA),
            const Color(0xFF1B3A5C),
          ),
        ],
        SizedBox(height: 16.h),

        // 4. Bank Statement & Transaction History
        _buildInputLabel('Bank Statement & Transaction History'),
        SizedBox(height: 2.h),
        Text(
          'Do you have an active bank account with at least 6 months of regular transaction records?',
          style: TextStyle(
            fontSize: 11.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.3,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Active Bank Account',
                icon: Icons.account_balance_rounded,
                isSelected: _hasVisitTransactionHistory,
                onTap: () => setState(() => _hasVisitTransactionHistory = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No Transaction History',
                icon: Icons.receipt_long_rounded,
                isSelected: !_hasVisitTransactionHistory,
                onTap: () =>
                    setState(() => _hasVisitTransactionHistory = false),
              ),
            ),
          ],
        ),
        if (_hasVisitTransactionHistory) ...[
          SizedBox(height: 10.h),
          _buildInputLabel('Share Bank Statement & Financial Details'),
          SizedBox(height: 6.h),
          _buildVisitTextArea(
            controller: _visitTransactionHistoryController,
            hint:
                'Bank name, 6-month average closing balance (PKR/USD), and regular credit sources...',
          ),
        ] else ...[
          SizedBox(height: 8.h),
          _buildVisitCleanPill(
            'Notice: A 3rd-party sponsor financial guarantee & affidavit of support will be attached.',
            const Color(0xFFFFF8E1),
            const Color(0xFFB76E00),
          ),
        ],
        SizedBox(height: 16.h),

        // 5. Visa Rejection / Refusal History
        _buildInputLabel('Previous Visa Rejection / Refusal History'),
        SizedBox(height: 2.h),
        Text(
          'Have you ever had a visa refused, rejected, or revoked by any immigration authority?',
          style: TextStyle(
            fontSize: 11.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.3,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No, Clean Record',
                icon: Icons.verified_user_rounded,
                isSelected: !_hasVisitVisaRejection,
                onTap: () => setState(() => _hasVisitVisaRejection = false),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Prior Refusal',
                icon: Icons.warning_amber_rounded,
                isSelected: _hasVisitVisaRejection,
                onTap: () => setState(() => _hasVisitVisaRejection = true),
              ),
            ),
          ],
        ),
        if (_hasVisitVisaRejection) ...[
          SizedBox(height: 10.h),
          _buildInputLabel('Share Visa Rejection Details'),
          SizedBox(height: 6.h),
          _buildVisitTextArea(
            controller: _visitVisaRejectionController,
            hint:
                'Country of refusal, year, visa category, and refusal grounds stated on official letter...',
            isAlert: true,
          ),
        ] else ...[
          SizedBox(height: 8.h),
          _buildVisitCleanPill(
            '✓ Clean immigration history — 0 previous visa refusals across all jurisdictions.',
            const Color(0xFFF0FDF4),
            const Color(0xFF15803D),
          ),
        ],
        SizedBox(height: 16.h),

        // 6. Live Visit Visa Readiness Status Banner
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF002444),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCleanAndStrong
                        ? Icons.verified_rounded
                        : Icons.assignment_turned_in_rounded,
                    color: isCleanAndStrong
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF59E0B),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCleanAndStrong
                            ? '★ Verified Tourist Application Profile'
                            : '★ Application Profile with Dedicated Advisory',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isCleanAndStrong
                            ? 'Your background details fulfill standard consular tourist clearance prerequisites.'
                            : 'Our senior visa lawyers will structure customized legal submissions for your case.',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: const Color(0xFFC3D5E8),
                          height: 1.3,
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

  Widget _buildVisitOptionBtn({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? (_isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444)) : (_isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFD)),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color:
                isSelected ? (_isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444)) : (_isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF)),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14.sp,
              color: isSelected ? Colors.white : (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A)),
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : (_isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTextArea({
    required TextEditingController controller,
    required String hint,
    bool isAlert = false,
  }) {
    final textColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isAlert
            ? (_isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFFF9F9))
            : (_isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE)),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFFCA5A5)
              : (_isDark ? const Color(0xFF27272A) : const Color(0xFF002444).withValues(alpha: 0.22)),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        minLines: 2,
        style: TextStyle(
          fontSize: 12.5.sp,
          color: textColor,
          height: 1.35,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(10.w),
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 11.5.sp,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitCleanPill(String text, Color bgColor, Color textColor) {
    final effectiveBg = _isDark ? const Color(0xFF18181B) : bgColor;
    final effectiveText = _isDark ? const Color(0xFF93C5FD) : textColor;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _isDark ? const Color(0xFF2E4057) : textColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: effectiveText,
          height: 1.3,
        ),
      ),
    );
  }

  // ===========================================================================
  // SPECIALIZED SECTION: GOLDEN VISA APPLICANT & INVESTMENT PROFILE
  // ===========================================================================
  Widget _buildGoldenVisaApplicantCard() {
    return _buildCardWrapper(
      title: 'Golden Visa Applicant Details',
      icon: Icons.workspace_premium_rounded,
      badgeText: 'Golden Residency',
      children: [
        // Subtitle note
        Text(
          'Official long-term residency qualification parameters for high-net-worth commercial investors and business owners.',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.35,
          ),
        ),
        SizedBox(height: 16.h),

        // 1. Full Legal Name
        _buildInputLabel('Full Legal Name (as per Passport)', isRequired: true),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _nameController,
          suffixIcon: Icons.edit_outlined,
        ),
        SizedBox(height: 14.h),

        // 2. Applicant Age & Contact Number Row
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Applicant Age (Years)', isRequired: true),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _goldenAgeController,
                    suffixIcon: Icons.cake_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Official Contact Number', isRequired: true),
                  SizedBox(height: 6.h),
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text('🇵🇰', style: TextStyle(fontSize: 14.sp)),
                              SizedBox(width: 4.w),
                              Text(
                                '+92',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10.w),
                              hintText: '300 1234567',
                              suffixIcon: const Icon(
                                Icons.phone_android_rounded,
                                size: 18,
                                color: Color(0xFF5B7FA5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // 3. Registered Email Address with Verified Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputLabel('Registered Email Address', isRequired: true),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 11,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _emailController,
          suffixIcon: Icons.lock_outline_rounded,
        ),
        SizedBox(height: 16.h),

        // 4. Business Information
        _buildInputLabel('Business Information & Enterprise Profile', isRequired: true),
        SizedBox(height: 2.h),
        Text(
          'Provide details of your enterprise, industry, commercial activities, and executive designation.',
          style: TextStyle(
            fontSize: 11.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.3,
          ),
        ),
        SizedBox(height: 6.h),
        _buildVisitTextArea(
          controller: _goldenBusinessInfoController,
          hint:
              'Enterprise/Company name, sector (e.g. Real Estate, Tech, Manufacturing), years active, and your ownership/role...',
        ),
        SizedBox(height: 16.h),

        // 5. Yearly Income in Numbers
        _buildInputLabel('Yearly Income in Numbers (PKR / USD)', isRequired: true),
        SizedBox(height: 2.h),
        Text(
          'Specify your annual verifiable gross/net income in numeric figures.',
          style: TextStyle(
            fontSize: 11.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.3,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isDark ? const Color(0xFF27272A) : const Color(0xFF002444).withValues(alpha: 0.22),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  'PKR',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _isDark ? const Color(0xFF93C5FD) : const Color(0xFF002444),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _goldenYearlyIncomeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                    hintText: 'e.g. 75,000,000',
                    hintStyle: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                    suffixIcon: const Icon(
                      Icons.payments_rounded,
                      size: 20,
                      color: Color(0xFF1B3A5C),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        _buildVisitCleanPill(
          '✓ Financial Metric Verified: Meets minimum capital threshold for Golden Residency.',
          const Color(0xFFF0FDF4),
          const Color(0xFF15803D),
        ),
        SizedBox(height: 16.h),

        // 6. FBR Payer or No
        _buildInputLabel('FBR Taxpayer Status (Tax Filer / Non-Filer)'),
        SizedBox(height: 2.h),
        Text(
          'Are you an active registered tax payer with the Federal Board of Revenue?',
          style: TextStyle(
            fontSize: 11.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.3,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Active FBR Payer',
                icon: Icons.verified_rounded,
                isSelected: _isGoldenFbrPayer,
                onTap: () => setState(() => _isGoldenFbrPayer = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No, Not FBR Payer',
                icon: Icons.close_rounded,
                isSelected: !_isGoldenFbrPayer,
                onTap: () => setState(() => _isGoldenFbrPayer = false),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _buildVisitCleanPill(
          _isGoldenFbrPayer
              ? '✓ Active FBR Tax Payer: Listed on Active Taxpayers List (ATL) — Prime Golden Visa Tier.'
              : 'Notice: Non-filer status recorded — Wealth audit documentation supported by SD legal team.',
          _isGoldenFbrPayer ? const Color(0xFFF0FDF4) : const Color(0xFFFFF8E1),
          _isGoldenFbrPayer ? const Color(0xFF15803D) : const Color(0xFFB76E00),
        ),
        SizedBox(height: 18.h),

        // 7. Live Golden Visa Status Banner
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF002444),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isGoldenFbrPayer
                            ? '★ Verified Golden Residency Candidate'
                            : '★ Golden Residency Candidate (Advisory Track)',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _isGoldenFbrPayer
                            ? 'Annual income figures, enterprise profile, and tax standing satisfy premier residency prerequisites.'
                            : 'Our senior investment solicitors will prepare certified asset statements for host country clearance.',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: const Color(0xFFC3D5E8),
                          height: 1.3,
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

  // ===========================================================================
  // SPECIALIZED SECTION: BUSINESS VISA APPLICANT & CONTACT PROFILE
  // ===========================================================================
  Widget _buildBusinessApplicantInfoCard() {
    return _buildCardWrapper(
      title: 'Applicant & Contact Profile',
      icon: Icons.person_outline_rounded,
      badgeText: 'Business Applicant',
      children: [
        // Full Legal Name
        _buildInputLabel('Full Legal Name (as per Passport)', isRequired: true),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _nameController,
          suffixIcon: Icons.edit_outlined,
        ),
        SizedBox(height: 14.h),

        // Age & City Row
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Applicant Age', isRequired: true),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _businessAgeController,
                    suffixIcon: Icons.cake_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('City of Residence', isRequired: true),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _cityController,
                    suffixIcon: Icons.location_city_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // Official Contact Number
        _buildInputLabel('Official Contact Number', isRequired: true),
        SizedBox(height: 6.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFDEE5EF)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Text('🇵🇰', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      '+92',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF171C21),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF171C21),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                    hintText: '300 1234567',
                    suffixIcon: const Icon(
                      Icons.phone_android_rounded,
                      size: 18,
                      color: Color(0xFF5B7FA5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Corporate / Registered Email with Verified Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputLabel('Corporate / Registered Email', isRequired: true),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 11,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Verified',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _emailController,
          suffixIcon: Icons.lock_outline_rounded,
        ),
      ],
    );
  }

  // ===========================================================================
  // SPECIALIZED SECTION: BUSINESS CREDENTIALS & REGULATORY VERIFICATION
  // ===========================================================================
  Widget _buildBusinessCredentialsCard() {
    final bool isFullCommercialReady = _hasBusiness &&
        _isFbrRegistered &&
        _hasNtnNumber &&
        _hasInvitationLetter &&
        _isChamberMember;

    return _buildCardWrapper(
      title: 'Business Credentials & Verification',
      icon: Icons.business_center_rounded,
      badgeText: 'Commercial Profile',
      children: [
        // Subtitle note
        Text(
          'Official commercial verification for embassy business delegation, trade clearances, and corporate visa issuance.',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.35,
          ),
        ),
        SizedBox(height: 16.h),

        // Question 1: Any Business?
        _buildProminentQuestionHeader(
          number: '1',
          question: 'Do you currently own or operate any business?',
          subtitle:
              'Select "Yes" if you have an active proprietary enterprise, company, or partnership.',
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Active Business',
                icon: Icons.store_rounded,
                isSelected: _hasBusiness,
                onTap: () => setState(() => _hasBusiness = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No Business',
                icon: Icons.person_outline_rounded,
                isSelected: !_hasBusiness,
                onTap: () => setState(() => _hasBusiness = false),
              ),
            ),
          ],
        ),
        if (_hasBusiness) ...[
          SizedBox(height: 10.h),
          _buildInputLabel('Share Business & Company Details', isRequired: true),
          SizedBox(height: 6.h),
          _buildVisitTextArea(
            controller: _businessDetailsController,
            hint:
                'Registered enterprise name, nature of business (e.g. Textile Export, IT Solutions), years active, and your designation...',
          ),
        ] else ...[
          SizedBox(height: 8.h),
          _buildVisitCleanPill(
            '✓ Applying as prospective commercial investor or corporate representative.',
            const Color(0xFFEFF4FA),
            const Color(0xFF1B3A5C),
          ),
        ],
        SizedBox(height: 18.h),

        // Question 2: Register from FBR? (only yes or no)
        _buildProminentQuestionHeader(
          number: '2',
          question: 'Is your business registered with FBR?',
          subtitle:
              'Federal Board of Revenue official taxpayer registration status (Only Yes or No).',
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Registered with FBR',
                icon: Icons.verified_rounded,
                isSelected: _isFbrRegistered,
                onTap: () => setState(() => _isFbrRegistered = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No, Not Registered',
                icon: Icons.close_rounded,
                isSelected: !_isFbrRegistered,
                onTap: () => setState(() => _isFbrRegistered = false),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _buildVisitCleanPill(
          _isFbrRegistered
              ? '✓ FBR Registered: Entity listed on Active Taxpayers List (ATL).'
              : 'Notice: Unregistered enterprise status will be noted for consular tax review.',
          _isFbrRegistered ? const Color(0xFFF0FDF4) : const Color(0xFFFFF8E1),
          _isFbrRegistered ? const Color(0xFF15803D) : const Color(0xFFB76E00),
        ),
        SizedBox(height: 18.h),

        // Question 3: NTN Number? (if yes then write otherwise no)
        _buildProminentQuestionHeader(
          number: '3',
          question: 'Do you have an active NTN number?',
          subtitle:
              'National Tax Number issued by the tax authorities (If yes write below, otherwise No).',
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Have NTN',
                icon: Icons.tag_rounded,
                isSelected: _hasNtnNumber,
                onTap: () => setState(() => _hasNtnNumber = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No NTN',
                icon: Icons.remove_circle_outline_rounded,
                isSelected: !_hasNtnNumber,
                onTap: () => setState(() => _hasNtnNumber = false),
              ),
            ),
          ],
        ),
        if (_hasNtnNumber) ...[
          SizedBox(height: 10.h),
          _buildInputLabel('Write Your 7-Digit NTN Number', isRequired: true),
          SizedBox(height: 6.h),
          _buildTextField(
            controller: _businessNtnController,
            suffixIcon: Icons.badge_rounded,
          ),
          SizedBox(height: 6.h),
          _buildVisitCleanPill(
            '✓ Active Filer NTN Confirmed: Validated for commercial trade submissions.',
            const Color(0xFFF0FDF4),
            const Color(0xFF15803D),
          ),
        ] else ...[
          SizedBox(height: 8.h),
          _buildVisitCleanPill(
            'No NTN provided — Classified under individual non-filer tax record.',
            const Color(0xFFFFF8E1),
            const Color(0xFFB76E00),
          ),
        ],
        SizedBox(height: 18.h),

        // Question 4: Business Invitation Letter? (only yes or no)
        _buildProminentQuestionHeader(
          number: '4',
          question: 'Do you have a business invitation letter?',
          subtitle:
              'Official host invitation from foreign corporate partner or trade delegation (Only Yes or No).',
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Have Invitation',
                icon: Icons.mark_email_read_rounded,
                isSelected: _hasInvitationLetter,
                onTap: () => setState(() => _hasInvitationLetter = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No Invitation Letter',
                icon: Icons.drafts_outlined,
                isSelected: !_hasInvitationLetter,
                onTap: () => setState(() => _hasInvitationLetter = false),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _buildVisitCleanPill(
          _hasInvitationLetter
              ? '✓ Host Invitation Available: Priority consular business delegation route.'
              : 'Standard track: SD Consultant legal team will facilitate consular host sponsorship.',
          _hasInvitationLetter
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFEFF4FA),
          _hasInvitationLetter
              ? const Color(0xFF15803D)
              : const Color(0xFF1B3A5C),
        ),
        SizedBox(height: 18.h),

        // Question 5: Member of Chamber of Commerce? (only yes or no)
        _buildProminentQuestionHeader(
          number: '5',
          question: 'Are you a member of Chamber of Commerce?',
          subtitle:
              'Active registration with LCCI, KCCI, ICCI, or foreign trade council (Only Yes or No).',
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'Yes, Active Member',
                icon: Icons.card_membership_rounded,
                isSelected: _isChamberMember,
                onTap: () => setState(() => _isChamberMember = true),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVisitOptionBtn(
                label: 'No Membership',
                icon: Icons.person_outline_rounded,
                isSelected: !_isChamberMember,
                onTap: () => setState(() => _isChamberMember = false),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _buildVisitCleanPill(
          _isChamberMember
              ? '✓ Trade Chamber Member: Eligible for Chamber Visa Recommendation Letter.'
              : 'Notice: Non-member route applicable; Chamber recommendation letter optional.',
          _isChamberMember ? const Color(0xFFF0FDF4) : const Color(0xFFEFF4FA),
          _isChamberMember ? const Color(0xFF15803D) : const Color(0xFF1B3A5C),
        ),
        SizedBox(height: 18.h),

        // 6. Live Business Visa Readiness Status Banner
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF002444),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFullCommercialReady
                        ? Icons.verified_rounded
                        : Icons.assignment_turned_in_rounded,
                    color: isFullCommercialReady
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFF59E0B),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFullCommercialReady
                            ? '★ Verified Commercial Delegation Candidate'
                            : '★ Commercial Profile with Advisory Facilitation',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isFullCommercialReady
                            ? 'FBR registration, NTN, Chamber membership & host invitation successfully validated.'
                            : 'Our senior trade lawyers will structure complete documentation for consular submission.',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: const Color(0xFFC3D5E8),
                          height: 1.3,
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

  Widget _buildProminentQuestionHeader({
    required String number,
    required String question,
    required String subtitle,
  }) {
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final subtextColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF002444),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Q$number',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                question,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Padding(
          padding: EdgeInsets.only(left: 2.w),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              color: subtextColor,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SPECIALIZED SECTION: STUDY VISA APPLICANT & ACADEMIC DETAILS
  // ===========================================================================
  Widget _buildStudyVisaApplicantCard() {
    return _buildCardWrapper(
      title: 'Study Visa Applicant Details',
      icon: Icons.school_rounded,
      badgeText: 'Academic Track',
      children: [
        // Subtitle note
        Text(
          'Complete applicant profile, destination preferences, program selection, and academic history for study permit processing.',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.35,
          ),
        ),
        SizedBox(height: 16.h),

        // 1. Full Legal Name
        _buildProminentFieldHeading(
          'Applicant Full Name (as per Passport)',
          icon: Icons.person_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _nameController,
          suffixIcon: Icons.edit_outlined,
        ),
        SizedBox(height: 14.h),

        // 2. Applicant Age & Current City Row
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProminentFieldHeading(
                    'Age (Years)',
                    icon: Icons.cake_rounded,
                    isRequired: true,
                  ),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _studyAgeController,
                    suffixIcon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProminentFieldHeading(
                    'Current City',
                    icon: Icons.location_city_rounded,
                    isRequired: true,
                  ),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _cityController,
                    suffixIcon: Icons.home_work_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // 3. Official Contact Number (Full Width for zero overflow)
        _buildProminentFieldHeading(
          'Contact Number',
          icon: Icons.phone_android_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFDEE5EF)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Text('🇵🇰', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      '+92',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF171C21),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF171C21),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                    hintText: '300 1234567',
                    suffixIcon: const Icon(
                      Icons.phone_android_rounded,
                      size: 18,
                      color: Color(0xFF5B7FA5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Registered Email Address
        _buildProminentFieldHeading(
          'Registered Email Address',
          icon: Icons.email_outlined,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _emailController,
          suffixIcon: Icons.lock_outline_rounded,
        ),
        SizedBox(height: 14.h),

        // 4. Target Destination Country (Full Width)
        _buildProminentFieldHeading(
          'Target Study Country',
          icon: Icons.public_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _studyCountryController,
          suffixIcon: Icons.flag_circle_rounded,
        ),
        SizedBox(height: 14.h),

        // 5. Intended Program (or Explain) (Full Width)
        _buildProminentFieldHeading(
          'Intended Program (or Explain)',
          subtitle:
              'Specify target degree program or describe educational objectives:',
          icon: Icons.school_outlined,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildVisitTextArea(
          controller: _studyProgramExplainController,
          hint:
              'e.g. MSc Advanced Computer Science / Seeking university admissions for Fall Intake...',
        ),
        SizedBox(height: 14.h),

        // 6. Last Completed Degree (Full Width)
        _buildProminentFieldHeading(
          'Last Completed Degree',
          icon: Icons.workspace_premium_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _studyLastDegreeController,
          suffixIcon: Icons.history_edu_rounded,
        ),
        SizedBox(height: 14.h),

        // 7. Marks / CGPA Obtained (Full Width)
        _buildProminentFieldHeading(
          'Marks / CGPA Obtained',
          icon: Icons.grade_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _studyMarksController,
          suffixIcon: Icons.military_tech_rounded,
        ),
        SizedBox(height: 14.h),

        // 8. University Name of Last Degree (Full Width)
        _buildProminentFieldHeading(
          'University Name of Last Degree',
          subtitle:
              'Institution or board that awarded your most recent qualification:',
          icon: Icons.account_balance_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _studyLastUniController,
          suffixIcon: Icons.domain_rounded,
        ),
        SizedBox(height: 14.h),

        // 9. Academic Verification Status Pill
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF16A34A),
                size: 16,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '✓ Academic Profile Verified: Ready for university admission & visa processing.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // 10. Proceed to Payment Button (Right Side, Prominent)
        Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (!_validateStep1()) return;
                final updatedItem = widget.item.copyWith(
                  serviceFeeValue: _resolvedServiceFee,
                  totalPayable: _resolvedServiceFee,
                );
                final currentUser = SupabaseDatabaseService.instance.client.auth.currentUser;
                final effectiveName = _nameController.text.trim();
                final effectiveEmail = _emailController.text.trim().isNotEmpty
                    ? _emailController.text.trim()
                    : currentUser?.email;
                final effectivePhone = _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : currentUser?.phone;
                final formDataPayload = _buildFormDataPayload();
                context.push(
                  AppRoutes.paymentCheckout,
                  extra: {
                    'item': updatedItem,
                    'formData': formDataPayload,
                    'applicantName': effectiveName,
                    'applicantEmail': effectiveEmail,
                    'applicantPhone': effectivePhone,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002444),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Proceed to Payment ($_resolvedServiceFee)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SPECIALIZED SECTION: WORK VISA APPLICANT & PROFESSIONAL CREDENTIALS
  // ===========================================================================
  Widget _buildWorkVisaApplicantCard() {
    return _buildCardWrapper(
      title: 'Work Visa Applicant Details',
      icon: Icons.work_rounded,
      badgeText: 'Skilled Work Track',
      children: [
        // Subtitle note
        Text(
          'Complete applicant profile, country destination, target job role, and verified professional & academic credentials for official work permit sponsorship.',
          style: TextStyle(
            fontSize: 11.5.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.35,
          ),
        ),
        SizedBox(height: 16.h),

        // 1. Full Legal Name
        _buildProminentFieldHeading(
          'Applicant Full Name (as per Passport)',
          icon: Icons.person_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _nameController,
          suffixIcon: Icons.edit_outlined,
        ),
        SizedBox(height: 14.h),

        // 2. Applicant Age & Current City Row
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProminentFieldHeading(
                    'Age (Years)',
                    icon: Icons.cake_rounded,
                    isRequired: true,
                  ),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _workAgeController,
                    suffixIcon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProminentFieldHeading(
                    'Current City',
                    icon: Icons.location_city_rounded,
                    isRequired: true,
                  ),
                  SizedBox(height: 6.h),
                  _buildTextField(
                    controller: _cityController,
                    suffixIcon: Icons.home_work_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        // 3. Official Contact Number (Full Width for zero overflow)
        _buildProminentFieldHeading(
          'Contact Number',
          icon: Icons.phone_android_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFDEE5EF)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    Text('🇵🇰', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      '+92',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF171C21),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF171C21),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                    hintText: '300 1234567',
                    suffixIcon: const Icon(
                      Icons.phone_android_rounded,
                      size: 18,
                      color: Color(0xFF5B7FA5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Registered Email Address
        _buildProminentFieldHeading(
          'Registered Email Address',
          icon: Icons.email_outlined,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _emailController,
          suffixIcon: Icons.lock_outline_rounded,
        ),
        SizedBox(height: 14.h),

        // 4. Target Destination Country (Full Width)
        _buildProminentFieldHeading(
          'Target Work Destination Country',
          icon: Icons.public_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _workCountryController,
          suffixIcon: Icons.flag_circle_rounded,
        ),
        SizedBox(height: 14.h),

        // 5. Target Job Role / Profession (or Explain) (Full Width)
        _buildProminentFieldHeading(
          'Target Job Role / Profession (or Explain)',
          subtitle:
              'Specify target profession, trade, or describe occupational experience:',
          icon: Icons.work_outline_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildVisitTextArea(
          controller: _workProgramExplainController,
          hint:
              'e.g. Senior Software Engineer / Seeking LMIA or CoS sponsorship for skilled tech role...',
        ),
        SizedBox(height: 14.h),

        // 6. Last Completed Degree / Qualification (Full Width)
        _buildProminentFieldHeading(
          'Last Completed Degree / Qualification',
          icon: Icons.workspace_premium_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _workLastDegreeController,
          suffixIcon: Icons.history_edu_rounded,
        ),
        SizedBox(height: 14.h),

        // 7. Marks / CGPA / Experience (Full Width)
        _buildProminentFieldHeading(
          'Marks / Grade / Experience',
          icon: Icons.military_tech_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _workMarksController,
          suffixIcon: Icons.grade_rounded,
        ),
        SizedBox(height: 14.h),

        // 8. University / Institute Name of Last Degree (Full Width)
        _buildProminentFieldHeading(
          'University Name of Last Degree',
          subtitle:
              'Institution or board that awarded your most recent qualification:',
          icon: Icons.account_balance_rounded,
          isRequired: true,
        ),
        SizedBox(height: 6.h),
        _buildTextField(
          controller: _workLastUniController,
          suffixIcon: Icons.domain_rounded,
        ),
        SizedBox(height: 14.h),

        // 9. Work Verification Status Pill
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF16A34A),
                size: 16,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '✓ Professional Profile Verified: Ready for employer sponsorship & work visa filing.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        // 10. Proceed to Payment Button (Right Side, Prominent)
        Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (!_validateStep1()) return;
                final updatedItem = widget.item.copyWith(
                  serviceFeeValue: _resolvedServiceFee,
                  totalPayable: _resolvedServiceFee,
                );
                final currentUser = SupabaseDatabaseService.instance.client.auth.currentUser;
                final effectiveName = _nameController.text.trim();
                final effectiveEmail = _emailController.text.trim().isNotEmpty
                    ? _emailController.text.trim()
                    : currentUser?.email;
                final effectivePhone = _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : currentUser?.phone;
                final formDataPayload = _buildFormDataPayload();
                context.push(
                  AppRoutes.paymentCheckout,
                  extra: {
                    'item': updatedItem,
                    'formData': formDataPayload,
                    'applicantName': effectiveName,
                    'applicantEmail': effectiveEmail,
                    'applicantPhone': effectivePhone,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002444),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Proceed to Payment ($_resolvedServiceFee)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProminentFieldHeading(
    String title, {
    String? subtitle,
    IconData? icon,
    bool isRequired = false,
  }) {
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final subtextColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15.sp,
                color: const Color(0xFF002444),
              ),
              SizedBox(width: 6.w),
            ],
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (isRequired) ...[
                    SizedBox(width: 3.w),
                    Text(
                      '*',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: subtextColor,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  // (Easily editable by user in `applicant_form_config.dart`)
  // ===========================================================================
  Widget _buildDynamicRequirementsCard() {
    return _buildCardWrapper(
      title: _config.sectionTitle,
      icon: _config.sectionIcon,
      badgeText: _config.badgeText,
      children: [
        // Subtitle note
        Text(
          _config.sectionSubtitle,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
          ),
        ),
        SizedBox(height: 12.h),

        // Render dynamically configured fields
        ..._buildDynamicFields(),
      ],
    );
  }

  List<Widget> _buildDynamicFields() {
    final widgets = <Widget>[];
    int i = 0;

    while (i < _config.fields.length) {
      final field = _config.fields[i];

      // Check if this field and the next field are paired half-width inputs (like Year & Result)
      if (field.isHalfWidth &&
          i + 1 < _config.fields.length &&
          _config.fields[i + 1].isHalfWidth) {
        final nextField = _config.fields[i + 1];
        widgets.add(
          Row(
            children: [
              Expanded(child: _buildDynamicFieldItem(field)),
              SizedBox(width: 10.w),
              Expanded(child: _buildDynamicFieldItem(nextField)),
            ],
          ),
        );
        widgets.add(SizedBox(height: 12.h));
        i += 2;
      } else {
        widgets.add(_buildDynamicFieldItem(field));
        widgets.add(SizedBox(height: 12.h));
        i++;
      }
    }

    return widgets;
  }

  Widget _buildDynamicFieldItem(RequirementField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(field.label, isRequired: true),
        SizedBox(height: 6.h),
        if (field.type == RequirementFieldType.dropdown)
          _buildDropdownButton(
            value: _dynamicDropdownValues[field.id] ?? field.defaultValue,
            items: field.dropdownOptions,
            onChanged: (val) {
              if (val != null) {
                setState(() => _dynamicDropdownValues[field.id] = val);
              }
            },
          )
        else
          _buildTextField(
            controller: _dynamicFieldControllers[field.id]!,
            suffixIcon: field.icon ?? Icons.edit_outlined,
          ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 4: ADDITIONAL NOTES (OPTIONAL)
  // ===========================================================================
  Widget _buildAdditionalNotesCard() {
    return _buildCardWrapper(
      title: 'Additional Notes (Optional)',
      icon: Icons.note_alt_outlined,
      trailing: Text(
        '$_notesCharCount / 300',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF73777F),
        ),
      ),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF)),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 300,
            onChanged: (text) {
              setState(() => _notesCharCount = text.length);
            },
            style: TextStyle(
              fontSize: 13.sp,
              color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText:
                  'Specify any prior travel / visa history, CAS notes, or special requirements...',
              hintStyle: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF8C939E),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 14,
              color: Color(0xFF1B3A5C),
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                'Handled with strict confidentiality under SD Legal Framework',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: const Color(0xFF5A626A),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: PAYMENT METHOD SELECTION
  // ===========================================================================
  Widget _buildStep2Payment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(),
        SizedBox(height: 12.h),
        _buildMilestoneStepper(),
        SizedBox(height: 16.h),
        _buildCardWrapper(
          title: 'Select Payment Method',
          icon: Icons.payment_rounded,
          badgeText: 'All Info Secure',
          children: [
            _buildPaymentOption(
              id: 'card',
              title: 'Credit or Debit Card',
              subtitle: 'Visa, MasterCard, UnionPay',
              icon: Icons.credit_card_rounded,
            ),
            SizedBox(height: 10.h),
            _buildPaymentOption(
              id: 'bank',
              title: 'Direct Bank Transfer',
              subtitle: 'Online wire / IBAN transfer',
              icon: Icons.account_balance_rounded,
            ),
            SizedBox(height: 10.h),
            _buildPaymentOption(
              id: 'mobile',
              title: 'JazzCash / Easypaisa',
              subtitle: 'Instant mobile wallet payment',
              icon: Icons.account_balance_wallet_rounded,
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildCardWrapper(
          title: 'Billing Summary',
          icon: Icons.receipt_long_rounded,
          children: [
            _buildSummaryRow(
                'Consultation & Advisory', _resolvedServiceFee),
            SizedBox(height: 8.h),
            _buildSummaryRow('Government Portal Processing', 'Included'),
            SizedBox(height: 8.h),
            _buildSummaryRow('Tax & Registry Verification', 'PKR 0.00'),
            Divider(height: 20.h, color: _isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5)),
            _buildSummaryRow(
              'Total Payable',
              _resolvedServiceFee,
              isTotal: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final subtextColor = _isDark ? const Color(0xFF94A3B8) : const Color(0xFF73777F);
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = id),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (_isDark ? const Color(0xFF1E3A8A) : const Color(0xFFF0F5FA))
              : (_isDark ? const Color(0xFF18181B) : const Color(0xFFF9FBFE)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected ? (_isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444)) : (_isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22.sp,
              color: isSelected
                  ? (_isDark ? const Color(0xFF60A5FA) : const Color(0xFF002444))
                  : const Color(0xFF5B7FA5),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected
                  ? (_isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444))
                  : (_isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1)),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14.sp : 12.5.sp,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color:
                  isTotal ? (_isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21)) : (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A)),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 13.sp,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
            color: isTotal ? const Color(0xFF002444) : (_isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: CONFIRMATION SUCCESS
  // ===========================================================================
  Widget _buildStep3Confirmation() {
    return Column(
      children: [
        SizedBox(height: 20.h),
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF14532D) : const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF2E7D32),
            size: 48.sp,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Application Submitted!',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Your file has been assigned to a Senior Immigration Consultant. Reference ID: #SB-2026-98124',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.sp,
            color: _isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A626A),
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),
        _buildCardWrapper(
          title: 'Application Overview',
          icon: Icons.verified_user_rounded,
          children: [
            _buildSummaryRow('Applicant', _nameController.text),
            SizedBox(height: 8.h),
            _buildSummaryRow('Visa Program', widget.item.title),
            SizedBox(height: 8.h),
            _buildSummaryRow('Status', 'Case Assigned to Officer'),
            SizedBox(height: 8.h),
            _buildSummaryRow('Consultant SLA', 'Direct call in 2-4 hrs'),
          ],
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 13.h),
              side: const BorderSide(color: Color(0xFF002444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: () => context.go(AppRoutes.dashboard, extra: widget.item),
            child: Text(
              'Back to Dashboard',
              style: TextStyle(
                color: const Color(0xFF002444),
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STICKY BOTTOM ACTION BAR
  // ===========================================================================
  Widget _buildBottomStickyBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5);
    final feeLabelColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF73777F);
    final feeValueColor = isDark ? Colors.white : const Color(0xFF171C21);
    final buttonBg =
        isDark ? const Color(0xFF3B82F6) : const Color(0xFF002444);

    final displayFee = _resolvedServiceFee;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              if (!_isScholarshipOrJob) ...[
                // Application Fee Display (Left Side)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 120.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APPLICATION FEE',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: feeLabelColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          displayFee,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: feeValueColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
              ],

              // Continue CTA Button (Right Side, Responsive, No Overflow)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBg,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_currentStep == 1 && !_validateStep1()) return;

                              final currentUser = SupabaseDatabaseService.instance.client.auth.currentUser;
                              final effectiveName = _nameController.text.trim();
                              final effectiveEmail = _emailController.text.trim().isNotEmpty
                                  ? _emailController.text.trim()
                                  : currentUser?.email;
                              final effectivePhone = _phoneController.text.trim().isNotEmpty
                                  ? _phoneController.text.trim()
                                  : currentUser?.phone;
                              final formDataPayload = _buildFormDataPayload();

                              final isUnlockPass = widget.item.id.contains('unlock') || widget.item.id.contains('pass');
                              if (_isScholarshipOrJob && !isUnlockPass) {
                                if (_currentStep == 1) {
                                  setState(() => _isSubmitting = true);
                                  final refNo = ReferenceCodeGenerator.generate(
      category: widget.item.categoryTag,
      title: widget.item.title,
      listingId: widget.item.id,
    );
                                  await SupabaseDatabaseService.instance.submitApplication(
                                    userId: currentUser?.id,
                                    referenceNumber: refNo,
                                    categoryType: widget.item.categoryTag.toUpperCase(),
                                    title: widget.item.title,
                                    subtitle: widget.item.subtitle,
                                    listingId: widget.item.id,
                                    applicantName: effectiveName,
                                    applicantEmail: effectiveEmail,
                                    applicantPhone: effectivePhone,
                                    formData: formDataPayload,
                                    paymentMethod: 'Free / Official Sponsorship',
                                  );

                                  if (mounted) {
                                    setState(() {
                                      _isSubmitting = false;
                                      _currentStep = 3;
                                    });
                                  }
                                } else {
                                  context.go('/');
                                }
                                return;
                              }

                              final updatedItem = widget.item.copyWith(
                                serviceFeeValue: _resolvedServiceFee,
                                totalPayable: _resolvedServiceFee,
                              );

                              final refNo = ReferenceCodeGenerator.generate(
                                category: widget.item.categoryTag,
                                title: widget.item.title,
                                listingId: widget.item.id,
                              );

                              if (_currentStep == 1) {
                                context.push(
                                  AppRoutes.paymentCheckout,
                                  extra: {
                                    'item': updatedItem,
                                    'formData': formDataPayload,
                                    'applicantName': effectiveName,
                                    'applicantEmail': effectiveEmail,
                                    'applicantPhone': effectivePhone,
                                    'customReference': refNo,
                                  },
                                );
                              } else if (_currentStep == 2) {
                                setState(() => _isSubmitting = true);
                                await SupabaseDatabaseService.instance.submitApplication(
                                  userId: currentUser?.id,
                                  referenceNumber: refNo,
                                  categoryType: widget.item.categoryTag.toUpperCase(),
                                  title: widget.item.title,
                                  subtitle: widget.item.subtitle,
                                  listingId: widget.item.id,
                                  applicantName: effectiveName,
                                  applicantEmail: effectiveEmail,
                                  applicantPhone: effectivePhone,
                                  formData: formDataPayload,
                                  paymentMethod: _selectedPaymentMethod,
                                );

                                if (!context.mounted) return;
                                setState(() => _isSubmitting = false);
                                if (_selectedPaymentMethod == 'bank' ||
                                    _selectedPaymentMethod == 'mobile') {
                                  context.push(
                                    AppRoutes.paymentPending,
                                    extra: updatedItem,
                                  );
                                } else {
                                  context.push(
                                    AppRoutes.paymentSuccess,
                                    extra: updatedItem,
                                  );
                                }
                              } else {
                                context.go('/');
                              }
                            },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: _isSubmitting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  const Text('Submitting...'),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                              _isScholarshipOrJob
                                  ? (_currentStep == 1 ? 'Submit Application' : 'Done')
                                  : (_currentStep == 1
                                      ? 'Continue to Payment'
                                      : _currentStep == 2
                                          ? 'Pay & Complete'
                                          : 'Done'),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              _currentStep == 3
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE INPUT HELPERS
  // ===========================================================================
  Widget _buildInputLabel(String label, {bool isRequired = false}) {
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        if (isRequired) ...[
          SizedBox(width: 3.w),
          Text(
            '*',
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    IconData? suffixIcon,
    Widget? prefix,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    final inputBg = _isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8);
    final inputBorder = _isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF);
    final textColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: inputBorder),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13.sp,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          prefixIcon: prefix,
          suffixIcon: suffixIcon != null
              ? Icon(
                  suffixIcon,
                  size: 18.sp,
                  color: _isDark ? const Color(0xFF93C5FD) : const Color(0xFF5B7FA5),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDropdownButton({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final inputBg = _isDark ? const Color(0xFF18181B) : const Color(0xFFEDF2F8);
    final inputBorder = _isDark ? const Color(0xFF27272A) : const Color(0xFFDEE5EF);
    final textColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final effectiveValue = items.contains(value) ? value : null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          dropdownColor: _isDark ? const Color(0xFF18181B) : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20.sp,
            color: _isDark ? const Color(0xFF93C5FD) : const Color(0xFF5B7FA5),
          ),
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          items: items.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(
                e,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE HELPER BUILDERS (Inputs, Card Wrappers, Pickers)
  // ===========================================================================
  Widget _buildCardWrapper({
    required String title,
    required IconData icon,
    String? badgeText,
    Widget? trailing,
    required List<Widget> children,
  }) {
    final titleColor = _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF171C21);
    final badgeBg = badgeText == 'Academic Track' || badgeText == 'Skilled Work Track'
        ? (_isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE3F2FD))
        : (_isDark ? const Color(0xFF18181B) : const Color(0xFFEFF3F8));
    final badgeTextColor = badgeText == 'Academic Track' || badgeText == 'Skilled Work Track'
        ? (_isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1565C0))
        : (_isDark ? const Color(0xFF94A3B8) : const Color(0xFF1B3A5C));
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _isDark ? const Color(0xFF27272A) : const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF1B3A5C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: _isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                      : const Color(0xFFF1F5FA),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  size: 17.sp,
                  color: _isDark ? const Color(0xFF60A5FA) : const Color(0xFF1B3A5C),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              if (badgeText != null) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }


  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1996, 8, 14),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF002444),
              onPrimary: Colors.white,
              onSurface: Color(0xFF171C21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        controller.text = formatted;
      });
    }
  }

  Future<void> _pickTravelDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 45)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF002444),
              onPrimary: Colors.white,
              onSurface: Color(0xFF171C21),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        controller.text = formatted;
      });
    }
  }

  Map<String, dynamic> _buildFormDataPayload() {
    final payload = <String, dynamic>{
      'applicant_name': _nameController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
      'gender': _selectedGender,
      'nationality': _selectedNationality,
      'marital_status': _selectedMaritalStatus,
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'notes': _notesController.text.trim(),
      'visa_title': widget.item.title,
      'visa_category': widget.item.categoryTag,
      'visa_country': widget.item.countryName,
    };

    if (_isScholarship) {
      payload['program_type'] = 'Scholarship';
    } else if (_isSponsoredJob) {
      payload['program_type'] = 'Sponsored Job';
    } else if (_isVisitVisa) {
      payload['visit_details'] = {
        'purpose': _visitPurpose,
        'stay_duration': _visitDuration,
        'travel_date': _visitTravelDateController.text.trim(),
        'applicant_age': _visitVisaAgeController.text.trim(),
        'age_bracket': _visitVisaAgeBracket,
        'has_previous_work': _hasVisitPreviousWork,
        'previous_work_history': _visitPreviousWorkController.text.trim(),
        'has_bank_transactions': _hasVisitTransactionHistory,
        'bank_transactions_history': _visitTransactionHistoryController.text.trim(),
        'has_visa_rejection': _hasVisitVisaRejection,
        'rejection_reason': _visitVisaRejectionController.text.trim(),
      };
    } else if (_isGoldenVisa) {
      payload['golden_visa_details'] = {
        'applicant_age': _goldenAgeController.text.trim(),
        'business_information': _goldenBusinessInfoController.text.trim(),
        'yearly_taxable_income': _goldenYearlyIncomeController.text.trim(),
        'is_fbr_taxpayer': _isGoldenFbrPayer,
      };
    } else if (_isBusinessVisa) {
      payload['business_visa_details'] = {
        'applicant_age': _businessAgeController.text.trim(),
        'has_registered_business': _hasBusiness,
        'business_details': _businessDetailsController.text.trim(),
        'is_fbr_registered': _isFbrRegistered,
        'has_ntn': _hasNtnNumber,
        'ntn_number': _businessNtnController.text.trim(),
        'has_invitation_letter': _hasInvitationLetter,
        'is_chamber_member': _isChamberMember,
      };
    } else if (_isStudyVisa) {
      payload['study_visa_details'] = {
        'applicant_age': _studyAgeController.text.trim(),
        'destination_country': _studyCountryController.text.trim(),
        'program_details': _studyProgramExplainController.text.trim(),
        'last_degree': _studyLastDegreeController.text.trim(),
        'marks_or_cgpa': _studyMarksController.text.trim(),
        'last_institution': _studyLastUniController.text.trim(),
      };
    } else if (_isWorkVisa) {
      payload['work_visa_details'] = {
        'applicant_age': _workAgeController.text.trim(),
        'destination_country': _workCountryController.text.trim(),
        'job_role_or_field': _workProgramExplainController.text.trim(),
        'last_qualification': _workLastDegreeController.text.trim(),
        'marks_or_grade': _workMarksController.text.trim(),
        'last_institution_or_employer': _workLastUniController.text.trim(),
      };
    }

    final dynamicMap = <String, dynamic>{};
    for (final entry in _dynamicFieldControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        dynamicMap[entry.key] = entry.value.text.trim();
      }
    }
    for (final entry in _dynamicDropdownValues.entries) {
      dynamicMap[entry.key] = entry.value;
    }
    if (dynamicMap.isNotEmpty) {
      payload['custom_requirements'] = dynamicMap;
    }

    return payload;
  }
}
