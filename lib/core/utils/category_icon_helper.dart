import 'package:flutter/material.dart';

class CategoryIconItem {
  final String key;
  final String label;
  final IconData icon;

  const CategoryIconItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class CategoryColorItem {
  final String hex;
  final String name;

  const CategoryColorItem({
    required this.hex,
    required this.name,
  });
}

class CategoryIconHelper {
  /// Map string key to IconData with fallbacks
  static IconData getIcon(String? iconKey) {
    if (iconKey == null || iconKey.isEmpty) {
      return Icons.category_rounded;
    }

    switch (iconKey.toLowerCase().trim()) {
      // Food & Drink
      case 'utensils':
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'coffee':
      case 'local_cafe':
        return Icons.local_cafe_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;

      // Transport
      case 'car':
      case 'directions_car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'two_wheeler':
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      case 'local_gas_station':
      case 'gas':
        return Icons.local_gas_station_rounded;
      case 'flight':
      case 'travel':
        return Icons.flight_takeoff_rounded;

      // Shopping
      case 'shopping-bag':
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;

      // Bills & Services
      case 'receipt':
      case 'receipt_long':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'bolt':
      case 'electricity':
        return Icons.bolt_rounded;
      case 'water_drop':
      case 'water':
        return Icons.water_drop_rounded;
      case 'wifi':
        return Icons.wifi_rounded;

      // Entertainment & Tech
      case 'film':
      case 'movie':
      case 'entertainment':
      case 'sports_esports':
      case 'game':
        return Icons.sports_esports_rounded;
      case 'music_note':
        return Icons.music_note_rounded;

      // Health & Fitness
      case 'heart-pulse':
      case 'health':
      case 'medical':
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'fitness':
      case 'fitness_center':
      case 'gym':
        return Icons.fitness_center_rounded;

      // Incomes
      case 'briefcase':
      case 'work':
      case 'salary':
      case 'payments':
        return Icons.payments_rounded;
      case 'military_tech':
      case 'bonus':
      case 'reward':
        return Icons.military_tech_rounded;
      case 'trending-up':
      case 'trending_up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'savings':
      case 'piggy_bank':
        return Icons.savings_rounded;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'storefront':
      case 'business':
      case 'shop':
        return Icons.storefront_rounded;
      case 'real_estate_agent':
      case 'rental':
        return Icons.real_estate_agent_rounded;
      case 'currency_exchange':
      case 'refund':
        return Icons.currency_exchange_rounded;
      case 'volunteer_activism':
      case 'allowance':
      case 'aid':
        return Icons.volunteer_activism_rounded;
      case 'account_balance':
      case 'dividend':
        return Icons.account_balance_rounded;

      // Living & Family
      case 'home':
      case 'house':
        return Icons.home_rounded;
      case 'school':
      case 'education':
        return Icons.school_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'child_care':
        return Icons.child_care_rounded;
      case 'phone_iphone':
        return Icons.phone_iphone_rounded;

      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'tag':
      default:
        return Icons.category_rounded;
    }
  }

  /// Safe Hex Color parser: #RRGGBB or RRGGBB to Color
  static Color hexToColor(String? hexString, {Color defaultColor = const Color(0xFF10B981)}) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      String cleanHex = hexString.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  /// Bộ icon chuyên biệt dành cho CHI TIÊU (Expense Icons)
  static const List<CategoryIconItem> expenseIcons = [
    CategoryIconItem(key: 'restaurant', label: 'Ăn uống', icon: Icons.restaurant_rounded),
    CategoryIconItem(key: 'local_cafe', label: 'Cà phê/Trà', icon: Icons.local_cafe_rounded),
    CategoryIconItem(key: 'fastfood', label: 'Đồ ăn nhanh', icon: Icons.fastfood_rounded),
    CategoryIconItem(key: 'shopping_bag', label: 'Mua sắm', icon: Icons.shopping_bag_rounded),
    CategoryIconItem(key: 'shopping_cart', label: 'Đi chợ/Siêu thị', icon: Icons.shopping_cart_rounded),
    CategoryIconItem(key: 'directions_car', label: 'Xe cộ/Ô tô', icon: Icons.directions_car_rounded),
    CategoryIconItem(key: 'two_wheeler', label: 'Xe máy', icon: Icons.two_wheeler_rounded),
    CategoryIconItem(key: 'local_gas_station', label: 'Đổ xăng', icon: Icons.local_gas_station_rounded),
    CategoryIconItem(key: 'receipt_long', label: 'Hóa đơn', icon: Icons.receipt_long_rounded),
    CategoryIconItem(key: 'bolt', label: 'Điện nước', icon: Icons.bolt_rounded),
    CategoryIconItem(key: 'home', label: 'Tiền nhà/Trọ', icon: Icons.home_rounded),
    CategoryIconItem(key: 'sports_esports', label: 'Giải trí/Game', icon: Icons.sports_esports_rounded),
    CategoryIconItem(key: 'movie', label: 'Xem phim', icon: Icons.movie_rounded),
    CategoryIconItem(key: 'medical_services', label: 'Y tế/Thuốc', icon: Icons.medical_services_rounded),
    CategoryIconItem(key: 'fitness_center', label: 'Gym/Thể thao', icon: Icons.fitness_center_rounded),
    CategoryIconItem(key: 'school', label: 'Học tập/Sách', icon: Icons.school_rounded),
    CategoryIconItem(key: 'flight', label: 'Du lịch', icon: Icons.flight_takeoff_rounded),
    CategoryIconItem(key: 'pets', label: 'Thú cưng', icon: Icons.pets_rounded),
    CategoryIconItem(key: 'phone_iphone', label: 'Điện thoại/4G', icon: Icons.phone_iphone_rounded),
    CategoryIconItem(key: 'card_giftcard', label: 'Quà tặng/Hiếu hỉ', icon: Icons.card_giftcard_rounded),
    CategoryIconItem(key: 'category', label: 'Khác', icon: Icons.category_rounded),
  ];

