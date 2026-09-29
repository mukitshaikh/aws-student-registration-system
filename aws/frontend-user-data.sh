#!/bin/bash
set -e

apt update -y
apt install -y nginx git nodejs npm

cd /opt
git clone https://github.com/mukitshaikh/student-registration-aws.git
cd /opt/student-registration-aws/frontend

cat > .env <<ENV
VITE_API_URL=/api
ENV

npm install
npm run build

rm -rf /var/www/html/*
cp -r dist/* /var/www/html/

cat > /etc/nginx/sites-available/default <<'NGINX'
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://internal-studentapp-backend-alb-1639984916.us-east-1.elb.amazonaws.com:8080/api/;

        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

nginx -t
systemctl enable nginx
systemctl restart nginx
