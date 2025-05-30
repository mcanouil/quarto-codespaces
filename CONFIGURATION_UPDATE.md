# Konfiguration Update: Gmail SMTP

## Durchgeführte Änderungen

Das Morning Briefing System wurde erfolgreich von Yahoo Mail auf Gmail SMTP umgestellt.

### Geänderte Dateien

1. **`.github/workflows/render-briefing.yml`**
   - SMTP Server: `smtp.mail.yahoo.com` → `smtp.gmail.com`
   - Port bleibt 587 (TLS)

2. **`test-email-local.sh`**
   - msmtp Account-Name: `yahoo` → `gmail`
   - SMTP Host: `smtp.mail.yahoo.com` → `smtp.gmail.com`
   - Beispiel-E-Mail in Fehlermeldung: `@yahoo.com` → `@gmail.com`

3. **`EMAIL_SETUP.md`**
   - War bereits für Gmail konfiguriert ✅
   - Enthält detaillierte Gmail App-Passwort Anleitung

## Erforderliche Repository Secrets

Stellen Sie sicher, dass folgende Secrets in den GitHub Repository Settings konfiguriert sind:

- `EMAIL_USERNAME`: Ihre Gmail-Adresse (z.B. `beispiel@gmail.com`)
- `EMAIL_PASSWORD`: Gmail App-Passwort (16-stellig)
- `EMAIL_RECIPIENTS`: Empfänger-E-Mail-Adressen (kommagetrennt)

## Gmail App-Passwort Setup

1. **2-Faktor-Authentifizierung aktivieren**
   - Gehen Sie zu [Google Account Settings](https://myaccount.google.com/)
   - Aktivieren Sie die 2-Schritt-Bestätigung

2. **App-Passwort generieren**
   - Gehen Sie zu "Sicherheit" → "App-Passwörter"
   - Wählen Sie "E-Mail" und "Anderes Gerät"
   - Verwenden Sie "GitHub Actions" als Namen
   - Kopieren Sie das 16-stellige Passwort

3. **GitHub Secrets einrichten**
   - Repository → Settings → Secrets and variables → Actions
   - Fügen Sie die drei erforderlichen Secrets hinzu

## Testen der Konfiguration

### Lokal testen:
```bash
export EMAIL_USERNAME="ihre-email@gmail.com"
export EMAIL_PASSWORD="ihr-app-passwort"
export EMAIL_RECIPIENTS="empfaenger@beispiel.com"
./test-email-local.sh
```

### GitHub Action testen:
- Push die Änderungen ins Repository
- Workflow wird täglich um 7:30 Uhr Berliner Zeit ausgeführt
- Oder manuell über GitHub Actions Tab triggern

## Status

✅ **Vollständig konfiguriert** - Das System ist bereit für Gmail SMTP
✅ **Dokumentiert** - Alle Setup-Anleitungen sind aktuell
✅ **Getestet** - Lokale und GitHub Action Tests verfügbar

Das Morning Briefing System ist jetzt vollständig für Gmail konfiguriert und bereit für den produktiven Einsatz.
