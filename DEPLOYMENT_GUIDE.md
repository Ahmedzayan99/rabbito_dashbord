# 🚀 Rabbit Ecosystem - Production Deployment Guide

This guide provides comprehensive instructions for deploying the Rabbit Ecosystem food delivery platform to production.

## 📋 Prerequisites

### Server Requirements
- **Ubuntu 20.04 LTS or later** (recommended)
- **Minimum 4GB RAM, 2 CPU cores**
- **50GB SSD storage**
- **Domain name** (for SSL certificates)
- **Root or sudo access**

### Required Software
- Docker & Docker Compose
- Git
- curl/wget
- ufw (firewall)
- certbot (for SSL)

## 🏗️ Production Infrastructure Setup

### 1. Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y docker.io docker-compose git curl wget ufw certbot

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (optional)
sudo usermod -aG docker $USER

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Enable automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### 2. Domain Configuration

Configure your domain DNS to point to your server IP:

```
Type: A
Name: @
Value: YOUR_SERVER_IP

Type: A
Name: api
Value: YOUR_SERVER_IP

Type: A
Name: dashboard
Value: YOUR_SERVER_IP
```

### 3. SSL Certificate Setup

```bash
# Obtain SSL certificates
sudo certbot certonly --standalone \
  --email admin@yourdomain.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com \
  -d api.yourdomain.com \
  -d dashboard.yourdomain.com

# Set up automatic renewal
sudo crontab -e
# Add this line:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📦 Application Deployment

### 1. Clone Repository

```bash
# Clone the application
git clone https://github.com/your-org/rabbit-ecosystem.git
cd rabbit-ecosystem

# Create production environment file
cp env.production .env
```

### 2. Environment Configuration

Edit `.env` file with your production values:

```env
# Database
DB_PASSWORD=your_secure_db_password_here

# JWT (generate a secure 256-bit key)
JWT_SECRET=your_256_bit_jwt_secret_key_here

# Firebase
FIREBASE_SERVER_KEY=your_firebase_server_key_here

# Payment Gateway
PAYMOB_API_KEY=your_paymob_api_key_here

# Email
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password_here

# URLs
APP_URL=https://api.yourdomain.com
DASHBOARD_URL=https://dashboard.yourdomain.com
```

### 3. Build and Deploy

```bash
# Build the Flutter dashboard
cd rabbit_ecosystem_dashboard
flutter pub get
flutter build web --release --dart-define=FLUTTER_WEB_CANVASKIT_URL=/assets/canvaskit/
cd ..

# Start all services
docker-compose -f docker-compose.prod.yml up -d --build

# Check service status
docker-compose -f docker-compose.prod.yml ps
```

### 4. Database Setup

```bash
# Wait for database to be ready
sleep 30

# Run migrations
docker-compose -f docker-compose.prod.yml exec backend dart bin/migrate.dart

