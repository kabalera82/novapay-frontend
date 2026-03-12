// lib/presentation/controllers/product.controller.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../data/models/product.dart';
import '../../services/product.service.dart';

class ProductController extends GetxController {
  final Isar isar;
  ProductController(this.isar);

  final products         = <Product>[].obs;
  final filtered         = <Product>[].obs;
  final categories       = <String>[].obs;
  final selectedCategory = ''.obs;
  final isLoading        = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    products.value = await getAllProducts(isar);
    _refreshCategories();
    applyFilter(selectedCategory.value);
    isLoading.value = false;
  }

  void _refreshCategories() {
    final cats = products
        .map((p) => p.category ?? 'Sin categoría')
        .toSet()
        .toList()
      ..sort();
    categories.value = ['Todos', ...cats];
  }

  void applyFilter(String category) {
    selectedCategory.value = category;
    if (category.isEmpty || category == 'Todos') {
      filtered.value = products.toList();
    } else {
      filtered.value = products
          .where((p) => (p.category ?? 'Sin categoría') == category)
          .toList();
    }
  }

  void search(String query) {
    if (query.isEmpty) {
      applyFilter(selectedCategory.value);
      return;
    }
    filtered.value = products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> create(Product product) async {
    await createProduct(isar, product);
    await loadAll();
  }

  Future<void> saveProduct(Product product) async {
    await updateProduct(isar, product);
    await loadAll();
  }

  Future<void> remove(int id) async {
    await deleteProduct(isar, id);
    await loadAll();
  }

  Future<void> decrement(int productId, int quantity) async {
    await decrementStock(isar, productId, quantity);
    await loadAll();
  }
}