#!/bin/bash

# Local email test script for Morning Briefing
# This script tests email sending functionality locally

set -e

echo "📧 Testing Morning Briefing Email Functionality..."

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    echo "📁 Loading environment variables from .env file..."
    export $(cat .env | grep -v '#' | grep -v '^$' | xargs)
fi

# Check if required environment variables are set
if [ -z "$EMAIL_USERNAME" ] || [ -z "$EMAIL_PASSWORD" ] || [ -z "$EMAIL_RECIPIENTS" ]; then
    echo "❌ Error: Email environment variables not set"
    echo ""
    echo "Please either:"
    echo "1. Set environment variables manually:"
    echo "   export EMAIL_USERNAME='your-email@gmail.com'"
    echo "   export EMAIL_PASSWORD='your-app-password'"
    echo "   export EMAIL_RECIPIENTS='recipient1@example.com,recipient2@example.com'"
    echo ""
    echo "2. Or configure the .env file with your credentials"
    echo "   (See .env template in the project root)"
    echo ""
    echo "For Gmail setup instructions, see EMAIL_SETUP.md"
    exit 1
fi

# Check if Morning Briefing PDF exists
if [ ! -f "morning_briefing.pdf" ]; then
    echo "📄 Morning Briefing PDF not found. Generating..."
    ./test-local-render.sh
fi

# Install msmtp if not available (for local testing)
if ! command -v msmtp &> /dev/null; then
    echo "📦 Installing msmtp for email testing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update
        sudo apt-get install -y msmtp msmtp-mta
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install msmtp
    else
        echo "❌ Unsupported OS for automatic msmtp installation"
        echo "Please install msmtp manually and try again"
        exit 1
    fi
fi

# Create msmtp configuration
echo "⚙️ Creating msmtp configuration..."
cat > ~/.msmtprc << EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           ${EMAIL_USERNAME}
user           ${EMAIL_USERNAME}
password       ${EMAIL_PASSWORD}

account default : gmail
EOF

chmod 600 ~/.msmtprc

# Create email content
echo "✍️ Preparing email content..."
CURRENT_DATE=$(date '+%Y-%m-%d')
EMAIL_SUBJECT="📊 Morning Briefing Test - ${CURRENT_DATE}"

# Create HTML email
cat > email_body.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${EMAIL_SUBJECT}</title>
</head>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
    <h2 style="color: #1a365d;">📊 Daily Morning Briefing (Test)</h2>
    <p>Guten Morgen!</p>
    
    <p>Dies ist eine <strong>Test-E-Mail</strong> für das automatische Morning Briefing System.</p>
    
    <p>Hier ist Ihr tagesaktuelles Morning Briefing für den <strong>${CURRENT_DATE}</strong>.</p>
    
    <h3 style="color: #2d3748;">📈 Inhalt des heutigen Briefings:</h3>
    <ul>
        <li><strong>Globale Indikatoren</strong> - DAX, S&P 500, EUR/USD, Rohstoffe</li>
        <li><strong>Wirtschaftskalender</strong> - Wichtige Events heute</li>
        <li><strong>Top 5 Stories</strong> - Aktuelle Wirtschaftsnachrichten</li>
        <li><strong>Industrie News</strong> - Branchenspezifische Meldungen</li>
    </ul>
    
    <p>Das vollständige Morning Briefing finden Sie im Anhang als PDF.</p>
    
    <hr style="margin: 20px 0; border: none; border-top: 1px solid #e2e8f0;">
    <p><em style="color: #718096;">Diese E-Mail wurde automatisch generiert um 7:30 Uhr Berliner Zeit.</em></p>
    <p><em style="color: #718096;">Dies ist eine Test-E-Mail für die lokale Entwicklung.</em></p>
</body>
</html>
EOF

# Function to send email to each recipient
send_email() {
    local recipient=$1
    echo "📤 Sending test email to: ${recipient}"
    
    {
        echo "To: ${recipient}"
        echo "From: Morning Briefing Bot <${EMAIL_USERNAME}>"
        echo "Subject: ${EMAIL_SUBJECT}"
        echo "MIME-Version: 1.0"
        echo "Content-Type: multipart/mixed; boundary=boundary123"
        echo ""
        echo "--boundary123"
        echo "Content-Type: text/html; charset=UTF-8"
        echo ""
        cat email_body.html
        echo ""
        echo "--boundary123"
        echo "Content-Type: application/pdf; name=\"morning_briefing.pdf\""
        echo "Content-Disposition: attachment; filename=\"morning_briefing.pdf\""
        echo "Content-Transfer-Encoding: base64"
        echo ""
        base64 morning_briefing.pdf
        echo ""
        echo "--boundary123--"
    } | msmtp "${recipient}"
}

# Send email to each recipient
IFS=',' read -ra RECIPIENTS <<< "$EMAIL_RECIPIENTS"
for recipient in "${RECIPIENTS[@]}"; do
    # Trim whitespace
    recipient=$(echo "$recipient" | xargs)
    send_email "$recipient"
done

# Cleanup
rm -f email_body.html

echo "✅ Test email(s) sent successfully!"
echo "📋 Email details:"
echo "  From: ${EMAIL_USERNAME}"
echo "  To: ${EMAIL_RECIPIENTS}"
echo "  Subject: ${EMAIL_SUBJECT}"
echo "  Attachment: morning_briefing.pdf ($(du -h morning_briefing.pdf | cut -f1))"
echo ""
echo "📧 Please check the recipient inboxes (including spam folders)"
echo "🔍 Check msmtp logs: cat ~/.msmtp.log"
