# Rabbit Ecosystem - Complete Food Delivery Platform

A comprehensive, production-ready food delivery platform built with modern technologies including Serverpod backend, Flutter mobile apps, and Flutter Web dashboard.

## 🚀 Project Overview

Rabbit Ecosystem is a complete food delivery platform consisting of:

- **Backend API** (Serverpod/Dart) - RESTful API with WebSocket support
- **Customer Mobile App** (Flutter) - iOS/Android customer app
- **Partner Mobile App** (Flutter) - Restaurant/partner management app
- **Driver Mobile App** (Flutter) - Delivery driver app
- **Admin Dashboard** (Flutter Web) - Complete administrative interface
- **Real-time Features** - WebSocket communication, push notifications
- **Payment Integration** - Paymob payment gateway
- **Advanced Analytics** - Comprehensive reporting and insights

## 🏗️ Architecture

### Backend Architecture
```
rabbit_ecosystem_backend/
├── lib/src/
│   ├── controllers/          # HTTP request handlers
│   │   ├── mobile/          # Mobile app endpoints
│   │   └── dashboard/       # Admin dashboard endpoints
│   ├── services/            # Business logic layer
│   ├── repositories/        # Data access layer
│   ├── models/              # Data models
│   ├── middleware/          # Authentication, validation, etc.
│   ├── routes/              # Route definitions
│   ├── config/              # Configuration files
│   └── websocket/           # WebSocket handlers
├── test/                    # Unit and integration tests
└── database/                # Database migrations
```

### Frontend Architecture
```
rabbit_ecosystem_dashboard/
├── lib/
│   ├── core/                # Core functionality
│   │   ├── config/          # App configuration
│   │   ├── di/              # Dependency injection
│   │   ├── network/         # API client, interceptors
│   │   ├── storage/         # Local storage
│   │   ├── theme/           # UI themes
│   │   └── utils/           # Utility functions
│   ├── features/            # Feature modules
│   │   ├── auth/            # Authentication
│   │   ├── dashboard/       # Main dashboard
│   │   ├── users/           # User management
│   │   ├── orders/          # Order management
│   │   └── analytics/       # Reports & analytics
│   └── shared/              # Shared components
```

## 🛠️ Technology Stack

### Backend
- **Framework**: Serverpod (Dart)
- **Database**: PostgreSQL
- **Cache**: Redis
- **Authentication**: JWT with RS256
- **Real-time**: WebSocket
- **Notifications**: Firebase Cloud Messaging
- **Payments**: Paymob Gateway
- **File Storage**: Cloudinary/Local

### Frontend (Dashboard)
- **Framework**: Flutter Web
- **State Management**: BLoC Pattern
- **UI**: Material Design 3
- **Charts**: FL Chart, Syncfusion Charts
- **Tables**: DataTable2
- **HTTP Client**: Dio

### Mobile Apps
- **Framework**: Flutter
- **State Management**: BLoC Pattern
- **Maps**: Google Maps
- **Location**: Geolocator
- **Notifications**: Firebase Cloud Messaging
- **Real-time**: Pusher Channels/WebSocket
- **Payments**: Paymob SDK

### DevOps
- **Containerization**: Docker & Docker Compose
- **Reverse Proxy**: Nginx
- **SSL**: Let's Encrypt
- **Monitoring**: Health checks, logging
- **Backup**: Automated PostgreSQL backups

## 📋 Prerequisites

- Docker & Docker Compose
- Flutter SDK (3.10+)
- Dart SDK (3.0+)
- PostgreSQL (15+)
- Redis (7+)
- Node.js (18+) for some scripts

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Clone the repository
git clone https://github.com/your-org/rabbit-ecosystem.git
cd rabbit-ecosystem

# Copy environment file and configure
cp env.production .env
# Edit .env with your actual values
```

### 2. Database Setup

```bash
# Start PostgreSQL and Redis
docker-compose -f docker-compose.prod.yml up -d postgres redis

# Run database migrations
docker-compose -f docker-compose.prod.yml exec backend dart bin/migrate.dart
```

### 3. Backend Deployment

```bash
# Build and start all services
docker-compose -f docker-compose.prod.yml up -d

# Check service health
docker-compose -f docker-compose.prod.yml ps
```

### 4. Dashboard Deployment

```bash
# Navigate to dashboard directory
cd rabbit_ecosystem_dashboard

# Install dependencies
flutter pub get

# Build for web
flutter build web --release

# Copy build files to nginx directory
cp -r build/web ../nginx/dashboard/
```

### 5. SSL Setup

```bash
# Get SSL certificates
docker-compose -f docker-compose.prod.yml run --rm certbot

# Reload nginx configuration
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```env
# Database
DB_HOST=localhost
DB_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_256_bit_secret

# Firebase
FIREBASE_SERVER_KEY=your_fcm_key

# Payments
PAYMOB_API_KEY=your_paymob_key

# Email
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password
```

### Application Settings

Configure business rules in `rabbit_ecosystem_backend/lib/src/config/app_config.dart`:

- Commission rates
- Delivery radius
- Order limits
- Platform fees

## 📱 API Endpoints

### Authentication
```
POST /api/v1/auth/login          # User login
POST /api/v1/auth/register       # User registration
POST /api/v1/auth/refresh        # Refresh JWT token
```

