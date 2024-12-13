#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
confirm_step() {
    read -p "🤔 Do you want to $1? (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

generate_jwt_secret() {
    python3 -c 'import secrets; print(secrets.token_urlsafe(32))'
}

# Welcome message
echo "🚀 Starting setup..."

# Virtual environment setup
if confirm_step "create a virtual environment"; then
    echo "🔨 Creating virtual environment..."
    python3 -m venv .venv
    
    # Activate virtual environment
    if [[ "$OSTYPE" == "msys" ]]; then
        source .venv/Scripts/activate
    else
        source .venv/bin/activate
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Virtual environment created and activated"
        
        if [ -f "requirements.txt" ]; then
            echo "📚 Installing dependencies..."
            pip install -r requirements.txt
        fi
    fi
fi

# FedEx configuration setup
if confirm_step "set up FedEx configuration"; then
    echo "⚙️ Setting up configuration..."
    mkdir -p config/fedex
    
    echo "🔐 Enter FedEx API credentials:"
    read -p "API Key: " api_key
    read -p "API Secret: " api_secret
    read -p "Account Number: " account_number
    read -p "Base URL: " base_url
    
    # Create FedEx config file
    cat > config/fedex/.env << EOF
# FedEx API Configuration
FEDEX_API_KEY=$api_key
FEDEX_API_SECRET=$api_secret
FEDEX_ACCOUNT_NUMBER=$account_number
FEDEX_BASE_URL=$base_url

# Flask Configuration
FLASK_APP=main.py
FLASK_ENV=development
FLASK_DEBUG=True
EOF
fi

# JWT configuration setup
if confirm_step "set up JWT configuration"; then
    echo "⚙️ Setting up JWT configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p config/fedex
    
    # Check if JWT_SECRET_KEY already exists in .env
    if grep -q "JWT_SECRET_KEY" config/fedex/.env 2>/dev/null; then
        echo "ℹ️  JWT_SECRET_KEY already exists in .env"
    else
        echo "🔑 Generating new JWT secret key..."
        # Add error handling for JWT secret generation
        JWT_SECRET=$(generate_jwt_secret) || {
            echo "${RED}Failed to generate JWT secret${NC}"
            exit 1
        }
        
        # Verify secret was generated
        if [ -z "$JWT_SECRET" ]; then
            echo "${RED}JWT secret generation failed${NC}"
            exit 1
        fi
        
        # Append to .env with error checking
        echo "JWT_SECRET_KEY=$JWT_SECRET" >> config/fedex/.env || {
            echo "${RED}Failed to write to .env file${NC}"
            exit 1
        }
        echo "✅ JWT secret key added to .env"
    fi
fi

# Set secure permissions for config files
if [[ "$OSTYPE" == "msys" ]]; then
    icacls config\\fedex\\.env /inheritance:r /grant:r "$USERNAME:F"
else
    chmod 600 config/fedex/.env
fi

# Summary
echo "🎉 ${GREEN}Setup complete!${NC}"
echo "Configuration:"
echo "- Virtual environment: ${YELLOW}.venv${NC}"
echo "- Config location: ${YELLOW}config/fedex/.env${NC}"
echo "- API endpoint: ${YELLOW}${base_url}${NC}"
echo "- JWT secret: ${YELLOW}Configured in .env${NC}"