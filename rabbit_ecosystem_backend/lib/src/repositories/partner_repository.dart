import 'dart:async';
import 'package:postgres/postgres.dart';
import 'base_repository.dart';
import '../models/partner.dart';

/// Repository for partner-related database operations
class PartnerRepository extends BaseRepository<Partner> {
  PartnerRepository(super.connection);

  @override
  String get tableName => 'partners';

  @override
  Partner fromMap(Map<String, dynamic> map) {
    return Partner.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(Partner partner) {
    return {
      'user_id': partner.userId,
      'business_name': partner.businessName,
      'business_type': partner.businessType,
      'business_license': partner.businessLicense,
      'tax_number': partner.taxNumber,
      'address': partner.address,
      'latitude': partner.latitude,
      'longitude': partner.longitude,
      'phone': partner.phone,
      'email': partner.email,
      'website': partner.website,
      'description': partner.description,
      'logo': partner.logo,
      'cover_image': partner.coverImage,
      'status': partner.status.name,
      'rating': partner.rating,
      'no_of_ratings': partner.numberOfRatings,
      'commission_rate': partner.commissionRate,
      'is_featured': partner.isFeatured,
      'opening_hours': partner.openingHours,
      'delivery_radius': partner.deliveryRadius,
      'minimum_order': partner.minimumOrder,
      'delivery_fee': partner.deliveryFee,
      'estimated_delivery_time': partner.estimatedDeliveryTime,
      'created_at': partner.createdAt.toIso8601String(),
      'updated_at': partner.updatedAt?.toIso8601String(),
    };
  }

  /// Find partner by user ID
  Future<Partner?> findByUserId(int userId) async {
    return await findOneWhere('user_id = @user_id', parameters: {'user_id': userId});
  }

  /// Find partner by mobile
  Future<Partner?> findByMobile(String mobile) async {
    return await findOneWhere('phone = @mobile', parameters: {'mobile': mobile});
  }

  /// Find partner by email
  Future<Partner?> findByEmail(String email) async {
    return await findOneWhere('email = @email', parameters: {'email': email});
  }

  /// Find partners by status
  Future<List<Partner>> findByStatus(PartnerStatus status, {int? limit, int? offset}) async {
    String query = 'SELECT * FROM partners WHERE status = @status ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'status': status.name},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find active partners
  Future<List<Partner>> findActivePartners({int? limit, int? offset}) async {
    return await findByStatus(PartnerStatus.active, limit: limit, offset: offset);
  }

  /// Find featured partners
  Future<List<Partner>> findFeaturedPartners({int? limit, int? offset}) async {
    String query = '''
      SELECT * FROM partners 
      WHERE status = @status AND is_featured = true 
      ORDER BY rating DESC, created_at DESC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {'status': PartnerStatus.active.name},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find partners by business type
  Future<List<Partner>> findByBusinessType(String businessType, {int? limit, int? offset}) async {
    String query = '''
      SELECT * FROM partners 
      WHERE business_type = @business_type AND status = @status 
      ORDER BY rating DESC, created_at DESC
    ''';
    
    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(
      query,
      parameters: {
        'business_type': businessType,
        'status': PartnerStatus.active.name,
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Find partners within delivery radius
  Future<List<Partner>> findNearbyPartners(
    double latitude,
    double longitude,
    {double? maxDistance, int? limit, int? offset}
  ) async {
    // Using Haversine formula to calculate distance
    String query = '''
      SELECT *, 
        (6371 * acos(cos(radians(@lat)) * cos(radians(latitude)) * 
        cos(radians(longitude) - radians(@lng)) + sin(radians(@lat)) * 
        sin(radians(latitude)))) AS distance
      FROM partners 
      WHERE status = @status
    ''';

    Map<String, dynamic> parameters = {
      'lat': latitude,
      'lng': longitude,
      'status': PartnerStatus.active.name,
    };

    if (maxDistance != null) {
      query += ' AND delivery_radius >= (6371 * acos(cos(radians(@lat)) * cos(radians(latitude)) * cos(radians(longitude) - radians(@lng)) + sin(radians(@lat)) * sin(radians(latitude))))';
    }

    query += ' ORDER BY distance ASC';

    if (limit != null) {
      query += ' LIMIT $limit';
    }
    if (offset != null) {
      query += ' OFFSET $offset';
    }

    final result = await connection.execute(query, parameters: parameters);
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Update partner status
  Future<Partner?> updateStatus(int partnerId, PartnerStatus status) async {
    return await update(partnerId, {'status': status.name});
  }

  /// Update partner rating
  Future<Partner?> updateRating(int partnerId, double newRating, int totalRatings) async {
    return await update(partnerId, {
      'rating': newRating,
      'no_of_ratings': totalRatings,
    });
  }

  /// Toggle featured status
  Future<Partner?> toggleFeatured(int partnerId, bool isFeatured) async {
    return await update(partnerId, {'is_featured': isFeatured});
  }

  /// Search partners by name or business type
  Future<List<Partner>> searchPartners(String query, {int? limit, int? offset}) async {
    final searchQuery = '''
      SELECT * FROM partners 
      WHERE (business_name ILIKE @query OR business_type ILIKE @query OR description ILIKE @query)
      AND status = @status
      ORDER BY rating DESC, created_at DESC
    ''';

    String finalQuery = searchQuery;
    if (limit != null) {
      finalQuery += ' LIMIT $limit';
    }
    if (offset != null) {
      finalQuery += ' OFFSET $offset';
    }

    final result = await connection.execute(
      finalQuery,
      parameters: {
        'query': '%$query%',
        'status': PartnerStatus.active.name,
      },
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Get partner statistics (general)
  Future<Map<String, dynamic>> getPartnerStats() async {
    final result = await executeQuerySingle('''
      SELECT
        COUNT(*) as total_partners,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active_partners,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_partners,
        COUNT(CASE WHEN status = 'suspended' THEN 1 END) as suspended_partners,
        COUNT(CASE WHEN is_featured = true THEN 1 END) as featured_partners,
        AVG(rating) as average_rating,
        AVG(commission_rate) as average_commission_rate
      FROM partners
    ''');

    return result ?? {};
  }

  /// Get partner statistics by ID and date range
  Future<Map<String, dynamic>> getPartnerStats(
    int partnerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final result = await executeQuerySingle('''
      SELECT
        p.business_name,
        p.rating,
        p.no_of_ratings,
        p.commission_rate,
        COUNT(o.id) as total_orders,
        COUNT(CASE WHEN o.status = 'completed' THEN 1 END) as completed_orders,
        COALESCE(SUM(CASE WHEN o.status = 'completed' THEN o.total END), 0) as total_revenue,
        COALESCE(AVG(CASE WHEN o.status = 'completed' THEN o.total END), 0) as average_order_value,
        COUNT(DISTINCT DATE(o.created_at)) as active_days
      FROM partners p
      LEFT JOIN orders o ON p.id = o.partner_id
        AND o.created_at >= @startDate
        AND o.created_at <= @endDate
      WHERE p.id = @partnerId
      GROUP BY p.id, p.business_name, p.rating, p.no_of_ratings, p.commission_rate
    ''', parameters: {
      'partnerId': partnerId,
      'startDate': start.toIso8601String(),
      'endDate': end.toIso8601String(),
    });

    return result ?? {};
  }

  /// Get top rated partners
  Future<List<Partner>> getTopRatedPartners({int limit = 10}) async {
    final result = await connection.execute(
      '''SELECT * FROM partners 
         WHERE status = @status AND no_of_ratings >= 5
         ORDER BY rating DESC, no_of_ratings DESC
         LIMIT $limit''',
      parameters: {'status': PartnerStatus.active.name},
    );
    
    return result.map((row) => fromMap(row.toColumnMap())).toList();
  }

  /// Get partners with most orders
  Future<List<Map<String, dynamic>>> getPartnersWithMostOrders({
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String whereClause = '';
    Map<String, dynamic> parameters = {};

    if (startDate != null || endDate != null) {
      whereClause = 'WHERE ';
      final conditions = <String>[];
      
      if (startDate != null) {
        conditions.add('o.created_at >= @start_date');
        parameters['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        conditions.add('o.created_at <= @end_date');
        parameters['end_date'] = endDate.toIso8601String();
      }
      
      whereClause += conditions.join(' AND ');
    }

    final result = await executeQuery('''
      SELECT 
        p.*,
        COUNT(o.id) as total_orders,
        SUM(o.total_amount) as total_revenue
      FROM partners p
      LEFT JOIN orders o ON p.id = o.partner_id
      $whereClause
      GROUP BY p.id
      ORDER BY total_orders DESC, total_revenue DESC
      LIMIT $limit
    ''', parameters: parameters);

    return result;
  }

  /// Update partner commission rate
  Future<Partner?> updateCommissionRate(int partnerId, double commissionRate) async {
    return await update(partnerId, {'commission_rate': commissionRate});
  }

  /// Get partner performance metrics
  Future<Map<String, dynamic>?> getPartnerPerformance(int partnerId, {DateTime? startDate, DateTime? endDate}) async {
    String whereClause = 'WHERE o.partner_id = @partner_id';
    Map<String, dynamic> parameters = {'partner_id': partnerId};

    if (startDate != null || endDate != null) {
      final conditions = <String>['o.partner_id = @partner_id'];
      
      if (startDate != null) {
        conditions.add('o.created_at >= @start_date');
        parameters['start_date'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        conditions.add('o.created_at <= @end_date');
        parameters['end_date'] = endDate.toIso8601String();
      }
      
      whereClause = 'WHERE ' + conditions.join(' AND ');
    }

    final result = await executeQuerySingle('''
      SELECT 
        COUNT(o.id) as total_orders,
        COUNT(CASE WHEN o.status = 'delivered' THEN 1 END) as completed_orders,
        COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) as cancelled_orders,
        SUM(CASE WHEN o.status = 'delivered' THEN o.total_amount ELSE 0 END) as total_revenue,
        AVG(CASE WHEN o.status = 'delivered' THEN o.total_amount END) as average_order_value,
        AVG(CASE WHEN o.status = 'delivered' AND o.actual_delivery_time IS NOT NULL 
                 THEN EXTRACT(EPOCH FROM (o.actual_delivery_time - o.created_at))/60 END) as average_delivery_time_minutes
      FROM orders o
      $whereClause
    ''', parameters: parameters);

    return result;
  }
}