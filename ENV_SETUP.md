# .env Datei Setup - Morning Briefing

## Übersicht

Die `.env` Datei ermöglicht eine einfache lokale Konfiguration der E-Mail-Einstellungen ohne die Notwendigkeit, Umgebungsvariablen manuell zu setzen.

## Quick Start

### Automatisches Setup (Empfohlen)
```bash
./setup-env.sh
```

### Manuelles Setup
1. Bearbeiten Sie die `.env` Datei im Projektroot
2. Tragen Sie Ihre Gmail-Daten ein:
   ```
   EMAIL_USERNAME=ihre-email@gmail.com
   EMAIL_PASSWORD=ihr-16-stelliges-app-passwort
   EMAIL_RECIPIENTS=empfaenger1@beispiel.com,empfaenger2@beispiel.com
   ```

## Sicherheit

- ✅ **Automatisch ignoriert**: Die `.env` Datei wird durch `.gitignore` nicht committet
- ✅ **Lokale Verwendung**: Nur für lokale Entwicklung und Tests
- ✅ **Sichere Produktionsumgebung**: GitHub Actions verwenden Repository Secrets

## Verwendung

Die `.env` Datei wird automatisch von folgenden Skripten geladen:
- `test-email-local.sh` - E-Mail-System testen
- `test-local-render.sh` - Morning Briefing rendern (falls erforderlich)

## Verfügbare Variablen

| Variable | Beschreibung | Beispiel |
|----------|--------------|----------|
| `EMAIL_USERNAME` | Gmail-Adresse | `beispiel@gmail.com` |
| `EMAIL_PASSWORD` | Gmail App-Passwort | `abcdefghijklmnop` |
| `EMAIL_RECIPIENTS` | Empfänger (kommagetrennt) | `emp1@test.com,emp2@test.com` |
| `EMAIL_TEST_RECIPIENTS` | Test-Empfänger | `test@example.com` |
| `DEBUG_EMAIL` | Debug-Modus | `true` oder `false` |
| `VERBOSE_OUTPUT` | Ausführliche Ausgabe | `true` oder `false` |

## Troubleshooting

### .env Datei wird nicht geladen
- Stellen Sie sicher, dass die Datei im Projektroot liegt
- Überprüfen Sie die Dateiberechtigungen
- Testen Sie mit `cat .env` ob die Datei lesbar ist

### Gmail App-Passwort
- Verwenden Sie niemals Ihr normales Gmail-Passwort
- Das App-Passwort muss genau 16 Zeichen haben
- Aktivieren Sie 2-Faktor-Authentifizierung in Google

## Dateien

```
/workspaces/morning_briefing/
├── .env                    # ← Lokale Umgebungsvariablen (nicht committet)
├── .gitignore             # ← Ignoriert .env und andere temporäre Dateien
├── setup-env.sh           # ← Interaktives Setup-Skript
├── test-email-local.sh    # ← Lädt .env automatisch
└── EMAIL_SETUP.md         # ← Detaillierte E-Mail-Dokumentation
```

## Weiterführende Dokumentation

- `EMAIL_SETUP.md` - Detaillierte Gmail-Konfiguration
- `GITHUB_ACTION_README.md` - Produktions-Setup mit Repository Secrets
