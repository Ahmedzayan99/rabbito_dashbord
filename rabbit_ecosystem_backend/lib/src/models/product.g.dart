// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: (json['id'] as num).toInt(),
      partnerId: (json['partnerId'] as num).toInt(),
      categoryId: (json['categoryId'] as num).toInt(),
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      longDescription: json['longDescription'] as String?,
      image: json['image'] as String?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      status: $enumDecodeNullable(_$ProductStatusEnumMap, json['status']) ??
          ProductStatus.active,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      numberOfRatings: (json['numberOfRatings'] as num?)?.toInt() ?? 0,
      basePrice: (json['basePrice'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      addons: (json['addons'] as List<dynamic>?)
              ?.map((e) => ProductAddon.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      preparationTime: (json['preparationTime'] as num?)?.toInt(),
      calories: (json['calories'] as num?)?.toInt(),
      ingredients: (json['ingredients'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'partnerId': instance.partnerId,
      'categoryId': instance.categoryId,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'shortDescription': instance.shortDescription,
      'description': instance.description,
      'longDescription': instance.longDescription,
      'image': instance.image,
      'images': instance.images,
      'status': _$ProductStatusEnumMap[instance.status]!,
      'rating': instance.rating,
      'numberOfRatings': instance.numberOfRatings,
      'basePrice': instance.basePrice,
      'discountedPrice': instance.discountedPrice,
      'isFeatured': instance.isFeatured,
      'sortOrder': instance.sortOrder,
      'variants': instance.variants,
      'addons': instance.addons,
      'allergens': instance.allergens,
      'tags': instance.tags,
      'preparationTime': instance.preparationTime,
      'calories': instance.calories,
      'ingredients': instance.ingredients,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$ProductStatusEnumMap = {
  ProductStatus.active: 'active',
  ProductStatus.inactive: 'inactive',
  ProductStatus.outOfStock: 'outOfStock',
};

ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    ProductVariant(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      price: (json['price'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProductVariantToJson(ProductVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'price': instance.price,
      'isDefault': instance.isDefault,
      'createdAt': instance.createdAt.toIso8601String(),
    };

ProductAddon _$ProductAddonFromJson(Map<String, dynamic> json) => ProductAddon(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      price: (json['price'] as num).toDouble(),
      isRequired: json['isRequired'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ProductAddonToJson(ProductAddon instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'price': instance.price,
      'isRequired': instance.isRequired,
      'createdAt': instance.createdAt.toIso8601String(),
    };

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      parentId: (json['parentId'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'description': instance.description,
      'image': instance.image,
      'parentId': instance.parentId,
      'sortOrder': instance.sortOrder,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

CreateProductRequest _$CreateProductRequestFromJson(
        Map<String, dynamic> json) =>
    CreateProductRequest(
      partnerId: (json['partnerId'] as num).toInt(),
      categoryId: (json['categoryId'] as num).toInt(),
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      basePrice: (json['basePrice'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      isFeatured: json['isFeatured'] as bool?,
      variants: (json['variants'] as List<dynamic>?)
          ?.map((e) =>
              CreateProductVariantRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      addons: (json['addons'] as List<dynamic>?)
          ?.map((e) =>
              CreateProductAddonRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateProductRequestToJson(
        CreateProductRequest instance) =>
    <String, dynamic>{
      'partnerId': instance.partnerId,
      'categoryId': instance.categoryId,
      'name': instance.name,
      'nameAr': instance.nameAr,
      'shortDescription': instance.shortDescription,
      'description': instance.description,
      'image': instance.image,
      'basePrice': instance.basePrice,
      'discountedPrice': instance.discountedPrice,
      'isFeatured': instance.isFeatured,
      'variants': instance.variants,
      'addons': instance.addons,
    };

CreateProductVariantRequest _$CreateProductVariantRequestFromJson(
        Map<String, dynamic> json) =>
    CreateProductVariantRequest(
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      price: (json['price'] as num).toDouble(),
      isDefault: json['isDefault'] as bool?,
    );

Map<String, dynamic> _$CreateProductVariantRequestToJson(
        CreateProductVariantRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'nameAr': instance.nameAr,
      'price': instance.price,
      'isDefault': instance.isDefault,
    };

CreateProductAddonRequest _$CreateProductAddonRequestFromJson(
        Map<String, dynamic> json) =>
    CreateProductAddonRequest(
      name: json['name'] as String,
      nameAr: json['nameAr'] as String?,
      price: (json['price'] as num).toDouble(),
      isRequired: json['isRequired'] as bool?,
    );

Map<String, dynamic> _$CreateProductAddonRequestToJson(
        CreateProductAddonRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'nameAr': instance.nameAr,
      'price': instance.price,
      'isRequired': instance.isRequired,
    };

UpdateProductRequest _$UpdateProductRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateProductRequest(
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      isFeatured: json['isFeatured'] as bool?,
      status: $enumDecodeNullable(_$ProductStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$UpdateProductRequestToJson(
        UpdateProductRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'nameAr': instance.nameAr,
      'shortDescription': instance.shortDescription,
      'description': instance.description,
      'image': instance.image,
      'categoryId': instance.categoryId,
      'basePrice': instance.basePrice,
      'discountedPrice': instance.discountedPrice,
      'isFeatured': instance.isFeatured,
      'status': _$ProductStatusEnumMap[instance.status],
    };

ProductFilter _$ProductFilterFromJson(Map<String, dynamic> json) =>
    ProductFilter(
      partnerId: (json['partnerId'] as num?)?.toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      status: $enumDecodeNullable(_$ProductStatusEnumMap, json['status']),
      isFeatured: json['isFeatured'] as bool?,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      minRating: (json['minRating'] as num?)?.toDouble(),
      searchTerm: json['searchTerm'] as String?,
    );

Map<String, dynamic> _$ProductFilterToJson(ProductFilter instance) =>
    <String, dynamic>{
      'partnerId': instance.partnerId,
      'categoryId': instance.categoryId,
      'status': _$ProductStatusEnumMap[instance.status],
      'isFeatured': instance.isFeatured,
      'minPrice': instance.minPrice,
      'maxPrice': instance.maxPrice,
      'minRating': instance.minRating,
      'searchTerm': instance.searchTerm,
    };
