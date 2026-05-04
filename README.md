# Claude Code Docker

Een persoonlijke, herbruikbare Docker-omgeving voor [Claude Code](https://docs.claude.com/en/docs/claude-code) met Git, GitHub CLI en optioneel Tailscale al voor je geregeld.

---

## Dagelijks gebruik

> Deze sectie ga je het vaakst gebruiken: container starten en aan een project werken. De [eerste-keer setup](#eerste-keer-setup) staat verderop in deze README — alleen nodig op een nieuwe machine.

### 1. Container starten (vanaf je host)

Open een terminal in deze repo en start de container (als die nog niet draait):

```bash
docker compose up -d
```

Niets te doen als hij al draait — `restart: unless-stopped` houdt hem aan.

### 2. In de container terechtkomen

Twee makkelijke opties — kies wat je prettig vindt:

**Browser-terminal** (geen client nodig):

```
http://localhost:7681
```

**SSH** (vanaf dezelfde host-terminal):

```bash
ssh claude@localhost -p 2222
```

### 3. Claude Code starten

Eenmaal binnen:

```bash
claude
```

Claude vraagt automatisch welk project je wilt openen en laat zowel je **lokale projecten in `/workspace`** als je **GitHub-repo's** zien:

> **Lokale projecten in `/workspace`:**
> 1. `project-a`
> 2. `project-b`
>
> **Jouw GitHub-repo's (nog niet gekloond):**
> 3. `mijn-repo` — korte beschrijving
> 4. `ander-project` — korte beschrijving
>
> Kies een nummer, of typ `nieuw` om een leeg project aan te maken.

### 4a. Verder aan een bestaand GitHub-project

- **Staat het al in `/workspace`?** Kies het nummer onder *Lokale projecten*. Claude doet `cd /workspace/<naam>` en gaat verder. De project-`CLAUDE.md` (als die er is) wordt automatisch geladen.
- **Staat het nog niet in de container?** Kies het nummer onder *Jouw GitHub-repo's*. Claude kloont automatisch via `gh` — geen login nodig — en springt erin:
  ```bash
  git clone https://github.com/<jij>/<repo> /workspace/<repo>
  cd /workspace/<repo>
  ```

Vanaf dat moment werk je volgens [`CLAUDE.md`](./CLAUDE.md): issue eerst, feature-branch, conventional commits, PR naar `main`.

### 4b. Een nieuw project starten

Typ `nieuw` bij de projectkeuze. Claude vraagt:

- de **projectnaam** (wordt `/workspace/<naam>`)
- optioneel een **GitHub-URL** voor een lege repo die je vooraf hebt aangemaakt

Daarna maakt Claude de map aan, doet `git init`, koppelt de remote en je kunt aan de slag. Vraag eventueel direct `/init` aan Claude — dan schrijft die meteen een project-`CLAUDE.md` op basis van wat er al is.

---

## Hoe `CLAUDE.md` werkt

Claude Code stapelt `CLAUDE.md`-bestanden automatisch:

| Locatie | Wat staat erin | Wanneer geladen |
|---------|----------------|-----------------|
| `~/.claude/CLAUDE.md` (globaal in container) | De `CLAUDE.md` van *deze* repo — projectkeuze, issues, branches, conventional commits, testen | **Altijd** — geldt voor elk project |
| `/workspace/<project>/CLAUDE.md` | Projectspecifieke afspraken, architectuur, dependencies | Automatisch wanneer je `cd /workspace/<project>` doet en `claude` start |

Beide gelden tegelijk. De globale werkwijze blijft overeind, projectregels komen erbovenop.

---

## Eerste-keer setup

Alleen nodig de eerste keer op een machine (deze of een andere).

### Vereisten

- Docker Desktop (Windows/Mac) of Docker Engine + `docker compose` (Linux)
- Een Anthropic API key — [console.anthropic.com](https://console.anthropic.com)
- Optioneel: een GitHub Personal Access Token met scopes `repo`, `workflow`, `read:org`

### 1. Repo klonen

```bash
git clone https://github.com/gvanhassel/claude-docker
cd claude-docker
```

### 2. `.env` aanmaken

Maak `.env` in de repo-root (wordt door `.gitignore` uitgesloten):

```env
# === VERPLICHT ===
ANTHROPIC_API_KEY=sk-ant-...

# === SSH toegang (kies wachtwoord óf publieke sleutel, of beide) ===
SSH_PASSWORD=kies_een_sterk_wachtwoord
SSH_PUBLIC_KEY=ssh-ed25519 AAAA... jouw@email

# === Git identiteit ===
GIT_USER_NAME=jouw-github-naam
GIT_USER_EMAIL=jij@example.com

# === GitHub token (gh CLI + git push zonder prompt) ===
GITHUB_TOKEN=ghp_...

# === Tailscale (optioneel — laat leeg om te skippen) ===
TAILSCALE_AUTH_KEY=tskey-auth-...
TAILSCALE_HOSTNAME=claude-docker
```

### 3. Container builden en starten

```bash
docker compose up -d --build
```

De eerste build duurt een paar minuten. Daarna draait alles in de achtergrond en herstart automatisch bij een reboot.

Daarna ben je klaar — terug naar [Dagelijks gebruik](#dagelijks-gebruik).

---

## Wat zit erin

- **Ubuntu 24.04** + Node.js 22 + Claude Code (globaal geïnstalleerd)
- **GitHub CLI (`gh`)** — automatisch ingelogd via `GITHUB_TOKEN`
- **Git** — naam, e-mail en token-credentials worden bij start ingesteld
- **SSH-server** op poort `2222` (host) → `22` (container)
- **ttyd** browser-terminal op poort `7681`
- **Tailscale** (optioneel) — bereik de container vanaf elk apparaat in je tailnet
- **Persistente `/workspace`** — blijft behouden tussen container-restarts en rebuilds
- **Globale `CLAUDE.md`** in `~/.claude/CLAUDE.md` — jouw werkwijze geldt voor *alle* projecten

---

## Vanaf een andere machine bereiken (Tailscale)

Heb je `TAILSCALE_AUTH_KEY` ingesteld? Dan is de container ook van onderweg bereikbaar:

```bash
ssh claude@claude-docker
```

Werkt vanaf elk apparaat dat in jouw tailnet zit.

---

## Persistentie

| Wat | Waar | Blijft behouden bij... |
|-----|------|------------------------|
| Code en projecten | `/workspace` (volume `workspace`) | restart, rebuild, host-reboot |
| Tailscale-state | `/var/lib/tailscale` (volume `tailscale-state`) | restart, rebuild |
| Globale `~/.claude` | In de image | restart (komt vers uit Dockerfile bij rebuild) |

Volledig opschonen — **verwijdert al je projecten in `/workspace`**:

```bash
docker compose down -v
```

---

## Troubleshooting

### Logs bekijken

```bash
docker compose ps
docker compose logs -f claude
```

### Controleren in de container

```bash
gh auth status            # toont ingelogd account
git config --global -l    # toont naam, e-mail, credential helper
```

### `git push` of `gh` vraagt om wachtwoord

`GITHUB_TOKEN` is verlopen of mist een scope. Vernieuw op **github.com → Settings → Developer settings → Personal access tokens** met scopes `repo`, `workflow`, `read:org`. Pas `.env` aan en herstart:

```bash
docker compose up -d --force-recreate
```

### `.env` aangepast — hoe activeer ik de wijzigingen?

Environment-variabelen worden alleen bij start gelezen:

```bash
docker compose up -d --force-recreate
```

### Image opnieuw builden (na Dockerfile-wijziging)

```bash
docker compose up -d --build
```

---

## Werkwijze in projecten

Zodra je in een project zit gelden de regels uit [`CLAUDE.md`](./CLAUDE.md):

- Elke wijziging hoort bij een GitHub issue
- Werk op een feature-branch, nooit direct op `main`
- Conventional Commits voor commit-berichten
- Pytest voor unit tests, `tests/integration/` voor integratietests
- PR met groene CI vóór merge naar `main`

Zie `CLAUDE.md` voor de volledige werkwijze.
