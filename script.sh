#!/bin/bash

show_adnsystems() {
clear

echo "                  _____  _   _    _____           _                     "
echo "            /\   |  __ \| \ | |  / ____|         | |                    "
echo "           /  \  | |  | |  \| | | (___  _   _ ___| |_ ___ _ __ ___  ___ "
echo "          / /\ \ | |  | | . \` |  \___ \| | | / __| __/ _ \ '_ \` _ \/ __|"
echo "         / ____ \| |__| | |\  |  ____) | |_| \__ \ ||  __/ | | | | \__ \\"
echo "        /_/    \_\_____/|_| \_| |_____/ \__, |___/\__\___|_| |_| |_|___/"
echo "                                         __/ |                          "
echo "                                        |___/                           "
echo "                                                                        "
echo "                                                                        "
}
show_adnsystems
echo "************************************************************************"
echo "*                                                                      *"
echo "* This script will install or upgrade ADN Systems Server and Dashboard *"
echo "*                                                                      *"
echo "************************************************************************"
echo "                                                                        "
echo "                                                                        "


# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to install ADN Systems
install_adn_systems() {
    show_adnsystems

    # Determine the Linux version
    . /etc/os-release
    if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
    echo "This script is only compatible with Debian or Ubuntu."
    exit 1
    fi

    if [[ "$VERSION_ID" != "11" && "$VERSION_ID" != "20.04" && "$VERSION_ID" != "22.04" ]]; then
    echo "Unsupported Debian/Ubuntu version. Supported versions: Debian 11, Ubuntu 20.04, 22.04."
    exit 1
    fi

    # Install net-tools if not installed
    if ! command -v netstat &> /dev/null; then
    echo "Installing net-tools..."
    apt-get update > /dev/null
    apt-get install -y net-tools > /dev/null
    fi

    # Check if TCP port 4321 is in use and /opt/adnserver does not exist
    if netstat -tuln | grep ':4321' > /dev/null && [ ! -d /opt/adnserver ]; then
        echo "It seems that you have a custom ADN server installation already installed. Please remove the current installation and run this script again."
        exit 1
    fi

    # Check if TCP port 9000 is in use and /opt/dashboard does not exist
    if netstat -tuln | grep ':9000' > /dev/null && [ ! -d /opt/adn-dashboard ]; then
        echo "It seems that you have a custom Dashboard installation already installed. Please remove the current installation and run this script again."
        exit 1
    fi

    # Update and install required packages
    echo "Updating package list and installing required packages... (this can take a while!)"
    apt-get update > /dev/null
    apt-get install -y git wget python3 python3-pip python3-dev libffi-dev libssl-dev cargo sed build-essential apache2 php libapache2-mod-php php-sqlite3

    # Install Python packages
    pip3 install --no-cache-dir bitstring bitarray Twisted dmr_utils3 configparser resettabletimer setproctitle Pyro5 spyne setuptools wheel autobahn jinja2 MarkupSafe pyOpenSSL service-identity bitarray

    # Clone server repository
    echo "Installing ADN Systems DMR Server..."
    cd /opt
    git clone https://github.com/Amateur-Digital-Network/ADN-DMR-Peer-Server.git adn-server > /dev/null

    # Create log directory if not exists
    mkdir -p /opt/adn-server/log

    # Copy and change configuration file
    cd /opt/adn-server/config
    cp ADN-SAMPLE.cfg adn.cfg
    sed -i 's|LOG_FILE: /dev/null|LOG_FILE: /opt/adn-server/log/adn-server.log|' adn.cfg
    sed -i 's|LOG_HANDLERS: console-timed|LOG_HANDLERS: file-timed|' adn.cfg
    sed -i 's|LOG_LEVEL: DEBUG|LOG_LEVEL: INFO|' adn.cfg

    # Create log rotation configuration
    echo "Creating ADN Systems DMR Server log rotation configuration..."
    cat <<EOL > /etc/logrotate.d/adn-server
/opt/adn-server/log/adn-server.log {
    daily
    rotate 7
    size 10M
    compress
    delaycompress
    copytruncate
}
EOL

    # Create adn_server service
    echo "Creating ADN Systems DMR Server service (adn_server.service)..."
    cat <<EOL > /etc/systemd/system/adn_server.service
[Unit]
Description=ADN Systems DMR Server
After=network-online.target syslog.target

[Service]
User=root
WorkingDirectory=/opt/adn-server
ExecStart=/usr/bin/python3 /opt/adn-server/bridge_master.py -c /opt/adn-server/config/adn.cfg
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

    # Create adn_parrot service
    echo "Creating ADN Systems DMR Server Parrot service (adn_parrot.service)..."
    cat <<EOL > /etc/systemd/system/adn_parrot.service
[Unit]
Description=ADN Systems Parrot
After=network-online.target syslog.target

[Service]
User=root
WorkingDirectory=/opt/adn-server
ExecStart=/usr/bin/python3 /opt/adn-server/playback.py -c /opt/adn-server/config/parrot.cfg
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

    # Clone dashboard repository
    cd /opt
    git clone https://github.com/Amateur-Digital-Network/ADN-Dashboard.git adn-dashboard > /dev/null

    # Copy configuration files
    cd /opt/adn-dashboard
    cp dashboard_SAMPLE.cfg dashboard.cfg
    cd /opt/adn-dashboard/proxy
    cp proxy_SAMPLE.cfg proxy.cfg

    # Create the database file
    echo "Creating the database file..."
    cd /opt/adn-dashboard
    python3 dash_db.py > /dev/null

    # Set ownership of the html directory
    echo "Setting ownership of the dashboard/html directory..."
    chown -R www-data:www-data /opt/adn-dashboard/html/

    # Create Apache configuration
    echo "Creating Apache configuration..."
    cat <<EOL > /etc/apache2/sites-available/adndash-default.conf
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /opt/adn-dashboard/html
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

    # Disable default Apache site and enable the new site
    echo "Configuring Apache..."
    a2dissite 000-default.conf > /dev/null
    a2ensite adndash-default.conf > /dev/null

    # Update Apache configuration
    cat <<EOL >> /etc/apache2/apache2.conf
<Directory /opt/adn-dashboard/>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
EOL


    # Create log rotation configuration
    echo "Creating ADN Syatems Dashboard log rotation configuration..."
    cat <<EOL > /etc/logrotate.d/adn-dashboard
/opt/adn-dashboard/log/dashboard.log {
    daily
    rotate 7
    size 10M
    compress
    delaycompress
    copytruncate
}
EOL

    # Create adn_dashboard service
    echo "Creating ADN Systems Dashboard service (adn_dashboard.service)..."
    cat <<EOL > /etc/systemd/system/adn_dashboard.service
[Unit]
Description=ADN Dashboard
After=network-online.target syslog.target
Wants=network-online.target

[Service]
StandardOutput=null
WorkingDirectory=/opt/adn-dashboard
RestartSec=3
ExecStart=/usr/bin/python3 /opt/adn-dashboard/dashboard.py
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL

    # Create adn_proxy service
    echo "Creating ADN Systems Proxy service (adn_proxy.service)..."
    cat <<EOL > /etc/systemd/system/adn_proxy.service
[Unit]
Description=ADN Server Proxy
After=multi-user.target

[Service]
StandardOutput=null
WorkingDirectory=/opt/adn-dashboard
RestartSec=3
ExecStart=/usr/bin/python3 /opt/adn-dashboard/proxy/hotspot_proxy_v2.py -c /opt/adn-dashboard/proxy/proxy.cfg
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

    # Enable services
    echo "Enabling services..."
    systemctl enable adn_server.service > /dev/null
    systemctl enable adn_parrot.service > /dev/null
    systemctl enable apache2 > /dev/null
    systemctl enable adn_proxy.service > /dev/null
    systemctl enable adn_dashboard.service > /dev/null

    # Start services
    echo "Starting services..."
    systemctl start adn_server.service > /dev/null
    systemctl start adn_parrot.service > /dev/null
    systemctl restart apache2 > /dev/null
    systemctl start adn_proxy.service > /dev/null
    systemctl start adn_dashboard.service > /dev/null

    echo "ADN Systems DMR Server and Dashboard installation complete."
}

