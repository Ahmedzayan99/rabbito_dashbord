import 'dart:async';
import '../repositories/partner_repository.dart';
import '../repositories/user_repository.dart';
import '../models/partner.dart';
import '../models/user.dart';
import '../models/user_role.dart';

/// Service for partner-related business logic
class PartnerService {
  final PartnerRepository _partnerRepository;
  final UserRepository _userRepository;

  PartnerService(this._partnerRepository, this._userRepository);

  /// Create a new partner (admin function)
  Future<Partner> createPartner({
    required String name,
    required String mobile,
    required String email,
    required String address,
    String? description,
    String? logoUrl,
    String? businessLicense,
  }) async {
    try {
      // Check if mobile already exists
      final existingPartner = await _partnerRepository.findByMobile(mobile);
      if (existingPartner != null) {
        throw Exception('Partner with this mobile number already exists');
      }

      // Check if email already exists
      final existingEmailPartner = await _partnerRepository.findByEmail(email);
      if (existingEmailPartner != null) {
        throw Exception('Partner with this email already exists');
      }

      // Create user account first
      final user = await _userRepository.createUser(
        mobile: mobile,
        password: 'temp_password_123', // Will be changed later
        email: email,
        username: name.split(' ').first,
        role: UserRole.partner,
      );

      // Create partner profile
      return await createPartnerApplication(
        userId: user.id,
        businessName: name,
        businessType: 'restaurant', // Default
        address: address,
        latitude: 0.0, // Default coordinates
        longitude: 0.0,
        businessLicense: businessLicense,
        phone: mobile,
        email: email,
        description: description,
      );
    } catch (e) {
      throw Exception('Partner creation failed: ${e.toString()}');
    }
  }

  /// Create a new partner application
  Future<Partner> createPartnerApplication({
    required int userId,
    required String businessName,
    required String businessType,
    required String address,
    required double latitude,
    required double longitude,
    String? businessLicense,
    String? taxNumber,
    String? phone,
    String? email,
    String? website,
    String? description,
    Map<String, dynamic>? openingHours,
    double? deliveryRadius,
    double? minimumOrder,
    double? deliveryFee,
    int? estimatedDeliveryTime,
  }) async {
    try {
      // Validate user exists and is not already a partner
      final user = await _userRepository.findById(userId);
      if (user == null || !user.isActive) {
        throw Exception('Invalid user');
      }

      // Check if user already has a partner account
      final existingPartner = await _partnerRepository.findByUserId(userId);
      if (existingPartner != null) {
        throw Exception('User already has a partner account');
      }

      // Validate business data
      if (businessName.trim().isEmpty) {
        throw Exception('Business name is required');
      }

      if (businessType.trim().isEmpty) {
        throw Exception('Business type is required');
      }

      if (address.trim().isEmpty) {
        throw Exception('Business address is required');
      }

      // Validate coordinates
      if (latitude < -90 || latitude > 90) {
        throw Exception('Invalid latitude');
      }

      if (longitude < -180 || longitude > 180) {
        throw Exception('Invalid longitude');
      }

      // Create partner data
      final partnerData = {
        'user_id': userId,
        'business_name': businessName.trim(),
        'business_type': businessType.trim(),
        'business_license': businessLicense?.trim(),
        'tax_number': taxNumber?.trim(),
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone?.trim() ?? user.mobile,
        'email': email?.trim() ?? user.email,
        'website': website?.trim(),
        'description': description?.trim(),
        'status': PartnerStatus.pending.name,
        'rating': 0.0,
        'no_of_ratings': 0,
        'commission_rate': 15.0, // Default 15% commission
        'is_featured': false,
        'opening_hours': openingHours,
        'delivery_radius': deliveryRadius ?? 10.0, // Default 10km
        'minimum_order': minimumOrder ?? 20.0, // Default 20 SAR
        'delivery_fee': deliveryFee ?? 5.0, // Default 5 SAR
        'estimated_delivery_time': estimatedDeliveryTime ?? 30, // Default 30 minutes
        'created_at': DateTime.now().toIso8601String(),
      };

      return await _partnerRepository.create(partnerData);
    } catch (e) {
      throw Exception('Partner application failed: ${e.toString()}');
    }
  }

