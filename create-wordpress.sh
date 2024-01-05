#!/bin/bash

# Get user input for username and domain
read -p "Enter username: " username
read -p "Enter custom domain (without www): " domain

# Install required software
sudo apt update
sudo apt install nginx mariadb-server php-fpm php-mysql php-curl php-gd php-mbstring php-xml certbot python3-certbot-nginx -y

# Create user account
sudo adduser $username

# Create website directory
sudo mkdir -p /var/www/$username/public_html
sudo chown -R $username:$username /var/www/$username

# Configure Nginx virtual host
sudo tee /etc/nginx/sites-available/$username.conf <<EOF
server {
    listen 80;
    server_name $domain;
    root /var/www/$username/public_html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
}
EOF

# Activate configuration and reload Nginx
sudo ln -s /etc/nginx/sites-available/$username.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Set up MariaDB database
sudo mysql -u root -e "CREATE DATABASE $username;"
sudo mysql -u root -e "CREATE USER '$username'@'localhost' IDENTIFIED BY 'password';"  # Replace 'password' with a secure password
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $username.* TO '$username'@'localhost';"

# Download and extract WordPress
cd /var/www/$username/public_html
sudo curl -O https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo rm latest.tar.gz
sudo chown -R $username:$username /var/www/$username/public_html

# Obtain SSL certificate
sudo certbot --nginx -d $domain

# Remind user to set up DNS records and WordPress configuration
echo "Don't forget to:"
echo "1. Create a TXT record with the displayed value in your DNS settings."
echo "2. Point the domain '$domain' to this server's IP address using A records."
echo "3. Visit http://$domain/wp-admin/install.php to complete WordPress setup."
