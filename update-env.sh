#!/bin/bash

CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "\n${CYAN}${BOLD}---- UPDATING ENVIRONMENT CONFIGURATION ----${RESET}\n"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${PURPLE}${BOLD}No .env file found. Creating new configuration...${RESET}\n"
    
    # Auto-detect P2P_IP from AWS
    echo -e "${LIGHTBLUE}${BOLD}Auto-detecting your IP address from AWS...${RESET}"
    P2P_IP=$(curl -s --connect-timeout 5 http://checkip.amazonaws.com 2>/dev/null)
    if [ -n "$P2P_IP" ]; then
        echo -e "${GREEN}${BOLD}Detected IP: $P2P_IP${RESET}\n"
    else
        echo -e "${PURPLE}${BOLD}Could not auto-detect IP from AWS. You'll need to provide it manually.${RESET}\n"
    fi
    
    # Initialize empty variables for new configuration
    ETHEREUM_HOSTS=""
    L1_CONSENSUS_HOST_URLS=""
    VALIDATOR_PRIVATE_KEY=""
    COINBASE=""
    
    echo -e "${LIGHTBLUE}${BOLD}Setting up your initial Aztec node configuration...${RESET}\n"
else
    # Load existing .env file
    echo -e "${GREEN}${BOLD}Loading existing configuration from .env file...${RESET}"
    source .env
    
    # Create backup of existing .env
    cp .env .env.backup
    echo -e "${LIGHTBLUE}${BOLD}Backup created: .env.backup${RESET}\n"
    
    # Always update P2P_IP from AWS
    echo -e "${LIGHTBLUE}${BOLD}Updating P2P_IP from AWS...${RESET}"
    OLD_P2P_IP="$P2P_IP"
    NEW_P2P_IP=$(curl -s --connect-timeout 5 http://checkip.amazonaws.com 2>/dev/null)
    
    if [ -n "$NEW_P2P_IP" ]; then
        if [ "$OLD_P2P_IP" != "$NEW_P2P_IP" ]; then
            echo -e "${PURPLE}${BOLD}P2P_IP changed: $OLD_P2P_IP → $NEW_P2P_IP${RESET}"
        else
            echo -e "${GREEN}${BOLD}P2P_IP unchanged: $NEW_P2P_IP${RESET}"
        fi
        P2P_IP="$NEW_P2P_IP"
    else
        echo -e "${RED}${BOLD}Failed to fetch new P2P_IP from AWS, keeping existing: $OLD_P2P_IP${RESET}"
    fi
    echo
fi



# Function to update environment variable
update_env_var() {
    local var_name=$1
    local prompt_text=$2
    local info_text=$3
    local current_value="${!var_name}"
    
    if [ -n "$info_text" ]; then
        echo -e "${LIGHTBLUE}${BOLD}$info_text${RESET}"
    fi
    
    if [ -n "$current_value" ]; then
        echo -e "${GREEN}Current value: ${current_value}${RESET}"
        read -p "$prompt_text (press Enter to keep current): " new_value
    else
        echo -e "${PURPLE}No current value set${RESET}"
        read -p "$prompt_text" new_value
    fi
    
    # If user provided a new value, update it
    if [ -n "$new_value" ]; then
        export $var_name="$new_value"
        echo -e "${GREEN}${BOLD}✓ Updated $var_name${RESET}\n"
        return 0
    else
        # Keep existing value or warn if no value for required field
        if [ -n "$current_value" ]; then
            echo -e "${LIGHTBLUE}${BOLD}✓ Keeping existing $var_name${RESET}\n"
            return 1
        else
            echo -e "${PURPLE}${BOLD}⚠ No value provided for $var_name (will be empty)${RESET}\n"
            return 1
        fi
    fi
}

echo -e "${CYAN}${BOLD}---- UPDATING CONFIGURATION VALUES ----${RESET}\n"
echo -e "${LIGHTBLUE}${BOLD}For each setting, provide a new value to update it, or press Enter to keep the current value.${RESET}\n"

# Track which variables were updated
updated_vars=()

# P2P_IP is automatically updated from AWS, add it to updated vars if it was changed
if [ -n "$NEW_P2P_IP" ] && [ "$OLD_P2P_IP" != "$NEW_P2P_IP" ]; then
    updated_vars+=("P2P_IP")
fi

# Update ETHEREUM_HOSTS
echo -e "${CYAN}${BOLD}1. Ethereum RPC URL${RESET}"
if update_env_var "ETHEREUM_HOSTS" "Enter Your Sepolia Ethereum RPC URL: " "Visit ${PURPLE}https://dashboard.alchemy.com/apps${RESET}${LIGHTBLUE}${BOLD} or ${PURPLE}https://developer.metamask.io/register${RESET}${LIGHTBLUE}${BOLD} to get a Sepolia RPC URL."; then
    updated_vars+=("ETHEREUM_HOSTS")
fi

# Update L1_CONSENSUS_HOST_URLS
echo -e "${CYAN}${BOLD}2. Consensus/Beacon URL${RESET}"
if update_env_var "L1_CONSENSUS_HOST_URLS" "Enter Your Sepolia Ethereum BEACON URL: " "Visit ${PURPLE}https://chainstack.com/global-nodes${RESET}${LIGHTBLUE}${BOLD} to get beacon RPC URL."; then
    updated_vars+=("L1_CONSENSUS_HOST_URLS")
fi

# Update VALIDATOR_PRIVATE_KEY
echo -e "${CYAN}${BOLD}3. Validator Private Key${RESET}"
if update_env_var "VALIDATOR_PRIVATE_KEY" "Enter your EVM wallet private key (with 0x prefix): " "Please ensure this is a secure wallet funded with Sepolia ETH."; then
    updated_vars+=("VALIDATOR_PRIVATE_KEY")
fi

# Update COINBASE
echo -e "${CYAN}${BOLD}4. Coinbase Address${RESET}"
if update_env_var "COINBASE" "Enter the wallet address associated with the private key: " ""; then
    updated_vars+=("COINBASE")
fi

# Write updated configuration to .env file
echo -e "${CYAN}${BOLD}---- SAVING CONFIGURATION ----${RESET}\n"

cat > .env << EOL
# Aztec Node Configuration
# Updated: $(date)

# Your VPS/WSL IP address
export P2P_IP="$P2P_IP"

# Sepolia Ethereum RPC URL
export ETHEREUM_HOSTS="$ETHEREUM_HOSTS"

# Sepolia Ethereum Beacon URL
export L1_CONSENSUS_HOST_URLS="$L1_CONSENSUS_HOST_URLS"

# Your EVM wallet private key (with 0x prefix)
export VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"

# The wallet address associated with the private key
export COINBASE="$COINBASE"

# Blob sink archive API URL (hardcoded)
export BLOB_SINK_ARCHIVE_API_URL="https://api.blobscan.com"
EOL

# Set secure permissions
chmod 600 .env

# Summary
echo -e "${GREEN}${BOLD}Configuration update completed!${RESET}"

if [ ${#updated_vars[@]} -gt 0 ]; then
    echo -e "${LIGHTBLUE}${BOLD}Updated variables: ${updated_vars[*]}${RESET}"
else
    echo -e "${LIGHTBLUE}${BOLD}No variables were updated (all existing values kept).${RESET}"
fi

echo -e "${GREEN}${BOLD}Configuration saved to .env file with secure permissions (600).${RESET}"

# Only show backup message if backup was created
if [ -f ".env.backup" ]; then
    echo -e "${LIGHTBLUE}${BOLD}Backup of previous configuration saved as .env.backup${RESET}"
fi

echo -e "${LIGHTBLUE}${BOLD}To start the node with updated configuration, run: ./start-node.sh${RESET}"
echo 
