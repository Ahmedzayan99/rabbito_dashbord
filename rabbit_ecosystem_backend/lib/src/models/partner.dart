import 'package:json_annotation/json_annotation.dart';

part 'partner.g.dart';

enum PartnerStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended');

  const PartnerStatus(this.value);
  final String value;

  static PartnerStatus fromString(String value) {
    return PartnerStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PartnerStatus.inactive,
    );
  }
}

@JsonSerializable()
class Partner {
  final int id;
  final int userId;
  final String partnerName;
  final String? ownerName;
  final String? partnerAddress;
  final int? cityId;
  final double? latitude;
  final double? longitude;
  final int cookingTime;
  final double commission;
  final bool isFeatured;
  final bool isBusy;
  final PartnerStatus status;
  final String? openingTime;
  final String? closingTime;
  final String? phone;
  final String? description;
  final String? image;
  final String? coverImage;
  final double minimumOrder;
  final double deliveryCharge;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Partner({
    required this.id,
    required this.userId,
    required this.partnerName,
    this.ownerName,
    this.partnerAddress,
    this.cityId,
    this.latitude,
    this.longitude,
    this.cookingTime = 30,
    this.commission = 10.0,
    this.isFeatured = false,
    this.isBusy = false,
    this.status = PartnerStatus.active,
    this.openingTime,
    this.closingTime,
    this.phone,
    this.description,
    this.image,
    this.coverImage,
    this.minimumOrder = 0.0,
    this.deliveryCharge = 5.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Partner.fromJson(Map<String, dynamic> json) => _$PartnerFromJson(json);
  Map<String, dynamic> toJson() => _$PartnerToJson(this);

  Partner copyWith({
    int? id,
    int? userId,
    String? partnerName,
    String? ownerName,
    String? partnerAddress,
    int? cityId,
    double? latitude,
    double? longitude,
    int? cookingTime,
    double? commission,
    bool? isFeatured,
    bool? isBusy,
    PartnerStatus? status,
    String? openingTime,
    String? closingTime,
    String? phone,
    String? description,
    String? image,
    String? coverImage,
    double? minimumOrder,
    double? deliveryCharge,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Partner(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerName: partnerName ?? this.partnerName,
      ownerName: ownerName ?? this.ownerName,
      partnerAddress: partnerAddress ?? this.partnerAddress,
      cityId: cityId ?? this.cityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cookingTime: cookingTime ?? this.cookingTime,
      commission: commission ?? this.commission,
      isFeatured: isFeatured ?? this.isFeatured,
      isBusy: isBusy ?? this.isBusy,
      status: status ?? this.status,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      image: image ?? this.image,
      coverImage: coverImage ?? this.coverImage,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Partner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Partner(id: $id, partnerName: $partnerName, status: $status)';
  }
}

@JsonSerializable()
class CreatePartnerRequest {
  final int userId;
  final String partnerName;
  final String? ownerName;
  final String? partnerAddress;
  final int? cityId;
  final double? latitude;
  final double? longitude;
  final int? cookingTime;
  final double? commission;
  final String? phone;
  final String? description;
  final String? image;
  final String? coverImage;
  final double? minimumOrder;
  final double? deliveryCharge;
  final String? openingTime;
  final String? closingTime;

  const CreatePartnerRequest({
    required this.userId,
    required this.partnerName,
    this.ownerName,
    this.partnerAddress,
    this.cityId,
    this.latitude,
    this.longitude,
    this.cookingTime,
    this.commission,
    this.phone,
    this.description,
    this.image,
    this.coverImage,
    this.minimumOrder,
    this.deliveryCharge,
    this.openingTime,
    this.closingTime,
  });

  factory CreatePartnerRequest.fromJson(Map<String, dynamic> json) => _$CreatePartnerRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreatePartnerRequestToJson(this);
}

@JsonSerializable()
class UpdatePartnerRequest {
  final String? partnerName;
  final String? ownerName;
  final String? partnerAddress;
  final int? cityId;
  final double? latitude;
  final double? longitude;
  final int? cookingTime;
  final double? commission;
  final bool? isFeatured;
  final bool? isBusy;
  final PartnerStatus? status;
  final String? phone;
  final String? description;
  final String? image;
  final String? coverImage;
  final double? minimumOrder;
  final double? deliveryCharge;
  final String? openingTime;
  final String? closingTime;

  const UpdatePartnerRequest({
    this.partnerName,
    this.ownerName,
    this.partnerAddress,
    this.cityId,
    this.latitude,
    this.longitude,
    this.cookingTime,
    this.commission,
    this.isFeatured,
    this.isBusy,
    this.status,
    this.phone,
    this.description,
    this.image,
    this.coverImage,
    this.minimumOrder,
    this.deliveryCharge,
    this.openingTime,
    this.closingTime,
  });

  factory UpdatePartnerRequest.fromJson(Map<String, dynamic> json) => _$UpdatePartnerRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdatePartnerRequestToJson(this);
}

@JsonSerializable()
class PartnerFilter {
  final PartnerStatus? status;
  final int? cityId;
  final bool? isFeatured;
  final bool? isBusy;
  final String? searchTerm;
  final double? minRating;
  final List<int>? categoryIds;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  const PartnerFilter({
    this.status,
    this.cityId,
    this.isFeatured,
    this.isBusy,
    this.searchTerm,
    this.minRating,
    this.categoryIds,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  factory PartnerFilter.fromJson(Map<String, dynamic> json) => _$PartnerFilterFromJson(json);
  Map<String, dynamic> toJson() => _$PartnerFilterToJson(this);
}