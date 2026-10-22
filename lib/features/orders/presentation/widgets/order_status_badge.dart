import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isSmall ? 12 : 14,
            color: config.textColor,
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  static _BadgeConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const _BadgeConfig(
          label: 'Pending',
          icon: Icons.access_time_rounded,
          backgroundColor: Color(0xFFFFFBEB),
          textColor: Color(0xFFB45309),
          borderColor: Color(0xFFFDE68A),
        );
      case 'confirmed':
        return const _BadgeConfig(
          label: 'Confirmed',
          icon: Icons.check_circle_outline_rounded,
          backgroundColor: Color(0xFFEFF6FF),
          textColor: Color(0xFF1D4ED8),
          borderColor: Color(0xFFBFDBFE),
        );
      case 'processing':
        return const _BadgeConfig(
          label: 'Processing',
          icon: Icons.inventory_2_outlined,
          backgroundColor: Color(0xFFFAF5FF),
          textColor: Color(0xFF7E22CE),
          borderColor: Color(0xFFE9D5FF),
        );
      case 'out_for_delivery':
      case 'out for delivery':
        return const _BadgeConfig(
          label: 'Out for Delivery',
          icon: Icons.local_shipping_outlined,
          backgroundColor: Color(0xFFFFF7ED),
          textColor: Color(0xFFC2410C),
          borderColor: Color(0xFFFED7AA),
        );
      case 'delivered':
        return const _BadgeConfig(
          label: 'Delivered',
          icon: Icons.verified_rounded,
          backgroundColor: Color(0xFFECFDF5),
          textColor: Color(0xFF047857),
          borderColor: Color(0xFFA7F3D0),
        );
      case 'cancelled':
        return const _BadgeConfig(
          label: 'Cancelled',
          icon: Icons.cancel_outlined,
          backgroundColor: Color(0xFFFEF2F2),
          textColor: Color(0xFFB91C1C),
          borderColor: Color(0xFFFECACA),
        );
      default:
        return _BadgeConfig(
          label: status,
          icon: Icons.info_outline_rounded,
          backgroundColor: const Color(0xFFF8FAFC),
          textColor: const Color(0xFF64748B),
          borderColor: const Color(0xFFE2E8F0),
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}
