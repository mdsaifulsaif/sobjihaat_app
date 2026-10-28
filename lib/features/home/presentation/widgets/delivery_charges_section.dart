import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/shipping_tier_model.dart';

class DeliveryChargesSection extends StatelessWidget {
  final ShippingConfigModel? shippingConfig;
  final String title;
  final String subtitle;

  const DeliveryChargesSection({
    super.key,
    this.shippingConfig,
    this.title = 'Delivery Charges & Rates',
    this.subtitle = 'Affordable delivery rates based on your order value',
  });

  @override
  Widget build(BuildContext context) {
    final rawTiers = shippingConfig?.tiers ?? ShippingConfigModel.defaultTiers;
    final tiers = rawTiers.isNotEmpty ? rawTiers : ShippingConfigModel.defaultTiers;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _showDeliveryTermsDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Enclosing Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner: 1st Order Free Promo
                _buildTopPromoBanner(),

                // Micro Trust Chips Strip
                _buildTrustChipsRow(),

                // Table Container
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sub-header: Standard Delivery Slabs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 15),
                              SizedBox(width: 5),
                              Text(
                                'STANDARD DELIVERY RATES',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF475569),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Applied automatically',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 2-Column Delivery Charges Table (Matching User's Request)
                      _buildTiersTable(tiers),

                      const SizedBox(height: 10),

                      // Bottom Info Note
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF475569),
                                    height: 1.35,
                                  ),
                                  children: [
                                    TextSpan(text: 'First order is '),
                                    TextSpan(
                                      text: '100% Free Delivery',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(text: '. Regular orders above '),
                                    TextSpan(
                                      text: '৳5,000',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    TextSpan(text: ' qualify for free doorstep delivery.'),
                                  ],
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
          ),
        ],
      ),
    );
  }

  // --- 1. Top Promo Banner: 1st Order Free ---
  Widget _buildTopPromoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF6FAF2),
        border: Border(bottom: BorderSide(color: Color(0xFFE8F0E2))),
      ),
      child: Row(
        children: [
          // Rider icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.two_wheeler_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Promo Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_awesome_rounded, size: 9, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            '1ST ORDER FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '100% Free Delivery',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Zero delivery fee on your very first order at ShodaiBari!',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Micro Trust Badges Row ---
  Widget _buildTrustChipsRow() {
    final chips = [
      (icon: Icons.bolt_rounded, label: '60-Min Delivery'),
      (icon: Icons.verified_user_outlined, label: '100% Fresh'),
      (icon: Icons.location_on_outlined, label: 'Live Tracking'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: chips.map((c) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 11, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  c.label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 3. Compact 2-Column Delivery Charges Table (Exact match to User Request) ---
  Widget _buildTiersTable(List<ShippingTierModel> tiers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header (2 Columns)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: const [
                Expanded(
                  flex: 6,
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 13, color: Color(0xFF64748B)),
                      SizedBox(width: 5),
                      Text(
                        'ORDER VALUE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 13, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text(
                        'DELIVERY FEE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Table Rows (2 Columns per row)
          ...tiers.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;
            final isFree = tier.isFree;
            final isEven = index.isEven;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
              decoration: BoxDecoration(
                color: isFree
                    ? const Color(0xFFF3F9EC)
                    : (isEven ? Colors.white : const Color(0xFFFAFAFA)),
                border: index < tiers.length - 1
                    ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))
                    : null,
              ),
              child: Row(
                children: [
                  // Column 1: Order Range
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [
                        Text(
                          tier.orderRangeText,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isFree ? FontWeight.w800 : FontWeight.w700,
                            color: isFree ? AppColors.primaryDark : const Color(0xFF0F172A),
                          ),
                        ),
                        if (isFree) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FREE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Column 2: Delivery Charge
                  Expanded(
                    flex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: const Text(
                              '৳০ FREE',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Text(
                            tier.chargeText,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Terms & Conditions Modal Dialog
  void _showDeliveryTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: const [
            Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Delivery Policy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildDialogBullet(
                '1st Order Free',
                'Zero delivery fee is automatically applied on every customer\'s first verified order.',
              ),
              const SizedBox(height: 10),
              _buildDialogBullet(
                'Free Over ৳5,000',
                'All regular orders with cart total ৳5,000 or more qualify for 100% free doorstep delivery.',
              ),
              const SizedBox(height: 10),
              _buildDialogBullet(
                '60-Min Express',
                'Delivery times may vary slightly based on traffic, weather, and order preparation.',
              ),
              const SizedBox(height: 10),
              _buildDialogBullet(
                'Subscription Boxes',
                'All curated weekly & monthly subscription boxes always ship with free delivery.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBullet(String heading, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
              children: [
                TextSpan(
                  text: '$heading: ',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