  /// Bộ icon chuyên biệt dành cho THU NHẬP (Income Icons)
  static const List<CategoryIconItem> incomeIcons = [
    CategoryIconItem(key: 'payments', label: 'Tiền lương', icon: Icons.payments_rounded),
    CategoryIconItem(key: 'military_tech', label: 'Thưởng/Bonus', icon: Icons.military_tech_rounded),
    CategoryIconItem(key: 'trending_up', label: 'Đầu tư/Lãi', icon: Icons.trending_up_rounded),
    CategoryIconItem(key: 'savings', label: 'Tiết kiệm', icon: Icons.savings_rounded),
    CategoryIconItem(key: 'work', label: 'Làm thêm/Freelance', icon: Icons.work_rounded),
    CategoryIconItem(key: 'storefront', label: 'Kinh doanh/Bán lẻ', icon: Icons.storefront_rounded),
    CategoryIconItem(key: 'real_estate_agent', label: 'Cho thuê nhà', icon: Icons.real_estate_agent_rounded),
    CategoryIconItem(key: 'card_giftcard', label: 'Quà tặng/Mừng', icon: Icons.card_giftcard_rounded),
    CategoryIconItem(key: 'currency_exchange', label: 'Hoàn tiền/Đòi nợ', icon: Icons.currency_exchange_rounded),
    CategoryIconItem(key: 'account_balance', label: 'Cổ tức/Ngân hàng', icon: Icons.account_balance_rounded),
    CategoryIconItem(key: 'volunteer_activism', label: 'Trợ cấp/Học bổng', icon: Icons.volunteer_activism_rounded),
    CategoryIconItem(key: 'wallet', label: 'Ví phụ/Thu khác', icon: Icons.account_balance_wallet_rounded),
    CategoryIconItem(key: 'category', label: 'Khác', icon: Icons.category_rounded),
  ];

  /// Danh sách toàn bộ icon (để tra cứu và tương thích ngược)
  static List<CategoryIconItem> get availableIcons => [...expenseIcons, ...incomeIcons];

  /// Available selectable colors
  static const List<CategoryColorItem> availableColors = [
    CategoryColorItem(hex: '#EF4444', name: 'Đỏ'),
    CategoryColorItem(hex: '#F59E0B', name: 'Cam hổ phách'),
    CategoryColorItem(hex: '#10B981', name: 'Xanh Emerald'),
    CategoryColorItem(hex: '#06B6D4', name: 'Xanh Cyan'),
    CategoryColorItem(hex: '#3B82F6', name: 'Xanh dương'),
    CategoryColorItem(hex: '#6366F1', name: 'Xanh Indigo'),
    CategoryColorItem(hex: '#8B5CF6', name: 'Tím'),
    CategoryColorItem(hex: '#EC4899', name: 'Hồng'),
    CategoryColorItem(hex: '#F97316', name: 'Cam rực'),
    CategoryColorItem(hex: '#84CC16', name: 'Xanh cốm'),
    CategoryColorItem(hex: '#14B8A6', name: 'Xanh Teal'),
    CategoryColorItem(hex: '#64748B', name: 'Xám Slate'),
  ];
}
