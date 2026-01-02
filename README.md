# Rabbit Ecosystem - Food Delivery Platform

A comprehensive food delivery platform built with Dart + Serverpod backend and Flutter Web dashboard.

## 🏗️ Architecture Overview

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

## 🚀 Features

### Backend API (Serverpod)
- **Separate API Routes**: `/api/mobile/*` and `/api/dashboard/*`
- **JWT Authentication**: Role-based access control
- **PostgreSQL Database**: Full relational database with migrations
- **Real-time Updates**: WebSocket support
- **File Upload**: Image and document handling
- **Push Notifications**: Firebase Cloud Messaging integration

### Dashboard (Flutter Web)
- **Role-based Access**: Super Admin, Admin, Finance, Support
- **Real-time Analytics**: Live charts and statistics
- **User Management**: Customers, Partners, Riders
- **Order Management**: Full order lifecycle tracking
- **Financial Reports**: Revenue, commissions, transactions
- **Content Management**: Products, categories, promotions

### User Roles
- **Customer**: Order food, track deliveries, manage wallet
- **Partner**: Restaurant/store owners, manage products and orders
- **Rider**: Delivery drivers, accept orders, track earnings
- **Super Admin**: Full system access and control
- **Admin**: Content and order management
- **Finance**: Financial reports and transactions
- **Support**: Customer service and issue resolution

## 📦 Project Structure

```
rabbit-ecosystem/
├── rabbit_ecosystem_backend/     # Serverpod Backend API
│   ├── lib/src/
│   │   ├── endpoints/           # API endpoints
│   │   ├── models/             # Data models
│   │   ├── services/           # Business logic
│   │   └── repositories/       # Data access layer
│   ├── config/                 # Configuration files
│   └── migrations/             # Database migrations
├── rabbit_ecosystem_dashboard/   # Flutter Web Dashboard
│   ├── lib/
│   │   ├── features/           # Feature modules
│   │   ├── core/              # Core utilities
│   │   └── shared/            # Shared components
│   └── web/                   # Web-specific files
├── database/                   # Database scripts
│   ├── migrations/            # SQL migration files
│   └── seeds/                 # Initial data
└── docker-compose.yml         # Docker configuration
```

## 🛠️ Technology Stack

### Backend
- **Dart + Serverpod**: Modern server-side framework
- **PostgreSQL**: Relational database
- **Redis**: Caching and session storage
- **JWT**: Authentication and authorization
- **Docker**: Containerization

### Frontend (Dashboard)
- **Flutter Web**: Cross-platform web framework
- **BLoC**: State management
- **Dio**: HTTP client
- **WebSocket**: Real-time communication
- **Charts**: Data visualization

### DevOps
- **Docker Compose**: Local development
- **Nginx**: Reverse proxy and static file serving
- **Let's Encrypt**: SSL certificates
- **Ubuntu VPS**: Production deployment

## 🚀 Quick Start

### Prerequisites
- Dart SDK 3.0+
- Flutter 3.10+
- Docker & Docker Compose
- PostgreSQL 15+

### 1. Clone Repository
```bash
git clone <repository-url>
cd rabbit-ecosystem
```

### 2. Environment Setup
```bash
# Copy environment file
cp .env.example .env

# Edit environment variables
nano .env
```

### 3. Start with Docker
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### 4. Database Setup
```bash
# Run migrations
docker-compose exec backend dart run serverpod create-migration
docker-compose exec backend dart run serverpod migrate

# Seed initial data
docker-compose exec postgres psql -U rabbit_user -d rabbit_ecosystem -f /docker-entrypoint-initdb.d/001_initial_data.sql
```

### 5. Access Applications
- **Backend API**: http://localhost:8080
- **Dashboard**: http://localhost:3000
- **Database**: localhost:5432

## 🔧 Development

### Backend Development
```bash
cd rabbit_ecosystem_backend

# Install dependencies
dart pub get

# Generate code
dart pub run build_runner build

# Run development server
dart run bin/main.dart
```

### Dashboard Development
```bash
cd rabbit_ecosystem_dashboard

# Install dependencies
flutter pub get

# Run development server
flutter run -d chrome --web-port 3000
```

### Database Management
```bash
# Create new migration
cd rabbit_ecosystem_backend
dart run serverpod create-migration --name migration_name

# Apply migrations
dart run serverpod migrate

# Reset database (development only)
docker-compose down -v
docker-compose up -d postgres
```

## 🧪 Testing

### Backend Tests
```bash
cd rabbit_ecosystem_backend

# Run all tests
dart test

# Run specific test file
dart test test/auth_test.dart

# Run with coverage
dart test --coverage=coverage
```

### Dashboard Tests
```bash
cd rabbit_ecosystem_dashboard

# Run widget tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📊 API Documentation

### Authentication Endpoints
```
POST /api/mobile/auth/login
POST /api/mobile/auth/register
POST /api/mobile/auth/refresh
POST /api/mobile/auth/logout
```

### Mobile API Endpoints
```
GET    /api/mobile/user/profile
PUT    /api/mobile/user/profile
GET    /api/mobile/partners
GET    /api/mobile/products
POST   /api/mobile/orders
GET    /api/mobile/orders/{id}
```

### Dashboard API Endpoints
```
GET    /api/dashboard/analytics/overview
GET    /api/dashboard/users
POST   /api/dashboard/users
GET    /api/dashboard/orders
PUT    /api/dashboard/orders/{id}/status
```

## 🚀 Production Deployment

### 1. Server Setup (Ubuntu VPS)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Install Nginx
sudo apt install nginx

# Install Certbot for SSL
sudo apt install certbot python3-certbot-nginx
```

### 2. Deploy Application
```bash
# Clone repository
git clone <repository-url>
cd rabbit-ecosystem

# Set production environment
cp .env.example .env
nano .env  # Update with production values

# Build and start services
docker-compose -f docker-compose.prod.yml up -d

# Setup SSL certificate
sudo certbot --nginx -d yourdomain.com
```

### 3. Nginx Configuration
```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Dashboard
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🔒 Security

### Authentication
- JWT tokens with RS256 signing
- Role-based access control (RBAC)
- Token expiration and refresh mechanism
- Password hashing with bcrypt

### API Security
- Input validation and sanitization
- SQL injection prevention
- Rate limiting
- CORS configuration
- HTTPS enforcement

### Database Security
- Connection encryption
- User privilege separation
- Regular backups
- Query parameterization

## 📈 Monitoring

### Application Monitoring
- Health check endpoints
- Performance metrics
- Error tracking
- User activity logs

### Infrastructure Monitoring
- Server resource usage
- Database performance
- Network latency
- Uptime monitoring

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Email**: support@rabbito.com
- **Phone**: +966500000000
- **Documentation**: [docs.rabbito.com](https://docs.rabbito.com)

## 🙏 Acknowledgments

- Serverpod team for the excellent backend framework
- Flutter team for the amazing cross-platform framework
- PostgreSQL community for the robust database system
- All contributors and testers

---

**Built with ❤️ for the food delivery industry**