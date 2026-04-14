```markdown
# 🛡️ Hamz-Flare Anti-DDoS

**Cloudflare-style Challenge Page untuk Pterodactyl Panel | 100% Gratis**

## 🚀 Instalasi (1 Command)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/hamzxdevbot/hamzantiddos/main/install-anti-ddos.sh)"
```

✨ Fitur

· ✅ Halaman "Melakukan verifikasi keamanan" ala Cloudflare
· ✅ Rate Limiting (10 req/detik per IP)
· ✅ Login Protection (2 req/detik)
· ✅ Connection Limiting (20 per IP)
· ✅ Cookie-based verification (1 jam)

🔧 Uninstall

```bash
sudo mv /etc/nginx/sites-available/pterodactyl.conf.bak.* /etc/nginx/sites-available/pterodactyl.conf
sudo systemctl reload ngi
