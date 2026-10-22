import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/subscription_package_model.dart';
import 'subscription_setup_modal.dart';

class SubscriptionPackageCard extends StatelessWidget {
  final SubscriptionPackageModel package;
  final bool isMostPopular;
  final VoidCallback? onBuyOnce;

  const SubscriptionPackageCard({
    super.key,
    required this.package,
    this.isMostPopular = false,
    this.onBuyOnce,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMostPopular ? AppColors.primary : AppColors.border,
          width: isMostPopular ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isMostPopular
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isMostPopular ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Plan Pill + Free Shipping
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Red Discount / Plan Pill (#EA4335)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.discountBadge,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        package.badge ?? package.boxType,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (package.freeShipping)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Free Delivery',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Package Title
                Text(
                  package.name,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (package.shortDescription != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    package.shortDescription!,
                    style: AppTypography.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),

                // Pricing
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '৳${package.subscriptionPrice.toInt()}',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${package.frequency}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (package.regularPrice > package.subscriptionPrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        '৳${package.regularPrice.toInt()}',
                        style: AppTypography.bodySmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // "What's Inside" Checklist (All items directly visible with green checks)
                Text(
                  "What's Inside:",
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: package.items.isNotEmpty ? package.items.length : 1,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      if (package.items.isEmpty) {
                        return _buildItemRow('Fresh seasonal vegetables & essentials', null);
                      }
                      final item = package.items[index];
                      return _buildItemRow(item.itemName, item.quantity);
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: "Buy once" & "Subscribe Now"
                Row(
                  children: [
                    if (package.allowOneTimePurchase) ...[
                      Expanded(
                        child: AppButton(
                          text: 'Buy once',
                          isOutlined: true,
                          height: 44,
                          borderRadius: 8,
                          onPressed: onBuyOnce,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 1,
                      child: AppButton(
                        text: 'Subscribe',
                        height: 44,
                        borderRadius: 8,
                        onPressed: () => SubscriptionSetupModal.show(context, package),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // "★ Most Popular" Badge (Positioned at top center only on the middle/recommended plan)
          if (isMostPopular)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'MOST POPULAR',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String name, String? quantity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.primary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            quantity != null && quantity.isNotEmpty ? '$name ($quantity)' : name,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
