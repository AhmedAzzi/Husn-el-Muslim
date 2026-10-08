import 'package:flutter/material.dart';
import 'package:small_husn_muslim/l10n/app_localizations.dart';

class TodoCategory {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final bool isDefault;
  final int sortOrder;

  const TodoCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  String localizedName(AppLocalizations loc) {
    if (!isDefault) return name;
    return switch (id) {
      'worship' => loc.todoCategoryWorship,
      'personal' => loc.todoCategoryPersonal,
      'work' => loc.todoCategoryWork,
      'general' => loc.todoCategoryGeneral,
      _ => name,
    };
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'name': name,
        'icon_code': iconCode,
        'color_value': colorValue,
        'is_default': isDefault ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory TodoCategory.fromDbMap(Map<String, dynamic> map) => TodoCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        iconCode: map['icon_code'] as int,
        colorValue: map['color_value'] as int,
        isDefault: (map['is_default'] as int? ?? 0) == 1,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  static List<TodoCategory> defaultCategories() => [
        TodoCategory(
          id: 'worship',
          name: 'عبادات',
          iconCode: Icons.mosque_rounded.codePoint,
          colorValue: 0xFF2E6B34, // Islamic green
          isDefault: true,
          sortOrder: 0,
        ),
        TodoCategory(
          id: 'personal',
          name: 'شخصي',
          iconCode: Icons.person_rounded.codePoint,
          colorValue: 0xFF3B82F6, // blue
          isDefault: true,
          sortOrder: 1,
        ),
        TodoCategory(
          id: 'work',
          name: 'عمل',
          iconCode: Icons.work_rounded.codePoint,
          colorValue: 0xFFF59E0B, // amber
          isDefault: true,
          sortOrder: 2,
        ),
        TodoCategory(
          id: 'general',
          name: 'عام',
          iconCode: Icons.checklist_rounded.codePoint,
          colorValue: 0xFFD64463, // Husn burgundy
          isDefault: true,
          sortOrder: 3,
        ),
      ];

  TodoCategory copyWith({
    String? id,
    String? name,
    int? iconCode,
    int? colorValue,
    bool? isDefault,
    int? sortOrder,
  }) {
    return TodoCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
