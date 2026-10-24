import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';
import '../widgets/order_cancel_modal.dart';
import '../widgets/order_card.dart';
import '../widgets/order_details_modal.dart';
import 'track_order_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final ScrollController _scrollController = ScrollController();

  static const List<_FilterTab> _tabs = [
    _FilterTab(key: 'all', label: 'All Orders', banglaLabel: 'সবগুলো'),
    _FilterTab(key: 'pending', label: 'Pending', banglaLabel: 'পেন্ডিং'),
    _FilterTab(key: 'confirmed', label: 'Confirmed', banglaLabel: 'কনফার্মড'),
    _FilterTab(key: 'processing', label: 'Processing', banglaLabel: 'প্রসেসিং'),
    _FilterTab(
        key: 'out_for_delivery',
        label: 'Out for Delivery',
        banglaLabel: 'ডেলিভারিতে'),
    _FilterTab(key: 'delivered', label: 'Delivered', banglaLabel: 'ডেলিভার্ড'),
    _FilterTab(key: 'cancelled', label: 'Cancelled', banglaLabel: 'বাতিল'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderNotifierProvider.notifier).fetchOrders();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(orderNotifierProvider.notifier).loadMore();
    }
  }

  void _selectTab(String key) {
    ref.read(orderNotifierProvider.notifier).fetchOrders(status: key);
  }

  Future<void> _handleRefresh() async {
    await ref.read(orderNotifierProvider.notifier).fetchOrders(refresh: true);
  }

  void _showCancelModal(OrderModel order) {
    OrderCancelModal.show(
      context,
      order: order,
      onConfirmCancel: (reason) async {
        final success = await ref
            .read(orderNotifierProvider.notifier)
            .cancelOrder(orderId: order.id, reason: reason);
        if (mounted) {
          if (success) {
            SnackbarUtils.showSuccess(
                context, 'Order #${order.orderNumber} cancelled successfully.');
          } else {
            final error = ref.read(orderNotifierProvider).errorMessage ??
                'Failed to cancel order';
            SnackbarUtils.showError(context, error);
          }
        }
        return success;
      },
    );
  }

  void _showDetailsModal(OrderModel order) {
    OrderDetailsModal.show(
      context,
      order: order,
      onTrackTap: () => _showTrackModal(order),
      onCancelTap: order.canCancel ? () => _showCancelModal(order) : null,
    );
  }

  void _showTrackModal(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackOrderScreen(initialOrderNumber: order.orderNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            if (state.totalOrders > 0)
              Text(
                'মোট ${state.totalOrders} টি অর্ডার পাওয়া গেছে',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: state.isLoading ? null : _handleRefresh,
            tooltip: 'Refresh Orders',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final isSelected = state.selectedStatus == tab.key;

                  return InkWell(
                    onTap: () => _selectTab(tab.key),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: state.isLoading && state.orders.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : state.orders.isEmpty
                ? _buildEmptyState(state)
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount:
                        state.orders.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.orders.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      final order = state.orders[index];
                      return OrderCard(
                        order: order,
                        onDetailsTap: () => _showDetailsModal(order),
                        onTrackTap: () => _showTrackModal(order),
                        onCancelTap: order.canCancel
                            ? () => _showCancelModal(order)
                            : null,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(OrderState state) {
    final isFiltered = state.selectedStatus != 'all';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 44,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No matching orders' : 'No orders yet!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'There are no orders found with the "${state.selectedStatus}" status.'
                  : 'You have not placed any orders yet. Start exploring fresh vegetables and groceries today!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (isFiltered)
              OutlinedButton.icon(
                onPressed: () => _selectTab('all'),
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('View All Orders'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.shopping_basket_rounded, size: 16),
                label: const Text('Start Shopping'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab {
  final String key;
  final String label;
  final String banglaLabel;

  const _FilterTab({
    required this.key,
    required this.label,
    required this.banglaLabel,
  });
}
