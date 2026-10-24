import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';
import 'my_orders_screen.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  final String? initialOrderNumber;

  const TrackOrderScreen({
    super.key,
    this.initialOrderNumber,
  });

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  OrderModel? _currentOrder;

  // Master status steps matching web
  static const List<_StatusStepDef> _statusSteps = [
    _StatusStepDef(
      key: 'pending',
      label: 'Order Placed',
      subLabel: 'অর্ডার গৃহীত',
      icon: Icons.receipt_long_rounded,
    ),
    _StatusStepDef(
      key: 'confirmed',
      label: 'Confirmed',
      subLabel: 'নিশ্চিত করা হয়েছে',
      icon: Icons.check_circle_outline_rounded,
    ),
    _StatusStepDef(
      key: 'assigned',
      label: 'Rider Assigned',
      subLabel: 'রাইডার নিয়োগপ্রাপ্ত',
      icon: Icons.person_outline_rounded,
    ),
    _StatusStepDef(
      key: 'processing',
      label: 'Packing & Ready',
      subLabel: 'প্রস্তুতকরণ চলছে',
      icon: Icons.inventory_2_outlined,
    ),
    _StatusStepDef(
      key: 'out_for_delivery',
      label: 'Out for Delivery',
      subLabel: 'ডেলিভারির পথে',
      icon: Icons.local_shipping_outlined,
    ),
    _StatusStepDef(
      key: 'delivered',
      label: 'Delivered',
      subLabel: 'ডেলিভারি সম্পন্ন',
      icon: Icons.check_circle_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderNumber != null &&
        widget.initialOrderNumber!.isNotEmpty) {
      _searchController.text = widget.initialOrderNumber!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _trackOrder(widget.initialOrderNumber!);
      });
    }

    // Load recent orders if user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authNotifierProvider).isAuthenticated) {
        ref.read(orderNotifierProvider.notifier).fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _trackOrder(String orderQuery) async {
    final query = orderQuery.trim();
    if (query.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your Order Number or ID');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = ref.read(orderRemoteDataSourceProvider);
      final order = await dataSource.getOrderTracking(query);
      if (mounted) {
        setState(() {
          _currentOrder = order;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _currentOrder = null;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentOrder = null;
          _errorMessage =
              'We couldn\'t find an order matching that number. Please verify and try again.';
          _isLoading = false;
        });
      }
    }
  }

  int _getStatusIndex(String status) {
    final cleanStatus = status.toLowerCase();
    if (cleanStatus == 'shipped') return 3; // map shipped to packing/ready
    return _statusSteps.indexWhere((s) => s.key == cleanStatus);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        SnackbarUtils.showInfo(context, 'Call $phone');
      }
    }
  }

  void _showCancelOrderModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CancelOrderBottomSheet(
        order: order,
        onCancelled: () {
          _trackOrder(order.orderNumber);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderNotifierProvider);
    final recentOrders = orderState.orders.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Track Order',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'লাইভ অর্ডার ট্র্যাকিং',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          if (_currentOrder != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              tooltip: 'Refresh Status',
              onPressed: _isLoading
                  ? null
                  : () => _trackOrder(_searchController.text),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =========================
            // Search Bar Card
            // =========================
            _buildSearchCard(recentOrders),
            const SizedBox(height: 16),

            // =========================
            // Loading State
            // =========================
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Loading order tracking details...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              )
            // =========================
            // Error / Not Found State
            // =========================
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Order Not Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('View My Orders'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MyOrdersScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            // =========================
            // Order Tracking Details
            // =========================
            else if (_currentOrder != null) ...[
              _buildHeaderSummaryCard(_currentOrder!),
              const SizedBox(height: 16),
              _buildTimelineCard(_currentOrder!),
              if (_currentOrder!.assignedRider != null) ...[
                const SizedBox(height: 16),
                _buildRiderCard(_currentOrder!.assignedRider!),
              ],
              const SizedBox(height: 16),
              _buildAddressAndFinancials(_currentOrder!),
              const SizedBox(height: 16),
              _buildItemsCard(_currentOrder!),
            ] else
              // Initial Prompt when nothing is searched yet
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Track Your Grocery Delivery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Enter your Order Number above to see live updates, packing stage, and assigned rider details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Search Card Widget
  // =========================
  Widget _buildSearchCard(List<OrderModel> recentOrders) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _trackOrder,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Enter Order Number (e.g. ORD-12345)...',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _trackOrder(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text(
                  'Track',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          // Quick Select Recent Orders (if available)
          if (recentOrders.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            const Text(
              'RECENT ORDERS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: recentOrders.map((rec) {
                  final isSelected =
                      _searchController.text.trim() == rec.orderNumber;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        _searchController.text = rec.orderNumber;
                        _trackOrder(rec.orderNumber);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          '#${rec.orderNumber} • ৳${rec.totalAmount.toInt()}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================
  // 1. Header Summary Card
  // =========================
  Widget _buildHeaderSummaryCard(OrderModel order) {
    final statusColor = _getStatusColors(order.status);
    final isCancellable = order.canCancel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Order ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '#${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Placed on ${DateFormat('dd MMM yyyy, h:mm a').format(order.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor.text,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isCancellable) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => _showCancelOrderModal(order),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Text(
                    'Cancel Order',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Meta Row: Total, Payment, Delivery Type, Est Time
          Row(
            children: [
              Expanded(
                child: _buildMetaCol(
                  'Total Amount',
                  '৳${order.totalAmount.toInt()}',
                  highlight: true,
                ),
              ),
              Expanded(
                child: _buildMetaCol(
                  'Payment',
                  '${order.paymentMethod.toUpperCase()} • ${order.paymentStatus.toUpperCase()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetaCol(
                  'Delivery Type',
                  order.deliveryType.toUpperCase(),
                ),
              ),
              Expanded(
                child: _buildMetaCol(
                  'Est. Delivery',
                  order.estimatedDelivery != null
                      ? DateFormat('dd MMM').format(order.estimatedDelivery!)
                      : 'Same Day',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCol(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
            color: highlight ? AppColors.primary : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // =========================
  // 2. Timeline Card Widget
  // =========================
  Widget _buildTimelineCard(OrderModel order) {
    final currentIdx = _getStatusIndex(order.status);
    final isCancelled = order.status.toLowerCase() == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Delivery Status Timeline',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Live Updates',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Vertical Stepper
          Column(
            children: List.generate(_statusSteps.length, (idx) {
              final step = _statusSteps[idx];
              final isCompleted = !isCancelled && idx <= currentIdx;
              final isActive = !isCancelled && idx == currentIdx;
              final isLast = idx == _statusSteps.length - 1;

              final timelineEntry = order.statusTimeline.cast<OrderTimelineModel?>().firstWhere(
                    (t) => t?.status.toLowerCase() == step.key,
                    orElse: () => null,
                  );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicator column with line
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : isActive
                                  ? const Color(0xFFEBF5E1)
                                  : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted || isActive
                                ? AppColors.primary
                                : const Color(0xFFE2E8F0),
                            width: isActive ? 2 : 1.5,
                          ),
                        ),
                        child: Icon(
                          step.icon,
                          size: 16,
                          color: isCompleted
                              ? Colors.white
                              : isActive
                                  ? AppColors.primary
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          color: isCompleted && idx < currentIdx
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Step details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCompleted || isActive
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isCompleted || isActive
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              if (timelineEntry?.changedAt != null)
                                Text(
                                  DateFormat('dd MMM, h:mm a')
                                      .format(timelineEntry!.changedAt!),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF94A3B8),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.subLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          if (timelineEntry?.note != null &&
                              timelineEntry!.note!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Text(
                                timelineEntry.note!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

          // Cancelled Notice Banner
          if (isCancelled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Cancelled',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        if (order.cancelReason != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Reason: ${order.cancelReason}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                        if (order.paymentStatus.toLowerCase() == 'refunded') ...[
                          const SizedBox(height: 4),
                          const Text(
                            '✓ Refund Processed: The paid amount has been scheduled for refund.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================
  // 3. Assigned Rider Card
  // =========================
  Widget _buildRiderCard(RiderModel rider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Delivery Rider Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Assigned 🛵',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (rider.fullName?.isNotEmpty == true)
                        ? rider.fullName![0].toUpperCase()
                        : 'R',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.fullName ?? 'Delivery Associate',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vehicle: ${rider.vehicleType ?? 'Bike'}${rider.vehicleNumber != null ? ' (${rider.vehicleNumber})' : ''}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (rider.phone != null && rider.phone!.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 14),
                    label: const Text(
                      'Call',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _callPhone(rider.phone!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 4. Delivery Address & Financials
  // =========================
  Widget _buildAddressAndFinancials(OrderModel order) {
    return Column(
      children: [
        // Address Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (order.deliveryAddress != null) ...[
                Text(
                  order.deliveryAddress!.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.deliveryAddress!.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.deliveryAddress!.fullAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
                if (order.deliveryAddress!.deliveryNotes != null &&
                    order.deliveryAddress!.deliveryNotes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note: ${order.deliveryAddress!.deliveryNotes}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ] else
                const Text(
                  'Address details unavailable',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Financials Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.credit_card_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Order Financials',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBillRow('Subtotal (${order.items.length} items)',
                  '৳${order.subtotal.toInt()}'),
              if (order.couponDiscount > 0) ...[
                const SizedBox(height: 6),
                _buildBillRow('Coupon Discount',
                    '-৳${order.couponDiscount.toInt()}',
                    isDiscount: true),
              ],
              const SizedBox(height: 6),
              _buildBillRow(
                  'Shipping Fee', '৳${order.shippingCharge.toInt()}'),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Payable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '৳${order.totalAmount.toInt()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
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

  Widget _buildBillRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDiscount ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDiscount ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // =========================
  // 5. Items Card
  // =========================
  Widget _buildItemsCard(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Order Items (${order.items.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (ctx, index) {
              final item = order.items[index];
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: const Color(0xFFF8FAFC),
                        child: item.thumbnail.isNotEmpty
                            ? Image.network(
                                item.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 20,
                                  color: Color(0xFF94A3B8),
                                ),
                              )
                            : const Icon(
                                Icons.eco_rounded,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: ${item.quantity} ${item.unit ?? 'pcs'} • ৳${item.salePrice > 0 ? item.salePrice.toInt() : item.unitPrice.toInt()} each',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '৳${item.totalPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  _StatusColor _getStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const _StatusColor(
          bg: Color(0xFFFFFBEB),
          text: Color(0xFFB45309),
          border: Color(0xFFFDE68A),
        );
      case 'confirmed':
        return const _StatusColor(
          bg: Color(0xFFEFF6FF),
          text: Color(0xFF1D4ED8),
          border: Color(0xFFBFDBFE),
        );
      case 'assigned':
        return const _StatusColor(
          bg: Color(0xFFEEF2FF),
          text: Color(0xFF4338CA),
          border: Color(0xFFC7D2FE),
        );
      case 'processing':
      case 'shipped':
        return const _StatusColor(
          bg: Color(0xFFFAF5FF),
          text: Color(0xFF7E22CE),
          border: Color(0xFFE9D5FF),
        );
      case 'out_for_delivery':
      case 'out for delivery':
        return const _StatusColor(
          bg: Color(0xFFFFF7ED),
          text: Color(0xFFC2410C),
          border: Color(0xFFFED7AA),
        );
      case 'delivered':
        return const _StatusColor(
          bg: Color(0xFFECFDF5),
          text: Color(0xFF047857),
          border: Color(0xFFA7F3D0),
        );
      case 'cancelled':
        return const _StatusColor(
          bg: Color(0xFFFEF2F2),
          text: Color(0xFFB91C1C),
          border: Color(0xFFFECACA),
        );
      default:
        return const _StatusColor(
          bg: Color(0xFFF1F5F9),
          text: Color(0xFF475569),
          border: Color(0xFFE2E8F0),
        );
    }
  }
}

class _StatusStepDef {
  final String key;
  final String label;
  final String subLabel;
  final IconData icon;

  const _StatusStepDef({
    required this.key,
    required this.label,
    required this.subLabel,
    required this.icon,
  });
}

class _StatusColor {
  final Color bg;
  final Color text;
  final Color border;

  const _StatusColor({
    required this.bg,
    required this.text,
    required this.border,
  });
}

// =========================
// Cancellation Modal
// =========================
class _CancelOrderBottomSheet extends ConsumerStatefulWidget {
  final OrderModel order;
  final VoidCallback onCancelled;

  const _CancelOrderBottomSheet({
    required this.order,
    required this.onCancelled,
  });

  @override
  ConsumerState<_CancelOrderBottomSheet> createState() =>
      _CancelOrderBottomSheetState();
}

class _CancelOrderBottomSheetState
    extends ConsumerState<_CancelOrderBottomSheet> {
  static const List<String> _reasons = [
    'Changed my mind',
    'Ordered wrong product',
    'Found better price elsewhere',
    'Delivery time is too long',
    'Need to change delivery address',
    'Other',
  ];

  String _selectedReason = 'Changed my mind';
  final _customReasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _submitCancel() async {
    final finalReason = _selectedReason == 'Other'
        ? _customReasonController.text.trim()
        : _selectedReason;

    if (finalReason.isEmpty) {
      SnackbarUtils.showError(
          context, 'Please specify a reason for cancellation');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await ref.read(orderNotifierProvider.notifier).cancelOrder(
          orderId: widget.order.id,
          reason: finalReason,
        );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Navigator.pop(context);
        SnackbarUtils.showSuccess(context, 'Order cancelled successfully');
        widget.onCancelled();
      } else {
        final error = ref.read(orderNotifierProvider).errorMessage ??
            'Failed to cancel order';
        SnackbarUtils.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cancel Order #${widget.order.orderNumber}?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Are you sure you want to cancel this order? Once cancelled, items will be released back to stock.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Radio options
          ...List.generate(_reasons.length, (index) {
            final reason = _reasons[index];
            final isSelected = _selectedReason == reason;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedReason = reason;
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1),
                          width: isSelected ? 5.5 : 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          if (_selectedReason == 'Other') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customReasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Please specify reason...',
                hintStyle:
                    const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Keep Order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
