#!/bin/bash

# Colors for pretty output
CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}================================${RESET}"
echo -e "${CYAN}${BOLD}  AZTEC NODE AUTO-START SETUP  ${RESET}"
echo -e "${CYAN}${BOLD}================================${RESET}\n"

# Function to print colored messages
print_status() {
    echo -e "${GREEN}${BOLD}✓${RESET} $1"
}

print_info() {
    echo -e "${LIGHTBLUE}${BOLD}ℹ${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}⚠${RESET} $1"
}

print_error() {
    echo -e "${RED}${BOLD}✗${RESET} $1"
}

# Detect current user and directory
CURRENT_USER=$(whoami)
CURRENT_DIR=$(pwd)
START_SCRIPT="$CURRENT_DIR/start-node.sh"
STOP_SCRIPT="$CURRENT_DIR/stop-node.sh"
SERVICE_NAME="aztec-node"

print_info "Detected user: $CURRENT_USER"
print_info "Current directory: $CURRENT_DIR"

# Check if start-node.sh exists
if [ ! -f "$START_SCRIPT" ]; then
    print_error "start-node.sh not found in current directory!"
    print_info "Please run this script from the directory containing your start-node.sh"
    exit 1
fi

print_status "Found start-node.sh script"

# Check if stop-node.sh exists (optional)
if [ ! -f "$STOP_SCRIPT" ]; then
    print_warning "stop-node.sh not found. Will create a basic stop script."
    STOP_SCRIPT=""
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Will set service to run as current user: $CURRENT_USER"
fi

echo -e "\n${LIGHTBLUE}${BOLD}This script will:${RESET}"
echo -e "${LIGHTBLUE}  1. Create a systemd service file${RESET}"
echo -e "${LIGHTBLUE}  2. Enable auto-start on boot${RESET}"
echo -e "${LIGHTBLUE}  3. Set up automatic restart if the node crashes${RESET}"
echo -e "${LIGHTBLUE}  4. Provide easy management commands${RESET}"

echo -e "\n${YELLOW}${BOLD}Do you want to continue? (y/N): ${RESET}"
read -p "" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Setup cancelled."
    exit 0
fi

print_info "Starting setup..."

# Create the systemd service file
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

print_info "Creating systemd service file..."

# Create the service file content
SERVICE_CONTENT="[Unit]
Description=Aztec Node Auto-Start Service
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$CURRENT_USER
Group=$CURRENT_USER
WorkingDirectory=$CURRENT_DIR
Environment=\"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.aztec/bin\"
Environment=\"HOME=$HOME\"
ExecStartPre=/bin/sleep 30
ExecStart=/bin/bash -c 'cd $CURRENT_DIR && ./start-node.sh'
ExecStop=/bin/bash -c 'cd $CURRENT_DIR && if [ -f \"./stop-node.sh\" ]; then ./stop-node.sh; else screen -S aztec -X quit 2>/dev/null || true; fi'
Restart=on-failure
RestartSec=60
StandardOutput=journal
StandardError=journal
TimeoutStartSec=600
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target"

# Write the service file (requires sudo)
echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null

if [ $? -eq 0 ]; then
    print_status "Service file created successfully"
else
    print_error "Failed to create service file. Check sudo permissions."
    exit 1
fi

# Reload systemd daemon
print_info "Reloading systemd daemon..."
sudo systemctl daemon-reload

if [ $? -eq 0 ]; then
    print_status "Systemd daemon reloaded"
else
    print_error "Failed to reload systemd daemon"
    exit 1
fi

# Enable the service
print_info "Enabling auto-start service..."
sudo systemctl enable $SERVICE_NAME.service

if [ $? -eq 0 ]; then
    print_status "Auto-start service enabled"
else
    print_error "Failed to enable service"
    exit 1
fi

echo -e "\n${GREEN}${BOLD}🎉 SETUP COMPLETE! 🎉${RESET}\n"

print_status "Your Aztec node will now automatically start on system boot"
print_status "The service will automatically restart if the node crashes"

