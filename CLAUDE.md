# Projectcontext

## Sessiestart — Projectkeuze

**Dit is een Docker-omgeving. Voer dit uit aan het begin van elke nieuwe sessie:**

1. Haal tegelijk op:
   - Lokale projecten in `/workspace`
   - GitHub-repo's van de ingelogde gebruiker
   ```bash
   ls /workspace
   gh repo list --limit 50 --json name,description,updatedAt --jq '.[] | "\(.name) — \(.description // "geen beschrijving")"'
   ```

2. Stel de gebruiker de volgende vraag, met beide lijsten:

   > **Lokale projecten in `/workspace`:**
   > 1. `project-a`
   > 2. `project-b`
   >
   > **Jouw GitHub-repo's (nog niet gekloned):**
   > 3. `mijn-repo` — korte beschrijving
   > 4. `ander-project` — korte beschrijving
   >
   > Kies een nummer, of typ `nieuw` om een leeg project aan te maken.

3. Op basis van het antwoord:
   - **Lokaal project gekozen** → `cd /workspace/{naam}` en ga verder
   - **GitHub-repo gekozen** → `git clone https://github.com/{gebruiker}/{naam} /workspace/{naam} && cd /workspace/{naam}`
   - **`nieuw`** → vraag naam en GitHub-URL, maak map aan, `git init`, koppel remote

## Git & GitHub in deze container

Credentials worden automatisch ingesteld via omgevingsvariabelen bij het opstarten. Je hoeft **nooit handmatig in te loggen**.

### Wat is al geconfigureerd
| Wat | Hoe |
|-----|-----|
| Git naam & e-mail | Via `GIT_USER_NAME` en `GIT_USER_EMAIL` in `.env` |
| GitHub CLI (`gh`) | Via `GITHUB_TOKEN` in `.env` — automatisch ingelogd |
| Git push/pull | Via token — geen wachtwoordprompt |

### Controleren
```bash
gh auth status          # toont ingelogd account
git config --global -l  # toont naam, e-mail en credential config
```

### Repo klonen
```bash
git clone https://github.com/gebruiker/repo /workspace/repo
cd /workspace/repo
```

### Troubleshooting
Als `git push` of `gh` toch om een wachtwoord vraagt, is de `GITHUB_TOKEN` waarschijnlijk verlopen of mist een scope. Vernieuw de token op **github.com → Settings → Developer settings → Personal access tokens** met scopes `repo`, `workflow` en `read:org`.

---

## Taal

Projectdocumentatie is in het Nederlands.

## Werkhouding bij coderen

Gedragsregels om veelgemaakte LLM-fouten te beperken. Voor triviale taken: gebruik je oordeel.

**Trade-off:** deze regels neigen naar zorgvuldigheid boven snelheid.

### 1. Eerst denken, dan coderen

**Geen aannames. Geen verborgen twijfel. Maak trade-offs zichtbaar.**

Voordat je begint te bouwen:
- Benoem aannames expliciet. Bij onzekerheid: vraag.
- Zijn er meerdere interpretaties? Leg ze voor — kies niet stilletjes.
- Bestaat er een eenvoudigere aanpak? Zeg dat. Geef terecht weerwoord.
- Is iets onduidelijk? Stop. Benoem wat verwart. Vraag.

### 2. Eenvoud eerst

**Minimale code die het probleem oplost. Niets speculatiefs.**

- Geen features buiten wat is gevraagd.
- Geen abstracties voor eenmalige code.
- Geen "flexibiliteit" of "configureerbaarheid" die niet is gevraagd.
- Geen errorhandling voor scenario's die niet kunnen optreden.
- Schrijf je 200 regels en kan het in 50? Herschrijf.

Toets: "Zou een senior engineer dit overgecompliceerd vinden?" Zo ja → simplificeer.

### 3. Chirurgische wijzigingen

**Raak alleen aan wat moet. Ruim alleen je eigen rommel op.**

