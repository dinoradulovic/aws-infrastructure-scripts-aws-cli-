#!/bin/bash

# Install NVM
mkdir $HOME/.nvm
export NVM_DIR="$HOME/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
cat <<EOF >> /home/ec2-user/.bashrc
export NVM_DIR="/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
EOF


# Install Node
nvm install node
node -e "console.log('Running Node.js ' + process.version)"

# Install PM2
npm install pm2 -g

# Install NGINX
sudo amazon-linux-extras install epel
sudo yum -y install nginx

# Configure NGINX
touch /etc/nginx/conf.d/api.example.com.conf
IP_ADDRESS=$(curl -s https://checkip.amazonaws.com/)
cat  > /etc/nginx/conf.d/api.example.com.conf <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name $IP_ADDRESS;

  location / {
    proxy_pass "http://localhost:3000/";
  }

  # redirect server error pages to the static page /40x.html

  error_page 404 /404.html;
  location = /40x.html {
  }

  # redirect server error pages to the static page /50x.html
  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
  }
}
EOF

# Start NGINX
sudo systemctl start nginx
