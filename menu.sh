#!/bin/bash

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

# Determine the Linux version
. /etc/os-release
if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
  echo "This script is only compatible with Debian or Ubuntu."
  exit 1
fi

if [[ "$VERSION_ID" != "10" && "$VERSION_ID" != "11" && "$VERSION_ID" != "18.04" && "$VERSION_ID" != "20.04" && "$VERSION_ID" != "22.04" ]]; then
  echo "Unsupported Debian/Ubuntu version. Supported versions: Debian 10, Debian 11, Ubuntu 18.04, 20.04, 22.04."
  exit 1
fi

# Install net-tools if not installed
if ! command -v netstat &> /dev/null; then
  echo "Installing net-tools..."
  apt update > /dev/null
  apt install -y net-tools > /dev/null
fi

# Function to install/update the ADN Server
install_update_server() {
  # Check if TCP port 4321 is in use and /opt/adnserver does not exist
  if netstat -tuln | grep ':4321' > /dev/null && [ ! -d /opt/adnserver ]; then
    echo "It seems that you have a custom ADN server installation already installed. Please remove the current installation and run this script again."
    exit 1
  fi

  # Check if the server is already installed
  if [ -d /opt/adnserver ]; then
    read -p "ADN Systems DMR Server is already installed! \nDo you want to update it from the latest version? (y/n): " update_choice
    if [[ "$update_choice" != "y" && "$update_choice" != "Y" ]]; then
      echo "Exiting without making any changes."
      exit 0
    fi
    echo "Stopping services before updating..."
    systemctl stop adn_server.service > /dev/null
    systemctl stop adn_parrot.service > /dev/null
    echo "Updating ADN Systems DMR Server..."
  else
    echo "Installing ADN Systems DMR Server..."
    
    # Update and install required packages
    echo "Updating package list and installing required packages... (this can take a while!)"
    apt update > /dev/null
    apt install -y git wget python3 python3-pip python3-dev libffi-dev libssl-dev cargo sed build-essential apache2 php libapache2-mod-php php-sqlite3 > /dev/null
    # Install Python packages
    pip3 install --no-cache-dir setuptools wheel Twisted dmr_utils3 bitstring autobahn jinja2 MarkupSafe pyOpenSSL service-identity bitarray configparser resettabletimer setproctitle Pyro5 spyne > /dev/null
  fi

  # Clone or update the server repository
  if [ -d /opt/adnserver ]; then
    cd /opt/adnserver
    git pull --ff-only > /dev/null
  else
    cd /opt
    git clone https://github.com/Amateur-Digital-Network/ADN-DMR-Peer-Server.git adnserver > /dev/null
  fi

  # Create log directory if not exists
  mkdir -p /opt/adnserver/log

  # Check and copy configuration files if not present
  cd /opt/adnserver/config
  if [ ! -f adnserver.cfg ]; then
    cp ADN-SAMPLE.cfg adnserver.cfg
    sed -i 's|LOG_FILE: /dev/null|LOG_FILE: /opt/adnserver/log/adnserver.log|' adnserver.cfg
    sed -i 's|LOG_HANDLERS: console-timed|LOG_HANDLERS: file-timed|' adnserver.cfg
    sed -i 's|LOG_LEVEL: DEBUG|LOG_LEVEL: INFO|' adnserver.cfg
  fi

  # Create log rotation configuration
  if [ ! -f /etc/logrotate.d/adnserver ]; then
    echo "Creating ADN Systems DMR Server log rotation configuration..."
    cat <<EOL > /etc/logrotate.d/adnserver
/opt/adnserver/log/adnserver.log {
    daily
    rotate 7
    size 10M
    compress
    delaycompress
    copytruncate
}
EOL
  fi

  # Create adn_server service
  if [ ! -f /etc/systemd/system/adn_server.service ]; then
    echo "Creating ADN Systems DMR Server service (adn_server.service)..."
    cat <<EOL > /etc/systemd/system/adn_server.service
[Unit]
Description=ADN Systems DMR Server
After=network-online.target syslog.target

[Service]
User=root
WorkingDirectory=/opt/adnserver
ExecStart=/usr/bin/python3 /opt/adnserver/bridge_master.py -c /opt/adnserver/config/adnserver.cfg
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL
  fi

  # Create adn_parrot service
  if [ ! -f /etc/systemd/system/adn_parrot.service ]; then
    echo "Creating ADN Systems DMR Server Parrot service (adn_parrot.service)..."
    cat <<EOL > /etc/systemd/system/adn_parrot.service
[Unit]
Description=ADN Systems Parrot
After=network-online.target syslog.target

[Service]
User=root
WorkingDirectory=/opt/adnserver
ExecStart=/usr/bin/python3 /opt/adnserver/playback.py -c /opt/adnserver/config/parrot.cfg
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL
  fi

  # Enable services
  echo "Enabling services..."
  systemctl enable adn_server.service > /dev/null
  systemctl enable adn_parrot.service > /dev/null

  # Start services
  echo "Starting services..."
  systemctl start adn_server.service > /dev/null
  systemctl start adn_parrot.service > /dev/null

  echo "ADN Systems DMR Server installation/update complete."
}

