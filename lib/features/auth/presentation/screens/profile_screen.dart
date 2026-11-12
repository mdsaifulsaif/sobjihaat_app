import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/user_model.dart';
import '../../../home/data/models/area_model.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../orders/presentation/screens/track_order_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../../../complaint/presentation/widgets/complaint_modal.dart';

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

  File? _avatarFile;
  String? _selectedAreaId;
  String? _selectedAreaName;

  bool _isSaving = false;
  String? _initializedUserId;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressLineController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    super.dispose();
  }

  void _populateFormIfChanged(UserModel? user, List<AreaModel> areas) {
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

      // Match area by id or name
      final userAreaId = user.shippingAddress?.areaId;
      final userAreaName = user.shippingAddress?.area;

      if (userAreaId != null && userAreaId.isNotEmpty) {
        final match = areas.where((a) => a.id == userAreaId).firstOrNull;
        _selectedAreaId = userAreaId;
        _selectedAreaName = match?.name ?? userAreaName;
      } else if (userAreaName != null && userAreaName.isNotEmpty) {
        final match = areas.where((a) => a.name.toLowerCase() == userAreaName.toLowerCase()).firstOrNull;
        _selectedAreaId = match?.id;
        _selectedAreaName = userAreaName;
      } else {
        _selectedAreaId = null;
        _selectedAreaName = null;
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _avatarFile = File(picked.path);
        });
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Avatar selected! Click Save Changes to apply.');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Could not select image: $e');
      }
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
      area: _selectedAreaName,
      areaId: _selectedAreaId,
      city: 'Barisal',
      addressState: 'Barisal',
      postalCode: '8200',
      avatarPath: _avatarFile?.path,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _avatarFile = null;
        }
      });
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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

    final homeData = ref.watch(homeDataProvider).value;
    final areas = homeData?.areas.where((a) => a.isActive).toList() ?? <AreaModel>[];

    _populateFormIfChanged(user, areas);

    final isRider = user?.role.toLowerCase() == 'rider';
    final isAdmin = user?.role.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 56,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
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
                fontSize: 19,
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
          // Rider Dashboard Pill
          if (isRider)
            Padding(
              padding: const EdgeInsets.only(right: 6),
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
                      Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.primary),
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
          // Admin Panel Pill
          else if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 6),
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
                      Icon(Icons.shield_outlined, size: 14, color: Color(0xFF7E22CE)),
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
      body: user == null ? _buildGuestView() : _buildProfileContent(user, areas),
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
                'Welcome to Mojutmart!',
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- LOGGED IN USER PROFILE (Exact replica of redesigned web /profile/page.tsx) ---
  Widget _buildProfileContent(UserModel user, List<AreaModel> areas) {
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Identity Bar (Matching web page.tsx lines 186-304)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color(0xFFF8FAFC),
                          Color(0xFFECFDF5),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                      ),
                    ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar + User Info Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Circular Avatar with Camera upload trigger
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _avatarFile != null
                                      ? Image.file(
                                          _avatarFile!,
                                          fit: BoxFit.cover,
                                        )
                                      : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                          ? Image.network(
                                              user.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => _buildAvatarFallback(user),
                                            )
                                          : _buildAvatarFallback(user),
                                ),
                              ),
                              // Camera icon button at bottom-right
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: InkWell(
                                  onTap: _pickAvatar,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // User Name, Badges & Joined Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name + Verified checkmark + Role badge
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      user.fullName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    // Role Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
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
                                                ? Icons.shield_outlined
                                                : isRider
                                                    ? Icons.local_shipping_outlined
                                                    : Icons.person_outline,
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

                                // Email Meta
                                Row(
                                  children: [
                                    const Icon(Icons.mail_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        user.email,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF475569),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),

                                // Phone & Joined Meta row
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 2,
                                  children: [
                                    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            user.phoneNumber!,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                                    ],
                                    if (user.createdAt != null) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Joined ${DateFormat('MMM yyyy').format(user.createdAt!)}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quick Action Buttons: Order History & Track Order (Matching web page.tsx lines 282-302)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                                );
                              },
                              icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                              label: const Text(
                                'Order History',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const TrackOrderScreen()),
                                );
                              },
                              icon: const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF475569)),
                              label: const Text(
                                'Track Order',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form Content (Matching web page.tsx lines 306-505)
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Personal Information
                      _buildSectionHeader(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                      ),
                      const SizedBox(height: 14),

                      // First Name & Last Name Grid
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
                      const SizedBox(height: 24),

                      // Section 2: Default Delivery Address
                      _buildSectionHeader(
                        icon: Icons.location_on_outlined,
                        title: 'Default Delivery Address',
                        badgeText: '📍 Barisal City Delivery',
                      ),
                      const SizedBox(height: 14),

                      // Delivery Area Dropdown & City
                      _buildAreaDropdown(areas),
                      const SizedBox(height: 12),

                      // City / Coverage (Fixed to Barisal City)
                      _buildInputField(
                        label: 'City / Coverage',
                        controller: TextEditingController(text: 'Barisal City (Default)'),
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),

                      // Street / House & Road Address
                      _buildInputField(
                        label: 'Street / House & Road Address',
                        controller: _addressLineController,
                        icon: Icons.location_on_outlined,
                        hintText: 'e.g. House #12, Road #4, Holding or Landmark',
                      ),
                      const SizedBox(height: 20),

                      // Bottom Save Actions (Matching web page.tsx lines 479-504)
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Keep your profile updated for hassle-free vegetable deliveries.',
                              style: TextStyle(
                                fontSize: 11.5,
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
                                elevation: 0,
                                shadowColor: AppColors.primary.withValues(alpha: 0.35),
                              ),
                              child: _isSaving
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Saving Changes...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.save_outlined, size: 18),
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
        ),
        const SizedBox(height: 16),

          // 2. Additional Quick Menu Options (WhatsApp, Complaints)
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
                    icon: Icons.chat_rounded,
                    title: 'WhatsApp Customer Support',
                    subtitle: '+${ApiConstants.whatsAppSupportNumber} (8:00 AM - 10:00 PM)',
                    iconColor: const Color(0xFF25D366),
                    onTap: () {
                      SnackbarUtils.showInfo(
                        context,
                        'WhatsApp Support: +${ApiConstants.whatsAppSupportNumber}',
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.report_problem_outlined,
                    title: 'Have a Complaint?',
                    subtitle: 'Submit feedback directly to executive support',
                    iconColor: Colors.amber.shade800,
                    onTap: () => ComplaintModal.show(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Sign Out Button
          Material(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showSignOutDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out of Mojutmart?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) {
                SnackbarUtils.showInfo(context, 'Signed out successfully');
              }
            },
            child: const Text('Sign Out'),
          ),
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
            fontSize: 32,
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
    String? badgeText,
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
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF047857),
              ),
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

  Widget _buildAreaDropdown(List<AreaModel> areas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Area (Barisal City) *',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: areas.any((a) => a.id == _selectedAreaId)
                  ? _selectedAreaId
                  : (areas.any((a) => a.name == _selectedAreaName)
                      ? areas.firstWhere((a) => a.name == _selectedAreaName).id
                      : null),
              hint: Row(
                children: const [
                  Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Text(
                    '-- Select Your Delivery Area --',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              items: areas.map((area) {
                return DropdownMenuItem<String>(
                  value: area.id,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          area.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newAreaId) {
                if (newAreaId != null) {
                  final selected = areas.firstWhere((a) => a.id == newAreaId);
                  setState(() {
                    _selectedAreaId = selected.id;
                    _selectedAreaName = selected.name;
                  });
                }
              },
            ),
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
}
