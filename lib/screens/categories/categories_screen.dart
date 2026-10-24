import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/category_icon_helper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCategoryDialog({CategoryModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryFormSheet(
        existingCategory: existing,
        onSaved: () {
          // Also refresh budget provider's category list if needed
          context.read<BudgetProvider>().fetchBudgets();
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel category) {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa danh mục mặc định của hệ thống!'),
          backgroundColor: AppTheme.expenseRed,
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận xóa danh mục',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.name}" không? Các giao dịch cũ vẫn sẽ được giữ lại.',
          style: TextStyle(color: isDark ? AppTheme.textMuted : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Hủy',
              style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context.read<CategoryProvider>().deleteCategory(category.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Đã xóa danh mục "${category.name}"' : 'Xóa thất bại, vui lòng thử lại',
                    ),
                    backgroundColor: success ? AppTheme.primaryEmerald : AppTheme.expenseRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> list, String emptyMessage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark.withOpacity(0.4) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 48,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openCategoryDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo danh mục mới'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final cat = list[index];
        final iconData = CategoryIconHelper.getIcon(cat.icon);
        final color = CategoryIconHelper.hexToColor(cat.color);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.cardDark.withOpacity(0.6) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              ),
              child: Icon(iconData, color: color, size: 22),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cat.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Mặc định',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppTheme.textMuted : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              cat.type == 'EXPENSE' ? 'Chi tiêu' : 'Thu nhập',
              style: TextStyle(
                fontSize: 12,
                color: cat.type == 'EXPENSE' ? AppTheme.expenseRed : AppTheme.incomeGreen,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                size: 20,
              ),
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') {
                  _openCategoryDialog(existing: cat);
                } else if (val == 'delete') {
                  _confirmDelete(context, cat);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chỉnh sửa',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!cat.isDefault)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppTheme.expenseRed),
                        SizedBox(width: 8),
                        Text('Xóa danh mục', style: TextStyle(color: AppTheme.expenseRed)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryEmerald,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryEmerald,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_downward_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Chi tiêu (${categoryProvider.expenseCategories.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text('Thu nhập (${categoryProvider.incomeCategories.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: categoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(categoryProvider.expenseCategories, 'Chưa có danh mục chi tiêu nào'),
                _buildCategoryList(categoryProvider.incomeCategories, 'Chưa có danh mục thu nhập nào'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryDialog(),
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm danh mục', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? existingCategory;
  final VoidCallback onSaved;

  const _CategoryFormSheet({
    this.existingCategory,
    required this.onSaved,
  });

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _nameController = TextEditingController();
  late String _selectedType;
  late String _selectedIconKey;
  late String _selectedColorHex;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      _nameController.text = widget.existingCategory!.name;
      _selectedType = widget.existingCategory!.type;
      _selectedIconKey = widget.existingCategory!.icon;
      _selectedColorHex = widget.existingCategory!.color;
    } else {
      _selectedType = 'EXPENSE';
      _selectedIconKey = 'restaurant';
      _selectedColorHex = '#EF4444';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên danh mục'),
          backgroundColor: AppTheme.expenseRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<CategoryProvider>();
    bool success = false;

    if (widget.existingCategory != null) {
      success = await provider.updateCategory(
        id: widget.existingCategory!.id,
        name: name,
        type: _selectedType,
        icon: _selectedIconKey,
        color: _selectedColorHex,
      );
    } else {
      success = await provider.addCategory(
        name: name,
        type: _selectedType,
        icon: _selectedIconKey,
        color: _selectedColorHex,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingCategory != null
                ? 'Đã cập nhật danh mục "$name"'
                : 'Đã tạo danh mục "$name"'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Thao tác thất bại, vui lòng thử lại'),
            backgroundColor: AppTheme.expenseRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingCategory != null;
    final currentIcon = CategoryIconHelper.getIcon(_selectedIconKey);
    final currentColor = CategoryIconHelper.hexToColor(_selectedColorHex);
    final currentIcons = _selectedType == 'EXPENSE'
        ? CategoryIconHelper.expenseIcons
        : CategoryIconHelper.incomeIcons;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bar drag indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? AppTheme.textMuted : const Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Preview Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark.withOpacity(0.4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? currentColor.withOpacity(0.3) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: currentColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: currentColor, width: 2),
                    ),
                    child: Icon(currentIcon, color: currentColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.trim().isEmpty
                              ? 'Tên danh mục...'
                              : _nameController.text.trim(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (_selectedType == 'EXPENSE'
                                        ? AppTheme.expenseRed
                                        : AppTheme.incomeGreen)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedType == 'EXPENSE' ? 'Chi tiêu' : 'Thu nhập',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == 'EXPENSE'
                                      ? AppTheme.expenseRed
                                      : AppTheme.incomeGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Type Segment
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark.withOpacity(0.6) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = 'EXPENSE';
                          if (!isEditing && _selectedColorHex == '#10B981') {
                            _selectedColorHex = '#EF4444';
                          }
                          if (!CategoryIconHelper.expenseIcons.any((i) => i.key.toLowerCase() == _selectedIconKey.toLowerCase())) {
                            _selectedIconKey = 'restaurant';
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == 'EXPENSE'
                              ? AppTheme.expenseRed
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Chi tiêu',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == 'EXPENSE'
                                ? Colors.white
                                : (isDark ? AppTheme.textMuted : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = 'INCOME';
                          if (!isEditing && _selectedColorHex == '#EF4444') {
                            _selectedColorHex = '#10B981';
                          }
                          if (!CategoryIconHelper.incomeIcons.any((i) => i.key.toLowerCase() == _selectedIconKey.toLowerCase())) {
                            _selectedIconKey = 'payments';
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == 'INCOME'
                              ? AppTheme.incomeGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Thu nhập',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == 'INCOME'
                                ? Colors.white
                                : (isDark ? AppTheme.textMuted : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Name Input
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Tên danh mục',
                hintText: _selectedType == 'EXPENSE' ? 'Ví dụ: Ăn uống, Cafe, Mua sắm...' : 'Ví dụ: Lương, Thưởng, Bán hàng...',
                prefixIcon: const Icon(Icons.edit_outlined, color: AppTheme.primaryEmerald),
              ),
            ),
            const SizedBox(height: 20),

            // Color Selector
            Text(
              'Chọn màu sắc đại diện:',
              style: TextStyle(
                color: isDark ? AppTheme.textMuted : const Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: CategoryIconHelper.availableColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final colorItem = CategoryIconHelper.availableColors[index];
                  final col = CategoryIconHelper.hexToColor(colorItem.hex);
                  final isSelected = _selectedColorHex.toUpperCase() == colorItem.hex.toUpperCase();

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = colorItem.hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Icon Selector
            Text(
              _selectedType == 'EXPENSE'
                  ? 'Chọn biểu tượng Chi tiêu:'
                  : 'Chọn biểu tượng Thu nhập:',
              style: TextStyle(
                color: isDark ? AppTheme.textMuted : const Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 220,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark.withOpacity(0.3) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.cardDark.withOpacity(0.6) : const Color(0xFFE2E8F0),
                ),
              ),
              child: GridView.builder(
                itemCount: currentIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final item = currentIcons[index];
                  final isSelected = _selectedIconKey.toLowerCase() == item.key.toLowerCase();

                  return InkWell(
                    onTap: () => setState(() => _selectedIconKey = item.key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? currentColor.withOpacity(0.2)
                            : (isDark ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? currentColor
                              : (isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected
                                ? currentColor
                                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? AppTheme.textMuted : const Color(0xFF64748B)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEditing ? 'Cập nhật danh mục' : 'Tạo danh mục',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
