import 'package:json_annotation/json_annotation.dart';

part 'cart.g.dart';

/// Cart model containing cart items
class Cart {
  final int userId;
  final List<CartItem> items;

  Cart({
    required this.userId,
    required this.items,
  });

  /// Calculate total items count
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Calculate subtotal
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_items': totalItems,
      'subtotal': subtotal,
    };
  }
}

/// Cart item model
class CartItem {
  final int id;
  final int userId;
  final int productId;
  final int? variantId;
  final int quantity;
  final String? specialInstructions;
  final bool isSavedForLater;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Product information (populated from joins)
  final String? productName;
  final String? productImage;
  final String? variantName;
  final double? unitPrice;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.variantId,
    required this.quantity,
    this.specialInstructions,
    required this.isSavedForLater,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.productImage,
    this.variantName,
    this.unitPrice,
  });

  /// Calculate total price for this item
  double get totalPrice => (unitPrice ?? 0.0) * quantity;

  /// Factory constructor from database map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      productId: map['product_id'] as int,
      variantId: map['product_variant_id'] as int?,
      quantity: map['quantity'] as int,
      specialInstructions: map['special_instructions'] as String?,
      isSavedForLater: map['is_saved_for_later'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      productName: map['product_name'] as String?,
      productImage: map['product_image'] as String?,
      variantName: map['variant_name'] as String?,
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'special_instructions': specialInstructions,
      'is_saved_for_later': isSavedForLater,
      'product_name': productName,
      'product_image': productImage,
      'variant_name': variantName,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method
  CartItem copyWith({
    int? id,
    int? userId,
    int? productId,
    int? variantId,
    int? quantity,
    String? specialInstructions,
    bool? isSavedForLater,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productName,
    String? productImage,
    String? variantName,
    double? unitPrice,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isSavedForLater: isSavedForLater ?? this.isSavedForLater,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      variantName: variantName ?? this.variantName,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
