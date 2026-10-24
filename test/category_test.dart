import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longwallet/models/category_model.dart';
import 'package:longwallet/core/utils/category_icon_helper.dart';

void main() {
  group('CategoryModel Tests', () {
    test('CategoryModel fromJson and toJson should serialize and deserialize correctly', () {
      final json = {
        'id': 'cat-123',
        'user_id': 'user-456',
        'name': 'Ăn uống',
        'type': 'EXPENSE',
        'icon': 'restaurant',
        'color': '#EF4444',
        'is_default': false,
      };

      final model = CategoryModel.fromJson(json);

      expect(model.id, 'cat-123');
      expect(model.userId, 'user-456');
      expect(model.name, 'Ăn uống');
      expect(model.type, 'EXPENSE');
      expect(model.icon, 'restaurant');
      expect(model.color, '#EF4444');
      expect(model.isDefault, false);

      final exportedJson = model.toJson();
      expect(exportedJson['id'], 'cat-123');
      expect(exportedJson['name'], 'Ăn uống');
      expect(exportedJson['type'], 'EXPENSE');
      expect(exportedJson['icon'], 'restaurant');
      expect(exportedJson['color'], '#EF4444');
      expect(exportedJson['is_default'], false);
    });

    test('CategoryModel handles default fallback values in fromJson', () {
      final minimalJson = {
        'id': 'cat-default-1',
        'name': 'Lương',
        'type': 'INCOME',
      };

      final model = CategoryModel.fromJson(minimalJson);

      expect(model.id, 'cat-default-1');
      expect(model.userId, isNull);
      expect(model.name, 'Lương');
      expect(model.type, 'INCOME');
      expect(model.icon, 'tag');
      expect(model.color, '#3B82F6');
      expect(model.isDefault, false);
    });
  });

  group('CategoryIconHelper Tests', () {
    test('hexToColor parses valid 6-char hex and handles hash prefix', () {
      expect(CategoryIconHelper.hexToColor('#EF4444'), const Color(0xFFEF4444));
      expect(CategoryIconHelper.hexToColor('10B981'), const Color(0xFF10B981));
    });

    test('hexToColor falls back to default on invalid or empty string', () {
      const fallback = Color(0xFF00FF00);
      expect(CategoryIconHelper.hexToColor('', defaultColor: fallback), fallback);
      expect(CategoryIconHelper.hexToColor(null, defaultColor: fallback), fallback);
      expect(CategoryIconHelper.hexToColor('invalid-hex', defaultColor: fallback), fallback);
    });

    test('getIcon maps food, transport, salary, and falls back correctly', () {
      // Food
      expect(CategoryIconHelper.getIcon('restaurant'), Icons.restaurant_rounded);
      expect(CategoryIconHelper.getIcon('utensils'), Icons.restaurant_rounded);
      expect(CategoryIconHelper.getIcon('coffee'), Icons.local_cafe_rounded);

      // Transport
      expect(CategoryIconHelper.getIcon('car'), Icons.directions_car_rounded);
      expect(CategoryIconHelper.getIcon('two_wheeler'), Icons.two_wheeler_rounded);

      // Income / Salary
      expect(CategoryIconHelper.getIcon('salary'), Icons.payments_rounded);
      expect(CategoryIconHelper.getIcon('briefcase'), Icons.payments_rounded);
      expect(CategoryIconHelper.getIcon('trending-up'), Icons.trending_up_rounded);

      // Fallback
      expect(CategoryIconHelper.getIcon(null), Icons.category_rounded);
      expect(CategoryIconHelper.getIcon('unknown_key_xyz'), Icons.category_rounded);
    });

    test('expenseIcons and incomeIcons are separated and valid', () {
      expect(CategoryIconHelper.expenseIcons.isNotEmpty, true);
      expect(CategoryIconHelper.incomeIcons.isNotEmpty, true);

      // Verify expense has restaurant and car
      expect(CategoryIconHelper.expenseIcons.any((i) => i.key == 'restaurant'), true);
      expect(CategoryIconHelper.expenseIcons.any((i) => i.key == 'directions_car'), true);
      expect(CategoryIconHelper.expenseIcons.any((i) => i.key == 'fastfood'), true);

      // Verify income has payments and bonus
      expect(CategoryIconHelper.incomeIcons.any((i) => i.key == 'payments'), true);
      expect(CategoryIconHelper.incomeIcons.any((i) => i.key == 'military_tech'), true);
      expect(CategoryIconHelper.incomeIcons.any((i) => i.key == 'storefront'), true);

      // Available icons should combine both
      expect(
        CategoryIconHelper.availableIcons.length,
        CategoryIconHelper.expenseIcons.length + CategoryIconHelper.incomeIcons.length,
      );
    });

    test('availableIcons and availableColors are populated and valid', () {
      expect(CategoryIconHelper.availableIcons.isNotEmpty, true);
      expect(CategoryIconHelper.availableColors.isNotEmpty, true);

      for (final icon in CategoryIconHelper.availableIcons) {
        expect(icon.key.isNotEmpty, true);
        expect(icon.label.isNotEmpty, true);
      }

      for (final color in CategoryIconHelper.availableColors) {
        expect(color.hex.startsWith('#'), true);
        expect(color.name.isNotEmpty, true);
      }
    });
  });
}
