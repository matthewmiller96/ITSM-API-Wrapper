#!/bin/bash
#
# FedEx API Environment Setup Script
# Usage: ./setup.sh
# Requirements: Python 3.8+, pip

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# FedEx URLs
SANDBOX_URL="https://apis-sandbox.fedex.com"
PROD_URL="https://apis.fedex.com"

echo "🚀 Setting up FedEx API environment..."

# Function to validate input
validate_input() {
    if [ -z "$1" ]; then
        echo "${RED}Error: Input cannot be empty${NC}"
        return 1
    fi
    return 0
}

# Function to confirm action
confirm_step() {
    read -p "Do you want to $1? (y/n): " choice
    case "$choice" in
        y|Y ) return 0 ;;
        * ) return 1 ;;
    esac
}

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "${RED}Error: Python 3 is required${NC}"
    exit 1
fi

# Check requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    echo "${RED}Error: requirements.txt not found${NC}"
    exit 1
fi

# Virtual environment setup
if confirm_step "create a virtual environment"; then
    echo "📦 Creating virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
fi

# Dependencies installation
if confirm_step "install dependencies"; then
    echo "📚 Installing dependencies..."
    pip install -r requirements.txt
fi

# Configuration setup
if confirm_step "set up FedEx configuration"; then
    echo "⚙️ Setting up configuration..."
    mkdir -p config/fedex
    
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

    # Select environment
    while true; do
        echo "Select FedEx environment:"
        echo "1) Sandbox (Testing)"
        echo "2) Production (Live)"
        read -p "Enter choice (1/2): " env_choice
        case $env_choice in
            1)
                base_url=$SANDBOX_URL
                echo "${GREEN}Using Sandbox environment${NC}"
                break
                ;;
            2)
                base_url=$PROD_URL
                echo "${RED}⚠️  Warning: Using Production environment${NC}"
                read -p "Are you sure? (y/N): " confirm
                if [[ $confirm =~ ^[Yy]$ ]]; then break; fi
                ;;
            *)
                echo "${RED}Invalid choice. Please enter 1 or 2${NC}"
                ;;
        esac
    done

    # Create .env file
    cat > config/fedex/.env << EOF
# FedEx API Configuration
client_id=${client_id}
client_secret=${client_secret}
base_url=${base_url}
account_number=${account_number}

# Flask Configuration
FLASK_APP=main.py
FLASK_ENV=development
FLASK_DEBUG=True
EOF

    chmod 600 config/fedex/.env
    echo "${GREEN}Configuration created successfully${NC}"
fi

# Summary
echo "🎉 ${GREEN}Setup complete!${NC}"
echo "Configuration:"
echo "- Virtual environment: ${YELLOW}.venv${NC}"
echo "- Config location: ${YELLOW}config/fedex/.env${NC}"
echo "- API endpoint: ${YELLOW}${base_url}${NC}"