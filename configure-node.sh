#!/bin/bash

CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
BOLD='\033[1m'
RESET='\033[0m'

# Ensure Aztec is in PATH
export PATH="$PATH:$HOME/.aztec/bin"

# Check if Aztec is available
if ! command -v aztec &> /dev/null; then
  echo -e "${RED}${BOLD}ERROR: Aztec CLI not found. Please run setup.sh first.${RESET}"
  exit 1
fi

echo -e "\n${CYAN}${BOLD}---- LOADING ENVIRONMENT CONFIGURATION ----${RESET}\n"

# Load existing .env file if it exists
if [ -f ".env" ]; then
    echo -e "${GREEN}${BOLD}Found existing .env file. Loading configuration...${RESET}"
    source .env
else
    echo -e "${LIGHTBLUE}${BOLD}No .env file found. Will create one with your configuration.${RESET}"
fi

# Function to prompt for missing environment variables
prompt_if_missing() {
    local var_name=$1
    local prompt_text=$2
    local info_text=$3
    
    if [ -z "${!var_name}" ]; then
        if [ -n "$info_text" ]; then
            echo -e "${LIGHTBLUE}${BOLD}$info_text${RESET}"
        fi
        read -p "$prompt_text" value
        export $var_name="$value"
        echo "export $var_name=\"$value\"" >> .env
    else
        echo -e "${GREEN}${BOLD}Using existing $var_name${RESET}"
    fi
}

echo -e "\n${CYAN}${BOLD}---- CONFIGURING NODE ----${RESET}\n"

# Get IP address if not set
if [ -z "$P2P_IP" ]; then
    IP=$(curl -s https://api.ipify.org)
    if [ -z "$IP" ]; then
        IP=$(curl -s http://checkip.amazonaws.com)
    fi
    if [ -z "$IP" ]; then
        IP=$(curl -s https://ifconfig.me)
    fi
    if [ -z "$IP" ]; then
        echo -e "${LIGHTBLUE}${BOLD}Could not determine IP address automatically.${RESET}"
        read -p "Please enter your VPS/WSL IP address: " IP
    fi
    export P2P_IP="$IP"
    echo "export P2P_IP=\"$IP\"" >> .env
else
    echo -e "${GREEN}${BOLD}Using existing P2P_IP: $P2P_IP${RESET}"
    IP="$P2P_IP"
fi

# Prompt for missing environment variables
prompt_if_missing "ETHEREUM_HOSTS" "Enter Your Sepolia Ethereum RPC URL: " "Visit ${PURPLE}https://dashboard.alchemy.com/apps${RESET}${LIGHTBLUE}${BOLD} or ${PURPLE}https://developer.metamask.io/register${RESET}${LIGHTBLUE}${BOLD} to create an account and get a Sepolia RPC URL."

prompt_if_missing "L1_CONSENSUS_HOST_URLS" "Enter Your Sepolia Ethereum BEACON URL: " "Visit ${PURPLE}https://chainstack.com/global-nodes${RESET}${LIGHTBLUE}${BOLD} to create an account and get beacon RPC URL."

prompt_if_missing "VALIDATOR_PRIVATE_KEY" "Enter your new evm wallet private key (with 0x prefix): " "Please create a new EVM wallet, fund it with Sepolia Faucet and then provide the private key."

prompt_if_missing "COINBASE" "Enter the wallet address associated with the private key you just provided: " ""

# Set secure permissions on .env file (readable/writable by owner only)
if [ -f ".env" ]; then
    chmod 600 .env
    echo -e "\n${GREEN}${BOLD}Configuration saved to .env file with secure permissions (600).${RESET}"
else
    echo -e "\n${GREEN}${BOLD}Configuration completed.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}---- CHECKING PORT AVAILABILITY ----${RESET}\n"
if netstat -tuln | grep -q ":8080 "; then
    echo -e "${LIGHTBLUE}${BOLD}Port 8080 is in use. Attempting to free it...${RESET}"
    sudo fuser -k 8080/tcp
    sleep 2
    echo -e "${GREEN}${BOLD}Port 8080 has been freed successfully.${RESET}"
else
    echo -e "${GREEN}${BOLD}Port 8080 is already free and available.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}---- CHECKING EXISTING SCREEN SESSIONS ----${RESET}\n"

# Check if screen session 'aztec' already exists
if screen -list | grep -q "\.aztec"; then
    echo -e "${LIGHTBLUE}${BOLD}Found existing 'aztec' screen session.${RESET}"
    read -p "Do you want to stop the existing session and start a new one? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${LIGHTBLUE}${BOLD}Stopping existing 'aztec' screen session...${RESET}"
        screen -S aztec -X quit
        sleep 2
        echo -e "${GREEN}${BOLD}Existing session stopped.${RESET}"
    else
        echo -e "${PURPLE}${BOLD}Keeping existing session. You can attach to it with: screen -r aztec${RESET}"
        echo -e "${LIGHTBLUE}${BOLD}If you want to start a new session later, first stop the existing one with: screen -S aztec -X quit${RESET}\n"
        exit 0
    fi
fi

echo -e "\n${CYAN}${BOLD}---- STARTING AZTEC NODE ----${RESET}\n"
cat > $HOME/start_aztec_node.sh << EOL
#!/bin/bash
export PATH=\$PATH:\$HOME/.aztec/bin
aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --port 8080 \
  --l1-rpc-urls "$ETHEREUM_HOSTS" \
  --l1-consensus-host-urls "$L1_CONSENSUS_HOST_URLS" \
  --sequencer.validatorPrivateKey "$VALIDATOR_PRIVATE_KEY" \
  --sequencer.coinbase "$COINBASE" \
  --p2p.p2pIp "$IP" \
  --p2p.maxTxPoolSize 1000000000
EOL

chmod +x $HOME/start_aztec_node.sh
screen -dmS aztec $HOME/start_aztec_node.sh

echo -e "${GREEN}${BOLD}Aztec node started successfully in a screen session.${RESET}\n"
echo -e "${LIGHTBLUE}${BOLD}To view the node logs, run: screen -r aztec${RESET}"
echo -e "${LIGHTBLUE}${BOLD}To detach from the screen session, press: Ctrl+A then D${RESET}"
echo -e "${LIGHTBLUE}${BOLD}To stop the node, run: screen -S aztec -X quit${RESET}\n" 