  /// Get partner by ID
  Future<Partner?> getPartnerById(int partnerId) async {
    return await _partnerRepository.findById(partnerId);
  }

  /// Get partner by user ID
  Future<Partner?> getPartnerByUserId(int userId) async {
    return await _partnerRepository.findByUserId(userId);
  }

  /// Get all partners with filters
  Future<List<Partner>> getPartners({
    PartnerStatus? status,
    String? businessType,
    bool? isFeatured,
    int? limit,
    int? offset,
  }) async {
    if (status != null) {
      return await _partnerRepository.findByStatus(status, limit: limit, offset: offset);
    }

    if (businessType != null) {
      return await _partnerRepository.findByBusinessType(businessType, limit: limit, offset: offset);
    }

    if (isFeatured == true) {
      return await _partnerRepository.findFeaturedPartners(limit: limit, offset: offset);
    }

    return await _partnerRepository.findActivePartners(limit: limit, offset: offset);
  }

  /// Get nearby partners
  Future<List<Partner>> getNearbyPartners(
    double latitude,
    double longitude, {
    double? maxDistance,
    int? limit,
    int? offset,
  }) async {
    return await _partnerRepository.findNearbyPartners(
      latitude,
      longitude,
      maxDistance: maxDistance,
      limit: limit,
      offset: offset,
    );
  }

  /// Search partners
  Future<List<Partner>> searchPartners(String query, {int? limit, int? offset}) async {
    if (query.trim().isEmpty) {
      return await getPartners(limit: limit, offset: offset);
    }
    return await _partnerRepository.searchPartners(query, limit: limit, offset: offset);
  }

  /// Update partner profile
  Future<Partner?> updatePartnerProfile(int partnerId, {
    String? businessName,
    String? businessType,
    String? businessLicense,
    String? taxNumber,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? website,
    String? description,
    String? logo,
    String? coverImage,
    Map<String, dynamic>? openingHours,
    double? deliveryRadius,
    double? minimumOrder,
    double? deliveryFee,
    int? estimatedDeliveryTime,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (businessName != null) {
        if (businessName.trim().isEmpty) {
          throw Exception('Business name cannot be empty');
        }
        updateData['business_name'] = businessName.trim();
      }

      if (businessType != null) {
        if (businessType.trim().isEmpty) {
          throw Exception('Business type cannot be empty');
        }
        updateData['business_type'] = businessType.trim();
      }

      if (businessLicense != null) {
        updateData['business_license'] = businessLicense.trim();
      }

      if (taxNumber != null) {
        updateData['tax_number'] = taxNumber.trim();
      }

      if (address != null) {
        if (address.trim().isEmpty) {
          throw Exception('Address cannot be empty');
        }
        updateData['address'] = address.trim();
      }

      if (latitude != null) {
        if (latitude < -90 || latitude > 90) {
          throw Exception('Invalid latitude');
        }
        updateData['latitude'] = latitude;
      }

      if (longitude != null) {
        if (longitude < -180 || longitude > 180) {
          throw Exception('Invalid longitude');
        }
        updateData['longitude'] = longitude;
      }

      if (phone != null) updateData['phone'] = phone.trim();
      if (email != null) updateData['email'] = email.trim();
      if (website != null) updateData['website'] = website.trim();
      if (description != null) updateData['description'] = description.trim();
      if (logo != null) updateData['logo'] = logo;
      if (coverImage != null) updateData['cover_image'] = coverImage;
      if (openingHours != null) updateData['opening_hours'] = openingHours;

      if (deliveryRadius != null) {
        if (deliveryRadius <= 0) {
          throw Exception('Delivery radius must be positive');
        }
        updateData['delivery_radius'] = deliveryRadius;
      }

      if (minimumOrder != null) {
        if (minimumOrder < 0) {
          throw Exception('Minimum order cannot be negative');
        }
        updateData['minimum_order'] = minimumOrder;
      }

      if (deliveryFee != null) {
        if (deliveryFee < 0) {
          throw Exception('Delivery fee cannot be negative');
        }
        updateData['delivery_fee'] = deliveryFee;
      }

      if (estimatedDeliveryTime != null) {
        if (estimatedDeliveryTime <= 0) {
          throw Exception('Estimated delivery time must be positive');
        }
        updateData['estimated_delivery_time'] = estimatedDeliveryTime;
      }

      if (updateData.isEmpty) {
        return await _partnerRepository.findById(partnerId);
      }

      return await _partnerRepository.update(partnerId, updateData);
    } catch (e) {
      throw Exception('Partner profile update failed: ${e.toString()}');
    }
  }

