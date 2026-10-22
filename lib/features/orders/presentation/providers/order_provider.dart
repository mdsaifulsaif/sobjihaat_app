import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/models/order_model.dart';

class OrderState {
  final List<OrderModel> orders;
  final int totalOrders;
  final int currentPage;
  final int limit;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String selectedStatus;
  final bool isCancelling;
  final String? cancellingOrderId;

  const OrderState({
    this.orders = const [],
    this.totalOrders = 0,
    this.currentPage = 1,
    this.limit = 10,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.selectedStatus = 'all',
    this.isCancelling = false,
    this.cancellingOrderId,
  });

  bool get hasMore => orders.length < totalOrders;

  OrderState copyWith({
    List<OrderModel>? orders,
    int? totalOrders,
    int? currentPage,
    int? limit,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? selectedStatus,
    bool? isCancelling,
    String? cancellingOrderId,
    bool clearError = false,
    bool clearCancellingId = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      totalOrders: totalOrders ?? this.totalOrders,
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedStatus: selectedStatus ?? this.selectedStatus,
      isCancelling: isCancelling ?? this.isCancelling,
      cancellingOrderId: clearCancellingId ? null : (cancellingOrderId ?? this.cancellingOrderId),
    );
  }
}

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return OrderRemoteDataSourceImpl(dioClient: dioClient);
});

final orderNotifierProvider =
    NotifierProvider<OrderNotifier, OrderState>(() {
  return OrderNotifier();
});

class OrderNotifier extends Notifier<OrderState> {
  @override
  OrderState build() {
    return const OrderState();
  }

  OrderRemoteDataSource get _dataSource => ref.read(orderRemoteDataSourceProvider);

  Future<void> fetchOrders({
    String? status,
    bool refresh = false,
  }) async {
    final targetStatus = status ?? state.selectedStatus;

    if (refresh || targetStatus != state.selectedStatus) {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        selectedStatus: targetStatus,
        currentPage: 1,
        orders: refresh && targetStatus == state.selectedStatus ? state.orders : const [],
      );
    } else if (state.isLoading) {
      return;
    }

    try {
      final response = await _dataSource.getMyOrders(
        page: 1,
        limit: state.limit,
        status: targetStatus,
      );

      state = state.copyWith(
        orders: response.orders,
        totalOrders: response.total,
        currentPage: response.page,
        isLoading: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load orders: $e',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final response = await _dataSource.getMyOrders(
        page: nextPage,
        limit: state.limit,
        status: state.selectedStatus,
      );

      final combined = [...state.orders, ...response.orders];
      state = state.copyWith(
        orders: combined,
        totalOrders: response.total,
        currentPage: response.page,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<OrderModel?> trackOrder(String orderNumberOrId) async {
    try {
      return await _dataSource.getOrderTracking(orderNumberOrId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    state = state.copyWith(
      isCancelling: true,
      cancellingOrderId: orderId,
      clearError: true,
    );

    try {
      final updatedOrder = await _dataSource.cancelOrder(
        orderId: orderId,
        reason: reason,
      );

      final updatedList = state.orders.map((o) {
        if (o.id == orderId) {
          return updatedOrder;
        }
        return o;
      }).toList();

      state = state.copyWith(
        orders: updatedList,
        isCancelling: false,
        clearCancellingId: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isCancelling: false,
        clearCancellingId: true,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isCancelling: false,
        clearCancellingId: true,
        errorMessage: 'Failed to cancel order: $e',
      );
      return false;
    }
  }
}
