# تحليل شامل لنظام Rabbit Ecosystem

## نظرة عامة على المشروع

نظام Rabbit Ecosystem هو منصة توصيل طعام متكاملة تتكون من ثلاثة تطبيقات Flutter مترابطة:

### 1. Rabbito (تطبيق العملاء)
- **الغرض**: تطبيق للعملاء لطلب الطعام والمنتجات
- **المسار**: `rabbito/`
- **الميزات الرئيسية**: تصفح المطاعم، إدارة السلة، تتبع الطلبات، المدفوعات

### 2. Rabbit-Partners (تطبيق الشركاء)
- **الغرض**: تطبيق لأصحاب المطاعم والمتاجر لإدارة أعمالهم
- **المسار**: `Rabbit-Partners/`
- **الميزات الرئيسية**: إدارة الطلبات، إدارة المنتجات، التقارير المالية

### 3. Rabbit-driver (تطبيق السائقين)
- **الغرض**: تطبيق لسائقي التوصيل لإدارة عمليات التسليم
- **المسار**: `Rabbit-driver/`
- **الميزات الرئيسية**: قبول الطلبات، تتبع الموقع، إدارة المحفظة

## البنية العامة (Architecture)

### نمط إدارة الحالة
جميع التطبيقات الثلاثة تستخدم **BLoC Pattern** لإدارة الحالة:
- **flutter_bloc**: ^9.1.1
- **dartz**: ^0.10.1 (للبرمجة الوظيفية)

### هيكل المجلدات المشترك
```
lib/
├── core/                 # الخدمات والأدوات المشتركة
├── features/            # الميزات الرئيسية
├── model/               # نماذج البيانات
├── network/             # طبقة الشبكة والAPI
├── routes/              # التنقل والمسارات
└── main.dart           # نقطة البداية
```

## الميزات والوظائف

### تطبيق Rabbito (العملاء)

#### الميزات الأساسية:
1. **المصادقة والتسجيل** (`features/auth/`)
   - تسجيل الدخول بالهاتف
   - التحقق من OTP
   - إدارة الملف الشخصي

2. **الصفحة الرئيسية** (`features/home/`)
   - عرض المطاعم والمتاجر
   - البانرات والعروض
   - البحث والفلترة

3. **إدارة العناوين** (`features/addresses/`)
   - إضافة وتعديل العناوين
   - تكامل خرائط Google
   - تحديد الموقع الحالي

4. **السلة والطلبات** (`features/checkout/`, `features/my_orders/`)
   - إدارة السلة
   - عملية الدفع
   - تتبع الطلبات

5. **المحفظة والمدفوعات** (`features/wallet/`)
   - إدارة الرصيد
   - تاريخ المعاملات
   - طرق الدفع المتعددة

6. **الخدمات المتخصصة**
   - المطاعم (`features/services/restaurant/`)
   - السوبر ماركت (`features/services/super_market/`)
   - المقاهي والحلويات (`features/services/sweets_cafe_shops/`)
   - توصيل البضائع (`features/cargo_delivery/`)

### تطبيق Rabbit-Partners (الشركاء)

#### الميزات الأساسية:
1. **إدارة الطلبات** (`features/view/order_screen/`)
   - عرض الطلبات الواردة
   - تحديث حالة الطلبات
   - طباعة الفواتير

2. **إدارة المنتجات** (`features/view/products/`)
   - إضافة وتعديل المنتجات
   - إدارة المخزون
   - الفئات والعروض

3. **التقارير المالية** (`features/view/transactions/`)
   - تتبع المبيعات
   - إدارة المحفظة
   - طلبات السحب

4. **إعدادات المتجر** (`features/view/setting/`)
   - أوقات العمل
   - معلومات المتجر
   - إعدادات التوصيل

### تطبيق Rabbit-driver (السائقين)

#### الميزات الأساسية:
1. **إدارة الطلبات** (`features/view/orders/`)
   - قبول الطلبات
   - تحديث حالة التسليم
   - تتبع المسار

2. **إدارة المحفظة** (`features/view/wallet/`)
   - عرض الأرباح
   - تحصيل النقدية
   - طلبات السحب

3. **الملف الشخصي** (`features/view/profile/`)
   - معلومات السائق
   - حالة العمل
   - التقييمات

## الخدمات والمكتبات المستخدمة

### خدمات Firebase
- **firebase_core**: ^4.2.1
- **firebase_messaging**: ^16.0.4 (الإشعارات)
- **cloud_firestore**: ^6.1.1 (قاعدة البيانات - Rabbito فقط)

### الشبكة والAPI
- **dio**: ^5.9.0 (HTTP client)
- **dio_smart_retry**: ^7.0.1 (إعادة المحاولة)
- **requests_inspector**: ^5.1.1 (تتبع الطلبات)