  /// Update partner status (admin only)
  Future<Partner?> updatePartnerStatus(int partnerId, PartnerStatus status) async {
    try {
      final partner = await _partnerRepository.findById(partnerId);
      if (partner == null) {
        throw Exception('Partner not found');
      }

      // If approving partner, update user role
      if (status == PartnerStatus.active && partner.status == PartnerStatus.pending) {
        await _userRepository.update(partner.userId, {'role': UserRole.partner.value});
      }

      return await _partnerRepository.updateStatus(partnerId, status);
    } catch (e) {
      throw Exception('Status update failed: ${e.toString()}');
    }
  }

  /// Update partner rating
  Future<Partner?> updatePartnerRating(int partnerId, double rating) async {
    try {
      final partner = await _partnerRepository.findById(partnerId);
      if (partner == null) {
        throw Exception('Partner not found');
      }

      if (rating < 0 || rating > 5) {
        throw Exception('Rating must be between 0 and 5');
      }

      // Calculate new average rating
      final totalRatings = partner.numberOfRatings + 1;
      final currentTotal = partner.rating * partner.numberOfRatings;
      final newAverage = (currentTotal + rating) / totalRatings;

      return await _partnerRepository.updateRating(partnerId, newAverage, totalRatings);
    } catch (e) {
      throw Exception('Rating update failed: ${e.toString()}');
    }
  }

  /// Toggle featured status (admin only)
  Future<Partner?> toggleFeaturedStatus(int partnerId, bool isFeatured) async {
    return await _partnerRepository.toggleFeatured(partnerId, isFeatured);
  }

  /// Update commission rate (admin only)
  Future<Partner?> updateCommissionRate(int partnerId, double commissionRate) async {
    if (commissionRate < 0 || commissionRate > 50) {
      throw Exception('Commission rate must be between 0% and 50%');
    }
    return await _partnerRepository.updateCommissionRate(partnerId, commissionRate);
  }

