#!/bin/bash

# Local test script for GitHub Action workflow
# This script mimics the GitHub Action environment for local testing

set -e

echo "🚀 Starting local Morning Briefing render test..."

# Check if running in correct directory
if [ ! -f "morning_briefing.qmd" ]; then
    echo "❌ Error: Please run this script from the morning_briefing directory"
    exit 1
fi

# Install system dependencies (Ubuntu/Debian)
echo "📦 Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    fontconfig

# Install fonts
echo "🎨 Installing BundesSans Web fonts..."
sudo mkdir -p /usr/share/fonts/truetype/bundesweb
sudo cp fonts/*.ttf /usr/share/fonts/truetype/bundesweb/
sudo fc-cache -fv

# Verify fonts
echo "🔍 Verifying font installation..."
fc-list | grep -i bundes || echo "BundesSans fonts installed successfully"

# Install Quarto if not present
if ! command -v quarto &> /dev/null; then
    echo "📚 Installing Quarto..."
    curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb
    sudo dpkg -i quarto-linux-amd64.deb
    rm quarto-linux-amd64.deb
fi

# Install Typst if not present
if ! command -v typst &> /dev/null; then
    echo "📝 Installing Typst..."
    curl -fsSL https://typst.community/typst-install/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install R dependencies
echo "📊 Installing R dependencies..."
R -e "if (!require('renv')) install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"
R -e "renv::restore()"

# Render the document
echo "🔄 Rendering Morning Briefing..."
export QUARTO_DENO_DOM_LOG_LEVEL=WARNING
quarto render morning_briefing.qmd --to typst-pdf

# Check if PDF was generated
if [ -f "morning_briefing.pdf" ]; then
    echo "✅ Success! Morning Briefing PDF generated successfully"
    echo "📄 File location: $(pwd)/morning_briefing.pdf"
    echo "📏 File size: $(du -h morning_briefing.pdf | cut -f1)"
else
    echo "❌ Error: PDF generation failed"
    exit 1
fi

echo "🎉 Local test completed successfully!"