# Function to install ADN Systems docker
install_adn_systems_docker() {
    # Install net-tools if not installed
    if ! command -v netstat &> /dev/null; then
    echo "Installing net-tools..."
    apt-get update > /dev/null
    apt-get install -y net-tools > /dev/null
    fi

    # Check if TCP port 4321 is in use and /opt/adnserver does not exist
    if netstat -tuln | grep ':4321' > /dev/null && [ ! -d /opt/adnserver ]; then
        echo "It seems that you have a custom ADN server installation already installed. Please remove the current installation and run this script again."
        exit 1
    fi

    # Check if TCP port 9000 is in use and /opt/dashboard does not exist
    if netstat -tuln | grep ':9000' > /dev/null && [ ! -d /opt/adn-dashboard ]; then
        echo "It seems that you have a custom Dashboard installation already installed. Please remove the current installation and run this script again."
        exit 1
    fi

    # install Docker Community Edition
    echo "Updating package list and installing required packages..."
    apt-get -y remove docker.io docker-doc docker-compose podman-docker containerd runc
    set -e
    apt-get update
    apt-get -y install apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get -y update
    apt-get -y install docker-ce docker-compose docker-compose-plugin

    # Set userland-proxy
    echo "Setting userland-proxy..."
    cat <<EOF > /etc/docker/daemon.json
{
     "userland-proxy": false,
     "experimental": true,
     "log-driver": "json-file",
     "log-opts": {
        "max-size": "10m",
        "max-file": "3"
      }
}
EOF
    # Applying changes
    systemctl restart docker

    # Making config folders
    mkdir -p /etc/ADN-Systems
    mkdir -p /etc/ADN-Systems/acme.sh
    mkdir -p /etc/ADN-Systems/certs

    # Clone repository
    echo "Cloning repositories..."
    cd /etc/ADN-Systems
    git clone https://github.com/Amateur-Digital-Network/ADN-Dashboard.git adn-dashboard > /dev/null
    git clone https://github.com/Amateur-Digital-Network/ADN-DMR-Peer-Server.git adn-server > /dev/null

    # Copy and modify configuration files
    echo "Copy config files..."
    cp /etc/ADN-Systems/adn-dashboard/docker/docker-compose.yml /etc/ADN-Systems/docker-compose.yml
    cd /etc/ADN-Systems/adn-server/config
    cp ADN-SAMPLE.cfg adn.cfg
    sed -i 's|REPORT_CLIENTS: 127.0.0.1|REPORT_CLIENTS: *|' adn.cfg
    cd /etc/ADN-Systems/adn-dashboard
    cp dashboard_SAMPLE.cfg dashboard.cfg
    sed -i 's|SERVER_IP = 127.0.0.1|SERVER_IP = 172.16.250.10|' dashboard.cfg
    sed -i 's|LOG_PATH = ./log|LOG_PATH = /dev/|' dashboard.cfg
    sed -i 's|LOG_FILE =  dashboard.log|LOG_FILE = null|' dashboard.cfg
    cd /etc/ADN-Systems/adn-dashboard/proxy
    cp proxy_SAMPLE.cfg proxy.cfg
    sed -i 's|MASTER = 127.0.0.1|MASTER = 172.16.250.10|' proxy.cfg
    chmod -R 755 /etc/ADN-Systems
    chown 54000:54000 /etc/ADN-Systems/adn-server

    #Tune network stack
    echo "Tunning network stack..."
    cat << EOF > /etc/sysctl.conf
net.core.rmem_default=134217728
net.core.rmem_max=134217728
net.core.wmem_max=134217728                       
net.core.rmem_default=134217728
net.core.netdev_max_backlog=250000
net.netfilter.nf_conntrack_udp_timeout=15
net.netfilter.nf_conntrack_udp_timeout_stream=35
EOF

    /usr/sbin/sysctl -p

    # Run containers
    cd /etc/ADN-Systems
    docker-compose up -d 

    echo Read notes in /etc/ADN-Systems/docker-compose.yml to understand how to implement extra functionality.
    echo ADN-Systems setup complete!

}