### الخرائط والموقع
- **google_maps_flutter**: ^2.13.1
- **geolocator**: ^14.0.2
- **location**: ^8.0.1
- **geocoding**: ^4.0.0

### التخزين المحلي
- **shared_preferences**: ^2.5.3
- **flutter_secure_storage**: ^9.2.4 (Rabbito فقط)

### واجهة المستخدم
- **flutter_screenutil**: ^5.9.3 (التكيف مع الشاشة)
- **flutter_svg**: ^2.2.1
- **cached_network_image**: ^3.4.1
- **lottie**: ^3.3.0 (الرسوم المتحركة)

### التواصل الفوري
- **pusher_channels_flutter**: ^2.5.0 (Partners & Driver)

### المدفوعات
- **paymob_payment**: ^0.0.1+1 (Rabbito فقط)

### أخرى
- **easy_localization**: ^3.0.8 (تعدد اللغات)
- **permission_handler**: ^12.0.1
- **device_info_plus**: ^12.1.0

## نماذج البيانات الرئيسية

### 1. نموذج المستخدم (User Model)
```dart
class AuthLoginModel {
  bool? error;
  String? token;
  String? message;
  Data? data; // معلومات المستخدم التفصيلية
}
```

### 2. نموذج الطلب (Order Model)
```dart
class OrderModel {
  String? id;
  String? userId;
  String? riderId;
  String? partnerId;
  String? total;
  String? deliveryCharge;
  String? paymentMethod;
  String? status;
  List<OrderItems>? orderItems;
}
```

### 3. نموذج الشريك (Partner Model)
```dart
class PartnersData {
  String? partnerId;
  String? partnerName;
  String? email;
  String? mobile;
  String? partnerAddress;
  String? partnerRating;
  String? cookingTime;
  List<String>? categoryIds;
  Permissions? permissions;
}
```

### 4. نموذج المنتج (Product Model)
```dart
class ProductMangerData {
  String? id;
  String? name;
  String? categoryId;
  String? partnerId;
  String? price;
  String? image;
  List<Variants>? variants;
  List<ProductAddOns>? productAddOns;
}
```

## API Endpoints المستخدمة

### Base URLs:
- **Customer App**: `https://hamster.nahrdev.com/app/v1/api/`
- **Partner App**: `https://hamster.nahrdev.com/partner/app/v1/api/`
- **Driver App**: `https://hamster.nahrdev.com/rider/app/v1/api/`

### المصادقة والمستخدمين
- `POST /login` - تسجيل الدخول
- `POST /register_user` - تسجيل مستخدم جديد
- `POST /verify_otp` - التحقق من OTP
- `POST /resend_otp` - إعادة إرسال OTP
- `GET /showProfile` - عرض الملف الشخصي
- `POST /updateProfile` - تحديث الملف الشخصي

### الطلبات
- `GET /get_orders` - جلب الطلبات
- `POST /place_order` - إنشاء طلب جديد
- `POST /update_order_status` - تحديث حالة الطلب
- `GET /order_details` - تفاصيل الطلب

### المنتجات والشركاء
- `GET /get_partners` - جلب الشركاء
- `GET /get_products` - جلب المنتجات
- `GET /get_categories` - جلب الفئات
- `POST /manage_cart` - إدارة السلة

### العناوين
- `GET /get_address` - جلب العناوين
- `POST /add_address` - إضافة عنوان
- `POST /update_address` - تحديث عنوان
- `DELETE /delete_address` - حذف عنوان

### المحفظة والمعاملات
- `GET /transactions` - جلب المعاملات
- `POST /add_transaction` - إضافة معاملة
- `POST /send_withdrawal_request` - طلب سحب

## هيكل قاعدة البيانات المتوقع

### الجداول الرئيسية:

