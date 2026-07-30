
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/const/app_data.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/category_model.dart';
import 'package:split_trip/data/service/shared_preferences_service.dart';


class CategoryController extends GetxController {
  final RxList<DBCategory> categories = <DBCategory>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    try {
      final dbCategories = await DatabaseHelper.instance.getAll(
        table: DBConstants.categoriesTable,
        orderBy: '${DBConstants.createdAt} ASC',
      );

      if (dbCategories.isEmpty) {
        // Pre-populate with default categories!
        await _prepopulateDefaultCategories();
        await loadCategories(); // reload after prepopulating
      } else {
        final List<DBCategory> loaded = dbCategories
            .map((map) => DBCategory.fromMap(map))
            .toList();

        final SharedPreferencesService prefs =
            Get.find<SharedPreferencesService>();
        final orderList = prefs.getStringList("category_sort_order");

        if (orderList.isNotEmpty) {
          loaded.sort((a, b) {
            final aIdStr = a.id?.toString() ?? "";
            final bIdStr = b.id?.toString() ?? "";
            int aIndex = orderList.indexOf(aIdStr);
            int bIndex = orderList.indexOf(bIdStr);
            if (aIndex == -1) aIndex = 9999;
            if (bIndex == -1) bIndex = 9999;
            return aIndex.compareTo(bIndex);
          });
        }
        categories.value = loaded;
      }
    } catch (e) {
      debugPrint("Error loading categories: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory({
    required String name,
    required String iconName,
    required Color color,
  }) async {
    final now = DateTime.now().toIso8601String();
    final newCat = DBCategory(
      name: name,
      iconName: iconName,
      colorValue: color.toARGB32(),
    );

    final values = newCat.toMap();
    values[DBConstants.createdAt] = now;
    values[DBConstants.updatedAt] = now;

    await DatabaseHelper.instance.insert(
      table: DBConstants.categoriesTable,
      values: values,
    );

    await loadCategories(); // refresh list
  }

  Future<void> updateCategory(DBCategory category) async {
    final now = DateTime.now().toIso8601String();
    final values = category.toMap();
    values[DBConstants.updatedAt] = now;

    await DatabaseHelper.instance.update(
      table: DBConstants.categoriesTable,
      values: values,
      where: '${DBConstants.id} = ?',
      args: [category.id],
    );
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseHelper.instance.delete(
      table: DBConstants.categoriesTable,
      where: '${DBConstants.id} = ?',
      args: [id],
    );
    await loadCategories();
  }

  Future<void> reorderCategory(
    int oldIndex,
    int newIndex,
  ) async {
    final list = [...categories];
    if (list.isEmpty) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex > list.length) return;

    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final SharedPreferencesService prefs = Get.find<SharedPreferencesService>();
    final newOrder = list
        .map((cat) => cat.id?.toString() ?? "")
        .where((idStr) => idStr.isNotEmpty)
        .toList();
    await prefs.setStringList("category_sort_order", newOrder);

    categories.value = list;
  }

  Future<void> _prepopulateDefaultCategories() async {
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> defaultValues = [];

    final defaultExpenses = AppData.defaultExpenses;

    for (final item in defaultExpenses) {
      defaultValues.add({
        DBConstants.categoryName: item["name"],
        DBConstants.categoryIconName: item["iconName"],
        DBConstants.categoryColorValue: item["color"],
        DBConstants.createdAt: now,
        DBConstants.updatedAt: now,
      });
    }

    await DatabaseHelper.instance.insertBatch(
      table: DBConstants.categoriesTable,
      values: defaultValues,
    );
  }
}