  /// Get partner statistics (with date range)
  Future<Map<String, dynamic>> getPartnerStatistics(
    int partnerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _partnerRepository.getPartnerStats(
      partnerId: partnerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get partner orders
  Future<List<Map<String, dynamic>>> getPartnerOrders(
    int partnerId, {
    int? limit,
    int? offset,
  }) async {
    // This would need to be implemented in OrderRepository
    // For now, return empty list
    return [];
  }

  /// Get pending partners
  Future<List<Partner>> getPendingPartners({
    int? limit,
    int? offset,
  }) async {
    return await _partnerRepository.findByStatus(
      PartnerStatus.pending,
      limit: limit,
      offset: offset,
    );
  }

  /// Approve partner application
  Future<Partner?> approvePartner(
    int partnerId, {
    required int approvedBy,
    String? notes,
  }) async {
    try {
      final partner = await _partnerRepository.findById(partnerId);
      if (partner == null || partner.status != PartnerStatus.pending) {
        throw Exception('Invalid partner or status');
      }

      // Update partner status
      final approvedPartner = await updatePartnerStatus(partnerId, PartnerStatus.active);

      // Update user role to partner
      await _userRepository.update(partner.userId, {'role': UserRole.partner.value});

      // Log approval (would be implemented with audit service)
      // await _auditService.logAction('partner_approved', partnerId, 'Approved by user $approvedBy: $notes');

      return approvedPartner;
    } catch (e) {
      throw Exception('Partner approval failed: ${e.toString()}');
    }
  }

  /// Reject partner application
  Future<Partner?> rejectPartner(
    int partnerId, {
    required int rejectedBy,
    required String reason,
  }) async {
    try {
      final partner = await _partnerRepository.findById(partnerId);
      if (partner == null || partner.status != PartnerStatus.pending) {
        throw Exception('Invalid partner or status');
      }

      // Update partner status
      final rejectedPartner = await updatePartnerStatus(partnerId, PartnerStatus.rejected);

      // Log rejection (would be implemented with audit service)
      // await _auditService.logAction('partner_rejected', partnerId, 'Rejected by user $rejectedBy: $reason');

      return rejectedPartner;
    } catch (e) {
      throw Exception('Partner rejection failed: ${e.toString()}');
    }
  }

  /// Get active partners only
  Future<List<Partner>> getActivePartners({
    int? limit,
    int? offset,
  }) async {
    return await _partnerRepository.findByStatus(
      PartnerStatus.active,
      limit: limit,
      offset: offset,
    );
  }

  /// Get nearby partners by location
  Future<List<Partner>> getNearbyPartnersByLocation({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    int? limit,
    int? offset,
  }) async {
    return await getNearbyPartners(
      latitude,
      longitude,
      maxDistance: radius,
      limit: limit,
      offset: offset,
    );
  }

  /// Get top rated partners
  Future<List<Partner>> getTopRatedPartners({int limit = 10}) async {
    return await _partnerRepository.getTopRatedPartners(limit: limit);
  }

  /// Get partners with most orders
  Future<List<Map<String, dynamic>>> getPartnersWithMostOrders({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _partnerRepository.getPartnersWithMostOrders(
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get partner performance metrics
  Future<Map<String, dynamic>?> getPartnerPerformance(
    int partnerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _partnerRepository.getPartnerPerformance(
      partnerId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Suspend partner (admin only)
  Future<Partner?> suspendPartner(int partnerId, String reason) async {
    try {
      final partner = await _partnerRepository.updateStatus(partnerId, PartnerStatus.suspended);
      
      // Log suspension reason (would be implemented with audit service)
      // await _auditService.logAction('partner_suspended', partnerId, reason);
      
      return partner;
    } catch (e) {
      throw Exception('Partner suspension failed: ${e.toString()}');
    }
  }

  /// Reactivate partner (admin only)
  Future<Partner?> reactivatePartner(int partnerId) async {
    return await _partnerRepository.updateStatus(partnerId, PartnerStatus.active);
  }

  /// Delete partner (soft delete)
  Future<bool> deletePartner(int partnerId) async {
    try {
      // Update status to inactive instead of hard delete
      final partner = await _partnerRepository.updateStatus(partnerId, PartnerStatus.inactive);
      return partner != null;
    } catch (e) {
      throw Exception('Partner deletion failed: ${e.toString()}');
    }
  }

  /// Check if user can manage partner
  bool canUserManagePartner(User user, Partner partner) {
    // Partner owner can manage their own account
    if (user.id == partner.userId) return true;
    
    // Admin/staff can manage all partners
    if (user.role.isStaff) return true;
    
    return false;
  }

  /// Validate partner application data
  Map<String, String> validatePartnerApplication({
    required String businessName,
    required String businessType,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? email,
  }) {
    final errors = <String, String>{};

    if (businessName.trim().isEmpty) {
      errors['business_name'] = 'Business name is required';
    }

    if (businessType.trim().isEmpty) {
      errors['business_type'] = 'Business type is required';
    }

    if (address.trim().isEmpty) {
      errors['address'] = 'Business address is required';
    }

    if (latitude < -90 || latitude > 90) {
      errors['latitude'] = 'Invalid latitude';
    }

    if (longitude < -180 || longitude > 180) {
      errors['longitude'] = 'Invalid longitude';
    }

    if (phone != null && phone.isNotEmpty) {
      if (!_isValidMobile(phone)) {
        errors['phone'] = 'Invalid phone number format';
      }
    }

    if (email != null && email.isNotEmpty) {
      if (!_isValidEmail(email)) {
        errors['email'] = 'Invalid email format';
      }
    }

    return errors;
  }

  /// Validate mobile number format
  bool _isValidMobile(String mobile) {
    final saudiMobileRegex = RegExp(r'^(\+966|0)?5[0-9]{8}$');
    return saudiMobileRegex.hasMatch(mobile);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Check if partner exists
  Future<bool> partnerExists(int partnerId) async {
    final partner = await _partnerRepository.findById(partnerId);
    return partner != null && partner.status != PartnerStatus.inactive;
  }

  /// Get partner by business name
  Future<List<Partner>> getPartnersByBusinessName(String businessName) async {
    return await _partnerRepository.searchPartners(businessName);
  }
}