Bij het bewerken van bestaande code:
- Geen "verbeteringen" aan aangrenzende code, comments of formatting.
- Geen refactor van wat niet stuk is.
- Volg bestaande stijl, ook als je het zelf anders zou doen.
- Zie je niet-gerelateerde dode code? Meld het — verwijder het niet.

Als jouw wijziging iets onbruikt maakt:
- Verwijder imports/variabelen/functies die *door jouw wijziging* onbruikt zijn.
- Verwijder geen al bestaande dode code, tenzij gevraagd.

Toets: elke gewijzigde regel moet direct te herleiden zijn naar de vraag van de gebruiker.

### 4. Doelgerichte uitvoering

**Definieer succescriteria. Itereer tot ze verifieerbaar groen zijn.**

Vertaal taken naar verifieerbare doelen:
- "Validatie toevoegen" → "Schrijf tests voor ongeldige invoer, maak ze groen"
- "Bug oplossen" → "Schrijf een test die de bug reproduceert, maak hem groen"
- "X refactoren" → "Tests groen vóór en na de wijziging"

Voor taken met meerdere stappen: benoem kort het plan:
```
1. [Stap] → verificatie: [check]
2. [Stap] → verificatie: [check]
3. [Stap] → verificatie: [check]
```

Sterke succescriteria laten je zelfstandig itereren. Zwakke criteria ("zorg dat het werkt") leveren constante terugvragen op. Voor de concrete test-eerst-volgorde bij nieuwe code: zie [Testen — Werkwijze](#testen--werkwijze) verderop.

---

**Deze regels werken als:** minder onnodige wijzigingen in diffs, minder herschrijfwerk door overcomplicatie, en verhelderingsvragen *vóór* implementatie in plaats van na fouten.

---

## Ontwikkeling & GitHub Issues — Werkwijze

Elke codewijziging is gekoppeld aan een GitHub issue. Dit is de vaste werkwijze:

### 1. Issue eerst
Voordat er code wordt geschreven of gewijzigd, bestaat er altijd een issue. Maak het aan via:
```
gh issue create --title "..." --body "..." --label "..."
```

**Labels:**
| Label | Wanneer |
|-------|---------|
| `bug` | Iets werkt niet zoals verwacht |
| `enhancement` | Nieuwe functionaliteit |
| `refactor` | Code verbeteren zonder gedragswijziging |
| `documentation` | Alleen documentatie |
| `research` | Onderzoek of verkenning, nog geen code |
| `chore` | Onderhoud, dependencies, CI/CD |

### 2. Branch per issue
Werk per issue op een aparte feature-branch zodat `main` onaangeraakt blijft en er parallel aan meerdere issues gewerkt kan worden.

**Stappen:**
1. Zorg dat `main` up-to-date is en maak een nieuwe branch aan:
   ```bash
   git checkout main
   git pull
   git checkout -b issue-42-korte-beschrijving
   ```
2. Werk op die branch — commits, bewerkingen en pushes gebeuren allemaal hier.
3. Push de branch en open een Pull Request:
   ```bash
   git push -u origin issue-42-korte-beschrijving
   gh pr create --fill
   ```
4. Na merge: schakel terug naar `main`, trek de wijzigingen op en verwijder de branch lokaal:
   ```bash
   git checkout main
   git pull
   git branch -d issue-42-korte-beschrijving
   ```

**Naamconventie branch:** `issue-{nummer}-{korte-beschrijving}`

**Belangrijk:**
- Werk **nooit** direct op `main` — altijd via een feature-branch
- Elke nieuwe programmeeropdracht → nieuw issue → nieuwe branch
- Na merge → lokale branch opruimen met `git branch -d`

### 3. Conventional Commits
Elk commit-bericht volgt de [Conventional Commits](https://www.conventionalcommits.org/) standaard:

```
<type>(<scope>): <omschrijving>

[optionele body]

[optionele footer, bijv. Closes #42]
```

**Types:**
| Type | Gebruik |
|------|---------|
| `fix:` | Bugfix — verhoogt patch-versie (1.0.**1**) |
| `feat:` | Nieuwe feature — verhoogt minor-versie (1.**1**.0) |
| `refactor:` | Herstructurering zonder gedragswijziging |
| `test:` | Alleen tests toevoegen of aanpassen |
| `docs:` | Alleen documentatie |
| `chore:` | Onderhoud, build, CI/CD |
| `ci:` | Wijzigingen aan pipelines of workflows |
| `BREAKING CHANGE:` | In de footer: verhoogt major-versie (**2**.0.0) |

**Voorbeelden:**
```
fix(auth): null pointer afgevangen bij lege gebruikersnaam

feat(export): PDF-export toegevoegd aan rapportmodule

Closes #42
```

Voor tussentijdse commits (werk in uitvoering):
```
wip(#42): eerste opzet exportfunctie, tests ontbreken nog
```

### 4. Pull Request naar main
Na afronding: maak een PR aan die het issue sluit. Gebruik `Closes #42` in de PR-beschrijving of het laatste commit-bericht — GitHub sluit het issue automatisch bij merge.

PR-titel volgt ook Conventional Commits: `feat(scope): omschrijving (#42)`

### Wanneer Claude een issue aanmaakt
- Bij elke nieuwe functionaliteit of codewijziging
- Wanneer een technisch probleem of risico wordt gesignaleerd
- Wanneer een idee opkomt dat nu niet direct wordt opgepakt

---

## Testen — Werkwijze

Elke functie of methode die wordt geschreven, krijgt direct een bijbehorende test. Dit is geen optie maar standaard onderdeel van het werk.

### Pytest — unit tests
- Elke functie krijgt direct een `pytest`-test in `tests/`
- Bestandsnaamconventie: `test_{modulenaam}.py`
- Testfunctienamen beschrijven het gedrag: `test_bereken_totaal_geeft_nul_bij_lege_lijst()`
- Dek minimaal af: het happy path, edge cases, en ongeldige invoer

### Integratietests
- Schrijf een integratietest zodra twee of meer componenten samenwerken
- Integratietests staan in `tests/integration/`
- Ze testen het systeem als geheel: van invoer tot verwachte uitvoer

### Committen en mergen
- **Committen met falende tests is toegestaan** — tussentijds werk opslaan is prima, gebruik dan een WIP-commit: `wip(#42): module half af, tests falen nog`
- **Mergen naar `main` met falende tests is niet toegestaan** — afgedwongen via GitHub Actions en branch protection rules op `main`

### GitHub Actions — CI pipeline
Bij elke pull request naar `main` draait GitHub Actions automatisch de volledige testsuite. De merge-knop is geblokkeerd zolang de check niet slaagt.

**Workflow-bestand: `.github/workflows/ci.yml`**
```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Python instellen
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      - name: Dependencies installeren
        run: pip install -r requirements.txt

      - name: Pytest uitvoeren
        run: pytest --tb=short
```

**Branch protection instellen (eenmalig via GitHub):**
1. Ga naar **Settings → Branches → Add branch ruleset**
2. Target: `main`
3. Vink aan: **Require status checks to pass before merging**
4. Voeg de check `test` toe (naam van de job in de workflow)
5. Vink aan: **Require branches to be up to date before merging**

Na deze instelling blokkeert GitHub de merge-knop automatisch zolang pytest faalt of de CI nog niet klaar is.

### Volgorde bij nieuwe code
1. Maak het issue aan
2. Schrijf de functie
3. Schrijf direct de bijbehorende pytest
4. Commit (mag ook als tests nog falen — gebruik WIP)
5. Maak integratietest zodra componenten worden gekoppeld
6. Alle tests groen vóór merge naar `main`