### Mobile App Endpoints
```
GET  /api/v1/mobile/partners     # Get partners list
POST /api/v1/mobile/orders       # Create order
GET  /api/v1/mobile/orders       # Get user orders
POST /api/v1/mobile/wallet/topup # Wallet topup
```

### Dashboard Endpoints
```
GET  /api/v1/dashboard/users     # Get users (admin)
POST /api/v1/dashboard/users     # Create user (admin)
GET  /api/v1/dashboard/orders    # Get all orders (admin)
PUT  /api/v1/dashboard/orders/{id}/status # Update order status
GET  /api/v1/dashboard/analytics # Get analytics
```

### WebSocket Events
```
order_update        # Order status changes
rider_location      # Rider location updates
chat_message        # Real-time chat
notification        # Push notifications
```

## 🧪 Testing

### Backend Tests

```bash
cd rabbit_ecosystem_backend

# Run all tests
dart test

# Run specific test file
dart test test/user_filtering_property_test.dart

# Run with coverage
dart pub run test_coverage
```

### Frontend Tests

```bash
cd rabbit_ecosystem_dashboard

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Property-Based Testing

The project includes comprehensive property-based tests that validate:

- User filtering and pagination (Property 11)
- Partner status updates (Property 15)
- Transaction processing (Property 34)
- Payment distribution (Property 36)
- Notification targeting (Property 39)
- WebSocket real-time updates (Property 41)
- Dashboard UI validation (Property 44)

## 📊 Monitoring & Analytics

### Health Checks
- Application health: `GET /health`
- Database connectivity: `GET /health/db`
- Redis connectivity: `GET /health/cache`

### Metrics
- Request/response times
- Error rates
- Database query performance
- WebSocket connection count
- Notification delivery rates

### Logging
- Structured JSON logging
- Log levels: DEBUG, INFO, WARN, ERROR
- Centralized log aggregation (recommended)

## 🔒 Security Features

### Authentication & Authorization
- JWT-based authentication with refresh tokens
- Role-based access control (RBAC)
- Password hashing with bcrypt
- Rate limiting and DDoS protection

### Data Protection
- HTTPS everywhere
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- CSRF protection

### Security Headers
- Content Security Policy (CSP)
- HSTS (HTTP Strict Transport Security)
- X-Frame-Options
- X-Content-Type-Options

## 🔄 Backup & Recovery

### Automated Backups
```bash
# Database backup script
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U rabbit_user rabbit_ecosystem > backup.sql

# Restore from backup
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U rabbit_user rabbit_ecosystem < backup.sql
```

### Backup Schedule
- Daily database backups at 2 AM
- File storage backups
- 30-day retention policy
- Offsite storage (S3 recommended)

## 🚀 Deployment Checklist

### Pre-deployment
- [ ] Environment variables configured
- [ ] SSL certificates obtained
- [ ] Database migrations run
- [ ] Firebase project configured
- [ ] Payment gateway configured
- [ ] File storage configured

### Deployment Steps
- [ ] Build Docker images
- [ ] Run database migrations
- [ ] Start services with docker-compose
- [ ] Configure nginx reverse proxy
- [ ] Set up SSL certificates
- [ ] Configure monitoring
- [ ] Test all endpoints

### Post-deployment
- [ ] Verify application health
- [ ] Test user registration/login
- [ ] Test order placement
- [ ] Test payment processing
- [ ] Test real-time features
- [ ] Configure backup schedule

## 🐛 Troubleshooting

### Common Issues

**Database Connection Failed**
```bash
# Check database logs
docker-compose -f docker-compose.prod.yml logs postgres

# Verify connection string
docker-compose -f docker-compose.prod.yml exec postgres psql -U rabbit_user -d rabbit_ecosystem
```

**WebSocket Connection Issues**
```bash
# Check WebSocket logs
docker-compose -f docker-compose.prod.yml logs backend

# Verify nginx WebSocket proxy configuration
docker-compose -f docker-compose.prod.yml exec nginx nginx -t
```

**SSL Certificate Issues**
```bash
# Renew certificates
docker-compose -f docker-compose.prod.yml run --rm certbot renew

# Reload nginx
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

## 📈 Performance Optimization

### Database Optimization
- Connection pooling
- Query optimization
- Indexing strategy
- Partitioning for large tables

### Caching Strategy
- Redis for session storage
- API response caching
- Static asset caching
- Database query result caching

### CDN Integration
- Static asset delivery
- Image optimization
- Global distribution

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Dart/Flutter best practices
- Write comprehensive tests
- Update documentation
- Use meaningful commit messages
- Maintain code coverage above 80%

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support and questions:
- **Email**: support@rabbit-ecosystem.com
- **Documentation**: [docs.rabbit-ecosystem.com](https://docs.rabbit-ecosystem.com)
- **Issues**: [GitHub Issues](https://github.com/your-org/rabbit-ecosystem/issues)

## 🎯 Roadmap

### Phase 1 (Current) ✅
- Core food delivery functionality
- Admin dashboard
- Real-time features
- Payment integration
- Mobile apps

### Phase 2 (Next)
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Loyalty program
- [ ] Restaurant management tools
- [ ] Driver management enhancements

### Phase 3 (Future)
- [ ] AI-powered recommendations
- [ ] Advanced routing optimization
- [ ] Integration APIs for third parties
- [ ] Mobile wallet integration
- [ ] Advanced fraud detection

---

**Built with ❤️ for the food delivery revolution**
