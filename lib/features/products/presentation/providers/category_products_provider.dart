import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_model.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ProductRemoteDataSourceImpl(dioClient: dioClient);
});

class CategoryProductsState {
  final List<ProductModel> products;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;

  const CategoryProductsState({
    this.products = const [],
    this.page = 1,
    this.limit = 12,
    this.total = 0,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
  });

  CategoryProductsState copyWith({
    List<ProductModel>? products,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
  }) {
    return CategoryProductsState(
      products: products ?? this.products,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class CategoryProductsNotifier extends Notifier<CategoryProductsState> {
  final String slug;

  CategoryProductsNotifier(this.slug);

  @override
  CategoryProductsState build() {
    Future.microtask(() => loadInitial());
    return const CategoryProductsState(isLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      final dataSource = ref.read(productRemoteDataSourceProvider);
      final res = await dataSource.getProductsByCategorySlug(
        slug: slug,
        page: 1,
        limit: 12,
      );

      final hasMore = res.page < res.totalPages;

      state = state.copyWith(
        products: res.products,
        page: res.page,
        limit: res.limit,
        total: res.total,
        totalPages: res.totalPages,
        hasMore: hasMore,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      state = state.copyWith(
        isLoading: false,
        error: msg,
        hasMore: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.page + 1;
      final dataSource = ref.read(productRemoteDataSourceProvider);
      final res = await dataSource.getProductsByCategorySlug(
        slug: slug,
        page: nextPage,
        limit: 12,
      );

      // Merge avoiding duplicates (just like web frontend merge logic)
      final existingIds = state.products.map((p) => p.id).toSet();
      final newUnique = res.products.where((p) => !existingIds.contains(p.id)).toList();

      final combined = [...state.products, ...newUnique];
      final hasMore = res.page < res.totalPages;

      state = state.copyWith(
        products: combined,
        page: res.page,
        total: res.total,
        totalPages: res.totalPages,
        hasMore: hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final categoryProductsProvider =
    NotifierProvider.autoDispose.family<CategoryProductsNotifier, CategoryProductsState, String>(
  (arg) => CategoryProductsNotifier(arg),
);