# Function update the ADN Server
update_adn_systems() {
    show_adnsystems

    if [ -d /opt/adn-server ]; then

        # Stopping services
        echo "Stopping services before updating..."
        systemctl stop adn_server.service > /dev/null
        systemctl stop adn_parrot.service > /dev/null
        systemctl stop adn_proxy.service > /dev/null
        systemctl stop adn_dashboard.service > /dev/null
        echo "Updating ADN Systems..."

        # Update the server repository
        cd /opt/adn-server
        git pull --ff-only 

        # Update the dashboard repository
        cd /opt/adn-dashboard
        git pull --ff-only 

        # Start services
        echo "Starting services..."
        systemctl start adn_server.service > /dev/null
        systemctl start adn_parrot.service > /dev/null
        systemctl restart apache2 > /dev/null
        systemctl start adn_proxy.service > /dev/null
        systemctl start adn_dashboard.service > /dev/null

        show_adn_status

        echo "ADN Systems DMR Server and Dashboard Update complete."

    fi
    if [ -d /etc/ADN-Systems ]; then

        # Stopping containers
        echo "Stopping containers before updating..."
        cd /etc/ADN-Systems
        docker-compose down
        echo "Updating ADN Systems..."

        # Update the server repository
        cd /etc/ADN-Systems/adn-server
        git pull --ff-only > /dev/null

        # Update the dashboard repository
        cd /etc/ADN-Systems/adn-dashboard
        git pull --ff-only > /dev/null

        # Start services
        echo "Starting containers..."
        docker-compose up -d

        echo "ADN Systems DMR Server and Dashboard Update complete."

    fi
}

