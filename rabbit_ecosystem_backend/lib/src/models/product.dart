import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

enum ProductStatus {
  active('active'),
  inactive('inactive');

  const ProductStatus(this.value);
  final String value;

  static ProductStatus fromString(String value) {
    return ProductStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProductStatus.inactive,
    );
  }
}

@JsonSerializable()
class Product {
  final int id;
  final int partnerId;
  final int categoryId;
  final String name;
  final String? nameAr;
  final String? shortDescription;
  final String? description;
  final String? image;
  final ProductStatus status;
  final double rating;
  final int numberOfRatings;
  final double basePrice;
  final double? discountedPrice;
  final bool isFeatured;
  final int sortOrder;
  final List<ProductVariant> variants;
  final List<ProductAddon> addons;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.partnerId,
    required this.categoryId,
    required this.name,
    this.nameAr,
    this.shortDescription,
    this.description,
    this.image,
    this.status = ProductStatus.active,
    this.rating = 0.0,
    this.numberOfRatings = 0,
    required this.basePrice,
    this.discountedPrice,
    this.isFeatured = false,
    this.sortOrder = 0,
    this.variants = const [],
    this.addons = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Product copyWith({
    int? id,
    int? partnerId,
    int? categoryId,
    String? name,
    String? nameAr,
    String? shortDescription,
    String? description,
    String? image,
    ProductStatus? status,
    double? rating,
    int? numberOfRatings,
    double? basePrice,
    double? discountedPrice,
    bool? isFeatured,
    int? sortOrder,
    List<ProductVariant>? variants,
    List<ProductAddon>? addons,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      image: image ?? this.image,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      numberOfRatings: numberOfRatings ?? this.numberOfRatings,
      basePrice: basePrice ?? this.basePrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      variants: variants ?? this.variants,
      addons: addons ?? this.addons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get effectivePrice => discountedPrice ?? basePrice;
  bool get hasDiscount => discountedPrice != null && discountedPrice! < basePrice;
  double get discountPercentage => hasDiscount ? ((basePrice - discountedPrice!) / basePrice) * 100 : 0.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $basePrice, status: $status)';
  }
}

@JsonSerializable()
class ProductVariant {
  final int id;
  final int productId;
  final String name;
  final String? nameAr;
  final double price;
  final bool isDefault;
  final DateTime createdAt;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    this.nameAr,
    required this.price,
    this.isDefault = false,
    required this.createdAt,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);
  Map<String, dynamic> toJson() => _$ProductVariantToJson(this);

  ProductVariant copyWith({
    int? id,
    int? productId,
    String? name,
    String? nameAr,
    double? price,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductVariant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class ProductAddon {
  final int id;
  final int productId;
  final String name;
  final String? nameAr;
  final double price;
  final bool isRequired;
  final DateTime createdAt;

  const ProductAddon({
    required this.id,
    required this.productId,
    required this.name,
    this.nameAr,
    required this.price,
    this.isRequired = false,
    required this.createdAt,
  });

  factory ProductAddon.fromJson(Map<String, dynamic> json) => _$ProductAddonFromJson(json);
  Map<String, dynamic> toJson() => _$ProductAddonToJson(this);

  ProductAddon copyWith({
    int? id,
    int? productId,
    String? name,
    String? nameAr,
    double? price,
    bool? isRequired,
    DateTime? createdAt,
  }) {
    return ProductAddon(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      price: price ?? this.price,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductAddon && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class Category {
  final int id;
  final String name;
  final String? nameAr;
  final String? description;
  final String? image;
  final int? parentId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    this.nameAr,
    this.description,
    this.image,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  Category copyWith({
    int? id,
    String? name,
    String? nameAr,
    String? description,
    String? image,
    int? parentId,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      image: image ?? this.image,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isParentCategory => parentId == null;
  bool get isSubCategory => parentId != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, isActive: $isActive)';
  }
}

@JsonSerializable()
class CreateProductRequest {
  final int partnerId;
  final int categoryId;
  final String name;
  final String? nameAr;
  final String? shortDescription;
  final String? description;
  final String? image;
  final double basePrice;
  final double? discountedPrice;
  final bool? isFeatured;
  final List<CreateProductVariantRequest>? variants;
  final List<CreateProductAddonRequest>? addons;

  const CreateProductRequest({
    required this.partnerId,
    required this.categoryId,
    required this.name,
    this.nameAr,
    this.shortDescription,
    this.description,
    this.image,
    required this.basePrice,
    this.discountedPrice,
    this.isFeatured,
    this.variants,
    this.addons,
  });

  factory CreateProductRequest.fromJson(Map<String, dynamic> json) => _$CreateProductRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateProductRequestToJson(this);
}

@JsonSerializable()
class CreateProductVariantRequest {
  final String name;
  final String? nameAr;
  final double price;
  final bool? isDefault;

  const CreateProductVariantRequest({
    required this.name,
    this.nameAr,
    required this.price,
    this.isDefault,
  });

  factory CreateProductVariantRequest.fromJson(Map<String, dynamic> json) => _$CreateProductVariantRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateProductVariantRequestToJson(this);
}

@JsonSerializable()
class CreateProductAddonRequest {
  final String name;
  final String? nameAr;
  final double price;
  final bool? isRequired;

  const CreateProductAddonRequest({
    required this.name,
    this.nameAr,
    required this.price,
    this.isRequired,
  });

  factory CreateProductAddonRequest.fromJson(Map<String, dynamic> json) => _$CreateProductAddonRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateProductAddonRequestToJson(this);
}

@JsonSerializable()
class UpdateProductRequest {
  final String? name;
  final String? nameAr;
  final String? shortDescription;
  final String? description;
  final String? image;
  final int? categoryId;
  final double? basePrice;
  final double? discountedPrice;
  final bool? isFeatured;
  final ProductStatus? status;

  const UpdateProductRequest({
    this.name,
    this.nameAr,
    this.shortDescription,
    this.description,
    this.image,
    this.categoryId,
    this.basePrice,
    this.discountedPrice,
    this.isFeatured,
    this.status,
  });

  factory UpdateProductRequest.fromJson(Map<String, dynamic> json) => _$UpdateProductRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateProductRequestToJson(this);
}

@JsonSerializable()
class ProductFilter {
  final int? partnerId;
  final int? categoryId;
  final ProductStatus? status;
  final bool? isFeatured;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? searchTerm;

  const ProductFilter({
    this.partnerId,
    this.categoryId,
    this.status,
    this.isFeatured,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.searchTerm,
  });

  factory ProductFilter.fromJson(Map<String, dynamic> json) => _$ProductFilterFromJson(json);
  Map<String, dynamic> toJson() => _$ProductFilterToJson(this);
}