// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Cart _$CartFromJson(Map<String, dynamic> json) => Cart(
      userId: (json['userId'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CartToJson(Cart instance) => <String, dynamic>{
      'userId': instance.userId,
      'items': instance.items,
    };

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      variantId: (json['variantId'] as num?)?.toInt(),
      quantity: (json['quantity'] as num).toInt(),
      specialInstructions: json['specialInstructions'] as String?,
      isSavedForLater: json['isSavedForLater'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      productName: json['productName'] as String?,
      productImage: json['productImage'] as String?,
      variantName: json['variantName'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'productId': instance.productId,
      'variantId': instance.variantId,
      'quantity': instance.quantity,
      'specialInstructions': instance.specialInstructions,
      'isSavedForLater': instance.isSavedForLater,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'productName': instance.productName,
      'productImage': instance.productImage,
      'variantName': instance.variantName,
      'unitPrice': instance.unitPrice,
    };
