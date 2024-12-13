#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
confirm_step() {
    read -r -p "🤔 Do you want to proceed with $1? (y/N) " REPLY
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

create_config_dirs() {
    echo "Creating config directories..."
    mkdir -p config/fedex || {
        echo "${RED}Failed to create config directories${NC}"
        exit 1
    }
    # Verify directory exists
    if [ ! -d "config/fedex" ]; then
        echo "${RED}Failed to verify config directory${NC}"
        exit 1
    }
}

generate_jwt_secret() {
    python3 -c 'import secrets; print(secrets.token_urlsafe(32))'
}

# Welcome message
echo "🚀 Starting setup..."

# Create config directories first
create_config_dirs

# Virtual environment setup
if confirm_step "create a virtual environment"; then
    echo "🔨 Creating virtual environment..."
    python3 -m venv .venv || {
        echo "${RED}Failed to create virtual environment${NC}"
        exit 1
    }
    
    # Activate virtual environment
    if [[ "$OSTYPE" == "msys" ]]; then
        venv_activate=".venv/Scripts/activate"
    else
        venv_activate=".venv/bin/activate"
    fi
    source $venv_activate
    
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
    # Function to load existing values
    load_existing_value() {
        local key=$1
        sed -n "s/^${key}=//p" config/fedex/.env 2>/dev/null
    }

    # Load existing values if the file exists
    if [ -f "config/fedex/.env" ]; then
        echo "🔍 Found existing configuration. Loading current values..."
        fedex_client_id=$(load_existing_value "FEDEX_CLIENT_ID")
        fedex_client_secret=$(load_existing_value "FEDEX_CLIENT_SECRET")
        fedex_account_number=$(load_existing_value "FEDEX_ACCOUNT_NUMBER")
        fedex_base_url=$(load_existing_value "FEDEX_BASE_URL")
    fi

    # Prompt for each value, allowing updates
    read -r -p "client_id [${fedex_client_id:-none}]: " new_client_id
    read -r -p "client_secret [${fedex_client_secret:-none}]: " new_client_secret
    read -r -p "account_number [${fedex_account_number:-none}]: " new_account_number
    read -r -p "base_url [${fedex_base_url:-none}]: " new_base_url

    # Use existing values if no input is provided
    fedex_client_id=${new_client_id:-$fedex_client_id}
    fedex_client_secret=${new_client_secret:-$fedex_client_secret}
    fedex_account_number=${new_account_number:-$fedex_account_number}
    fedex_base_url=${new_base_url:-$fedex_base_url}

    # Create or update FedEx config file
    cat > config/fedex/.env << EOF
# FedEx API Configuration
FEDEX_CLIENT_ID=$fedex_client_id
FEDEX_CLIENT_SECRET=$fedex_client_secret
FEDEX_ACCOUNT_NUMBER=$fedex_account_number
FEDEX_BASE_URL=$fedex_base_url

# Flask Configuration
FLASK_APP=main.py
FLASK_ENV=development
FLASK_DEBUG=True
EOF

    echo "✅ FedEx configuration updated"
fi
    if grep -q "JWT_SECRET_KEY" config/fedex/.env 2>/dev/null; then
        echo "ℹ️  JWT_SECRET_KEY already exists in .env"
    else
        echo "🔑 Generating new JWT secret key..."
        JWT_SECRET=$(generate_jwt_secret)
        
        if [ $? -ne 0 ] || [ -z "$JWT_SECRET" ]; then
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
# Single JWT configuration setup
if confirm_step "set up JWT configuration"; then
    echo "⚙️ Setting up JWT configuration..."
    
    # Check if JWT_SECRET_KEY already exists in .env
    if grep -q "JWT_SECRET_KEY" config/fedex/.env 2>/dev/null; then
        echo "ℹ️  JWT_SECRET_KEY already exists in .env"
    else
        echo "🔑 Generating new JWT secret key..."
        JWT_SECRET=$(generate_jwt_secret)
        
        if [ $? -ne 0 ] || [ -z "$JWT_SECRET" ]; then
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

# Flask app user configuration setup
if confirm_step "set up Flask app user configuration"; then
    echo "🔐 Enter Flask app user credentials:"
    read -r -p "username: " flask_username
    read -r -p "password: " flask_password
    
    # Append to .env with error checking
    echo "USERNAME=$flask_username" >> config/fedex/.env
        if [ $? -ne 0 ]; then
            echo "${RED}Failed to write to .env file${NC}"
            exit 1
        fi
        if ! echo "PASSWORD=$flask_password" >> config/fedex/.env; then
            echo "${RED}Failed to write to .env file${NC}"
            exit 1
        fi
    fi
# Set secure permissions for config files
if [[ "$OSTYPE" == "msys" ]]; then
    icacls config\\\\fedex\\\\.env /inheritance:r /grant:r "$USERNAME:F"
else
    chmod 600 config/fedex/.env
fi

# Summary section
echo -e "🎉 ${GREEN}Setup complete!${NC}"
echo "----------------------------------------"
echo "Configuration Summary:"
echo "----------------------------------------"
echo -e "- Virtual environment: ${YELLOW}.venv${NC}"
echo -e "- Config location: ${YELLOW}config/fedex/.env${NC}"
if [ -n "$fedex_base_url" ]; then
    echo -e "- API endpoint: ${YELLOW}${fedex_base_url}${NC}"
else
    echo -e "- API endpoint: ${YELLOW}Not configured${NC}"
fi
echo -e "- JWT secret: ${YELLOW}Configured in .env${NC}"