#!/bin/bash

# ============================================
# HAMZ-FLARE - Anti DDoS untuk Pterodactyl
# Cloudflare Style Challenge Page
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════╗"
echo "║         HAMZ-FLARE ANTI-DDoS SETUP             ║"
echo "║         Untuk VPS Pterodactyl Panel            ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"

# Cek domain yang terdaftar di Pterodactyl
echo -e "${YELLOW}📋 Mendeteksi domain yang terdaftar di Pterodactyl...${NC}"
DOMAINS=$(mysql -u root -p$(grep -oP "(?<=DB_PASSWORD=).*" /var/www/pterodactyl/.env 2>/dev/null) -e "SELECT domain FROM panel.nodes WHERE public=1;" pterodactyl 2>/dev/null)

if [ -z "$DOMAINS" ]; then
    # Ambil dari konfigurasi nginx
    DOMAINS=$(grep -h "server_name" /etc/nginx/sites-available/pterodactyl.conf 2>/dev/null | grep -v "_" | awk '{print $2}' | sed 's/;//g' | head -5)
fi

echo -e "${GREEN}Domain yang terdeteksi:${NC}"
echo "$DOMAINS" | nl
echo "0. Masukkan domain manual"

echo ""
read -p "Pilih nomor domain (0-${#DOMAINS[@]}): " DOMAIN_CHOICE

if [ "$DOMAIN_CHOICE" == "0" ]; then
    read -p "Masukkan domain Anda (contoh: panel.domain.com): " DOMAIN
else
    DOMAIN=$(echo "$DOMAINS" | sed -n "${DOMAIN_CHOICE}p")
fi

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Domain tidak valid!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Domain terpilih: $DOMAIN${NC}"
echo ""

# Backup konfigurasi
echo -e "${YELLOW}[1/5] Backup konfigurasi...${NC}"
cp /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-available/pterodactyl.conf.bak.$(date +%Y%m%d_%H%M%S)

# Buat direktori challenge
echo -e "${YELLOW}[2/5] Membuat challenge page...${NC}"
mkdir -p /var/www/hamzflare/{challenge,cookies,logs}

