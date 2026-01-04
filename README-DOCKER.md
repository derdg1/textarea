# Textarea - Docker Self-Hosting Guide

Diese Anleitung zeigt, wie du textarea.my mit Docker Compose selbst hosten kannst.

## Voraussetzungen

- Docker installiert (Version 20.10+)
- Docker Compose installiert (Version 2.0+)

## Schnellstart

### 1. Repository klonen

```bash
git clone https://github.com/antonmedv/textarea.git
cd textarea
```

### 2. Mit Docker Compose starten

```bash
docker-compose up -d
```

Die Anwendung läuft nun auf: **http://localhost:8080**

## Verfügbare Befehle

### Container starten
```bash
docker-compose up -d
```

### Container stoppen
```bash
docker-compose down
```

### Logs anzeigen
```bash
docker-compose logs -f
```

### Container neu bauen
```bash
docker-compose up -d --build
```

### Status prüfen
```bash
docker-compose ps
```

## Konfiguration

### Port ändern

Bearbeite `docker-compose.yml` und ändere den Port:

```yaml
ports:
  - "3000:80"  # Ändere 8080 zu deinem gewünschten Port
```

### Reverse Proxy (z.B. Nginx/Traefik)

Für den Einsatz hinter einem Reverse Proxy:

#### Mit Nginx:

```nginx
server {
    listen 80;
    server_name textarea.deine-domain.de;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Mit Traefik (docker-compose.yml):

```yaml
version: '3.8'

services:
  textarea:
    build: .
    container_name: textarea
    restart: unless-stopped
    networks:
      - traefik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.textarea.rule=Host(`textarea.deine-domain.de`)"
      - "traefik.http.routers.textarea.entrypoints=websecure"
      - "traefik.http.routers.textarea.tls.certresolver=letsencrypt"
      - "traefik.http.services.textarea.loadbalancer.server.port=80"

networks:
  traefik:
    external: true
```

## SSL/HTTPS einrichten

### Mit Caddy (einfachste Lösung)

Erstelle eine `docker-compose.caddy.yml`:

```yaml
version: '3.8'

services:
  textarea:
    build: .
    container_name: textarea
    restart: unless-stopped
    networks:
      - textarea-network

  caddy:
    image: caddy:alpine
    container_name: textarea-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - textarea-network

networks:
  textarea-network:
    driver: bridge

volumes:
  caddy_data:
  caddy_config:
```

Erstelle eine `Caddyfile`:

```
textarea.deine-domain.de {
    reverse_proxy textarea:80
}
```

Starten mit:
```bash
docker-compose -f docker-compose.caddy.yml up -d
```

## Production Deployment

### docker-compose.prod.yml

```yaml
version: '3.8'

services:
  textarea:
    build: .
    container_name: textarea
    ports:
      - "8080:80"
    restart: always
    networks:
      - textarea-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M

networks:
  textarea-network:
    driver: bridge
```

Starten mit:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## Updates

### Update auf neue Version

```bash
git pull
docker-compose down
docker-compose up -d --build
```

## Troubleshooting

### Container startet nicht
```bash
docker-compose logs textarea
```

### Port bereits belegt
```bash
# Ändere den Port in docker-compose.yml
# oder finde den Prozess, der den Port belegt:
sudo lsof -i :8080
```

### Permission-Fehler
```bash
# Stelle sicher, dass Docker läuft:
sudo systemctl status docker

# Füge deinen User zur docker Gruppe hinzu:
sudo usermod -aG docker $USER
```

## Sicherheit

- Verwende immer HTTPS in Production (mit Caddy/Traefik/Let's Encrypt)
- Setze Resource Limits in Production
- Halte das Base Image aktuell: `docker-compose pull && docker-compose up -d`
- Verwende einen Reverse Proxy mit Rate Limiting

## Performance

Die nginx.conf ist bereits optimiert mit:
- Gzip Kompression
- Browser Caching
- Security Headers

Für hohen Traffic kannst du zusätzlich einen CDN wie Cloudflare vorschalten.

## Support

Bei Fragen oder Problemen:
- GitHub Issues: https://github.com/antonmedv/textarea/issues
- Original README: [README.md](README.md)
