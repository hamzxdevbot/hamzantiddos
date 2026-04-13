# 🛡️ HamzAntiddos - Anti DDoS Free

**Anti-DDoS dengan Cloudflare-Style Challenge Page untuk Pterodactyl Panel | 100% Gratis**

## ✨ Fitur
✓ Challenge Page "Saya bukan robot" ala Cloudflare
✓ Rate Limiting 10 req/detik per IP
✓ Login Protection 2 req/detik
✓ Connection Limiting 20 koneksi per IP
✓ Cookie Verification tahan 1 jam
✓ Auto Backup Konfigurasi

## 🚀 Instalasi 1 Command
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/hamzantiddos/hamzantiddos/main/install.sh)"

📋 Prasyarat

· VPS Ubuntu/Debian
· Pterodactyl Panel terinstall
· Nginx + PHP-FPM

🔧 Manual Install

git clone https://github.com/hamzantiddos/hamzantiddos.git
cd hamzantiddos
chmod +x install.sh
sudo ./install.sh

🧪 Testing

for i in {1..15}; do curl -I https://domain-anda.com; done
tail -f /var/log/nginx/error.log | grep limiting

📁 Lokasi File

· Config: /etc/nginx/sites-available/pterodactyl.conf
· Challenge: /var/www/hamzflare/challenge/index.html

🔄 Uninstall
sudo mv /etc/nginx/sites-available/pterodactyl.conf.bak.* /etc/nginx/sites-available/pterodactyl.conf && sudo systemctl reload nginx


Made by Hamz | Anti DDoS Free
