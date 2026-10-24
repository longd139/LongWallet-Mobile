import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../core/services/supabase_service.dart';

class CategoryProvider extends ChangeNotifier {
  final SupabaseService? _injectedService;

  CategoryProvider({SupabaseService? supabaseService})
      : _injectedService = supabaseService;

  SupabaseService get _supabaseService => _injectedService ?? SupabaseService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == 'EXPENSE').toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == 'INCOME').toList();

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _supabaseService.getCategories();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory({
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    try {
      final newCat = await _supabaseService.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      _categories.add(newCat);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding category: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required String type,
    required String icon,
    required String color,
  }) async {
    try {
      final updatedCat = await _supabaseService.updateCategory(
        id: id,
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      final index = _categories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _categories[index] = updatedCat;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating category: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _supabaseService.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting category: $e');
      notifyListeners();
      return false;
    }
  }
}