#### 1. جدول المستخدمين (users)
```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    mobile VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255),
    type ENUM('customer', 'partner', 'rider'),
    balance DECIMAL(10,2) DEFAULT 0,
    rating DECIMAL(3,2),
    no_of_ratings INT DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. جدول الشركاء (partners)
```sql
CREATE TABLE partners (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    partner_name VARCHAR(255),
    owner_name VARCHAR(255),
    partner_address TEXT,
    city_id INT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    cooking_time INT,
    commission DECIMAL(5,2),
    is_featured BOOLEAN DEFAULT FALSE,
    is_busy BOOLEAN DEFAULT FALSE,
    status ENUM('active', 'inactive', 'suspended'),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### 3. جدول الطلبات (orders)
```sql
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    rider_id INT,
    partner_id INT,
    address_id INT,
    total DECIMAL(10,2),
    delivery_charge DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    final_total DECIMAL(10,2),
    payment_method VARCHAR(50),
    status VARCHAR(50),
    active_status VARCHAR(50),
    otp VARCHAR(6),
    delivery_time TIME,
    delivery_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (rider_id) REFERENCES users(id),
    FOREIGN KEY (partner_id) REFERENCES partners(id)
);
```

#### 4. جدول المنتجات (products)
```sql
CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    partner_id INT,
    category_id INT,
    name VARCHAR(255),
    short_description TEXT,
    image VARCHAR(255),
    status ENUM('active', 'inactive'),
    rating DECIMAL(3,2),
    no_of_ratings INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (partner_id) REFERENCES partners(id)
);
```

#### 5. جدول عناصر الطلب (order_items)
```sql
CREATE TABLE order_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    product_variant_id INT,
    quantity INT,
    price DECIMAL(10,2),
    discounted_price DECIMAL(10,2),
    sub_total DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);
```

## متطلبات الـ Backend

### APIs المطلوبة:

#### 1. خدمات المصادقة
- نظام JWT للمصادقة
- إدارة OTP للتحقق
- إدارة الجلسات والتوكن

#### 2. خدمات الطلبات
- إنشاء ومعالجة الطلبات
- تتبع حالة الطلبات
- إدارة المدفوعات

#### 3. خدمات الإشعارات
- إشعارات push عبر Firebase
- إشعارات real-time عبر Pusher
- إدارة قوالب الإشعارات

#### 4. خدمات الموقع
- حساب المسافات والتكاليف
- تكامل مع Google Maps API
- إدارة مناطق التوصيل

### Database Tables المطلوبة:
- users (المستخدمين)
- partners (الشركاء)
- riders (السائقين)
- categories (الفئات)
- products (المنتجات)
- product_variants (متغيرات المنتجات)
- orders (الطلبات)
- order_items (عناصر الطلبات)
- addresses (العناوين)
- transactions (المعاملات)
- notifications (الإشعارات)
- cities (المدن)
- settings (الإعدادات)

## متطلبات الـ Dashboard

### الصفحات المطلوبة:

#### 1. لوحة التحكم الرئيسية
- إحصائيات عامة (الطلبات، المبيعات، المستخدمين)
- الرسوم البيانية والتقارير
- الأنشطة الحديثة

#### 2. إدارة المستخدمين
- قائمة العملاء
- قائمة الشركاء
- قائمة السائقين
- إدارة الحسابات والصلاحيات

#### 3. إدارة الطلبات
- عرض جميع الطلبات
- تتبع حالة الطلبات
- إدارة المشاكل والشكاوى

#### 4. إدارة المحتوى
- إدارة الفئات
- إدارة البانرات والعروض
- إدارة المدن ومناطق التوصيل

#### 5. التقارير والإحصائيات
- تقارير المبيعات
- تقارير الأداء
- تحليلات المستخدمين

#### 6. الإعدادات
- إعدادات النظام العامة
- إعدادات المدفوعات
- إعدادات الإشعارات

### الصلاحيات المطلوبة:
- **Super Admin**: صلاحية كاملة
- **Admin**: إدارة المحتوى والطلبات
- **Support**: دعم العملاء والشكاوى
- **Finance**: التقارير المالية والمعاملات

## User Flow

### تدفق العميل (Customer Flow):
1. تسجيل الدخول/التسجيل
2. تصفح المطاعم والمنتجات
3. إضافة المنتجات للسلة
4. اختيار العنوان وطريقة الدفع
5. تأكيد الطلب
6. تتبع الطلب
7. استلام الطلب وتقييمه

### تدفق الشريك (Partner Flow):
1. تسجيل الدخول
2. استقبال الطلبات الجديدة
3. قبول/رفض الطلب
4. تحضير الطلب
5. تسليم الطلب للسائق
6. متابعة التقارير المالية

### تدفق السائق (Driver Flow):
1. تسجيل الدخول
2. تفعيل حالة العمل
3. استقبال طلبات التوصيل
4. قبول الطلب والتوجه للمطعم
5. استلام الطلب
6. التوجه للعميل وتسليم الطلب
7. تحديث حالة التسليم

## الخلاصة

نظام Rabbit Ecosystem هو منصة توصيل طعام متكاملة ومعقدة تتطلب:

- **3 تطبيقات Flutter** مترابطة
- **Backend API شامل** مع قاعدة بيانات متقدمة
- **Dashboard إداري** لإدارة النظام
- **تكاملات متعددة** (Firebase, Google Maps, Payment Gateways)
- **نظام إشعارات متقدم** (Push + Real-time)

النظام يدعم عمليات معقدة مثل إدارة المخزون، تتبع الطلبات، المدفوعات المتعددة، وإدارة السائقين، مما يجعله حلاً شاملاً لسوق توصيل الطعام.