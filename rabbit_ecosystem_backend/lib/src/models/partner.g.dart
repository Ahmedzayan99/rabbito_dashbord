// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Partner _$PartnerFromJson(Map<String, dynamic> json) => Partner(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      partnerName: json['partnerName'] as String,
      ownerName: json['ownerName'] as String?,
      partnerAddress: json['partnerAddress'] as String?,
      cityId: (json['cityId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cookingTime: (json['cookingTime'] as num?)?.toInt() ?? 30,
      commission: (json['commission'] as num?)?.toDouble() ?? 10.0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isBusy: json['isBusy'] as bool? ?? false,
      status: $enumDecodeNullable(_$PartnerStatusEnumMap, json['status']) ??
          PartnerStatus.active,
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      coverImage: json['coverImage'] as String?,
      minimumOrder: (json['minimumOrder'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 5.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PartnerToJson(Partner instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'partnerName': instance.partnerName,
      'ownerName': instance.ownerName,
      'partnerAddress': instance.partnerAddress,
      'cityId': instance.cityId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'cookingTime': instance.cookingTime,
      'commission': instance.commission,
      'isFeatured': instance.isFeatured,
      'isBusy': instance.isBusy,
      'status': _$PartnerStatusEnumMap[instance.status]!,
      'openingTime': instance.openingTime,
      'closingTime': instance.closingTime,
      'phone': instance.phone,
      'description': instance.description,
      'image': instance.image,
      'coverImage': instance.coverImage,
      'minimumOrder': instance.minimumOrder,
      'deliveryCharge': instance.deliveryCharge,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$PartnerStatusEnumMap = {
  PartnerStatus.pending: 'pending',
  PartnerStatus.active: 'active',
  PartnerStatus.inactive: 'inactive',
  PartnerStatus.suspended: 'suspended',
  PartnerStatus.rejected: 'rejected',
};

CreatePartnerRequest _$CreatePartnerRequestFromJson(
        Map<String, dynamic> json) =>
    CreatePartnerRequest(
      userId: (json['userId'] as num).toInt(),
      partnerName: json['partnerName'] as String,
      ownerName: json['ownerName'] as String?,
      partnerAddress: json['partnerAddress'] as String?,
      cityId: (json['cityId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cookingTime: (json['cookingTime'] as num?)?.toInt(),
      commission: (json['commission'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      coverImage: json['coverImage'] as String?,
      minimumOrder: (json['minimumOrder'] as num?)?.toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble(),
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
    );

Map<String, dynamic> _$CreatePartnerRequestToJson(
        CreatePartnerRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'partnerName': instance.partnerName,
      'ownerName': instance.ownerName,
      'partnerAddress': instance.partnerAddress,
      'cityId': instance.cityId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'cookingTime': instance.cookingTime,
      'commission': instance.commission,
      'phone': instance.phone,
      'description': instance.description,
      'image': instance.image,
      'coverImage': instance.coverImage,
      'minimumOrder': instance.minimumOrder,
      'deliveryCharge': instance.deliveryCharge,
      'openingTime': instance.openingTime,
      'closingTime': instance.closingTime,
    };

UpdatePartnerRequest _$UpdatePartnerRequestFromJson(
        Map<String, dynamic> json) =>
    UpdatePartnerRequest(
      partnerName: json['partnerName'] as String?,
      ownerName: json['ownerName'] as String?,
      partnerAddress: json['partnerAddress'] as String?,
      cityId: (json['cityId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cookingTime: (json['cookingTime'] as num?)?.toInt(),
      commission: (json['commission'] as num?)?.toDouble(),
      isFeatured: json['isFeatured'] as bool?,
      isBusy: json['isBusy'] as bool?,
      status: $enumDecodeNullable(_$PartnerStatusEnumMap, json['status']),
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      coverImage: json['coverImage'] as String?,
      minimumOrder: (json['minimumOrder'] as num?)?.toDouble(),
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble(),
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
    );

Map<String, dynamic> _$UpdatePartnerRequestToJson(
        UpdatePartnerRequest instance) =>
    <String, dynamic>{
      'partnerName': instance.partnerName,
      'ownerName': instance.ownerName,
      'partnerAddress': instance.partnerAddress,
      'cityId': instance.cityId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'cookingTime': instance.cookingTime,
      'commission': instance.commission,
      'isFeatured': instance.isFeatured,
      'isBusy': instance.isBusy,
      'status': _$PartnerStatusEnumMap[instance.status],
      'phone': instance.phone,
      'description': instance.description,
      'image': instance.image,
      'coverImage': instance.coverImage,
      'minimumOrder': instance.minimumOrder,
      'deliveryCharge': instance.deliveryCharge,
      'openingTime': instance.openingTime,
      'closingTime': instance.closingTime,
    };

PartnerFilter _$PartnerFilterFromJson(Map<String, dynamic> json) =>
    PartnerFilter(
      status: $enumDecodeNullable(_$PartnerStatusEnumMap, json['status']),
      cityId: (json['cityId'] as num?)?.toInt(),
      isFeatured: json['isFeatured'] as bool?,
      isBusy: json['isBusy'] as bool?,
      searchTerm: json['searchTerm'] as String?,
      minRating: (json['minRating'] as num?)?.toDouble(),
      categoryIds: (json['categoryIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusKm: (json['radiusKm'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PartnerFilterToJson(PartnerFilter instance) =>
    <String, dynamic>{
      'status': _$PartnerStatusEnumMap[instance.status],
      'cityId': instance.cityId,
      'isFeatured': instance.isFeatured,
      'isBusy': instance.isBusy,
      'searchTerm': instance.searchTerm,
      'minRating': instance.minRating,
      'categoryIds': instance.categoryIds,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radiusKm': instance.radiusKm,
    };
