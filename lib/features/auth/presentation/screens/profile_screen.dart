import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLineController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;

  bool _isSaving = false;
  String? _initializedUserId;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressLineController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _populateFormIfChanged(UserModel? user) {
    if (user == null) {
      _initializedUserId = null;
      return;
    }
    if (_initializedUserId != user.id) {
      _initializedUserId = user.id;
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _phoneController.text = user.phoneNumber ?? '';
      _addressLineController.text = user.shippingAddress?.addressLine ?? '';
      _cityController.text = user.shippingAddress?.city ?? '';
      _stateController.text = user.shippingAddress?.state ?? '';
      _postalCodeController.text = user.shippingAddress?.postalCode ?? '';
    }
  }

  Future<void> _handleSave() async {
    final firstName = _firstNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty) {
      SnackbarUtils.showError(context, 'First name is required');
      return;
    }

    if (phone.isEmpty) {
      SnackbarUtils.showError(context, 'Phone number is required');
      return;
    }

    setState(() => _isSaving = true);

    final success = await ref.read(authNotifierProvider.notifier).updateProfile(
      firstName: firstName,
      lastName: _lastNameController.text.trim(),
      phoneNumber: phone,
      addressLine: _addressLineController.text.trim(),
      city: _cityController.text.trim(),
      addressState: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        SnackbarUtils.showSuccess(context, 'Profile updated successfully! 🎉');
      } else {
        final error = ref.read(authNotifierProvider).errorMessage ?? 'Failed to update profile';
        SnackbarUtils.showError(context, error);
      }
    }
  }

  void _showServerSettingsModal() {
    final storage = ref.read(storageServiceProvider);
    final currentUrl = storage.getCustomBaseUrl() ?? ApiConstants.defaultBaseUrl;
    final urlController = TextEditingController(text: currentUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Server Settings', style: AppTypography.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Configure API Base URL for testing on Android/iOS/physical devices.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: urlController,
                label: 'Base URL',
                hintText: 'http://10.0.2.2:5001/api/v1',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Save URL',
                      onPressed: () async {
                        final val = urlController.text.trim();
                        if (val.isNotEmpty) {
                          await storage.setCustomBaseUrl(val);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            SnackbarUtils.showSuccess(ctx, 'Base URL updated to: $val');
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await storage.removeCustomBaseUrl();
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        SnackbarUtils.showInfo(ctx, 'Reset to default Base URL');
                      }
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    _populateFormIfChanged(user);

    final isRider = user?.role == 'rider';
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 54,
        leading: Navigator.canPop(context)
            ? Center(
                child: InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Manage and update your personal details',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          // Rider / Admin Quick Dashboard Link Pill (Matching web profile page)
          if (isRider)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.local_shipping_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Rider',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E22CE).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shield_rounded, size: 14, color: Color(0xFF7E22CE)),
                      SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7E22CE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Server Settings Icon
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B), size: 22),
            onPressed: _showServerSettingsModal,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: user == null ? _buildGuestView() : _buildProfileContent(user),
    );
  }

  // --- GUEST VIEW (When not logged in) ---
  Widget _buildGuestView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to SobjiHaat!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your profile, view orders, update delivery addresses, and track real-time shipments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Sign In or Register',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- LOGGED IN USER PROFILE (Exact replica of web /profile/page.tsx) ---
  Widget _buildProfileContent(UserModel user) {
    final role = user.role.toLowerCase();
    final isAdmin = role == 'admin';
    final isRider = role == 'rider';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Profile Container Card (Matching web card structure)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner with Brand Gradient & Organic Patterns (Matching web page.tsx lines 168-179)
                Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            Color(0xFF3B6412),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Soft decorative background circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -15,
                      left: 20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  ],
                ),

                // Profile Identity Bar (Matching web page.tsx lines 181-273)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Avatar overlapping top banner
                      Transform.translate(
                        offset: const Offset(0, -45),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Avatar container with white border & shadow
                            Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white, width: 3.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                      ? Image.network(
                                          user.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              _buildAvatarFallback(user),
                                        )
                                      : _buildAvatarFallback(user),
                                ),
                                // Camera change badge (bottom right)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: () {
                                      SnackbarUtils.showInfo(
                                        context,
                                        'Upload avatar from web panel or attach image.',
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // User Name & Badges
                      Transform.translate(
                        offset: const Offset(0, -32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                // Role Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? const Color(0xFFF3E8FF)
                                        : isRider
                                            ? const Color(0xFFDBEAFE)
                                            : const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isAdmin
                                          ? const Color(0xFFE9D5FF)
                                          : isRider
                                              ? const Color(0xFFBFDBFE)
                                              : const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isAdmin
                                            ? Icons.shield_rounded
                                            : isRider
                                                ? Icons.local_shipping_rounded
                                                : Icons.person_rounded,
                                        size: 11,
                                        color: isAdmin
                                            ? const Color(0xFF7E22CE)
                                            : isRider
                                                ? const Color(0xFF1D4ED8)
                                                : const Color(0xFF047857),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isAdmin
                                              ? const Color(0xFF7E22CE)
                                              : isRider
                                                  ? const Color(0xFF1D4ED8)
                                                  : const Color(0xFF047857),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Meta detail strip: Email & Phone
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.phoneNumber!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Form Content (Matching web page.tsx lines 276-457)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Personal Information
                      _buildSectionHeader(
                        icon: Icons.person_rounded,
                        title: 'Personal Information',
                      ),
                      const SizedBox(height: 14),

                      // First Name & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'First Name *',
                              controller: _firstNameController,
                              icon: Icons.person_outline_rounded,
                              hintText: 'e.g. Saiful',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInputField(
                              label: 'Last Name',
                              controller: _lastNameController,
                              hintText: 'e.g. Islam',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      _buildInputField(
                        label: 'Phone Number *',
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        hintText: 'e.g. 01711223344',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      // Email Address (Disabled / ReadOnly)
                      _buildInputField(
                        label: 'Email Address (Registered)',
                        controller: TextEditingController(text: user.email),
                        icon: Icons.mail_outline_rounded,
                        readOnly: true,
                      ),
                      const SizedBox(height: 22),

                      // Section 2: Default Delivery Address
                      _buildSectionHeader(
                        icon: Icons.location_on_rounded,
                        title: 'Default Delivery Address',
                      ),
                      const SizedBox(height: 14),

                      // Street Address Line
                      _buildInputField(
                        label: 'Street / House & Road Address',
                        controller: _addressLineController,
                        icon: Icons.location_on_outlined,
                        hintText: 'e.g. House #12, Road #4, Bangla Bazar',
                      ),
                      const SizedBox(height: 12),

                      // City, State, Postal Code
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              label: 'City',
                              controller: _cityController,
                              hintText: 'e.g. Barisal',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              label: 'State / Division',
                              controller: _stateController,
                              hintText: 'e.g. Barisal',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              label: 'Postal Code',
                              controller: _postalCodeController,
                              hintText: 'e.g. 8200',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bottom Save Actions
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Keep your profile updated for hassle-free vegetable deliveries.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.save_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Additional Quick Menu Options (Orders, WhatsApp, Complaints)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Order History',
                    subtitle: 'View active and previous grocery orders',
                    onTap: () {
                      SnackbarUtils.showInfo(context, 'Opening order history...');
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.chat_rounded,
                    title: 'WhatsApp Customer Support',
                    subtitle: '+${ApiConstants.whatsAppSupportNumber} (8:00 AM - 10:00 PM)',
                    iconColor: const Color(0xFF25D366),
                    onTap: () {
                      SnackbarUtils.showInfo(
                        context,
                        'Opening WhatsApp Support (+${ApiConstants.whatsAppSupportNumber})...',
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.report_problem_outlined,
                    title: 'Have a Complaint?',
                    subtitle: 'Submit feedback directly to executive support',
                    iconColor: Colors.amber.shade800,
                    onTap: () => _showComplaintDialog(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Sign Out Button
          Material(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: ListTile(
              onTap: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (mounted) {
                  SnackbarUtils.showInfo(context, 'Signed out successfully');
                }
              },
              leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(UserModel user) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    String? hintText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    icon,
                    size: 16,
                    color: readOnly ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ] else
                const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: readOnly ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
          size: 20,
        ),
      ),
    );
  }

  void _showComplaintDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.report_problem_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Submit Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about any delivery issues, product freshness or app problems:',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your issue here...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              SnackbarUtils.showSuccess(
                context,
                'Thank you! Your complaint has been submitted to support team.',
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
