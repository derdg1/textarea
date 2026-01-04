# GitHub Action - Docker Container Build

Automatisches Bauen und Veröffentlichen des textarea Docker Images zu GitHub Container Registry.

## Was macht die Action?

Die GitHub Action `.github/workflows/docker-build.yaml` baut automatisch einen Docker Container und veröffentlicht ihn zu `ghcr.io` (GitHub Container Registry).

### Features

✅ **Automatischer Build** bei jedem Push auf `main` oder `claude/**` Branches
✅ **Multi-Platform Support** - Build für AMD64 und ARM64 (z.B. Raspberry Pi, Apple Silicon)
✅ **GitHub Container Registry** - Kostenlos für public Repositories
✅ **Smart Tagging** - Automatische Tags für Branches, PRs und Commits
✅ **Build Cache** - Schnellere Builds durch GitHub Actions Cache
✅ **Attestation** - Provenance-Informationen für Supply Chain Security

---

## Automatischer Build-Trigger

Die Action wird automatisch ausgelöst bei:

- ✅ Push auf `main` Branch
- ✅ Push auf `claude/**` Branches
- ✅ Pull Requests zu `main`
- ✅ Manuell über "Run workflow" im GitHub UI

---

## Container Image Tags

Das Image wird mit verschiedenen Tags veröffentlicht:

| Tag | Beschreibung | Beispiel |
|-----|--------------|----------|
| `latest` | Neuester Build vom `main` Branch | `ghcr.io/derdg1/textarea:latest` |
| `<branch>` | Build vom spezifischen Branch | `ghcr.io/derdg1/textarea:main` |
| `<branch>-<sha>` | Build mit Git Commit SHA | `ghcr.io/derdg1/textarea:main-abc1234` |
| `pr-<number>` | Build von einem Pull Request | `ghcr.io/derdg1/textarea:pr-42` |

---

## Container verwenden

### 1. Mit Docker direkt

```bash
# Latest Version
docker pull ghcr.io/derdg1/textarea:latest
docker run -d -p 8080:80 ghcr.io/derdg1/textarea:latest

# Spezifischer Branch
docker pull ghcr.io/derdg1/textarea:main
docker run -d -p 8080:80 ghcr.io/derdg1/textarea:main
```

### 2. Mit Docker Compose

```yaml
version: '3.8'

services:
  textarea:
    image: ghcr.io/derdg1/textarea:latest
    container_name: textarea
    restart: unless-stopped
    ports:
      - "8080:80"
```

### 3. Mit Portainer Stack (empfohlen)

**Wichtig:** Ersetze die `build:` Section in `docker-compose.portainer.yml`:

**ALT:**
```yaml
services:
  textarea:
    build:
      context: https://github.com/derdg1/textarea.git#claude/self-hosting-setup-vOYPN
      dockerfile: Dockerfile
```

**NEU:**
```yaml
services:
  textarea:
    image: ghcr.io/derdg1/textarea:latest
```

**Vorteile:**
- ✅ Kein Build-Prozess in Portainer nötig (schneller!)
- ✅ Nutzt vorgebautes, getestetes Image
- ✅ Multi-Platform Support (läuft auf Intel, AMD, ARM)
- ✅ Automatische Updates mit Watchtower möglich

---

## Für Portainer Stack angepasste docker-compose

Erstelle eine neue Datei `docker-compose.portainer-ghcr.yml`:

```yaml
version: '3.8'

services:
  textarea:
    image: ghcr.io/derdg1/textarea:latest
    container_name: textarea
    restart: unless-stopped
    networks:
      - textarea-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    labels:
      - "com.centurylinklabs.watchtower.enable=true"

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: textarea-cloudflared
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    networks:
      - textarea-network
    depends_on:
      - textarea
    labels:
      - "com.centurylinklabs.watchtower.enable=true"

networks:
  textarea-network:
    driver: bridge
```

**In Portainer verwenden:**

1. **Stacks** → **Add stack**
2. **Name:** `textarea-ghcr`
3. **Build method:** **Web editor**
4. Füge die obige `docker-compose.yml` ein
5. **Environment variables:**
   - `CLOUDFLARE_TUNNEL_TOKEN`: `dein_token`
6. **Deploy the stack**

---

## Auto-Updates mit Watchtower

Die Container haben bereits das Label für Watchtower. Installiere Watchtower, um automatische Updates zu erhalten:

**Watchtower Stack:**

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
      - WATCHTOWER_POLL_INTERVAL=3600  # Prüfe stündlich
    command: --interval 3600
```

**Was passiert:**
1. Du pushst Code zu GitHub
2. GitHub Action baut neues Image
3. Watchtower erkennt neues Image
4. Watchtower updated Container automatisch
5. ✅ Deine App ist immer aktuell!

---

## Für Private Repositories

Falls dein Repository privat ist, musst du dich authentifizieren:

### Docker Login

```bash
# Personal Access Token (PAT) erstellen:
# GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# Permissions: read:packages

