# Textarea - Portainer Stack mit Cloudflare Tunnel

Komplette Anleitung für das Deployment von textarea auf deinem NUC mit Portainer und Cloudflare Tunnel.

## Vorteile dieser Lösung

✅ Kein Port-Forwarding nötig
✅ Automatisches SSL durch Cloudflare
✅ Schutz deiner Home-IP-Adresse
✅ Auto-Updates direkt aus dem Git-Repository
✅ Einfaches Management über Portainer UI

---

## Teil 1: Cloudflare Tunnel einrichten

### Schritt 1: Cloudflare Zero Trust einrichten

1. Gehe zu [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Wähle deine Domain aus (oder füge eine neue hinzu)
3. Navigiere zu **Zero Trust** (im linken Menü)
   - Falls noch nicht aktiviert: Klicke auf "Get started" und folge den Schritten

### Schritt 2: Tunnel erstellen

1. Im Zero Trust Dashboard: **Networks** → **Tunnels**
2. Klicke auf **Create a tunnel**
3. Wähle **Cloudflared**
4. Gib deinem Tunnel einen Namen: z.B. `nuc-textarea`
5. Klicke auf **Save tunnel**

### Schritt 3: Tunnel Token kopieren

Nach dem Erstellen siehst du verschiedene Installationsmethoden:

1. Wähle **Docker** aus
2. Du siehst einen Befehl wie:
   ```bash
   docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiM...
   ```
3. **Kopiere nur den Token** (den langen String nach `--token`)
4. **WICHTIG:** Speichere diesen Token sicher - du brauchst ihn gleich!

### Schritt 4: Public Hostname konfigurieren

1. Im gleichen Tunnel-Setup: Klicke auf **Next** oder gehe zu **Public Hostname**
2. Klicke auf **Add a public hostname**
3. Konfiguriere:
   - **Subdomain:** `textarea` (oder was du möchtest)
   - **Domain:** `deine-domain.de` (aus dem Dropdown)
   - **Path:** leer lassen
   - **Service Type:** `HTTP`
   - **URL:** `textarea:80`
4. Klicke auf **Save hostname**

Deine App wird dann erreichbar sein unter: `https://textarea.deine-domain.de`

---

## Teil 2: Portainer Stack einrichten

### Schritt 1: Stack erstellen

1. Öffne Portainer: `http://nuc-ip:9000` (oder deine Portainer-URL)
2. Wähle dein **Environment** aus (z.B. "local")
3. Im linken Menü: **Stacks**
4. Klicke auf **+ Add stack**

### Schritt 2: Repository-basiertes Deployment konfigurieren

1. **Name:** `textarea`
2. **Build method:** Wähle **Repository** aus

#### Git Repository Einstellungen:

- **Repository URL:**
  ```
  https://github.com/derdg1/textarea
  ```

- **Repository reference:**
  ```
  refs/heads/claude/self-hosting-setup-vOYPN
  ```

  *Optional: Wenn der Branch später gemerged wird, nutze:*
  ```
  refs/heads/main
  ```

- **Compose path:**
  ```
  docker-compose.portainer.yml
  ```

- **Authentication:** Nicht nötig (public repository)

#### Automatisches Update aktivieren (optional):

- ✅ **GitOps updates** aktivieren
- **Polling interval:** z.B. `5m` (5 Minuten)

  *So zieht Portainer automatisch Updates aus dem Repository!*

### Schritt 3: Environment Variables konfigurieren

Scrolle nach unten zu **Environment variables**

Klicke auf **+ Add an environment variable** und füge hinzu:

| Name | Value |
|------|-------|
| `CLOUDFLARE_TUNNEL_TOKEN` | `dein_kopierter_token_aus_schritt_3` |

**WICHTIG:** Setze den echten Token ein, den du in Teil 1, Schritt 3 kopiert hast!

### Schritt 4: Stack deployen

1. Scrolle nach unten
2. Klicke auf **Deploy the stack**
3. Warte, bis der Build abgeschlossen ist (kann 1-2 Minuten dauern)

---

## Teil 3: Überprüfung & Zugriff

### Container Status prüfen

1. In Portainer → **Stacks** → **textarea**
2. Du solltest 2 laufende Container sehen:
   - ✅ `textarea` (grün)
   - ✅ `textarea-cloudflared` (grün)

### Logs überprüfen

**Cloudflared Logs:**
1. Klicke auf den Container `textarea-cloudflared`
2. Wähle **Logs** aus
3. Du solltest sehen:
   ```
   INF Connection <UUID> registered connIndex=0
   INF Connection <UUID> registered connIndex=1
   ```
   → Das bedeutet: Tunnel ist verbunden! ✅

**Textarea Logs:**
1. Klicke auf den Container `textarea`
2. Sollte nginx-Startup-Logs zeigen

### Zugriff testen

Öffne im Browser:
```
https://textarea.deine-domain.de
```

Du solltest jetzt textarea sehen! 🎉

---

## Teil 4: Erweiterte Konfiguration

### Mehrere Subdomains auf demselben Tunnel

Du kannst denselben Cloudflare Tunnel für mehrere Services nutzen:

1. In Cloudflare Zero Trust → **Networks** → **Tunnels**
2. Klicke auf deinen Tunnel → **Public Hostname**
3. Füge weitere Hostnames hinzu:
   - `service1.deine-domain.de` → `http://service1:80`
   - `service2.deine-domain.de` → `http://service2:8080`

### Auto-Update mit Watchtower

Die Container haben bereits das Label `com.centurylinklabs.watchtower.enable=true`

Füge Watchtower als separaten Stack hinzu:

**Stack Name:** `watchtower`

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=false
      - WATCHTOWER_LABEL_ENABLE=true
    command: --interval 3600
```

Watchtower aktualisiert dann automatisch alle Container mit dem Label stündlich.

### Cloudflare Access (optional)

Schütze deine App mit Cloudflare Access:

1. In Zero Trust → **Access** → **Applications**
2. **Add an application** → **Self-hosted**
3. **Application name:** `Textarea`
4. **Application domain:** `textarea.deine-domain.de`
5. Konfiguriere Zugriffsregeln (Email, Google Login, etc.)

---

## Teil 5: Updates & Wartung

### Stack Updates aus Repository

**Automatisch (wenn GitOps aktiviert):**
- Portainer zieht alle 5 Minuten Updates
- Automatisches Rebuild wenn Änderungen erkannt werden

**Manuell:**
1. In Portainer → **Stacks** → **textarea**
2. Klicke auf **Pull and redeploy**
3. Bestätige mit **Update**

### Container neu starten

**Über Portainer:**
1. **Stacks** → **textarea**
2. Klicke auf den Container
3. **Restart**

**Über CLI:**
```bash
docker restart textarea
docker restart textarea-cloudflared
```

### Logs anzeigen

**Über Portainer:**
- Container auswählen → **Logs**

**Über CLI:**
```bash
# Live logs
docker logs -f textarea
docker logs -f textarea-cloudflared

# Letzte 100 Zeilen
docker logs --tail 100 textarea
```

---

## Troubleshooting

### ❌ "Container startet nicht"

**Prüfe Logs:**
```bash
docker logs textarea
```

**Häufige Ursachen:**
- Build-Fehler → Prüfe ob alle Dateien im Repository sind
- Port bereits belegt → In dieser Config nicht relevant (kein exposed port)

### ❌ "Cloudflare Tunnel verbindet nicht"

**Prüfe Logs:**
```bash
docker logs textarea-cloudflared
```

**Fehlermeldung: "Invalid tunnel token"**
- Token ist falsch oder abgelaufen
- Lösung: Neuen Token in Cloudflare generieren und in Portainer Environment Variables aktualisieren

**Fehlermeldung: "Cannot reach service"**
- Service `textarea` läuft nicht
- Prüfe: `docker ps | grep textarea`

**Fehlermeldung: "Tunnel credentials file not found"**
- Normal beim ersten Start mit Token-basierter Auth
- Ignorieren, falls Tunnel trotzdem funktioniert

### ❌ "Seite nicht erreichbar (502 Bad Gateway)"

**Mögliche Ursachen:**

1. **Textarea Container läuft nicht:**
   ```bash
   docker ps | grep textarea
   docker restart textarea
   ```

2. **Falscher Service-Name in Cloudflare:**
   - In Cloudflare Tunnel → Public Hostname
   - Service URL muss sein: `http://textarea:80`
   - Nicht: `http://localhost:80` ❌

3. **Container nicht im gleichen Network:**
   - Beide Container müssen im `textarea-network` sein
   - Prüfe: `docker network inspect textarea-network`

### ❌ "Portainer kann Repository nicht klonen"

**Fehler: "Authentication failed"**
- Bei public Repository nicht nötig
- Falls private: SSH-Key oder Personal Access Token in Portainer hinterlegen

**Fehler: "Reference not found"**
- Branch-Name prüfen
- Nutze: `refs/heads/claude/self-hosting-setup-vOYPN`
- Nicht: `claude/self-hosting-setup-vOYPN` ❌

### ❌ "SSL-Fehler / Zertifikat ungültig"

- Cloudflare Tunnel nutzt automatisch Cloudflare SSL
- Falls Fehler: Prüfe in Cloudflare → SSL/TLS → Overview
- Empfohlen: "Full" oder "Full (strict)"

### 🔍 Netzwerk-Debugging

**Prüfe Container-Netzwerk:**
```bash
# Alle Netzwerke anzeigen
docker network ls

# Netzwerk inspizieren
docker network inspect textarea-network

# Sollte beide Container zeigen
```

**Teste Verbindung zwischen Containern:**
```bash
# Vom cloudflared Container zum textarea Container
docker exec textarea-cloudflared wget -O- http://textarea:80

# Sollte HTML zurückgeben
```

### 🔄 Kompletter Neustart

Falls alles fehlschlägt:

```bash
# Stack stoppen
docker-compose -f docker-compose.portainer.yml down

# Alle Container entfernen
docker rm -f textarea textarea-cloudflared

# Netzwerk entfernen
docker network rm textarea-network

# In Portainer: Stack neu deployen
```

---

## Performance & Sicherheit

### Ressourcen-Limits setzen

Bearbeite in Portainer die Stack-Definition:

```yaml
services:
  textarea:
    # ... existing config ...
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
```

### Cloudflare Firewall Rules

Schütze deine App zusätzlich:

1. Cloudflare Dashboard → **Security** → **WAF**
2. Erstelle Regeln für:
   - Rate Limiting
   - Bot Protection
   - Geo-Blocking (falls gewünscht)

### Backup

**Wichtig:** Diese App speichert Daten im URL-Hash, NICHT im Container!

Aber für Konfiguration:
```bash
# Stack-Konfiguration in Portainer exportieren
# Portainer → Stacks → textarea → Editor → Copy
```

---

## Nützliche Befehle

```bash
# Container Status
docker ps | grep textarea

# Alle Logs anzeigen
docker-compose -f docker-compose.portainer.yml logs -f

# Nur textarea Logs
docker logs -f textarea

# Nur cloudflared Logs
docker logs -f textarea-cloudflared

# Container neu starten
docker restart textarea textarea-cloudflared

# Stack komplett entfernen
docker-compose -f docker-compose.portainer.yml down

# Netzwerk inspizieren
docker network inspect textarea-network

# Container inspizieren
docker inspect textarea
docker inspect textarea-cloudflared
```

---

## Alternative: Cloudflare Tunnel separat verwalten

Falls du den Cloudflare Tunnel für mehrere Services nutzen möchtest:

1. Erstelle einen separaten Portainer Stack für Cloudflare Tunnel
2. Nutze ein gemeinsames Docker-Netzwerk
3. Konfiguriere mehrere Services im Cloudflare Dashboard

**Siehe:** [Separate Tunnel Setup Guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

---

## Support & Links

- **Textarea GitHub:** https://github.com/antonmedv/textarea
- **Cloudflare Tunnel Docs:** https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- **Portainer Docs:** https://docs.portainer.io/user/docker/stacks
- **Docker Compose Docs:** https://docs.docker.com/compose/

---

**Made with ❤️ for Self-Hosting auf dem NUC!**
