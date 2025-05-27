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

# Verify required environment variables are set for validator registration
required_vars=("ETHEREUM_HOSTS" "VALIDATOR_PRIVATE_KEY" "COINBASE")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo -e "${RED}${BOLD}ERROR: Missing required environment variables for validator registration: ${missing_vars[*]}${RESET}"
    echo -e "${LIGHTBLUE}${BOLD}Please run configure-node.sh to set up your configuration.${RESET}"
    exit 1
fi

echo -e "${GREEN}${BOLD}All required environment variables found.${RESET}"

echo -e "\n${CYAN}${BOLD}---- VALIDATOR REGISTRATION ----${RESET}\n"

# Display configuration that will be used
echo -e "${LIGHTBLUE}${BOLD}Registration Configuration:${RESET}"
echo -e "${LIGHTBLUE}  • Ethereum RPC: ${ETHEREUM_HOSTS}${RESET}"
echo -e "${LIGHTBLUE}  • Validator Address: ${COINBASE}${RESET}"
echo -e "${LIGHTBLUE}  • Private Key: ...${VALIDATOR_PRIVATE_KEY: -10}${RESET}"

echo -e "\n${PURPLE}${BOLD}WARNING: You may see an error like 'ValidatorQuotaFilledUntil' when trying to register as a validator,${RESET}"
echo -e "${PURPLE}${BOLD}which means the daily quota has been reached. Convert the provided Unix timestamp to local time${RESET}"
echo -e "${PURPLE}${BOLD}to know when you can try again to register as Validator.${RESET}\n"

echo -e "${LIGHTBLUE}${BOLD}Do you want to proceed with validator registration? (y/N): ${RESET}"
read -p "" -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${PURPLE}${BOLD}Registration cancelled.${RESET}"
    exit 0
fi

echo -e "\n${CYAN}${BOLD}---- EXECUTING VALIDATOR REGISTRATION ----${RESET}\n"

# Execute the validator registration command
echo -e "${GREEN}${BOLD}Registering validator...${RESET}"

aztec add-l1-validator \
  --l1-rpc-urls "$ETHEREUM_HOSTS" \
  --private-key "$VALIDATOR_PRIVATE_KEY" \
  --attester "$COINBASE" \
  --proposer-eoa "$COINBASE" \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111

# Check the exit status of the registration command
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}${BOLD}✅ Validator registration completed successfully!${RESET}"
    echo -e "${LIGHTBLUE}${BOLD}Your validator address: ${COINBASE}${RESET}"
    echo -e "${LIGHTBLUE}${BOLD}You can now participate in the Aztec network as a validator.${RESET}\n"
else
    echo -e "\n${RED}${BOLD}❌ Validator registration failed.${RESET}"
    echo -e "${LIGHTBLUE}${BOLD}Please check the error message above and try again.${RESET}"
    echo -e "${LIGHTBLUE}${BOLD}Common issues:${RESET}"
    echo -e "${LIGHTBLUE}  • Daily validator quota reached (ValidatorQuotaFilledUntil error)${RESET}"
    echo -e "${LIGHTBLUE}  • Insufficient Sepolia ETH balance (need at least 2.5 ETH)${RESET}"
    echo -e "${LIGHTBLUE}  • Invalid private key or RPC URL${RESET}"
    echo -e "${LIGHTBLUE}  • Network connectivity issues${RESET}\n"
    exit 1
fi 
