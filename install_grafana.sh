#!/bin/bash

# Constants
LOG_FILE="/var/log/grafana_install.log"

# Ensure the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Error: This script must be run as root!" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Logging function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Update system packages
update_system() {
    log "Updating system packages..."
    apt update && apt upgrade -y
    if [[ $? -ne 0 ]]; then
        log "Error: Failed to update system packages."
        exit 1
    fi
}

# Add the Grafana APT repository
add_grafana_repo() {
    log "Adding Grafana APT repository..."
    
    apt install -y software-properties-common && \
    wget -q -O - https://packages.grafana.com/gpg.key | apt-key add - && \
    add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"

    if [[ $? -ne 0 ]]; then
        log "Error: Failed to add Grafana repository."
        exit 1
    fi
}

# Install Grafana
install_grafana() {
    if dpkg -l | grep -q grafana; then
        log "Grafana is already installed. Skipping installation."
        return 0
    fi

    log "Installing Grafana..."
    apt install grafana -y
    if [[ $? -ne 0 ]]; then
        log "Error: Failed to install Grafana."
        exit 1
    fi
}

# Start and enable Grafana service
start_grafana() {
    log "Starting and enabling Grafana service..."
    
    systemctl start grafana-server
    systemctl enable grafana-server
    
    if systemctl is-active --quiet grafana-server; then
        log "Grafana service is running."
    else
        log "Error: Grafana service failed to start."
        exit 1
    fi
}

# Verify installation
verify_grafana() {
    log "Verifying Grafana installation..."
    grafana_version=$(grafana-server -v 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        log "Grafana successfully installed: $grafana_version"
    else
        log "Error: Grafana verification failed."
        exit 1
    fi
}

# Main function to execute all steps
main() {
    check_root
    update_system
    add_grafana_repo
    install_grafana
    start_grafana
    verify_grafana
    log "Grafana installation completed successfully!"
}

# Execute main function
main
