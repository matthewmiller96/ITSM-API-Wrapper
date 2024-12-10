#!/bin/bash

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Setting up FedEx API environment..."

# Function to validate input
validate_input() {
    if [ -z "$1" ]; then
        echo "${RED}Error: Input cannot be empty${NC}"
        return 1
    fi
    return 0
}

# Check Python installation
if ! command -v python3 &> /dev/null; then
    echo "${RED}Python 3 is not installed. Please install Python 3 first.${NC}"
    exit 1
fi

# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Create config directories
echo "⚙️ Setting up configuration..."
mkdir -p config/fedex

# Prompt for credentials
echo "🔐 Enter FedEx API credentials:"

# Get client ID
while true; do
    read -p "Enter FedEx client ID: " client_id
    if validate_input "$client_id"; then break; fi
done

# Get client secret
while true; do
    read -s -p "Enter FedEx client secret: " client_secret
    echo
    if validate_input "$client_secret"; then break; fi
done

# Get account number
while true; do
    read -p "Enter FedEx account number: " account_number
    if validate_input "$account_number"; then break; fi
done

# Create .env file
echo "Creating environment file..."
cat > config/fedex/.env << EOF
# FedEx API Configuration
client_id=${client_id}
client_secret=${client_secret}
base_url=https://apis-sandbox.fedex.com
account_number=${account_number}

# Flask Configuration
FLASK_APP=main.py
FLASK_ENV=development
FLASK_DEBUG=True
EOF

# Set permissions
chmod 600 config/fedex/.env

echo "🎉 ${GREEN}Setup complete!${NC}"