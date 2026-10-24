import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/complaint_provider.dart';

class ComplaintModal extends ConsumerStatefulWidget {
  const ComplaintModal({super.key});

  /// Static method to display the complaint modal as a styled dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => const ComplaintModal(),
    );
  }

  @override
  ConsumerState<ComplaintModal> createState() => _ComplaintModalState();
}

class _ComplaintModalState extends ConsumerState<ComplaintModal> {
  static const List<String> _subjects = [
    'Product Quality Issue',
    'Delivery Problem',
    'Wrong Item Received',
    'Payment Issue',
    'Customer Service',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedSubject;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Prefill phone number if user is logged in and has phone
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
        final rawPhone = user.phoneNumber!.replaceAll(RegExp(r'\D'), '');
        final phone = rawPhone.length > 11 ? rawPhone.substring(rawPhone.length - 11) : rawPhone;
        _phoneController.text = phone;
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidBDPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(cleaned);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.length();

      // Check max size: 5MB
      if (bytes > 5 * 1024 * 1024) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Image size must be less than 5MB');
        }
        return;
      }

      // Check extension (jpg, jpeg, png)
      final ext = picked.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Only JPG/PNG images are allowed');
        }
        return;
      }

      setState(() {
        _selectedImage = file;
      });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Could not select image: $e');
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _handleSubmit() async {
    // 1. Check Subject
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      SnackbarUtils.showError(context, 'Please select a subject.');
      return;
    }

    // 2. Check Description
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      SnackbarUtils.showError(context, 'Please describe your issue in detail.');
      return;
    }

    // 3. Check Phone Number
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      SnackbarUtils.showError(context, 'Phone number is required.');
      return;
    }

    if (!_isValidBDPhone(phone)) {
      SnackbarUtils.showError(
        context,
        'Please enter a valid Bangladeshi phone number (e.g. 017XXXXXXXX)',
      );
      return;
    }

    // 4. Check Authentication
    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    // 5. Submit to backend
    final success = await ref.read(complaintNotifierProvider.notifier).submitComplaint(
          subject: _selectedSubject!,
          description: description,
          phoneNumber: phone,
          imageFile: _selectedImage,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      SnackbarUtils.showSuccess(context, 'Complaint submitted successfully!');
    } else {
      final error = ref.read(complaintNotifierProvider).errorMessage ??
          'Something went wrong. Please try again.';
      SnackbarUtils.showError(context, error);
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Login Required', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'You need to be logged in to submit a complaint or feedback so our support team can assist you directly.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaintState = ref.watch(complaintNotifierProvider);
    final isLoading = complaintState.status == ComplaintStateStatus.loading;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =========================
                // Header (Matching Screenshot)
                // =========================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Complain / Feedback',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "We're sorry to hear that! Please let us know the details.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        splashRadius: 20,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                // =========================
                // Form Body
                // =========================
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Subject Field
                          _buildLabel('Subject', isRequired: true),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedSubject,
                                hint: const Text(
                                  'Select a subject',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF6B7280),
                                ),
                                items: _subjects.map((subject) {
                                  return DropdownMenuItem<String>(
                                    value: subject,
                                    child: Text(
                                      subject,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSubject = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Description Field
                          _buildLabel('Description', isRequired: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            minLines: 4,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                            decoration: InputDecoration(
                              hintText: 'Please describe your issue in detail...',
                              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Phone Number Field
                          _buildLabel('Phone Number', isRequired: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 11,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '01XXXXXXXXX',
                              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Format: 01XXXXXXXXX (11 digits)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 16),

                          // 4. Attach Image (Optional)
                          Row(
                            children: const [
                              Text(
                                'Attach Image ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              Text(
                                '(Optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (_selectedImage == null)
                            InkWell(
                              onTap: _showImageSourcePicker,
                              borderRadius: BorderRadius.circular(8),
                              child: CustomPaint(
                                painter: DashedBorderPainter(
                                  color: const Color(0xFFD1D5DB),
                                  radius: 8,
                                  dashWidth: 5,
                                  dashSpace: 3,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.file_upload_outlined,
                                        color: Color(0xFF9CA3AF),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Choose File',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF4B5563),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Max size: 5MB (jpg, png)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: _removeImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),

                          // =========================
                          // Bottom Actions (Matching Screenshot)
                          // =========================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Cancel Button
                              OutlinedButton(
                                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Submit Button
                              ElevatedButton(
                                onPressed: isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isLoading
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Submitting...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Submit',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for crisp dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    this.color = const Color(0xFFD1D5DB),
    this.strokeWidth = 1.0,
    this.radius = 8.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        dest.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}
