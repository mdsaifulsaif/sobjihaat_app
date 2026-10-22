import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/models/category_model.dart';
import 'home_provider.dart';

class CategoriesState {
  final List<CategoryModel> categories;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int limit;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const CategoriesState({
    this.categories = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.limit = 10,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => currentPage < totalPages;

  CategoriesState copyWith({
    List<CategoryModel>? categories,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    int? limit,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }
}

class CategoriesNotifier extends Notifier<CategoriesState> {
  @override
  CategoriesState build() {
    Future.microtask(() => fetchInitial());
    return const CategoriesState(isLoading: true);
  }

  HomeRemoteDataSource get _dataSource => ref.read(homeRemoteDataSourceProvider);

  Future<void> fetchInitial({int limit = 6}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, limit: limit);
    try {
      final res = await _dataSource.getPaginatedCategories(
        page: 1,
        limit: limit,
      );
      state = state.copyWith(
        categories: res.categories,
        currentPage: res.page,
        totalPages: res.totalPages,
        totalCount: res.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> goToPage(int targetPage) async {
    if (state.isLoading || targetPage == state.currentPage || targetPage < 1 || targetPage > state.totalPages) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _dataSource.getPaginatedCategories(
        page: targetPage,
        limit: state.limit,
      );
      state = state.copyWith(
        categories: res.categories,
        currentPage: res.page,
        totalPages: res.totalPages,
        totalCount: res.total,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final res = await _dataSource.getPaginatedCategories(
        page: nextPage,
        limit: state.limit,
      );

      // Append avoiding duplicates
      final existingIds = state.categories.map((c) => c.id).toSet();
      final newItems = res.categories.where((c) => !existingIds.contains(c.id)).toList();

      state = state.copyWith(
        categories: [...state.categories, ...newItems],
        currentPage: res.page,
        totalPages: res.totalPages,
        totalCount: res.total,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void showAll() {
    fetchInitial(limit: 100);
  }

  void setLimit(int newLimit) {
    fetchInitial(limit: newLimit);
  }

  Future<void> refresh() async {
    await fetchInitial(limit: state.limit);
  }
}


final categoriesNotifierProvider =
    NotifierProvider<CategoriesNotifier, CategoriesState>(() => CategoriesNotifier());
