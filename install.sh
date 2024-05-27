#!/bin/bash

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

# Check if the dashboard is already installed
if [ -d /opt/dashboard ]; then
  read -p "Dashboard is already installed. Do you want to update it from the latest version on GitHub? (y/n): " update_choice
  if [[ "$update_choice" != "y" && "$update_choice" != "Y" ]]; then
    echo "Exiting without making any changes."
    exit 0
  fi
  echo "Stopping services before updating..."
  systemctl stop adn_proxy.service > /dev/null
  systemctl stop adn_dashboard.service > /dev/null
  echo "Updating the dashboard..."
else
  echo "Installing the dashboard..."

  # Update and install required packages
  echo "Updating package list and installing required packages..."
  apt update > /dev/null
  apt install -y git wget python3 python3-pip python3-dev libffi-dev libssl-dev cargo sed build-essential apache2 php libapache2-mod-php php-sqlite3 > /dev/null

  # Install Python packages
  echo "Installing Python packages..."
  pip3 install --no-cache-dir setuptools wheel Twisted dmr_utils3 bitstring autobahn jinja2 MarkupSafe pyOpenSSL service-identity bitarray configparser resettabletimer setproctitle Pyro5 spyne > /dev/null
fi

# Clone or update the dashboard repository
if [ -d /opt/dashboard ]; then
  cd /opt/dashboard
  git pull > /dev/null
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
if [ ! -f /opt/dashboard/dashboard.db ]; then
  echo "Creating the database file..."
  python3 dash_db.py > /dev/null
fi

# Set ownership of the html directory
echo "Setting ownership of the html directory..."
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
  echo "Creating log rotation configuration..."
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
  echo "Creating ADN Dashboard service..."
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
  echo "Creating Proxy service..."
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

echo "ADN Dashboard and Proxy installation complete."
