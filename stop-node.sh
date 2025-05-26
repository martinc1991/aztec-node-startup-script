#!/bin/bash

CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "\n${CYAN}${BOLD}---- STOPPING AZTEC NODE ----${RESET}\n"

echo -e "\n${CYAN}${BOLD}---- STOPPING SCREEN SESSIONS ----${RESET}\n"

# Check if screen session 'aztec' exists and stop it
if screen -list | grep -q "\.aztec"; then
    echo -e "${LIGHTBLUE}${BOLD}Found existing 'aztec' screen session. Stopping it...${RESET}"
    screen -S aztec -X quit
    sleep 2
    
    # Verify it was stopped
    if screen -list | grep -q "\.aztec"; then
        echo -e "${RED}${BOLD}Warning: Screen session may still be running. Trying force quit...${RESET}"
        screen -S aztec -X kill
        sleep 1
    fi
    
    echo -e "${GREEN}${BOLD}Screen session stopped.${RESET}"
else
    echo -e "${GREEN}${BOLD}No 'aztec' screen session found.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}---- STOPPING DOCKER CONTAINERS ----${RESET}\n"

# Stop any existing Aztec containers
if docker ps -q --filter "name=aztec" | grep -q .; then
    echo -e "${LIGHTBLUE}${BOLD}Stopping existing Aztec containers...${RESET}"
    docker stop $(docker ps -q --filter "name=aztec")
    docker rm $(docker ps -aq --filter "name=aztec")
    echo -e "${GREEN}${BOLD}Aztec containers stopped and removed.${RESET}"
else
    echo -e "${GREEN}${BOLD}No Aztec containers found.${RESET}"
fi

# Also check for containers using the aztec image
if docker ps -q --filter "ancestor=aztecprotocol/aztec:latest" | grep -q .; then
    echo -e "${LIGHTBLUE}${BOLD}Stopping containers using aztecprotocol/aztec:latest image...${RESET}"
    docker stop $(docker ps -q --filter "ancestor=aztecprotocol/aztec:latest")
    docker rm $(docker ps -aq --filter "ancestor=aztecprotocol/aztec:latest")
    echo -e "${GREEN}${BOLD}Aztec image containers stopped and removed.${RESET}"
else
    echo -e "${GREEN}${BOLD}No containers using aztecprotocol/aztec:latest image found.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}---- CLEARING PORT 8080 ----${RESET}\n"

# Check and clear port 8080
if netstat -tuln | grep -q ":8080 "; then
    echo -e "${LIGHTBLUE}${BOLD}Port 8080 is in use. Clearing it...${RESET}"
    sudo fuser -k 8080/tcp
    sleep 2
    
    # Verify port is cleared
    if netstat -tuln | grep -q ":8080 "; then
        echo -e "${RED}${BOLD}Warning: Port 8080 may still be in use.${RESET}"
    else
        echo -e "${GREEN}${BOLD}Port 8080 cleared successfully.${RESET}"
    fi
else
    echo -e "${GREEN}${BOLD}Port 8080 is already free.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}---- CLEANUP COMPLETE ----${RESET}\n"

# Remove the generated startup script if it exists
if [ -f "$HOME/start_aztec_node.sh" ]; then
    echo -e "${LIGHTBLUE}${BOLD}Removing generated startup script...${RESET}"
    rm "$HOME/start_aztec_node.sh"
    echo -e "${GREEN}${BOLD}Startup script removed.${RESET}"
fi

echo -e "${GREEN}${BOLD}Aztec node stopped successfully!${RESET}"
echo -e "${LIGHTBLUE}${BOLD}To start the node again, run: ./start-node.sh${RESET}\n" 
