# خطة تنفيذ نظام Rabbit Ecosystem

- [x] 1. إعداد البنية الأساسية للمشروع




  - إنشاء هيكل المجلدات الأساسي للـ Backend (Serverpod) والـ Dashboard (Flutter Web)
  - إعداد ملفات التكوين الأساسية (pubspec.yaml, docker-compose.yml)
  - إعداد PostgreSQL وملفات الاتصال
  - إنشاء ملفات البيئة (.env) للإعدادات المختلفة
  - _Requirements: 1.1, 1.2, 11.1, 11.2_



- [x] 1.1 كتابة اختبار خاصية لإعداد قاعدة البيانات


  - **Property 1: Database Connection Pooling**

  - **Validates: Requirements 1.2**








- [x] 2. تنفيذ نظام المصادقة والتوكن

- [x] 2.1 إنشاء خدمة المصادقة الأساسية


  - تنفيذ JWT token generation و validation


  - إنشاء middleware للتحقق من التوكن
  - تنفيذ نظام refresh tokens



  - _Requirements: 1.3, 2.1, 2.2_



- [x] 2.2 كتابة اختبار خاصية لتوليد التوكن



  - **Property 2: JWT Token Generation and Validation**
  - **Validates: Requirements 1.3**




- [x] 2.3 كتابة اختبار خاصية للتحقق من التوكن


  - **Property 5: Token Validation**


  - **Validates: Requirements 2.2**




- [x] 2.4 تنفيذ نظام الأدوار والصلاحيات


  - إنشاء enum للأدوار المختلفة
  - تنفيذ middleware للتحقق من الصلاحيات

  - إعداد قواعد الوصول للـ APIs المختلفة
  - _Requirements: 1.4, 2.3, 2.4_





- [x] 2.5 كتابة اختبار خاصية للتحكم في الوصول





  - **Property 3: Role-Based Access Control**


  - **Validates: Requirements 1.4**


- [x] 2.6 كتابة اختبار خاصية لرفض التوكن المنتهي الصلاحية

  - **Property 8: Expired Token Rejection**
  - **Validates: Requirements 2.5**

- [x] 3. إنشاء نماذج البيانات وقاعدة البيانات


- [x] 3.1 تصميم وإنشاء جداول قاعدة البيانات



  - إنشاء جداول المستخدمين، الشركاء، السائقين
  - إنشاء جداول الطلبات، المنتجات، الفئات
  - إنشاء جداول المعاملات، العناوين، الإشعارات
  - إعداد العلاقات والفهارس
  - _Requirements: 1.2, 11.2_

- [x] 3.2 إنشاء نماذج البيانات في Dart

  - تنفيذ User, Partner, Rider models
  - تنفيذ Order, Product, Category models
  - تنفيذ Transaction, Address, Notification models
  - إضافة serialization/deserialization methods
  - _Requirements: 3.1, 4.1, 5.1_



- [x] 3.3 كتابة اختبارات الوحدة لنماذج البيانات


  - اختبار serialization/deserialization
  - اختبار validation methods
  - اختبار العلاقات بين النماذج
  - _Requirements: 3.1, 4.1, 5.1_

- [x] 4. تنفيذ طبقة Repository والخدمات الأساسية


- [x] 4.1 إنشاء Repository classes

  - تنفيذ UserRepository مع CRUD operations
  - تنفيذ OrderRepository مع البحث والفلترة
  - تنفيذ PartnerRepository مع إدارة الحالة
  - تنفيذ ProductRepository مع إدارة المخزون
  - _Requirements: 3.2, 4.2, 6.1, 7.1_

- [x] 4.2 تنفيذ Service Layer


  - إنشاء UserService للعمليات المعقدة
  - إنشاء OrderService لمعالجة الطلبات
  - إنشاء PartnerService لإدارة الشركاء
  - إنشاء ProductService لإدارة المنتجات
  - _Requirements: 3.1, 4.1, 6.1, 7.1_

- [x] 4.3 كتابة اختبار خاصية لتسجيل المستخدمين


  - **Property 9: User Registration Validation**
  - **Validates: Requirements 3.1**

- [x] 4.4 كتابة اختبار خاصية لتحديث الملف الشخصي


  - **Property 10: Profile Update Persistence**
  - **Validates: Requirements 3.2**

