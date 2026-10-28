import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../data/models/area_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/available_coupons_bottom_sheet.dart';
import '../widgets/mini_cart_bottom_sheet.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _districtController;
  late final TextEditingController _upazilaController;
  late final TextEditingController _houseNoController;
  late final TextEditingController _roadController;
  late final TextEditingController _flatNoController;
  late final TextEditingController _deliveryNotesController;
  late final TextEditingController _specialInstructionsController;
  late final TextEditingController _couponInputController;
  final FocusNode _couponFocusNode = FocusNode();

  String _deliveryType = 'local'; // 'local' or 'nationwide'
  String _addressLabel = 'home'; // 'home', 'work', 'partner', 'other'
  String? _selectedAreaId;
  String _orderMode = 'normal'; // 'normal' or 'preorder'
  bool _wantsCustomTime = false;
  String? _selectedCustomTime;

  bool _isSubmitting = false;
  bool _showItemsPreview = false;

  List<AreaModel> _areas = [];
  bool _isLoadingAreas = true;
  double _shippingCharge = 0.0;
  bool _isLoadingShipping = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    final shipping = user?.shippingAddress;

    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _districtController = TextEditingController(text: shipping?.state ?? '');
    _upazilaController = TextEditingController(text: shipping?.city ?? '');
    _houseNoController = TextEditingController();
    _roadController = TextEditingController(text: shipping?.addressLine ?? '');
    _flatNoController = TextEditingController();
    _deliveryNotesController = TextEditingController();
    _specialInstructionsController = TextEditingController();
    _couponInputController = TextEditingController();

    _loadAreasAndShipping();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _upazilaController.dispose();
    _houseNoController.dispose();
    _roadController.dispose();
    _flatNoController.dispose();
    _deliveryNotesController.dispose();
    _specialInstructionsController.dispose();
    _couponInputController.dispose();
    _couponFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAreasAndShipping() async {
    final subtotal = ref.read(cartNotifierProvider).subtotal;
    try {
      final dataSource = ref.read(cartRemoteDataSourceProvider);
      final areas = await dataSource.getAreas();
      final shipping = await dataSource.getShippingPreview(
        deliveryType: _deliveryType,
        subtotal: subtotal,
      );

      if (mounted) {
        setState(() {
          _areas = areas;
          if (_areas.isNotEmpty && _selectedAreaId == null) {
            _selectedAreaId = _areas.first.id;
          }
          _shippingCharge = shipping;
          _isLoadingAreas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final shippingConfig = ref.read(homeDataProvider).value?.shippingConfig;
        final dynamicFee = shippingConfig?.getChargeForSubtotal(subtotal) ?? (subtotal >= 5000 ? 0.0 : 30.0);
        setState(() {
          _shippingCharge = _deliveryType == 'local' ? dynamicFee : 120.0;
          _isLoadingAreas = false;
        });
      }
    }
  }

  Future<void> _recalculateShipping() async {
    setState(() => _isLoadingShipping = true);
    final subtotal = ref.read(cartNotifierProvider).subtotal;
    try {
      final dataSource = ref.read(cartRemoteDataSourceProvider);
      final shipping = await dataSource.getShippingPreview(
        deliveryType: _deliveryType,
        subtotal: subtotal,
      );
      if (mounted) {
        setState(() {
          _shippingCharge = shipping;
          _isLoadingShipping = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final shippingConfig = ref.read(homeDataProvider).value?.shippingConfig;
        final dynamicFee = shippingConfig?.getChargeForSubtotal(subtotal) ?? (subtotal >= 5000 ? 0.0 : 30.0);
        setState(() {
          _shippingCharge = _deliveryType == 'local' ? dynamicFee : 120.0;
          _isLoadingShipping = false;
        });
      }
    }
  }

  Future<void> _applyCouponFromInput([String? directCode]) async {
    final code = directCode ?? _couponInputController.text.trim();
    if (code.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter a coupon code');
      return;
    }
    final user = ref.read(authNotifierProvider).user;
    final success = await ref
        .read(cartNotifierProvider.notifier)
        .applyCoupon(code, userId: user?.id);

    if (mounted) {
      if (success) {
        _couponInputController.clear();
        SnackbarUtils.showSuccess(context, 'Coupon $code applied successfully! 🎉');
      } else {
        final err = ref.read(cartNotifierProvider).couponError ?? 'Invalid coupon code';
        SnackbarUtils.showError(context, err);
      }
    }
  }

  Future<void> _handlePlaceOrder() async {
    final cartState = ref.read(cartNotifierProvider);
    if (cartState.items.isEmpty) {
      SnackbarUtils.showError(context, 'Your cart is empty');
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your full name');
      return;
    }
    if (phone.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your phone number');
      return;
    }

    if (_deliveryType == 'local' && (_selectedAreaId == null || _selectedAreaId!.isEmpty)) {
      SnackbarUtils.showError(context, 'Please select your delivery area in Barisal');
      return;
    }

    if (_deliveryType == 'nationwide' && _districtController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your district');
      return;
    }

    if (_wantsCustomTime && (_selectedCustomTime == null || _selectedCustomTime!.isEmpty)) {
      SnackbarUtils.showError(context, 'অনুগ্রহ করে ডেলিভারি সময় নির্বাচন করুন');
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState.user == null) {
      SnackbarUtils.showInfo(context, 'Please login first to confirm your order');
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true && ref.read(authNotifierProvider).user == null) {
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];

    final orderData = <String, dynamic>{
      'items': cartState.items.map((item) => {
            'productID': item.product.id,
            'quantity': item.quantity,
          }).toList(),
      'deliveryType': _deliveryType,
      'deliveryAddress': {
        'name': name,
        'phone': phone,
        'area': _selectedAreaId,
        'district': _deliveryType == 'nationwide' ? _districtController.text.trim() : null,
        'upazila': _deliveryType == 'nationwide' ? _upazilaController.text.trim() : null,
        'houseNo': _houseNoController.text.trim().isNotEmpty ? _houseNoController.text.trim() : null,
        'road': _roadController.text.trim().isNotEmpty ? _roadController.text.trim() : null,
        'flatNo': _flatNoController.text.trim().isNotEmpty ? _flatNoController.text.trim() : null,
        'deliveryNotes': _deliveryNotesController.text.trim().isNotEmpty
            ? _deliveryNotesController.text.trim()
            : null,
        'label': _addressLabel,
      },
      'paymentMethod': 'cod',
      'specialInstructions': _specialInstructionsController.text.trim().isNotEmpty
          ? _specialInstructionsController.text.trim()
          : null,
      if (cartState.appliedCoupon != null) 'couponCode': cartState.appliedCoupon!.code,
      if (cartState.couponDiscount > 0) 'couponDiscount': cartState.couponDiscount,
    };

    if (_deliveryType == 'local') {
      if (_orderMode == 'preorder') {
        orderData['deliveryDate'] = tomorrowStr;
        if (_wantsCustomTime && _selectedCustomTime != null) {
          orderData['deliveryTime'] = _selectedCustomTime;
        }
      } else if (_wantsCustomTime && _selectedCustomTime != null) {
        orderData['deliveryDate'] = todayStr;
        orderData['deliveryTime'] = _selectedCustomTime;
      }
    }

    try {
      final dataSource = ref.read(cartRemoteDataSourceProvider);
      final res = await dataSource.placeOrder(orderData);
      final orderId = (res['data'] is Map<String, dynamic>)
          ? (res['data']['orderNumber'] ?? res['data']['_id'] ?? '').toString()
          : null;

      final grandTotal = (cartState.subtotal + _shippingCharge - cartState.couponDiscount)
          .clamp(0.0, double.infinity);

      ref.read(cartNotifierProvider.notifier).clearCart();

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              orderId: orderId,
              totalAmount: grandTotal,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        SnackbarUtils.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        SnackbarUtils.showError(
          context,
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final items = cartState.items;
    final subtotal = cartState.subtotal;
    final couponDiscount = cartState.couponDiscount;
    final grandTotal = (subtotal + _shippingCharge - couponDiscount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_rounded, size: 14, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Secure',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Smart Upsell Nudge Banner (Matches web SmartUpsellNudge)
                      _buildSmartUpsellNudge(subtotal),
                      const SizedBox(height: 12),

                      // Section 1: Customer Information
                      _buildSectionCard(
                        icon: Icons.person_rounded,
                        title: 'Customer Information',
                        subtitle: 'Who should we deliver this to?',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Full Name *',
                                  controller: _nameController,
                                  hintText: 'Your full name',
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Phone Number *',
                                  controller: _phoneController,
                                  hintText: '01XXXXXXXXX',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Section 2: Delivery Address
                      _buildSectionCard(
                        icon: Icons.location_on_rounded,
                        title: 'Delivery Address',
                        subtitle: 'Where should we bring your fresh items?',
                        children: [
                          // Address Label Chips (Home, Work, Partner, Other)
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildLabelChip('home', 'Home', Icons.home_rounded),
                              _buildLabelChip('work', 'Work', Icons.work_rounded),
                              _buildLabelChip('partner', 'Partner', Icons.favorite_rounded),
                              _buildLabelChip('other', 'Other', Icons.more_horiz_rounded),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Area selector (Local Barisal City)

                          // Area selector (if Local) or District/Upazila (if Nationwide)
                          if (_deliveryType == 'local') ...[
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
                              child: _isLoadingAreas
                                  ? const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _areas.any((a) => a.id == _selectedAreaId) ? _selectedAreaId : null,
                                        isExpanded: true,
                                        hint: const Text(
                                          'Select your area',
                                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                        ),
                                        items: _areas.map((area) {
                                          return DropdownMenuItem<String>(
                                            value: area.id,
                                            child: Text(
                                              area.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedAreaId = val);
                                        },
                                      ),
                                    ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'District *',
                                    controller: _districtController,
                                    hintText: 'e.g. Dhaka',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'Upazila / Thana',
                                    controller: _upazilaController,
                                    hintText: 'e.g. Dhanmondi',
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),

                          // House No, Road, Flat No
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'House No',
                                  controller: _houseNoController,
                                  hintText: 'e.g. 12',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Road / Street',
                                  controller: _roadController,
                                  hintText: 'e.g. 4',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Flat / Floor',
                                  controller: _flatNoController,
                                  hintText: 'e.g. 3B',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Additional delivery notes
                          _buildInputField(
                            label: 'Additional Delivery Notes',
                            controller: _deliveryNotesController,
                            hintText: 'Landmark, gate color, or instruction for rider...',
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Section 3: Delivery Time (Compact & Elegant)
                      if (_deliveryType == 'local') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.access_time_rounded, size: 15, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Delivery Time',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '• কখন ডেলিভারি চান?',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Segmented Options: Normal vs Pre-order
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeModeButton(
                                        mode: 'normal',
                                        icon: Icons.bolt_rounded,
                                        label: 'Normal (ASAP)',
                                        sub: 'যত দ্রুত সম্ভব',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: _buildTimeModeButton(
                                        mode: 'preorder',
                                        icon: Icons.calendar_today_rounded,
                                        label: 'Pre-order',
                                        sub: 'আগামীকাল ডেলিভারি',
                                        badge: 'Tomorrow',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Slim inline toggle for specific delivery time
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _wantsCustomTime = !_wantsCustomTime;
                                    if (!_wantsCustomTime) _selectedCustomTime = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _wantsCustomTime
                                        ? AppColors.primary.withValues(alpha: 0.05)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _wantsCustomTime
                                          ? AppColors.primary.withValues(alpha: 0.3)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: _wantsCustomTime ? AppColors.primary : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'নির্দিষ্ট সময়ে ডেলিভারি চান?',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: _wantsCustomTime ? AppColors.primaryDark : const Color(0xFF334155),
                                              ),
                                            ),
                                            Text(
                                              _wantsCustomTime
                                                  ? 'নিচের সুবিধাজনক সময় সিলেক্ট করুন'
                                                  : 'না দিলে সুবিধাজনক সময়ে দ্রুত ডেলিভারি হবে',
                                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: 0.72,
                                        child: Switch(
                                          value: _wantsCustomTime,
                                          activeThumbColor: Colors.white,
                                          activeTrackColor: AppColors.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (val) {
                                            setState(() {
                                              _wantsCustomTime = val;
                                              if (!val) _selectedCustomTime = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Time slots if toggled
                              if (_wantsCustomTime) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    '09:00 AM - 11:00 AM',
                                    '11:00 AM - 01:00 PM',
                                    '02:00 PM - 04:00 PM',
                                    '04:00 PM - 06:00 PM',
                                  ].map((timeSlot) {
                                    final isSelected = _selectedCustomTime == timeSlot;
                                    return InkWell(
                                      onTap: () => setState(() => _selectedCustomTime = timeSlot),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primary : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Text(
                                          timeSlot,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? Colors.white : const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Section 4: Payment Method (Compact single row)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.payment_rounded, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 5),
                                  Text(
                                    'Cash on Delivery',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Section 5: Coupon Code (Clean 1-line bar matching web)
                      _buildCouponSection(cartState),
                      const SizedBox(height: 12),

                      // Section 6: Payment Summary & Item Preview
                      _buildPaymentSummary(
                        cartState: cartState,
                        items: items,
                        subtotal: subtotal,
                        shippingCharge: _shippingCharge,
                        couponDiscount: couponDiscount,
                        grandTotal: grandTotal,
                      ),
                      const SizedBox(height: 12),

                      // Outside Barisal location notice (matching web)
                      _buildOutsideBarisalNotice(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom Bar with Total & Confirm Button
            _buildBottomBar(grandTotal),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSmartUpsellNudge(double subtotal) {
    final shippingConfig = ref.watch(homeDataProvider).value?.shippingConfig;
    final freeShippingThreshold = (shippingConfig?.freeDeliveryThreshold ?? 5000).toDouble();
    final isFreeShipping = subtotal >= freeShippingThreshold;
    final needed = (freeShippingThreshold - subtotal).toInt().clamp(0, freeShippingThreshold.toInt());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isFreeShipping ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFreeShipping ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFreeShipping ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
            size: 18,
            color: isFreeShipping ? const Color(0xFF15803D) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFreeShipping
                  ? '🎉 Congratulations! Free Delivery unlocked for this order!'
                  : 'Add ৳$needed more to enjoy FREE Delivery in Barisal!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isFreeShipping ? const Color(0xFF15803D) : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabelChip(String value, String text, IconData icon) {
    final isSelected = _addressLabel == value;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? AppColors.primary : const Color(0xFF64748B),
      ),
      label: Text(text),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundColor: const Color(0xFFF8FAFC),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? AppColors.primary : const Color(0xFF475569),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
        ),
      ),
      showCheckmark: false,
      onSelected: (_) => setState(() => _addressLabel = value),
    );
  }

  // ignore: unused_element
  Widget _buildDeliveryTypeOption({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _deliveryType == type;
    return InkWell(
      onTap: () {
        setState(() => _deliveryType = type);
        _recalculateShipping();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeModeButton({
    required String mode,
    required IconData icon,
    required String label,
    required String sub,
    String? badge,
  }) {
    final isSelected = _orderMode == mode;
    return InkWell(
      onTap: () => setState(() => _orderMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.primaryDark : const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(CartState cartState) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_offer_rounded, size: 15, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Coupon Code',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  AvailableCouponsBottomSheet.show(
                    context,
                    currentSubtotal: cartState.subtotal,
                    onApplyCoupon: (code) => _applyCouponFromInput(code),
                    onManualCodeRequested: () => _couponFocusNode.requestFocus(),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Text('🎟️', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4),
                      Text(
                        'Available Coupons',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (cartState.appliedCoupon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cartState.appliedCoupon!.code,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(-৳${cartState.couponDiscount.toInt()} saved)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(cartNotifierProvider.notifier).removeCoupon();
                      SnackbarUtils.showInfo(context, 'Coupon removed');
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _couponInputController,
                    focusNode: _couponFocusNode,
                    hintText: 'Enter coupon code',
                    textCapitalization: TextCapitalization.characters,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      letterSpacing: 0.8,
                    ),
                    onSubmitted: (_) => _applyCouponFromInput(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: cartState.isApplyingCoupon ? null : () => _applyCouponFromInput(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: cartState.isApplyingCoupon
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Apply', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'কুপন কোড বড় হাতের অক্ষরে লিখুন',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
                GestureDetector(
                  onTap: () {
                    AvailableCouponsBottomSheet.show(
                      context,
                      currentSubtotal: cartState.subtotal,
                      onApplyCoupon: (code) => _applyCouponFromInput(code),
                      onManualCodeRequested: () => _couponFocusNode.requestFocus(),
                    );
                  },
                  child: const Text(
                    'কুপন তালিকা দেখুন →',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSummary({
    required CartState cartState,
    required List<CartItem> items,
    required double subtotal,
    required double shippingCharge,
    required double couponDiscount,
    required double grandTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Summary',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              InkWell(
                onTap: () => setState(() => _showItemsPreview = !_showItemsPreview),
                child: Row(
                  children: [
                    Text(
                      '${items.length} ${items.length == 1 ? "item" : "items"}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    Icon(
                      _showItemsPreview ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_showItemsPreview) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final it = items[i];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.quantity}× ${it.product.name}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '৳${it.totalPrice.toInt()}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          _buildSummaryRow('Subtotal', '৳${subtotal.toInt()}'),
          const SizedBox(height: 6),
          _buildSummaryRow(
            'Delivery Charge',
            _isLoadingShipping
                ? 'Calculating...'
                : shippingCharge == 0
                    ? 'FREE'
                    : '৳${shippingCharge.toInt()}',
            isFree: shippingCharge == 0,
          ),
          if (couponDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Coupon Discount',
              '-৳${couponDiscount.toInt()}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              Text(
                '৳${grandTotal.toInt()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isFree = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFree
                ? AppColors.primary
                : isDiscount
                    ? const Color(0xFF15803D)
                    : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: hintText,
      icon: icon,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildOutsideBarisalNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'বরিশাল শহরের বাইরে থেকে অর্ডার করছেন?',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'অর্ডারের পর আমাদের ডেলিভারি টিম আপনার ডেলিভারি ঠিকানা ও রিসিভার নিশ্চিত করতে ফোনে যোগাযোগ করতে পারে।',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.35,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _openCartDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MiniCartBottomSheet(
        checkoutButtonText: 'Back to Checkout',
        onProceedToCheckout: () {
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Widget _buildBottomBar(double grandTotal) {
    final cartState = ref.watch(cartNotifierProvider);
    final totalCount = cartState.totalCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Cart button to view added products
              Tooltip(
                message: 'View Cart Items',
                child: InkWell(
                  onTap: _openCartDetails,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Center(
                      child: Badge(
                        isLabelVisible: totalCount > 0,
                        label: Text(
                          '$totalCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFF1E293B),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Total Payable text & amount (also clickable to view cart)
              InkWell(
                onTap: _openCartDetails,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Total Payable', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Color(0xFF64748B)),
                      ],
                    ),
                    Text(
                      '৳${grandTotal.toInt()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePlaceOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Confirm Order • ৳${grandTotal.toInt()}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'By placing your order, you agree to our Terms & Conditions',
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
