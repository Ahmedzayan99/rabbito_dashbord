-- Insert initial cities
INSERT INTO cities (name, country, is_active) VALUES
('الرياض', 'Saudi Arabia', true),
('جدة', 'Saudi Arabia', true),
('الدمام', 'Saudi Arabia', true),
('مكة المكرمة', 'Saudi Arabia', true),
('المدينة المنورة', 'Saudi Arabia', true);

-- Insert initial categories
INSERT INTO categories (name, name_ar, description, is_active) VALUES
('Restaurants', 'مطاعم', 'Food delivery from restaurants', true),
('Fast Food', 'وجبات سريعة', 'Quick meals and fast food', true),
('Coffee & Sweets', 'قهوة وحلويات', 'Coffee shops and desserts', true),
('Supermarket', 'سوبر ماركت', 'Grocery and daily needs', true),
('Pharmacy', 'صيدلية', 'Medicines and health products', true);

-- Insert subcategories
INSERT INTO categories (name, name_ar, description, parent_id, is_active) VALUES
('Pizza', 'بيتزا', 'Pizza restaurants', 1, true),
('Burgers', 'برجر', 'Burger restaurants', 1, true),
('Arabic Food', 'أكل عربي', 'Traditional Arabic cuisine', 1, true),
('Asian Food', 'أكل آسيوي', 'Asian cuisine', 1, true),
('Sandwiches', 'ساندويتشات', 'Sandwich shops', 2, true),
('Fried Chicken', 'دجاج مقلي', 'Fried chicken restaurants', 2, true);

-- Insert initial settings
INSERT INTO settings (key, value, description, type) VALUES
('app_name', 'Rabbit Ecosystem', 'Application name', 'string'),
('app_version', '1.0.0', 'Current application version', 'string'),
('default_delivery_charge', '5.00', 'Default delivery charge', 'decimal'),
('default_tax_rate', '15.00', 'Default tax rate percentage', 'decimal'),
('min_order_amount', '20.00', 'Minimum order amount', 'decimal'),
('max_delivery_distance', '50', 'Maximum delivery distance in KM', 'integer'),
('order_auto_cancel_time', '30', 'Auto cancel order time in minutes', 'integer'),
('default_cooking_time', '30', 'Default cooking time in minutes', 'integer'),
('commission_rate', '10.00', 'Default commission rate percentage', 'decimal'),
('currency_symbol', 'ر.س', 'Currency symbol', 'string'),
('support_phone', '+966500000000', 'Support phone number', 'string'),
('support_email', 'support@rabbito.com', 'Support email address', 'string');

-- Insert super admin user (password: admin123)
INSERT INTO users (username, email, mobile, password_hash, role, is_active, email_verified, mobile_verified) VALUES
('Super Admin', 'admin@rabbito.com', '+966500000001', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'super_admin', true, true, true);

-- Insert sample admin users
INSERT INTO users (username, email, mobile, password_hash, role, is_active, email_verified, mobile_verified) VALUES
('Admin User', 'admin.user@rabbito.com', '+966500000002', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', true, true, true),
('Finance Manager', 'finance@rabbito.com', '+966500000003', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'finance', true, true, true),
('Support Agent', 'support@rabbito.com', '+966500000004', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'support', true, true, true);

-- Insert sample customer
INSERT INTO users (username, email, mobile, password_hash, role, balance, is_active, email_verified, mobile_verified) VALUES
('Ahmed Ali', 'ahmed@example.com', '+966500000010', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'customer', 100.00, true, true, true);

-- Insert sample partner user
INSERT INTO users (username, email, mobile, password_hash, role, is_active, email_verified, mobile_verified) VALUES
('Restaurant Owner', 'restaurant@example.com', '+966500000020', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'partner', true, true, true);

-- Insert sample rider user
INSERT INTO users (username, email, mobile, password_hash, role, is_active, email_verified, mobile_verified) VALUES
('Delivery Driver', 'driver@example.com', '+966500000030', '$2b$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'rider', true, true, true);

-- Insert sample partner
INSERT INTO partners (user_id, partner_name, owner_name, partner_address, city_id, latitude, longitude, cooking_time, commission, is_featured, status, opening_time, closing_time, phone, description, minimum_order, delivery_charge) VALUES
((SELECT id FROM users WHERE email = 'restaurant@example.com'), 'مطعم الأصالة', 'محمد أحمد', 'شارع الملك فهد، الرياض', 1, 24.7136, 46.6753, 25, 12.00, true, 'active', '08:00:00', '23:00:00', '+966500000021', 'مطعم متخصص في الأكلات العربية الأصيلة', 25.00, 8.00);

-- Link partner with categories
INSERT INTO partner_categories (partner_id, category_id) VALUES
(1, 1), -- Restaurants
(1, 3); -- Arabic Food

-- Insert sample address
INSERT INTO addresses (user_id, title, address_line_1, city_id, latitude, longitude, is_default) VALUES
((SELECT id FROM users WHERE email = 'ahmed@example.com'), 'المنزل', 'حي النخيل، شارع الأمير سلطان', 1, 24.7136, 46.6753, true);

-- Insert sample products
INSERT INTO products (partner_id, category_id, name, name_ar, short_description, description, base_price, discounted_price, is_featured, status) VALUES
(1, 3, 'Kabsa with Chicken', 'كبسة دجاج', 'Traditional Saudi Kabsa with chicken', 'أرز كبسة بالدجاج مع الخضار والتوابل الخاصة', 35.00, 30.00, true, 'active'),
(1, 3, 'Grilled Lamb', 'لحم مشوي', 'Grilled lamb with rice', 'لحم خروف مشوي مع الأرز الأبيض والسلطة', 45.00, NULL, false, 'active'),
(1, 3, 'Mixed Grill', 'مشاوي مشكلة', 'Mixed grilled meats', 'تشكيلة من اللحوم المشوية مع الأرز والخضار', 55.00, 50.00, true, 'active');

-- Insert product variants
INSERT INTO product_variants (product_id, name, name_ar, price, is_default) VALUES
(1, 'Regular', 'عادي', 30.00, true),
(1, 'Large', 'كبير', 40.00, false),
(2, 'Half Kilo', 'نصف كيلو', 45.00, true),
(2, 'Full Kilo', 'كيلو كامل', 80.00, false);

-- Insert product addons
INSERT INTO product_addons (product_id, name, name_ar, price, is_required) VALUES
(1, 'Extra Rice', 'أرز إضافي', 5.00, false),
(1, 'Yogurt', 'لبن', 3.00, false),
(1, 'Salad', 'سلطة', 8.00, false),
(2, 'Extra Bread', 'خبز إضافي', 2.00, false),
(3, 'Grilled Vegetables', 'خضار مشوية', 12.00, false);