#!/bin/bash

CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
BOLD='\033[1m'
RESET='\033[0m'

curl -s https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/refs/heads/main/wakeup-logo.sh | bash
sleep 3

echo -e "\n${CYAN}${BOLD}---- CHECKING DOCKER INSTALLATION ----${RESET}\n"
if ! command -v docker &> /dev/null; then
  echo -e "${LIGHTBLUE}${BOLD}Docker not found. Installing Docker...${RESET}"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
  rm get-docker.sh
  echo -e "${GREEN}${BOLD}Docker installed successfully!${RESET}"
fi

echo -e "${LIGHTBLUE}${BOLD}Setting up Docker to run without sudo for this session...${RESET}"
if ! getent group docker > /dev/null; then
  sudo groupadd docker
fi

sudo usermod -aG docker $USER

if [ -S /var/run/docker.sock ]; then
  sudo chmod 666 /var/run/docker.sock
  echo -e "${GREEN}${BOLD}Docker socket permissions updated.${RESET}"
else
  echo -e "${RED}${BOLD}Docker socket not found. Docker daemon might not be running.${RESET}"
  echo -e "${LIGHTBLUE}${BOLD}Starting Docker daemon...${RESET}"
  sudo systemctl start docker
  sudo chmod 666 /var/run/docker.sock
fi

if docker info &>/dev/null; then
  echo -e "${GREEN}${BOLD}Docker is now working without sudo.${RESET}"
else
  echo -e "${RED}${BOLD}Failed to configure Docker to run without sudo. Using sudo for Docker commands.${RESET}"
  DOCKER_CMD="sudo docker"
fi

echo -e "\n${CYAN}${BOLD}---- INSTALLING DEPENDENCIES ----${RESET}\n"
sudo apt-get update
sudo apt-get install -y curl screen net-tools psmisc jq

[ -d /root/.aztec/alpha-testnet ] && rm -r /root/.aztec/alpha-testnet

AZTEC_PATH=$HOME/.aztec
BIN_PATH=$AZTEC_PATH/bin
mkdir -p $BIN_PATH

echo -e "\n${CYAN}${BOLD}---- INSTALLING AZTEC TOOLKIT ----${RESET}\n"

if [ -n "$DOCKER_CMD" ]; then
  export DOCKER_CMD="$DOCKER_CMD"
fi

curl -fsSL https://install.aztec.network | bash

if ! command -v aztec >/dev/null 2>&1; then
    echo -e "${LIGHTBLUE}${BOLD}Aztec CLI not found in PATH. Adding it for current session...${RESET}"
    export PATH="$PATH:$HOME/.aztec/bin"

    if ! grep -Fxq 'export PATH=$PATH:$HOME/.aztec/bin' "$HOME/.bashrc"; then
        echo 'export PATH=$PATH:$HOME/.aztec/bin' >> "$HOME/.bashrc"
        echo -e "${GREEN}${BOLD}Added Aztec to PATH in .bashrc${RESET}"
    fi
fi

if [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

export PATH="$PATH:$HOME/.aztec/bin"

if ! command -v aztec &> /dev/null; then
  echo -e "${RED}${BOLD}ERROR: Aztec installation failed. Please check the logs above.${RESET}"
  exit 1
fi

echo -e "\n${CYAN}${BOLD}---- UPDATING AZTEC TO ALPHA-TESTNET ----${RESET}\n"
aztec-up alpha-testnet

echo -e "\n${CYAN}${BOLD}---- DOWNLOADING AUTO-START SETUP SCRIPT ----${RESET}\n"

# Download the setup-autostart.sh script if it doesn't exist
if [ ! -f "setup-autostart.sh" ]; then
    echo -e "${LIGHTBLUE}${BOLD}Downloading setup-autostart.sh script...${RESET}"
    curl -sSL -o setup-autostart.sh https://raw.githubusercontent.com/martinc1991/aztec-node-startup-script/main/setup-autostart.sh
    chmod +x setup-autostart.sh
    echo -e "${GREEN}${BOLD}✓ Auto-start setup script downloaded${RESET}"
else
    echo -e "${GREEN}${BOLD}✓ Auto-start setup script already exists${RESET}"
fi

echo -e "\n${CYAN}${BOLD}---- OPTIONAL: AUTO-START ON BOOT SETUP ----${RESET}\n"
echo -e "${LIGHTBLUE}${BOLD}Would you like to set up your Aztec node to automatically start when your server reboots?${RESET}"
echo -e "${LIGHTBLUE}This is highly recommended for production servers and EC2 instances.${RESET}\n"
echo -e "${LIGHTBLUE}This will:${RESET}"
echo -e "${LIGHTBLUE}  • Automatically start your node when the server boots${RESET}"
echo -e "${LIGHTBLUE}  • Restart the node if it crashes${RESET}"
echo -e "${LIGHTBLUE}  • Provide easy management commands${RESET}\n"
echo -e "${YELLOW}${BOLD}Set up auto-start now? (y/N): ${RESET}"
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${LIGHTBLUE}${BOLD}Running auto-start setup...${RESET}"
    ./setup-autostart.sh
    echo -e "\n${GREEN}${BOLD}Auto-start setup completed!${RESET}"
else
    echo -e "\n${LIGHTBLUE}${BOLD}Auto-start setup skipped.${RESET}"
    echo -e "${LIGHTBLUE}You can run it later with: ${YELLOW}./setup-autostart.sh${RESET}"
fi

echo -e "\n${GREEN}${BOLD}Setup completed successfully!${RESET}"
echo -e "${LIGHTBLUE}${BOLD}You can now run the node configuration script: ./configure-node.sh${RESET}\n" 
