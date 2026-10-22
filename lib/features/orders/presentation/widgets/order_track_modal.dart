import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';
import 'order_status_badge.dart';

class OrderTrackModal extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderTrackModal({
    super.key,
    required this.order,
  });

  static Future<void> show(BuildContext context, {required OrderModel order}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderTrackModal(order: order),
    );
  }

  @override
  ConsumerState<OrderTrackModal> createState() => _OrderTrackModalState();
}

class _OrderTrackModalState extends ConsumerState<OrderTrackModal> {
  OrderModel? _detailedOrder;

  @override
  void initState() {
    super.initState();
    _detailedOrder = widget.order;
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    final result = await ref
        .read(orderNotifierProvider.notifier)
        .trackOrder(widget.order.orderNumber);
    if (mounted) {
      setState(() {
        if (result != null) {
          _detailedOrder = result;
        }
      });
    }
  }

  int _getStatusStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'out_for_delivery':
      case 'out for delivery':
        return 3;
      case 'delivered':
        return 4;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _detailedOrder ?? widget.order;
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final currentStep = _getStatusStepIndex(order.status);

    final steps = [
      _TrackStep(
        title: 'Order Placed',
        subtitle: 'We have received your order.',
        icon: Icons.receipt_long_rounded,
      ),
      _TrackStep(
        title: 'Order Confirmed',
        subtitle: 'Order verified and sent to processing.',
        icon: Icons.verified_outlined,
      ),
      _TrackStep(
        title: 'Processing & Packing',
        subtitle: 'Fresh produce inspected and safely packed.',
        icon: Icons.inventory_2_outlined,
      ),
      _TrackStep(
        title: 'Out for Delivery',
        subtitle: 'Rider is on the way to your location.',
        icon: Icons.local_shipping_outlined,
      ),
      _TrackStep(
        title: 'Delivered',
        subtitle: 'Order successfully delivered to your doorstep.',
        icon: Icons.check_circle_rounded,
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cancel_rounded,
                              color: Color(0xFFDC2626), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'This order has been cancelled',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                                if (order.cancelReason != null &&
                                    order.cancelReason!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reason: ${order.cancelReason}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Delivery destination preview
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.deliveryAddress?.name ?? 'Customer',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.deliveryAddress?.fullAddress ??
                                    'Standard local delivery',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Timeline steps
                  const Text(
                    'Order Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      final isPassed = !isCancelled && index <= currentStep;
                      final isCurrent = !isCancelled && index == currentStep;
                      final isLast = index == steps.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isPassed
                                      ? AppColors.primary
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isPassed
                                        ? AppColors.primary
                                        : const Color(0xFFCBD5E1),
                                    width: isCurrent ? 3 : 1.5,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  isPassed ? Icons.check : step.icon,
                                  size: 16,
                                  color: isPassed
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 38,
                                  color: (!isCancelled && index < currentStep)
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        step.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isCurrent || isPassed
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isCurrent || isPassed
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Current',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    step.subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPassed
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackStep {
  final String title;
  final String subtitle;
  final IconData icon;

  _TrackStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