# Function to install/update the ADN Dashboard
install_update_dashboard() {
  # Check if TCP port 9000 is in use and /opt/dashboard does not exist
  if netstat -tuln | grep ':9000' > /dev/null && [ ! -d /opt/dashboard ]; then
    echo "It seems that you have a custom Dashboard installation already installed. Please remove the current installation and run this script again."
    exit 1
  fi

  # Check if the dashboard is already installed
  if [ -d /opt/dashboard ]; then
    read -p "Dashboard is already installed. \nDo you want to update it from the latest version on GitHub? (y/n): " update_choice
    if [[ "$update_choice" != "y" && "$update_choice" != "Y" ]]; then
      echo "Exiting without making any changes."
      exit 0
    fi
    echo "Stopping services before updating..."
    systemctl stop adn_proxy.service > /dev/null
    systemctl stop adn_dashboard.service > /dev/null
    echo "Updating the dashboard..."
  else
    echo "Installing the ADN Systems Dashboard..."

    # Update and install required packages
    echo "Updating package list and installing required packages... (this can take a while)"
    apt update > /dev/null
    apt install -y git wget python3 python3-pip python3-dev libffi-dev libssl-dev cargo sed build-essential apache2 php libapache2-mod-php php-sqlite3 > /dev/null

    # Install Python packages
    pip3 install --no-cache-dir setuptools wheel Twisted dmr_utils3 bitstring autobahn jinja2 MarkupSafe pyOpenSSL service-identity bitarray configparser resettabletimer setproctitle Pyro5 spyne > /dev/null
  fi

  # Clone or update the dashboard repository
  if [ -d /opt/dashboard ]; then
    cd /opt/dashboard
    git pull --ff-only > /dev/null
  else
    cd /opt
    git clone https://github.com/Amateur-Digital-Network/ADN-Dashboard.git dashboard > /dev/null
  fi

  # Check and copy configuration files if not present
  cd /opt/dashboard
  if [ ! -f dashboard.cfg ]; then
    cp dashboard_SAMPLE.cfg dashboard.cfg
  fi

  cd /opt/dashboard/proxy
  if [ ! -f proxy.cfg ]; then
    cp proxy_SAMPLE.cfg proxy.cfg
  fi

  cd /opt/dashboard

  # Create the database file only if installing
  if [ ! -f /opt/dashboard/html/db/dashboard.db ]; then
    echo "Creating the database file..."
    python3 dash_db.py > /dev/null
  fi

  # Set ownership of the html directory
  echo "Setting ownership of the dashboard/html directory..."
  chown -R www-data:www-data /opt/dashboard/html/

  # Create Apache configuration
  echo "Creating Apache configuration..."
  cat <<EOL > /etc/apache2/sites-available/adndash-default.conf
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /opt/dashboard/html
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

  # Disable default Apache site and enable the new site
  echo "Configuring Apache..."
  a2dissite 000-default.conf > /dev/null
  a2ensite adndash-default.conf > /dev/null

  # Update Apache configuration
  if ! grep -q "<Directory /opt/dashboard/>" /etc/apache2/apache2.conf; then
    cat <<EOL >> /etc/apache2/apache2.conf

<Directory /opt/dashboard/>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
EOL
  fi

  # Create log rotation configuration
  if [ ! -f /etc/logrotate.d/dashboard ]; then
    echo "Creating ADN Syatems Dashboard log rotation configuration..."
    cat <<EOL > /etc/logrotate.d/dashboard
/opt/dashboard/log/dashboard.log {
    daily
    rotate 7
    size 10M
    compress
    delaycompress
    copytruncate
}
EOL
  fi

  # Create adn_dashboard service
  if [ ! -f /etc/systemd/system/adn_dashboard.service ]; then
    echo "Creating ADN Systems Dashboard service (adn_dashboard.service)..."
    cat <<EOL > /etc/systemd/system/adn_dashboard.service
[Unit]
Description=ADN Dashboard
After=network-online.target syslog.target
Wants=network-online.target

[Service]
StandardOutput=null
WorkingDirectory=/opt/dashboard
RestartSec=3
ExecStart=/usr/bin/python3 /opt/dashboard/dashboard.py
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOL
  fi

  # Create adn_proxy service
  if [ ! -f /etc/systemd/system/adn_proxy.service ]; then
    echo "Creating ADN Systems Proxy service (adn_proxy.service)..."
    cat <<EOL > /etc/systemd/system/adn_proxy.service
[Unit]
Description=ADN Server Proxy
After=multi-user.target

[Service]
StandardOutput=null
WorkingDirectory=/opt/dashboard
RestartSec=3
ExecStart=/usr/bin/python3 /opt/dashboard/proxy/hotspot_proxy_v2.py -c /opt/dashboard/proxy/proxy.cfg
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL
  fi

  # Enable services
  echo "Enabling services..."
  systemctl enable apache2 > /dev/null
  systemctl enable adn_proxy.service > /dev/null
  systemctl enable adn_dashboard.service > /dev/null

  # Start services
  echo "Starting services..."
  systemctl restart apache2 > /dev/null
  systemctl start adn_proxy.service > /dev/null
  systemctl start adn_dashboard.service > /dev/null

  echo "ADN Systems Dashboard installation/update complete."
}

# Main script execution
dashboard_installed=false
server_installed=false

# Check if Dashboard or Server is already installed
if [ -d /opt/dashboard ]; then
  dashboard_installed=true
fi
if [ -d /opt/adnserver ]; then
  server_installed=true
fi

# Prompt user for action
if $dashboard_installed || $server_installed; then
  echo "ADN Systems Server and Dashboard are already installed."
  echo "Do you want to update:"
  echo "1 - only the Dashboard"
  echo "2 - only the DMR Server"
  echo "3 - both DMR Server and Dashboard"
  echo "4 - Exit"
  read -p "Choose (1/2/3/4): " update_choice
  case $update_choice in
    1) install_update_dashboard ;;
    2) install_update_server ;;
    3) install_update_dashboard; install_update_server ;;
    4) echo "Exiting without making any changes."; exit 0 ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
else
  read -p "Do you want to install ADN Systems DMR Server with Dashboard? (y/n): " install_choice
  if [[ "$update_choice" != "y" && "$update_choice" != "Y" ]]; then
    echo "Exiting without making any changes."
    exit 0
  fi
  install_update_server
  install_update_dashboard
fi

echo "You're done. Enjoy!"
