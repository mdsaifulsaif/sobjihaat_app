import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../../subscriptions/data/models/subscription_package_model.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/models/area_model.dart';
import '../../data/models/banner_model.dart';
import '../../data/models/brand_model.dart';
import '../../data/models/category_model.dart';

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return HomeRemoteDataSourceImpl(dioClient: dioClient);
});

class HomeData {
  final List<BannerModel> banners;
  final List<CategoryModel> categories;
  final List<ProductModel> featuredProducts;
  final List<SubscriptionPackageModel> subscriptionPackages;
  final List<BrandModel> brands;
  final List<AreaModel> areas;

  HomeData({
    this.banners = const [],
    this.categories = const [],
    this.featuredProducts = const [],
    this.subscriptionPackages = const [],
    this.brands = const [],
    this.areas = const [],
  });
}

class SelectedAreaNotifier extends Notifier<String> {
  @override
  String build() => 'Dhaka';

  void setArea(String newArea) => state = newArea;
}

final selectedAreaProvider =
    NotifierProvider<SelectedAreaNotifier, String>(() => SelectedAreaNotifier());

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final dataSource = ref.watch(homeRemoteDataSourceProvider);

  Future<List<BrandModel>> safeGetBrands() async {
    try {
      final dynamic res = await (dataSource as dynamic).getBrands();
      if (res is List) {
        final list = res.whereType<BrandModel>().toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return BrandModel.fallbackBrands;
  }

  final results = await Future.wait([
    dataSource.getBanners().catchError((_) => <BannerModel>[]),
    dataSource.getCategories().catchError((_) => <CategoryModel>[]),
    dataSource.getFeaturedProducts().catchError((_) => <ProductModel>[]),
    dataSource.getSubscriptionPackages().catchError((_) => <SubscriptionPackageModel>[]),
    safeGetBrands(),
    dataSource.getAreas().catchError((_) => <AreaModel>[]),
  ]);

  final banners =
      (results[0] as List<dynamic>?)?.whereType<BannerModel>().toList() ?? <BannerModel>[];
  final categories =
      (results[1] as List<dynamic>?)?.whereType<CategoryModel>().toList() ?? <CategoryModel>[];
  final products =
      (results[2] as List<dynamic>?)?.whereType<ProductModel>().toList() ?? <ProductModel>[];
  final packages = (results[3] as List<dynamic>?)
          ?.whereType<SubscriptionPackageModel>()
          .toList() ??
      <SubscriptionPackageModel>[];
  final brands =
      (results[4] as List<dynamic>?)?.whereType<BrandModel>().toList() ?? BrandModel.fallbackBrands;
  final areas =
      (results[5] as List<dynamic>?)?.whereType<AreaModel>().toList() ?? <AreaModel>[];

  return HomeData(
    banners: banners,
    categories: categories,
    featuredProducts: products,
    subscriptionPackages: packages,
    brands: brands.isNotEmpty ? brands : BrandModel.fallbackBrands,
    areas: areas,
  );
});

