# وثيقة تصميم نظام Rabbit Ecosystem

## نظرة عامة

نظام Rabbit Ecosystem هو منصة توصيل طعام متكاملة تتكون من Backend API مبني بـ Dart + Serverpod ولوحة تحكم إدارية مبنية بـ Flutter Web. النظام يدعم APIs منفصلة للتطبيقات المحمولة (/api/mobile/*) ولوحة التحكم (/api/dashboard/*) مع نظام مصادقة JWT متقدم وإدارة صلاحيات شاملة.

## البنية المعمارية

### البنية العامة
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile Apps   │    │  Dashboard Web  │    │  Admin Panel    │
│   (Flutter)     │    │   (Flutter)     │    │   (Flutter)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ /api/mobile/*         │ /api/dashboard/*      │
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Nginx Reverse  │
                    │     Proxy       │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Serverpod     │
                    │   Backend       │
                    │   (Dart)        │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │   Database      │
                    └─────────────────┘
```

### نمط المعمارية
- **Clean Architecture**: فصل طبقات العمل والبيانات والعرض
- **Repository Pattern**: طبقة تجريد لقاعدة البيانات
- **Service Layer**: منطق العمل المركزي
- **API Gateway Pattern**: توجيه الطلبات حسب النوع

## المكونات والواجهات

### 1. Backend Services (Serverpod)

#### Authentication Service
```dart
abstract class AuthenticationService {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(UserRegistration registration);
  Future<bool> validateToken(String token);
  Future<bool> refreshToken(String refreshToken);
  Future<void> logout(String token);
}
```

#### User Management Service
```dart
abstract class UserService {
  Future<User> createUser(CreateUserRequest request);
  Future<User> updateUser(int userId, UpdateUserRequest request);
  Future<User?> getUserById(int userId);
  Future<List<User>> getUsers(UserFilter filter);
  Future<bool> deactivateUser(int userId);
}
```

#### Order Management Service
```dart
abstract class OrderService {
  Future<Order> createOrder(CreateOrderRequest request);
  Future<Order> updateOrderStatus(int orderId, OrderStatus status);
  Future<List<Order>> getOrders(OrderFilter filter);
  Future<Order?> getOrderById(int orderId);
  Future<bool> cancelOrder(int orderId, String reason);
}
```

#### Partner Management Service
```dart
abstract class PartnerService {
  Future<Partner> createPartner(CreatePartnerRequest request);
  Future<Partner> updatePartner(int partnerId, UpdatePartnerRequest request);
  Future<List<Partner>> getPartners(PartnerFilter filter);
  Future<bool> updatePartnerStatus(int partnerId, PartnerStatus status);
}
```

### 2. API Endpoints Structure

#### Mobile API (/api/mobile/*)
```
POST   /api/mobile/auth/login
POST   /api/mobile/auth/register
GET    /api/mobile/partners
GET    /api/mobile/products
POST   /api/mobile/orders
GET    /api/mobile/orders/{id}
POST   /api/mobile/cart/add
GET    /api/mobile/user/profile
```

#### Dashboard API (/api/dashboard/*)
```
GET    /api/dashboard/analytics/overview
GET    /api/dashboard/users
POST   /api/dashboard/users
GET    /api/dashboard/orders
PUT    /api/dashboard/orders/{id}/status
GET    /api/dashboard/partners
POST   /api/dashboard/partners
GET    /api/dashboard/reports/sales
```

### 3. Database Layer

#### Repository Interfaces
```dart
abstract class UserRepository {
  Future<User> create(User user);
  Future<User?> findById(int id);
  Future<User?> findByEmail(String email);
  Future<List<User>> findByRole(UserRole role);
  Future<User> update(User user);
  Future<bool> delete(int id);
}

abstract class OrderRepository {
  Future<Order> create(Order order);
  Future<Order?> findById(int id);
  Future<List<Order>> findByStatus(OrderStatus status);
  Future<List<Order>> findByUser(int userId);
  Future<Order> update(Order order);
}
```

## نماذج البيانات

### User Model
```dart
class User {
  final int id;
  final String username;
  final String email;
  final String mobile;
  final UserRole role;
  final double balance;
  final double rating;
  final int numberOfRatings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

enum UserRole {
  customer,
  partner,
  rider,
  superAdmin,
  admin,
  finance,
  support
}
```

### Order Model
```dart
class Order {
  final int id;
  final int userId;
  final int? riderId;
  final int partnerId;
  final int addressId;
  final double total;
  final double deliveryCharge;
  final double taxAmount;
  final double finalTotal;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final String? otp;
  final DateTime? deliveryTime;
  final List<OrderItem> items;
  final DateTime createdAt;
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  pickedUp,
  delivered,
  cancelled
}
```

### Partner Model
```dart
class Partner {
  final int id;
  final int userId;
  final String partnerName;
  final String ownerName;
  final String address;
  final int cityId;
  final double latitude;
  final double longitude;
  final int cookingTime;
  final double commission;
  final bool isFeatured;
  final bool isBusy;
  final PartnerStatus status;
  final DateTime createdAt;
}

enum PartnerStatus {
  active,
  inactive,
  suspended
}
```

### Product Model
```dart
class Product {
  final int id;
  final int partnerId;
  final int categoryId;
  final String name;
  final String shortDescription;
  final String image;
  final ProductStatus status;
  final double rating;
  final int numberOfRatings;
  final List<ProductVariant> variants;
  final List<ProductAddOn> addOns;
  final DateTime createdAt;
}
```

## خصائص الصحة

*خاصية هي سمة أو سلوك يجب أن يكون صحيحاً عبر جميع التنفيذات الصالحة للنظام - في الأساس، بيان رسمي حول ما يجب أن يفعله النظام. الخصائص تعمل كجسر بين المواصفات المقروءة بشرياً وضمانات الصحة القابلة للتحقق آلياً.*
بناءً على تحليل معايير القبول، إليك الخصائص القابلة للاختبار:

**Property 1: Database Connection Pooling**
*For any* database connection request, the system should establish connections through proper connection pooling without exceeding configured limits
**Validates: Requirements 1.2**

**Property 2: JWT Token Generation and Validation**
*For any* valid user credentials, the authentication system should generate valid JWT tokens that can be successfully validated
**Validates: Requirements 1.3**

**Property 3: Role-Based Access Control**
*For any* API endpoint and user role combination, the system should only allow access to endpoints permitted for that specific role
**Validates: Requirements 1.4**

**Property 4: Login Token Generation**
*For any* valid user credentials, the authentication system should generate JWT tokens containing the correct user role information
**Validates: Requirements 2.1**

**Property 5: Token Validation**
*For any* JWT token, the authentication system should correctly validate token signature and expiration status
**Validates: Requirements 2.2**

**Property 6: Customer Role Access Restriction**
*For any* customer role user, the authentication system should only grant access to /api/mobile/* endpoints
**Validates: Requirements 2.3**

**Property 7: Admin Role Access Control**
*For any* admin role user (super_admin, admin, finance, support), the authentication system should grant access to appropriate /api/dashboard/* endpoints based on role-specific permissions
**Validates: Requirements 2.4**

**Property 8: Expired Token Rejection**
*For any* expired JWT token, the authentication system should reject requests and require re-authentication
**Validates: Requirements 2.5**

**Property 9: User Registration Validation**
*For any* user registration request, the system should create user accounts with proper role assignment and data validation
**Validates: Requirements 3.1**

**Property 10: Profile Update Persistence**
*For any* user profile update, the system should validate changes and persist them correctly to the database
**Validates: Requirements 3.2**

**Property 11: User List Filtering and Pagination**
*For any* user list request with role filter and pagination parameters, the system should return correctly filtered and paginated results
**Validates: Requirements 3.3**

**Property 12: Account Deactivation**
*For any* user account deactivation, the system should prevent login while preserving all historical data
**Validates: Requirements 3.4**

**Property 13: User Attribute Maintenance**
*For any* user of any role, the system should properly maintain balance, ratings, and activity status
**Validates: Requirements 3.5**

**Property 14: Partner Registration**
*For any* partner registration request, the system should create partner profiles with complete location and business information
**Validates: Requirements 4.1**

**Property 15: Partner Status Updates**
*For any* partner status change, the system should update availability and trigger appropriate system notifications
**Validates: Requirements 4.2**

**Property 16: Commission Calculation**
*For any* partner transaction, the system should apply correct commission rates based on partner-specific agreements
**Validates: Requirements 4.3**

**Property 17: Partner Performance Metrics**
*For any* partner performance evaluation, the system should calculate accurate ratings and cooking time metrics
**Validates: Requirements 4.4**

**Property 18: Partner Attribute Management**
*For any* partner, the system should properly manage categories, featured status, and operational hours
**Validates: Requirements 4.5**

**Property 19: Rider Registration**
*For any* rider registration request, the system should create rider profiles with complete vehicle and document information
**Validates: Requirements 5.1**

**Property 20: Rider Availability Management**
*For any* rider availability toggle, the system should update rider status and affect order assignment accordingly
**Validates: Requirements 5.2**

**Property 21: Rider Location Tracking**
*For any* rider location update, the system should store current location and use it for delivery optimization
**Validates: Requirements 5.3**

**Property 22: Rider Performance Tracking**
*For any* rider performance evaluation, the system should calculate accurate delivery ratings and completion rates
**Validates: Requirements 5.4**

**Property 23: Rider Data Management**
*For any* rider, the system should properly track earnings, delivery history, and working hours
**Validates: Requirements 5.5**

**Property 24: Order Creation Process**
*For any* order placement, the system should create orders with items, calculate correct totals, and assign to available partners
**Validates: Requirements 6.1**

**Property 25: Order Status Notifications**
*For any* order status update, the system should notify all relevant parties and update delivery tracking
**Validates: Requirements 6.2**

**Property 26: Order Assignment to Rider**
*For any* order assigned to a rider, the system should generate unique OTP and provide complete delivery instructions
**Validates: Requirements 6.3**

**Property 27: Order Completion Processing**
*For any* completed order, the system should process payments, update balances, and record transactions correctly
**Validates: Requirements 6.4**

**Property 28: Order Cancellation Handling**
*For any* order cancellation, the system should handle refunds and dispute resolution according to business rules
**Validates: Requirements 6.5**

**Property 29: Product Creation Validation**
*For any* product creation request, the system should validate product data and properly associate with partner and category
**Validates: Requirements 7.1**

**Property 30: Product Variant Management**
*For any* product with variants, the system should correctly handle different sizes, prices, and add-ons
**Validates: Requirements 7.2**

**Property 31: Real-time Product Updates**
*For any* product availability change, the system should reflect changes immediately in customer applications
**Validates: Requirements 7.3**

**Property 32: Product Rating Calculation**
*For any* product rating submission, the system should calculate accurate average ratings and update product scores
**Validates: Requirements 7.4**

**Property 33: Product Attribute Management**
*For any* product, the system should properly manage images, descriptions, and promotional pricing
**Validates: Requirements 7.5**

**Property 34: Transaction Processing**
*For any* transaction, the system should record complete transaction details and update relevant wallet balances correctly
**Validates: Requirements 8.1**

**Property 35: Withdrawal Request Processing**
*For any* withdrawal request, the system should validate and process according to established business rules
**Validates: Requirements 8.2**

**Property 36: Payment Distribution**
*For any* completed payment, the system should distribute amounts to partner, rider, and platform according to commission structure
**Validates: Requirements 8.3**

**Property 37: Financial Report Accuracy**
*For any* financial report generation, the system should provide accurate calculations with complete audit trail
**Validates: Requirements 8.4**

**Property 38: Payment Method Support**
*For any* payment method, the system should handle transactions and currency calculations correctly
**Validates: Requirements 8.5**

**Property 39: Notification Targeting**
*For any* notification event, the system should send appropriate notifications to correctly targeted users
**Validates: Requirements 9.1**

**Property 40: Firebase Integration**
*For any* push notification, the system should successfully integrate with Firebase Cloud Messaging for delivery
**Validates: Requirements 9.2**

**Property 41: WebSocket Real-time Updates**
*For any* real-time update requirement, the system should use WebSocket connections for instant communication
**Validates: Requirements 9.3**

**Property 42: Notification Personalization**
*For any* notification template usage, the system should personalize content based on user data and language preferences
**Validates: Requirements 9.4**

**Property 43: Notification Tracking**
*For any* notification sent, the system should track delivery status and user engagement metrics
**Validates: Requirements 9.5**

**Property 44: Dashboard Role-Based UI**
*For any* dashboard access, the system should authenticate users and display role-appropriate interface elements
**Validates: Requirements 10.1**

**Property 45: Dashboard API Endpoint Usage**
*For any* dashboard data request, the system should fetch data exclusively from /api/dashboard/* endpoints
**Validates: Requirements 10.2**

**Property 46: Administrative Action Validation**
*For any* administrative action, the dashboard should validate permissions before executing through appropriate API calls
**Validates: Requirements 10.3**

**Property 47: Dashboard Real-time Updates**
*For any* real-time data requirement, the dashboard should maintain WebSocket connections for live data updates
**Validates: Requirements 10.4**

## معالجة الأخطاء

### استراتيجية معالجة الأخطاء
1. **Structured Error Responses**: جميع APIs تُرجع أخطاء منظمة مع رموز HTTP مناسبة
2. **Error Logging**: تسجيل شامل للأخطاء مع معلومات السياق
3. **Graceful Degradation**: النظام يستمر في العمل حتى مع فشل بعض المكونات
4. **Retry Mechanisms**: إعادة المحاولة التلقائية للعمليات المؤقتة الفاشلة

### أنواع الأخطاء
```dart
enum ErrorType {
  validation,
  authentication,
  authorization,
  notFound,
  conflict,
  serverError,
  networkError,
  timeout
}

class ApiError {
  final ErrorType type;
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
}
```

### معالجة الأخطاء في الطبقات المختلفة
- **API Layer**: التحقق من صحة المدخلات وإرجاع أخطاء HTTP مناسبة
- **Service Layer**: معالجة منطق العمل والتحقق من القواعد
- **Repository Layer**: معالجة أخطاء قاعدة البيانات والاتصال
- **Client Layer**: عرض رسائل خطأ مفهومة للمستخدم

## استراتيجية الاختبار

### نهج الاختبار المزدوج
النظام يستخدم نهجاً مزدوجاً للاختبار يجمع بين:

#### اختبارات الوحدة (Unit Tests)
- اختبار مكونات فردية معزولة
- التحقق من أمثلة محددة وحالات حدية
- اختبار نقاط التكامل بين المكونات
- التركيز على السيناريوهات المحددة والحالات الاستثنائية

#### اختبارات قائمة على الخصائص (Property-Based Tests)
- التحقق من الخصائص العامة عبر مدخلات متعددة
- استخدام مكتبة **test** و **faker** في Dart لتوليد البيانات
- تشغيل كل اختبار خاصية لـ 100 تكرار على الأقل
- كل اختبار خاصية يجب أن يحتوي على تعليق يربطه بخاصية التصميم

#### متطلبات اختبارات الخصائص
- استخدام مكتبة **test** و **faker** للاختبارات القائمة على الخصائص
- تكوين كل اختبار خاصية لتشغيل 100 تكرار كحد أدنى
- وسم كل اختبار خاصية بتعليق يحدد الخاصية المرتبطة بصيغة: '**Feature: rabbit-ecosystem, Property {number}: {property_text}**'
- كل خاصية صحة يجب أن تُنفذ بواسطة اختبار خاصية واحد
- التركيز على اختبار المنطق الأساسي والحالات الحدية المهمة

#### إرشادات الاختبار العامة
- الاختبارات تكمل بعضها البعض: اختبارات الوحدة تكتشف أخطاء محددة، اختبارات الخصائص تتحقق من الصحة العامة
- كتابة حلول اختبار مبسطة - تجنب الإفراط في اختبار الحالات الحدية
- الحد من محاولات التحقق إلى محاولتين كحد أقصى
- عدم استخدام Mock أو بيانات وهمية لجعل الاختبارات تنجح - الاختبارات يجب أن تتحقق من الوظائف الحقيقية
- توليد اختبارات تركز على منطق الوظائف الأساسية والحالات الحدية المهمة

### بنية الاختبارات
```
test/
├── unit/
│   ├── services/
│   ├── repositories/
│   └── models/
├── integration/
│   ├── api/
│   └── database/
└── property/
    ├── auth_properties_test.dart
    ├── order_properties_test.dart
    └── user_properties_test.dart
```

### أدوات الاختبار
- **test**: إطار عمل الاختبار الأساسي في Dart
- **faker**: توليد بيانات اختبار عشوائية
- **mockito**: إنشاء Mock objects للاختبارات
- **integration_test**: اختبارات التكامل الشاملة

## الأمان

### مصادقة JWT
- استخدام RS256 للتوقيع
- انتهاء صلاحية التوكن خلال 24 ساعة
- Refresh tokens صالحة لـ 30 يوم
- تخزين آمن للمفاتيح الخاصة

### تشفير البيانات
- تشفير كلمات المرور باستخدام bcrypt
- تشفير البيانات الحساسة في قاعدة البيانات
- استخدام HTTPS لجميع الاتصالات
- تشفير WebSocket connections

### التحقق من المدخلات
- التحقق من صحة جميع المدخلات
- منع SQL Injection
- تنظيف البيانات المدخلة
- حدود معدل الطلبات (Rate Limiting)

## الأداء

### تحسين قاعدة البيانات
- فهرسة الحقول المستخدمة في البحث
- تحسين الاستعلامات المعقدة
- Connection pooling
- Database caching

### تحسين API
- Response caching
- Pagination للقوائم الطويلة
- Compression للاستجابات
- CDN للملفات الثابتة

### مراقبة الأداء
- تتبع أوقات الاستجابة
- مراقبة استخدام الذاكرة
- تتبع معدل الأخطاء
- إنذارات الأداء

## النشر والبنية التحتية

### متطلبات الخادم
- Ubuntu 20.04 LTS أو أحدث
- 4GB RAM كحد أدنى
- 50GB مساحة تخزين
- اتصال إنترنت مستقر

### مكونات النشر
```
Production Stack:
├── Nginx (Reverse Proxy + SSL)
├── Serverpod Backend
├── PostgreSQL Database
├── Flutter Web Dashboard
├── SSL Certificates (Let's Encrypt)
└── Monitoring Tools
```

### إعداد Nginx
```nginx
server {
    listen 443 ssl;
    server_name api.rabbito.com;
    
    ssl_certificate /etc/letsencrypt/live/api.rabbito.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.rabbito.com/privkey.pem;
    
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location / {
        root /var/www/dashboard;
        try_files $uri $uri/ /index.html;
    }
}
```

### إعداد قاعدة البيانات
```sql
-- إعداد قاعدة البيانات الأساسية
CREATE DATABASE rabbito_ecosystem;
CREATE USER rabbito_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE rabbito_ecosystem TO rabbito_user;

-- إعداد الفهارس الأساسية
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

### النسخ الاحتياطي والمراقبة
- نسخ احتياطية يومية لقاعدة البيانات
- مراقبة حالة الخدمات
- تسجيل الأحداث المهمة
- إنذارات الأعطال

## التوثيق

### وثائق API
- Swagger/OpenAPI documentation
- أمثلة على الطلبات والاستجابات
- أكواد الأخطاء ومعانيها
- دليل المطور

### وثائق النشر
- دليل تثبيت النظام
- إعدادات البيئة الإنتاجية
- إجراءات الصيانة
- استكشاف الأخطاء وإصلاحها

### وثائق المستخدم
- دليل استخدام لوحة التحكم
- شرح الأدوار والصلاحيات
- إجراءات العمليات اليومية
- الأسئلة الشائعة