# Remove ADN Systems
remove_adn_systems() {
    show_adnsystems
    if [ -d /opt/adn-server ]; then
        echo "Stopping and Removing Services..."
        systemctl stop adn_server.service
        systemctl stop adn_proxy.service
        systemctl stop adn_parrot.service
        systemctl stop adn_dashboard.service

        systemctl disable adn_server.service
        systemctl disable adn_proxy.service
        systemctl disable adn_parrot.service
        systemctl disable adn_dashboard.service

        echo "Backup config files to /opt/..."
        cp /opt/adn-server/config/adn.cfg /opt/adn.cfg
        cp /opt/adn-dashboard/dashboard.cfg /opt/dashboard.cfg
        cp /opt/adn-dashboard/proxy/proxy.cfg /opt/proxy.cfg

        echo "Removing files..."
        rm -rf /etc/logrotate.d/adn-server
        rm -rf /etc/logrotate.d/adn-dashboard
        rm -rf /etc/systemd/system/adn_server.service
        rm -rf /etc/systemd/system/adn_proxy.service
        rm -rf /etc/systemd/system/adn_parrot.service
        rm -rf /etc/systemd/system/adn_dashboard.service
        rm -rf /etc/apache2/sites-available/adndash-default.conf
        rm -rf /opt/adn-server
        rm -rf /opt/adn-dashboard

        echo "Removing Apache Settings..."
        sed -i.bak '/<Directory \/opt\/adn-dashboard\/>/,/<\/Directory>/d' /etc/apache2/apache2.conf
        a2dissite adndash-default.conf > /dev/null
        a2ensite 000-default.conf > /dev/null
        systemctl restart apache2.service
    fi
    if [ -d /etc/ADN-Systems ]; then
        echo "Stopping and Removing Containers..."
        cd /etc/ADN-Systems
        docker-compose down
	docker rmi $(docker images -q) -f
 	docker system prune -a -f

        echo "Backup config files to /opt/..."
        cp /etc/ADN-Systems/adn-server/config/adn.cfg /opt/adn.cfg
        cp /etc/ADN-Systems/adn-dashboard/dashboard.cfg /opt/dashboard.cfg
        cp /etc/ADN-Systems/adn-dashboard/proxy/proxy.cfg /opt/proxy.cfg
        cp /etc/ADN-Systems/docker-compose.yml /opt/docker-compose.yml

        echo "Removing files..."
        rm -rf /etc/ADN-Systems

    fi
    echo "Remove complete."
}

# show services status
show_adn_status() {
    # Checking services status
    systemctl status adn_server.service
    systemctl status adn_proxy.service
    systemctl status adn_parrot.service
    systemctl status adn_dashboard.service
}


# Main
dashboard_installed=false
server_installed=false
docker_installed=false

# Check if Server/Dashboard or Docker installed
if [ -d /opt/adn-server ]; then
    server_installed=true
fi
if [ -d /etc/ADN-Systems ]; then
    docker_installed=true
fi

if [ "$server_installed" = true ] || [ "$docker_installed" = true ]; then
    echo "************************************************************************"
    echo "*                                                                      *"
    echo "*    ADN Systems DMR Server and Dashboard detected.                    *"
    echo "*                                                                      *"
    echo "*     1 - Update ADN Systems Server and Dashboard                      *"
    echo "*     2 - REMOVE ADN Systems Server and Dashboard                      *"
    echo "*     3 - Exit                                                         *"
    echo "*                                                                      *"
    echo "************************************************************************"
    read -p "Choose (1/2/3): " update_choice
    case $update_choice in
        1) show_adnsystems; update_adn_systems ;;
        2) show_adnsystems; remove_adn_systems ;;
        3) echo "Exiting without making any changes."; exit 0 ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac
else
    echo "************************************************************************"
    echo "*                                                                      *"
    echo "*     ADN Systems DMR Server and Dashboard installation                *"
    echo "*                                                                      *"
    echo "*      1 - Install ADN Systems Server and Dashboard locally            *"
    echo "*      2 - Install ADN Systems Server and Dashboard in docker          *"
    echo "*      3 - Exit                                                        *"
    echo "*                                                                      *"
    echo "************************************************************************"
    read -p "Choose (1/2/3): " update_choice
    case $update_choice in
        1) show_adnsystems; install_adn_systems; show_adn_status ;;
        2) show_adnsystems; install_adn_systems_docker; show_adn_status ;;
        3) echo "Exiting without making any changes."; exit 0 ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac
fi
