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

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}${BOLD}ERROR: .env file not found. Please run configure-node.sh first to set up your configuration.${RESET}"
    exit 1
fi

echo -e "\n${CYAN}${BOLD}---- LOADING ENVIRONMENT CONFIGURATION ----${RESET}\n"
echo -e "${GREEN}${BOLD}Loading configuration from .env file...${RESET}"
source .env

# Verify required environment variables are set
required_vars=("P2P_IP" "ETHEREUM_HOSTS" "L1_CONSENSUS_HOST_URLS" "VALIDATOR_PRIVATE_KEY" "COINBASE")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo -e "${RED}${BOLD}ERROR: Missing required environment variables: ${missing_vars[*]}${RESET}"
    echo -e "${LIGHTBLUE}${BOLD}Please run configure-node.sh to set up your configuration.${RESET}"
    exit 1
fi

echo -e "${GREEN}${BOLD}All required environment variables found.${RESET}"

# Display current configuration (with masked private key)
echo -e "\n${CYAN}${BOLD}---- CURRENT CONFIGURATION ----${RESET}\n"
echo -e "${LIGHTBLUE}${BOLD}Network Configuration:${RESET}"
echo -e "${LIGHTBLUE}  • ETHEREUM_HOSTS: ${ETHEREUM_HOSTS}${RESET}"
echo -e "${LIGHTBLUE}  • L1_CONSENSUS_HOST_URLS: ${L1_CONSENSUS_HOST_URLS}${RESET}"
echo -e "${LIGHTBLUE}  • P2P_IP: ${P2P_IP}${RESET}"

echo -e "\n${LIGHTBLUE}${BOLD}Validator Configuration:${RESET}"
echo -e "${LIGHTBLUE}  • COINBASE: ${COINBASE}${RESET}"
echo -e "${LIGHTBLUE}  • VALIDATOR_PRIVATE_KEY: ...${VALIDATOR_PRIVATE_KEY: -10}${RESET}"

echo -e "\n${CYAN}${BOLD}---- CLEANING UP EXISTING INSTANCES ----${RESET}\n"

# Check if there are any existing instances running
existing_containers=$(docker ps -q --filter "name=aztec" 2>/dev/null || true)
existing_screen=$(screen -list 2>/dev/null | grep "\.aztec" || true)
port_in_use=$(netstat -tuln 2>/dev/null | grep ":8080 " || true)

if [ -n "$existing_containers" ] || [ -n "$existing_screen" ] || [ -n "$port_in_use" ]; then
    echo -e "${LIGHTBLUE}${BOLD}Found existing Aztec instances. Do you want to stop them and start fresh? (y/N): ${RESET}"
    read -p "" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${LIGHTBLUE}${BOLD}Stopping existing instances...${RESET}"
        # Check if stop-node.sh exists, if not use inline cleanup
        if [ -f "./stop-node.sh" ]; then
            ./stop-node.sh
        else
            # Fallback inline cleanup
            [ -n "$existing_screen" ] && screen -S aztec -X quit 2>/dev/null
            [ -n "$existing_containers" ] && docker stop $(docker ps -q --filter "name=aztec") && docker rm $(docker ps -aq --filter "name=aztec")
            [ -n "$port_in_use" ] && sudo fuser -k 8080/tcp
        fi
        echo -e "${GREEN}${BOLD}Cleanup completed. Proceeding with startup.${RESET}"
    else
        echo -e "${PURPLE}${BOLD}Keeping existing instances. You can attach to the screen session with: screen -r aztec${RESET}"
        echo -e "${LIGHTBLUE}${BOLD}If you want to start fresh later, run: ./stop-node.sh${RESET}\n"
        exit 0
    fi
else
    echo -e "${GREEN}${BOLD}No existing instances found. Proceeding with startup.${RESET}"
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
  --p2p.p2pIp "$P2P_IP" \
  --p2p.maxTxPoolSize 1000000000
EOL

chmod +x $HOME/start_aztec_node.sh
screen -dmS aztec $HOME/start_aztec_node.sh

echo -e "${GREEN}${BOLD}Aztec node started successfully in a screen session.${RESET}\n" 