# Create initial admin user (optional)
docker-compose -f docker-compose.prod.yml exec backend dart bin/create_admin.dart
```

## 🌐 Nginx Configuration

Create nginx configuration at `nginx/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    # Performance
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Upstream backend
    upstream backend {
        server backend:8080;
    }

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # API Server
    server {
        listen 443 ssl http2;
        server_name api.yourdomain.com;

        ssl_certificate /etc/nginx/ssl/live/api.yourdomain.com/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/live/api.yourdomain.com/privkey.pem;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

        # API proxy
        location / {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 86400;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }

    # Dashboard Server
    server {
        listen 443 ssl http2;
        server_name dashboard.yourdomain.com;

        ssl_certificate /etc/nginx/ssl/live/dashboard.yourdomain.com/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/live/dashboard.yourdomain.com/privkey.pem;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;

        # Static files with caching
        location / {
            root /var/www/dashboard;
            try_files $uri $uri/ /index.html;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # API proxy for dashboard
        location /api/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    # Main Domain Redirect
    server {
        listen 443 ssl http2;
        server_name yourdomain.com;

        ssl_certificate /etc/nginx/ssl/live/yourdomain.com/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/live/yourdomain.com/privkey.pem;

        return 301 https://dashboard.yourdomain.com$request_uri;
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name yourdomain.com api.yourdomain.com dashboard.yourdomain.com;
        return 301 https://$server_name$request_uri;
    }
}
```

## 🔧 Maintenance & Monitoring

### Health Checks

```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# Check application health
curl -f https://api.yourdomain.com/health

# Check database connectivity
docker-compose -f docker-compose.prod.yml exec backend dart bin/health_check.dart
```

### Logs Monitoring

```bash
# View all logs
docker-compose -f docker-compose.prod.yml logs -f

# View specific service logs
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f postgres
docker-compose -f docker-compose.prod.yml logs -f nginx
```

### Backup Strategy

```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/rabbit-ecosystem/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker-compose -f /opt/rabbit-ecosystem/docker-compose.prod.yml exec -T postgres pg_dump -U rabbit_user rabbit_ecosystem > $BACKUP_DIR/db_$DATE.sql

# Compress backup
gzip $BACKUP_DIR/db_$DATE.sql

# Upload to cloud storage (configure as needed)
# aws s3 cp $BACKUP_DIR/db_$DATE.sql.gz s3://your-backup-bucket/

# Clean old backups (keep last 30 days)
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x backup.sh

# Add to crontab for daily backups
(crontab -l ; echo "0 2 * * * /opt/rabbit-ecosystem/backup.sh") | crontab -
```

### Performance Monitoring

```bash
# Monitor resource usage
docker stats

# Check disk usage
df -h

# Monitor network connections
netstat -tlnp

# Check nginx status
docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

## 🔄 Updates & Rollbacks

### Application Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart services
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# Run database migrations if needed
docker-compose -f docker-compose.prod.yml exec backend dart bin/migrate.dart
```

### Rollback Strategy

```bash
# Stop current deployment
docker-compose -f docker-compose.prod.yml down

# Checkout previous version
git checkout <previous-commit-hash>

# Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build
```

## 🔒 Security Hardening

### Server Security

```bash
# Disable root login
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Install fail2ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban

# Configure automatic updates
sudo apt install -y unattended-upgrades
```

### Application Security

```bash
# Set proper file permissions
sudo chown -R www-data:www-data /opt/rabbit-ecosystem
sudo chmod -R 755 /opt/rabbit-ecosystem

# Secure environment variables
sudo chmod 600 /opt/rabbit-ecosystem/.env

# Configure log rotation
cat > /etc/logrotate.d/rabbit-ecosystem << EOF
/opt/rabbit-ecosystem/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        docker-compose -f /opt/rabbit-ecosystem/docker-compose.prod.yml restart
    endscript
}
EOF
```

## 🚨 Emergency Procedures

### Service Outage

```bash
# Quick service restart
docker-compose -f docker-compose.prod.yml restart backend

# Full system restart
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Emergency maintenance page
sudo cp maintenance.html /var/www/html/index.html
```

### Database Recovery

```bash
# Stop application
docker-compose -f docker-compose.prod.yml stop backend

# Restore from backup
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U rabbit_user rabbit_ecosystem < /path/to/backup.sql

# Restart application
docker-compose -f docker-compose.prod.yml start backend
```

## 📊 Scaling Considerations

### Horizontal Scaling

```yaml
# Add multiple backend instances
services:
  backend:
    deploy:
      replicas: 3
      restart_policy:
        condition: on-failure

  # Load balancer
  nginx:
    depends_on:
      - backend
    ports:
      - "80:80"
      - "443:443"
```

### Database Scaling

```yaml
# PostgreSQL with read replicas
services:
  postgres_master:
    # Primary database

  postgres_replica:
    # Read replica
    command: ["postgres", "-c", "hot_standby=on"]
```

## 📞 Support & Monitoring

### Monitoring Setup

```bash
# Install monitoring tools
sudo apt install -y prometheus grafana

# Configure alerts for:
# - Service downtime
# - High CPU/memory usage
# - Database connection issues
# - SSL certificate expiration
# - Disk space warnings
```

### Log Aggregation

```bash
# Install ELK stack or similar
# Configure centralized logging
# Set up log alerts and dashboards
```

## ✅ Deployment Checklist

### Pre-deployment
- [ ] Server provisioned and secured
- [ ] Domain configured and DNS propagated
- [ ] SSL certificates obtained
- [ ] Environment variables configured
- [ ] Database backups configured
- [ ] Monitoring and alerting set up

### Deployment
- [ ] Code deployed successfully
- [ ] Database migrations run
- [ ] Services started without errors
- [ ] SSL certificates configured
- [ ] Nginx configuration applied

### Post-deployment
- [ ] Application accessible via HTTPS
- [ ] API endpoints responding correctly
- [ ] WebSocket connections working
- [ ] File uploads functioning
- [ ] Email notifications working
- [ ] Payment processing tested
- [ ] Admin dashboard accessible

### Monitoring
- [ ] Health checks passing
- [ ] Logs being collected
- [ ] Performance metrics normal
- [ ] Backup jobs running
- [ ] SSL certificates auto-renewing

---

## 📞 Need Help?

For deployment issues or questions:
- Check the [troubleshooting guide](README.md#troubleshooting)
- Review [application logs](#logs-monitoring)
- Contact the development team

**Happy deploying! 🚀**