echo -e "\n${CYAN}${BOLD}USEFUL COMMANDS:${RESET}"
echo -e "${LIGHTBLUE}Start the service now:${RESET}        sudo systemctl start $SERVICE_NAME"
echo -e "${LIGHTBLUE}Stop the service:${RESET}             sudo systemctl stop $SERVICE_NAME"
echo -e "${LIGHTBLUE}Restart the service:${RESET}          sudo systemctl restart $SERVICE_NAME"
echo -e "${LIGHTBLUE}Check service status:${RESET}         sudo systemctl status $SERVICE_NAME"
echo -e "${LIGHTBLUE}View live logs:${RESET}               sudo journalctl -u $SERVICE_NAME -f"
echo -e "${LIGHTBLUE}View recent logs:${RESET}             sudo journalctl -u $SERVICE_NAME -n 50"
echo -e "${LIGHTBLUE}Disable auto-start:${RESET}           sudo systemctl disable $SERVICE_NAME"

echo -e "\n${YELLOW}${BOLD}TESTING THE SETUP:${RESET}"
echo -e "${LIGHTBLUE}Would you like to start the service now to test it? (y/N): ${RESET}"
read -p "" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Starting the service..."
    sudo systemctl start $SERVICE_NAME.service
    
    sleep 5
    
    # Check service status
    if sudo systemctl is-active --quiet $SERVICE_NAME.service; then
        print_status "Service is running successfully!"
        echo -e "\n${LIGHTBLUE}You can view the logs with:${RESET}"
        echo -e "${YELLOW}sudo journalctl -u $SERVICE_NAME -f${RESET}"
    else
        print_warning "Service may have issues. Check status with:"
        echo -e "${YELLOW}sudo systemctl status $SERVICE_NAME${RESET}"
    fi
else
    print_info "Service setup complete. You can start it manually or reboot to test."
fi

echo -e "\n${GREEN}${BOLD}Next time your EC2 instance restarts, your Aztec node will start automatically!${RESET}"

# Create a quick management script
MGMT_SCRIPT="$CURRENT_DIR/manage-autostart.sh"
cat > "$MGMT_SCRIPT" << 'EOF'
#!/bin/bash

# Colors
GREEN='\033[1;32m'
LIGHTBLUE='\033[1;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

SERVICE_NAME="aztec-node"

case "$1" in
    start)
        echo -e "${LIGHTBLUE}Starting Aztec node service...${RESET}"
        sudo systemctl start $SERVICE_NAME
        ;;
    stop)
        echo -e "${LIGHTBLUE}Stopping Aztec node service...${RESET}"
        sudo systemctl stop $SERVICE_NAME
        ;;
    restart)
        echo -e "${LIGHTBLUE}Restarting Aztec node service...${RESET}"
        sudo systemctl restart $SERVICE_NAME
        ;;
    status)
        sudo systemctl status $SERVICE_NAME
        ;;
    logs)
        sudo journalctl -u $SERVICE_NAME -f
        ;;
    enable)
        echo -e "${LIGHTBLUE}Enabling auto-start...${RESET}"
        sudo systemctl enable $SERVICE_NAME
        ;;
    disable)
        echo -e "${LIGHTBLUE}Disabling auto-start...${RESET}"
        sudo systemctl disable $SERVICE_NAME
        ;;
    *)
        echo -e "${GREEN}Aztec Node Management Script${RESET}"
        echo "Usage: $0 {start|stop|restart|status|logs|enable|disable}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the Aztec node service"
        echo "  stop     - Stop the Aztec node service"
        echo "  restart  - Restart the Aztec node service"
        echo "  status   - Show service status"
        echo "  logs     - Show live logs"
        echo "  enable   - Enable auto-start on boot"
        echo "  disable  - Disable auto-start on boot"
        ;;
esac
EOF

chmod +x "$MGMT_SCRIPT"
print_status "Created management script: $MGMT_SCRIPT"

echo -e "\n${YELLOW}${BOLD}BONUS:${RESET} Use ${YELLOW}./manage-autostart.sh${RESET} for easy service management!" 