- [-] 5. تنفيذ APIs للتطبيقات المحمولة (/api/mobile/*)


- [x] 5.1 إنشاء Authentication endpoints




  - POST /api/mobile/auth/login
  - POST /api/mobile/auth/register
  - POST /api/mobile/auth/refresh
  - POST /api/mobile/auth/logout
  - _Requirements: 2.1, 3.1_

- [x] 5.2 إنشاء User Management endpoints


  - GET /api/mobile/user/profile
  - PUT /api/mobile/user/profile
  - GET /api/mobile/user/addresses
  - POST /api/mobile/user/addresses
  - _Requirements: 3.2, 3.3_

- [x] 5.3 إنشاء Partner و Product endpoints


  - GET /api/mobile/partners
  - GET /api/mobile/partners/{id}/products
  - GET /api/mobile/products/{id}
  - GET /api/mobile/categories
  - _Requirements: 4.1, 7.1, 7.3_

- [x] 5.4 إنشاء Order Management endpoints


  - POST /api/mobile/orders
  - GET /api/mobile/orders
  - GET /api/mobile/orders/{id}
  - PUT /api/mobile/orders/{id}/cancel
  - _Requirements: 6.1, 6.2, 6.5_

- [x] 5.5 كتابة اختبار خاصية لإنشاء الطلبات


  - **Property 24: Order Creation Process**
  - **Validates: Requirements 6.1**

- [ ] 5.6 إنشاء Cart و Payment endpoints


  - POST /api/mobile/cart/add
  - GET /api/mobile/cart
  - DELETE /api/mobile/cart/clear
  - POST /api/mobile/payments/process
  - _Requirements: 6.1, 8.1, 8.3_

- [ ] 6. تنفيذ APIs للوحة التحكم (/api/dashboard/*)
- [ ] 6.1 إنشاء Dashboard Analytics endpoints
  - GET /api/dashboard/analytics/overview
  - GET /api/dashboard/analytics/sales
  - GET /api/dashboard/analytics/users
  - GET /api/dashboard/analytics/orders
  - _Requirements: 10.2, 8.4_

- [ ] 6.2 إنشاء User Management endpoints للإدارة
  - GET /api/dashboard/users
  - POST /api/dashboard/users
  - PUT /api/dashboard/users/{id}
  - DELETE /api/dashboard/users/{id}
  - _Requirements: 3.3, 3.4, 10.3_

- [ ] 6.3 كتابة اختبار خاصية لفلترة المستخدمين
  - **Property 11: User List Filtering and Pagination**
  - **Validates: Requirements 3.3**

- [ ] 6.4 إنشاء Partner Management endpoints للإدارة
  - GET /api/dashboard/partners
  - POST /api/dashboard/partners
  - PUT /api/dashboard/partners/{id}
  - PUT /api/dashboard/partners/{id}/status
  - _Requirements: 4.1, 4.2, 10.3_

- [ ] 6.5 كتابة اختبار خاصية لتحديث حالة الشريك
  - **Property 15: Partner Status Updates**
  - **Validates: Requirements 4.2**

- [ ] 6.6 إنشاء Order Management endpoints للإدارة
  - GET /api/dashboard/orders
  - PUT /api/dashboard/orders/{id}/status
  - GET /api/dashboard/orders/{id}/details
  - POST /api/dashboard/orders/{id}/assign-rider
  - _Requirements: 6.2, 6.3, 10.3_

- [ ] 7. تنفيذ خدمات المعاملات والمحفظة
- [ ] 7.1 إنشاء Transaction Service
  - تنفيذ معالجة المدفوعات
  - حساب العمولات والتوزيع
  - إدارة أرصدة المحافظ
  - معالجة طلبات السحب
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 7.2 كتابة اختبار خاصية لمعالجة المعاملات
  - **Property 34: Transaction Processing**
  - **Validates: Requirements 8.1**

- [ ] 7.3 كتابة اختبار خاصية لتوزيع المدفوعات
  - **Property 36: Payment Distribution**
  - **Validates: Requirements 8.3**

- [ ] 7.4 إنشاء Wallet Management endpoints
  - GET /api/mobile/wallet/balance
  - GET /api/mobile/wallet/transactions
  - POST /api/mobile/wallet/withdrawal
  - GET /api/dashboard/wallets/overview
  - _Requirements: 8.1, 8.2, 8.4_

- [ ] 8. تنفيذ نظام الإشعارات
- [ ] 8.1 إعداد Firebase Cloud Messaging
  - تكوين Firebase project
  - إنشاء خدمة إرسال الإشعارات
  - تنفيذ notification templates
  - _Requirements: 9.1, 9.2_

- [ ] 8.2 كتابة اختبار خاصية لاستهداف الإشعارات
  - **Property 39: Notification Targeting**
  - **Validates: Requirements 9.1**

- [ ] 8.3 تنفيذ WebSocket للتحديثات الفورية
  - إعداد WebSocket server
  - تنفيذ real-time order updates
  - تنفيذ live dashboard updates
  - _Requirements: 9.3, 10.4_

- [ ] 8.4 كتابة اختبار خاصية للتحديثات الفورية
  - **Property 41: WebSocket Real-time Updates**
  - **Validates: Requirements 9.3**

- [ ] 8.5 إنشاء Notification Management endpoints
  - POST /api/dashboard/notifications/send
  - GET /api/dashboard/notifications/templates
  - GET /api/dashboard/notifications/history
  - _Requirements: 9.4, 9.5_

- [ ] 9. تطوير لوحة التحكم (Flutter Web)
- [ ] 9.1 إعداد مشروع Flutter Web
  - إنشاء مشروع Flutter Web جديد
  - إعداد routing والتنقل
  - تكوين HTTP client للـ APIs
  - إعداد state management (BLoC)
  - _Requirements: 10.1, 10.2_

- [ ] 9.2 تنفيذ صفحة تسجيل الدخول
  - تصميم واجهة تسجيل الدخول
  - تنفيذ authentication logic
  - إدارة JWT tokens
  - التوجيه حسب الدور
  - _Requirements: 10.1, 2.3, 2.4_

- [ ] 9.3 كتابة اختبار خاصية لواجهة لوحة التحكم
  - **Property 44: Dashboard Role-Based UI**
  - **Validates: Requirements 10.1**

- [ ] 9.4 تنفيذ لوحة التحكم الرئيسية
  - عرض الإحصائيات العامة
  - الرسوم البيانية والتقارير
  - الأنشطة الحديثة
  - _Requirements: 10.2, 10.4_

- [ ] 9.5 تنفيذ صفحات إدارة المستخدمين
  - قائمة العملاء مع البحث والفلترة
  - قائمة الشركاء مع إدارة الحالة
  - قائمة السائقين مع تتبع الأداء
  - _Requirements: 10.3, 3.3, 4.2, 5.2_

- [ ] 9.6 تنفيذ صفحات إدارة الطلبات
  - عرض جميع الطلبات مع الفلترة
  - تتبع حالة الطلبات
  - إدارة المشاكل والشكاوى
  - _Requirements: 10.3, 6.2, 6.5_

- [ ] 9.7 تنفيذ صفحات التقارير والإحصائيات
  - تقارير المبيعات
  - تقارير الأداء
  - تحليلات المستخدمين
  - _Requirements: 10.2, 8.4_

- [ ] 10. Checkpoint - التأكد من نجاح جميع الاختبارات
  - التأكد من نجاح جميع الاختبارات، اسأل المستخدم إذا ظهرت أسئلة

- [ ] 11. إعداد البيئة الإنتاجية
- [ ] 11.1 إعداد Ubuntu VPS
  - تثبيت وتكوين Ubuntu Server
  - إعداد firewall وإعدادات الأمان
  - تثبيت Docker و Docker Compose
  - إعداد SSL certificates
  - _Requirements: 11.1, 11.3_

- [ ] 11.2 نشر قاعدة البيانات PostgreSQL
  - تثبيت وتكوين PostgreSQL
  - إنشاء قاعدة البيانات والمستخدمين
  - تشغيل migration scripts
  - إعداد النسخ الاحتياطية
  - _Requirements: 11.2_

- [ ] 11.3 نشر Backend Serverpod
  - بناء Docker image للـ Backend
  - إعداد environment variables
  - نشر الخدمة مع Docker Compose
  - اختبار APIs في البيئة الإنتاجية
اك  - _Requirements: 11.3_

- [ ] 11.4 نشر Dashboard Flutter Web
  - بناء Flutter Web للإنتاج
  - إعداد nginx configuration
  - نشر الملفات الثابتة
  - اختبار الوصول والوظائف
  - _Requirements: 11.4_

- [ ] 11.5 إعداد Nginx وSSL
  - تكوين nginx كـ reverse proxy
  - إعداد SSL certificates مع Let's Encrypt
  - تكوين load balancing إذا لزم الأمر
  - اختبار الأمان والأداء
  - _Requirements: 11.3, 11.4_

- [ ] 12. إنشاء الوثائق والملفات التشغيلية
- [ ] 12.1 كتابة وثائق API
  - إنشاء Swagger/OpenAPI documentation
  - أمثلة على الطلبات والاستجابات
  - أكواد الأخطاء ومعانيها
  - دليل المطور

- [ ] 12.2 كتابة دليل النشر والتشغيل
  - دليل تثبيت النظام خطوة بخطوة
  - إعدادات البيئة الإنتاجية
  - إجراءات الصيانة والنسخ الاحتياطي
  - استكشاف الأخطاء وإصلاحها

- [ ] 12.3 إنشاء ملفات README شاملة
  - README.md للمشروع الكامل
  - README.md للـ Backend
  - README.md للـ Dashboard
  - تعليمات التطوير والمساهمة

- [ ] 13. Final Checkpoint - التأكد من نجاح جميع الاختبارات
  - التأكد من نجاح جميع الاختبارات، اسأل المستخدم إذا ظهرت أسئلة