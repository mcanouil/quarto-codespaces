# E-Mail Konfiguration für Morning Briefing

## Automatischer E-Mail-Versand

Das Morning Briefing wird täglich um 7:30 Uhr Berliner Zeit automatisch per E-Mail versendet.

## Lokale Entwicklung

### Option 1: .env Datei (Empfohlen)
Für die lokale Entwicklung können Sie eine `.env` Datei verwenden:

1. **Automatisches Setup:**
   ```bash
   ./setup-env.sh
   ```

2. **Manuelles Setup:**
   - Kopieren Sie die `.env` Vorlage und tragen Sie Ihre Daten ein
   - Die `.env` Datei wird automatisch von den Test-Skripten geladen
   - **Wichtig:** Die `.env` Datei wird nicht committet (siehe `.gitignore`)

### Option 2: Umgebungsvariablen
```bash
export EMAIL_USERNAME="ihre-email@gmail.com"
export EMAIL_PASSWORD="ihr-app-passwort"
export EMAIL_RECIPIENTS="empfaenger@beispiel.com"
```

## Repository Secrets Setup

Für den E-Mail-Versand müssen folgende Secrets in den GitHub Repository Settings konfiguriert werden:

### Erforderliche Secrets

1. **`EMAIL_USERNAME`** - Die E-Mail-Adresse des Absenders
   ```
   beispiel@gmail.com
   ```

2. **`EMAIL_PASSWORD`** - Das App-Passwort für den Gmail Account
   ```
   Für Gmail: Generieren Sie ein App-Passwort in den Google Account Settings
   ```

3. **`EMAIL_RECIPIENTS`** - E-Mail-Adressen der Empfänger (kommagetrennt)
   ```
   empfaenger1@beispiel.com,empfaenger2@beispiel.com
   ```

## Gmail Setup (Konfiguriert)

### Schritt 1: 2-Faktor-Authentifizierung aktivieren
1. Gehen Sie zu [Google Account Settings](https://myaccount.google.com/)
2. Wählen Sie "Sicherheit" → "2-Schritt-Bestätigung"
3. Aktivieren Sie die 2-Faktor-Authentifizierung

### Schritt 2: App-Passwort generieren
1. Gehen Sie zu "Sicherheit" → "App-Passwörter"
2. Wählen Sie "E-Mail" und "Anderes Gerät"
3. Geben Sie "GitHub Actions" als Namen ein
4. Kopieren Sie das generierte 16-stellige Passwort

### Schritt 3: GitHub Secrets konfigurieren
1. Gehen Sie zu Ihrem GitHub Repository
2. Klicken Sie auf "Settings" → "Secrets and variables" → "Actions"
3. Fügen Sie die drei Secrets hinzu:
   - `EMAIL_USERNAME`: Ihre Gmail-Adresse
   - `EMAIL_PASSWORD`: Das App-Passwort (16 Stellen)
   - `EMAIL_RECIPIENTS`: Empfänger-E-Mail-Adressen

## Alternative E-Mail-Provider

### Yahoo Mail
```yaml
server_address: smtp.mail.yahoo.com
server_port: 587
```

### Outlook/Hotmail
```yaml
server_address: smtp-mail.outlook.com
server_port: 587
```

### Custom SMTP
```yaml
server_address: your-smtp-server.com
server_port: 587  # oder 465 für SSL
```

## E-Mail-Inhalt

Die E-Mail enthält:

- **Betreff**: "📊 Morning Briefing - [Datum]"
- **PDF-Anhang** mit dem vollständigen Morning Briefing
- **Automatische Zeitstempel**

## Troubleshooting

### E-Mail wird nicht versendet
1. Überprüfen Sie die Repository Secrets
2. Stellen Sie sicher, dass 2FA und App-Passwort korrekt eingerichtet sind
3. Prüfen Sie die GitHub Actions Logs für Fehlermeldungen

### Yahoo Mail-spezifische Probleme
- Verwenden Sie das App-Passwort, nicht Ihr normales Passwort
- Stellen Sie sicher, dass die 2-Faktor-Authentifizierung aktiviert ist
- Prüfen Sie, dass "Less secure app access" deaktiviert ist (App-Passwort verwenden)
- Prüfen Sie Spam-Ordner der Empfänger

### Empfänger erhalten keine E-Mails
- Überprüfen Sie die `EMAIL_RECIPIENTS` Formatierung
- Stellen Sie sicher, dass keine Leerzeichen in der Liste sind
- Prüfen Sie Spam-Filter der Empfänger

## Erweiterte Konfiguration

### Mehrere Empfänger-Gruppen
Sie können verschiedene E-Mail-Listen für verschiedene Anlässe erstellen:

```yaml
# Tägliche Empfänger
to: ${{ secrets.EMAIL_RECIPIENTS_DAILY }}

# Wöchentliche Zusammenfassung
to: ${{ secrets.EMAIL_RECIPIENTS_WEEKLY }}
```

### Custom E-Mail-Template
Bearbeiten Sie den `html_body` Abschnitt in der Workflow-Datei für individuelle E-Mail-Templates.

### Bedingte E-Mail-Versendung
```yaml
# Nur an Werktagen senden
if: ${{ github.event.schedule == '30 5 * * 1-5' }}
```

## Sicherheitshinweise

- **Niemals** echte Passwörter in der Workflow-Datei speichern
- Verwenden Sie immer App-Passwörter für Gmail
- Überprüfen Sie regelmäßig die Repository-Zugriffe
- Rotieren Sie App-Passwörter bei Bedarf

## Support

Bei Problemen mit der E-Mail-Konfiguration:
1. Prüfen Sie die GitHub Actions Logs
2. Testen Sie die SMTP-Einstellungen lokal
3. Kontaktieren Sie den Repository-Administrator