# Login
echo $GITHUB_PAT | docker login ghcr.io -u DEIN_GITHUB_USERNAME --password-stdin
```

### Portainer Registry

1. **Registries** → **Add registry**
2. **Type:** GitHub Container Registry
3. **URL:** `ghcr.io`
4. **Username:** Dein GitHub Username
5. **Password:** Personal Access Token mit `read:packages` Permission

---

## Workflow anpassen

### Andere Plattformen bauen

Bearbeite `.github/workflows/docker-build.yaml`:

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64,linux/arm/v7  # Raspberry Pi hinzugefügt
```

### Zu Docker Hub statt GitHub pushen

Ändere in `.github/workflows/docker-build.yaml`:

```yaml
env:
  REGISTRY: docker.io
  IMAGE_NAME: dein-username/textarea

# ...

- name: Log in to Container Registry
  uses: docker/login-action@v3
  with:
    registry: docker.io
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

Dann füge in GitHub Secrets hinzu:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

### Nur auf main Branch pushen

```yaml
on:
  push:
    branches:
      - main  # Entferne claude/** wenn nicht gewünscht
```

---

## Workflow Status prüfen

### Im GitHub UI

1. Repository → **Actions** Tab
2. Wähle den Workflow "Build and Push Docker Image"
3. Sieh alle Runs und deren Status

### Container Registry prüfen

1. Repository → **Packages** (rechte Sidebar)
2. Klicke auf `textarea`
3. Sieh alle verfügbaren Tags und Versionen

**Direkt URL:**
```
https://github.com/derdg1/textarea/pkgs/container/textarea
```

---

## Troubleshooting

### ❌ "Error: failed to push to ghcr.io"

**Lösung:** Prüfe Permissions in `.github/workflows/docker-build.yaml`:

```yaml
permissions:
  contents: read
  packages: write  # Wichtig!
```

### ❌ "Error: buildx failed"

**Häufige Ursache:** Dockerfile Syntax-Fehler

**Lösung:**
1. Teste lokal: `docker build .`
2. Prüfe Logs in GitHub Actions

### ❌ "Error: denied: installation not allowed"

**Lösung:**
1. Repository → **Settings** → **Actions** → **General**
2. **Workflow permissions:** Wähle "Read and write permissions"

### ❌ Container auf ARM64 läuft nicht

**Prüfe:** Ist `linux/arm64` in `platforms` definiert?

```yaml
platforms: linux/amd64,linux/arm64
```

### 🔍 Build Logs anschauen

1. GitHub → **Actions**
2. Klicke auf den fehlgeschlagenen Run
3. Klicke auf "build-and-push" Job
4. Expandiere "Build and push Docker image"

---

## Nützliche Befehle

```bash
# Neuestes Image pullen
docker pull ghcr.io/derdg1/textarea:latest

# Alle verfügbaren Tags anzeigen (erfordert GitHub CLI)
gh api /users/derdg1/packages/container/textarea/versions | jq -r '.[].metadata.container.tags[]'

# Image lokal inspizieren
docker inspect ghcr.io/derdg1/textarea:latest

# Image History anzeigen
docker history ghcr.io/derdg1/textarea:latest

# Multi-Arch Images anzeigen
docker buildx imagetools inspect ghcr.io/derdg1/textarea:latest
```

---

## Best Practices

### Security

- ✅ Nutze `GITHUB_TOKEN` (automatisch verfügbar, keine Secrets nötig)
- ✅ Scanne Images mit Trivy oder Snyk (optional hinzufügen)
- ✅ Nutze minimal base images (wie `nginx:alpine`)
- ✅ Aktiviere Dependabot für Docker

### Performance

- ✅ Nutze Build Cache (`cache-from`, `cache-to`)
- ✅ Multi-stage Builds (falls nötig)
- ✅ `.dockerignore` verwenden

### Tagging

- ✅ `latest` nur für stable main branch
- ✅ Semantic Versioning für Releases (z.B. `v1.2.3`)
- ✅ SHA-basierte Tags für Reproducibility

---

## Weitere Integrationen

### Semantic Versioning mit Releases

Füge zu `.github/workflows/docker-build.yaml` hinzu:

```yaml
on:
  push:
    tags:
      - 'v*.*.*'
```

```yaml
tags: |
  type=semver,pattern={{version}}
  type=semver,pattern={{major}}.{{minor}}
  type=semver,pattern={{major}}
```

Dann: `git tag v1.0.0 && git push --tags`

Erstellt automatisch: `ghcr.io/derdg1/textarea:1.0.0`, `1.0`, `1`

### Container Scanning

Füge vor dem Push hinzu:

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
    format: 'sarif'
    output: 'trivy-results.sarif'

- name: Upload Trivy results to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

---

## Support

- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Docker Build Push Action:** https://github.com/docker/build-push-action
- **GitHub Container Registry:** https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

---

**Happy Building! 🚀**