# Buat challenge page HTML
cat > /var/www/hamzflare/challenge/index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hamz-Flare | Verifikasi Keamanan</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            min-height: 100vh;
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .container {
            background: rgba(255,255,255,0.98);
            border-radius: 20px;
            padding: 45px 40px;
            box-shadow: 0 25px 50px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 500px;
            width: 90%;
            animation: fadeIn 0.5s ease;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-30px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .shield-icon { font-size: 64px; margin-bottom: 20px; }
        h1 { color: #1e3c72; font-size: 28px; margin-bottom: 10px; }
        .subtitle { color: #666; font-size: 14px; margin-bottom: 30px; }
        .recaptcha-box {
            background: #f9f9f9;
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
            border: 2px solid #e0e0e0;
            transition: all 0.3s;
            cursor: pointer;
        }
        .recaptcha-box.verified {
            background: #e8f5e9;
            border-color: #4caf50;
        }
        .checkbox-area {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 10px;
        }
        .checkbox {
            width: 32px;
            height: 32px;
            border: 2px solid #aaa;
            border-radius: 6px;
            background: white;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
        }
        .checkbox.checked {
            background: #4caf50;
            border-color: #4caf50;
        }
        .checkbox.checked::after {
            content: "✓";
            color: white;
            font-size: 20px;
        }
        .checkbox-text { font-size: 16px; color: #333; font-weight: 500; }
        .recaptcha-badge {
            font-size: 11px;
            color: #999;
            margin-top: 10px;
        }
        .verify-btn {
            background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
            color: white;
            border: none;
            padding: 14px 45px;
            border-radius: 50px;
            font-size: 16px;
            font-weight: bold;
            cursor: not-allowed;
            opacity: 0.5;
            transition: all 0.3s;
            width: 100%;
            margin-top: 20px;
        }
        .verify-btn.active {
            cursor: pointer;
            opacity: 1;
        }
        .verify-btn.active:hover {
            transform: scale(1.02);
            box-shadow: 0 5px 20px rgba(30,60,114,0.4);
        }
        .spinner {
            display: none;
            width: 24px;
            height: 24px;
            border: 3px solid #f3f3f3;
            border-top: 3px solid #1e3c72;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            margin-left: auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        .message {
            margin-top: 20px;
            padding: 12px;
            border-radius: 10px;
            display: none;
            font-size: 14px;
        }
        .message.success {
            background: #d4edda;
            color: #155724;
            display: block;
        }
        .message.error {
            background: #f8d7da;
            color: #721c24;
            display: block;
        }
        .footer {
            margin-top: 30px;
            font-size: 12px;
            color: #aaa;
            border-top: 1px solid #eee;
            padding-top: 20px;
        }
        .hamz-flare {
            color: #1e3c72;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="shield-icon">🛡️</div>
        <h1>Hamz-Flare Security</h1>
        <div class="subtitle">Verifikasi untuk mengakses panel</div>
        
        <div class="recaptcha-box" id="recaptchaBox">
            <div class="checkbox-area">
                <div class="checkbox" id="checkbox"></div>
                <span class="checkbox-text">Saya bukan robot</span>
                <div class="spinner" id="spinner"></div>
            </div>
            <div class="recaptcha-badge">Protected by Hamz-Flare Anti-DDoS</div>
        </div>
        
        <button class="verify-btn" id="verifyBtn" disabled>Verifikasi Akses</button>
        
        <div class="message" id="message"></div>
        
        <div class="footer">
            🔒 <span class="hamz-flare">Hamz-Flare</span> Active • DDoS Protection • Rate Limited
        </div>
    </div>
    
    <script>
        let verified = false;
        const box = document.getElementById('recaptchaBox');
        const checkbox = document.getElementById('checkbox');
        const spinner = document.getElementById('spinner');
        const btn = document.getElementById('verifyBtn');
        const msg = document.getElementById('message');
        
        box.addEventListener('click', function(e) {
            if (verified) return;
            
            spinner.style.display = 'block';
            box.style.opacity = '0.7';
            
            // Simulasi verifikasi
            setTimeout(() => {
                spinner.style.display = 'none';
                box.style.opacity = '1';
                verified = true;
                checkbox.classList.add('checked');
                box.classList.add('verified');
                btn.classList.add('active');
                btn.disabled = false;
                
                msg.className = 'message success';
                msg.innerHTML = '✓ Verifikasi berhasil! Klik tombol untuk melanjutkan ke panel.';
                
                // Set cookie
                document.cookie = "hamzflare_verified=true; path=/; max-age=3600; SameSite=Strict";
            }, 1500);
        });
        
        btn.addEventListener('click', function() {
            if (!verified) {
                msg.className = 'message error';
                msg.innerHTML = '✗ Silakan centang "Saya bukan robot" terlebih dahulu!';
                return;
            }
            
            msg.className = 'message success';
            msg.innerHTML = '✓ Verifikasi diterima, mengalihkan...';
            
            document.cookie = "hamzflare_verified=true; path=/; max-age=3600; SameSite=Strict";
            
            setTimeout(() => {
                window.location.href = '/?hamz_verified=1';
            }, 800);
        });
        
        // Cek cookie existing
        if (document.cookie.includes('hamzflare_verified=true')) {
            window.location.href = '/?hamz_verified=1';
        }
    </script>
</body>
</html>
EOF

# Update Nginx config dengan challenge
echo -e "${YELLOW}[3/5] Mengupdate konfigurasi Nginx...${NC}"

cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
# Rate Limiting Zones
limit_req_zone \$binary_remote_addr zone=ddos_limit:10m rate=10r/s;
limit_req_zone \$binary_remote_addr zone=login_limit:10m rate=2r/s;
limit_conn_zone \$binary_remote_addr zone=conn_limit:10m;

server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    
    # Root untuk Pterodactyl
    root /var/www/pterodactyl/public;
    index index.php;
    
    # Security Headers
    server_tokens off;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Hamz-Flare "Active" always;
    
    # Rate limiting default
    limit_req zone=ddos_limit burst=20 nodelay;
    limit_req_status 429;
    limit_conn conn_limit 20;
    
    # Cookie verification check
    map \$cookie_hamzflare_verified \$verified_user {
        default 0;
        "true" 1;
    }
    
    # Challenge page untuk unverified
    location / {
        # Jika sudah verified, lanjut ke Pterodactyl
        if (\$verified_user = 1) {
            try_files \$uri \$uri/ /index.php?\$query_string;
            break;
        }
        
        # Tampilkan challenge page
        root /var/www/hamzflare/challenge;
        try_files /index.html =404;
    }
    
    # Endpoint untuk verifikasi (opsional)
    location /hamz-verify {
        add_header Set-Cookie "hamzflare_verified=true; Path=/; Max-Age=3600; HttpOnly; SameSite=Strict";
        return 302 /;
    }
    
    # Proteksi login Pterodactyl
    location /auth/login {
        limit_req zone=login_limit burst=3 nodelay;
        limit_req_status 429;
        limit_conn conn_limit 5;
        
        add_header X-RateLimit-Limit "2r/s" always;
        
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # Proteksi admin
    location /admin {
        limit_req zone=ddos_limit burst=10 nodelay;
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # API protection
    location /api {
        limit_req zone=ddos_limit burst=15 nodelay;
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    # Static files (bypass limit)
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
        limit_req off;
        limit_conn off;
        try_files \$uri =404;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        
        # Timeouts
        fastcgi_read_timeout 30s;
        fastcgi_connect_timeout 10s;
        
        # Buffer
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }
    
    # Block bad patterns
    location ~ /\.(env|git|sql|bak|config) {
        deny all;
        return 403;
    }
    
    # Error pages
    error_page 429 /429.html;
    location = /429.html {
        internal;
        return 429 "🚫 Rate limit exceeded. Slow down!\n";
        add_header Content-Type text/plain;
    }
}

# Redirect HTTP ke HTTPS (jika pakai SSL)
# server {
#     listen 443 ssl http2;
#     server_name $DOMAIN;
#     # SSL config here...
# }
EOF

# Test dan reload Nginx
echo -e "${YELLOW}[4/5] Testing konfigurasi...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Konfigurasi valid${NC}"
    echo -e "${YELLOW}[5/5] Reload Nginx...${NC}"
    systemctl reload nginx
else
    echo -e "${RED}✗ Konfigurasi error, restoring backup...${NC}"
    mv /etc/nginx/sites-available/pterodactyl.conf.bak.* /etc/nginx/sites-available/pterodactyl.conf
    systemctl reload nginx
    exit 1
fi

# Tampilkan info
clear
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════╗"
echo "║     HAMZ-FLARE ANTI-DDoS ACTIVE!               ║"
echo "╚════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${BLUE}🌐 Domain:${NC} https://$DOMAIN"
echo ""
echo -e "${GREEN}✅ Fitur yang aktif:${NC}"
echo "   ✓ Challenge Page (Centang 'Saya bukan robot')"
echo "   ✓ Rate Limiting: 10 request/detik per IP"
echo "   ✓ Login Protection: 2 request/detik"
echo "   ✓ Connection Limit: 20 per IP"
echo "   ✓ Cookie Verification (1 jam)"
echo "   ✓ DDoS Mitigation"
echo ""
echo -e "${YELLOW}📝 Testing:${NC}"
echo "   curl -I http://$DOMAIN"
echo ""
echo -e "${CYAN}🛡️ Hamz-Flare is protecting your panel!${NC}"
