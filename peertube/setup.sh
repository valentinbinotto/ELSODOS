#!/bin/bash

sudo apt update
sudo apt install -y curl sudo unzip vim wget
sudo apt install -y nodejs npm
sudo npm install --global yarn
sudo apt install -y python3-dev python3-pip python-is-python3
python --version # Should be >= 3.8
sudo apt install -y certbot nginx ffmpeg postgresql postgresql-contrib openssl g++ make redis-server git cron
ffmpeg -version # Should be >= 4.1
g++ -v # Should be >= 5.x
redis-server --version # Should be >= 6.x
sudo systemctl start redis postgresql
sudo useradd -m -d /var/www/peertube -s /bin/bash -p peertube peertube
sudo passwd peertube # interactive
ls -ld /var/www/peertube # Should be drwxr-xr-x
cd /var/www/peertube
sudo -u postgres createuser -P peertube # password interactive
sudo -u postgres createdb -O peertube -E UTF8 -T template0 peertube_prod
sudo -u postgres psql -c "CREATE EXTENSION pg_trgm;" peertube_prod
sudo -u postgres psql -c "CREATE EXTENSION unaccent;" peertube_prod
VERSION=$(curl -s https://api.github.com/repos/chocobozzz/peertube/releases/latest | grep tag_name | cut -d '"' -f 4) && echo "Latest Peertube version is $VERSION"
cd /var/www/peertube
sudo -u peertube mkdir config storage versions
sudo -u peertube chmod 750 config/
cd /var/www/peertube/versions
# Releases are also available on https://builds.joinpeertube.org/release
sudo -u peertube wget -q "https://github.com/Chocobozzz/PeerTube/releases/download/${VERSION}/peertube-${VERSION}.zip"
sudo -u peertube unzip -q peertube-${VERSION}.zip && sudo -u peertube rm peertube-${VERSION}.zip
cd /var/www/peertube
sudo -u peertube ln -s versions/peertube-${VERSION} ./peertube-latest
cd ./peertube-latest && sudo -H -u peertube yarn install --production --pure-lockfile
cd /var/www/peertube
sudo -u peertube cp peertube-latest/config/default.yaml config/default.yaml
cd /var/www/peertube
sudo -u peertube cp peertube-latest/config/production.yaml.example config/production.yaml
echo 'Now edit config/production.yaml and set webserver, secrets, database-password for postgres, redis, smtp, admin.email'
sudo cp /var/www/peertube/peertube-latest/support/nginx/peertube /etc/nginx/sites-available/peertube
sudo sed -i 's/${WEBSERVER_HOST}/tv.local/g' /etc/nginx/sites-available/peertube
sudo sed -i 's/${PEERTUBE_HOST}/127.0.0.1:9000/g' /etc/nginx/sites-available/peertube
sudo ln -s /etc/nginx/sites-available/peertube /etc/nginx/sites-enabled/peertube
sudo systemctl stop nginx
sudo certbot certonly --standalone --post-hook "systemctl restart nginx" # interactive
sudo systemctl restart nginx
sudo cp /var/www/peertube/peertube-latest/support/sysctl.d/30-peertube-tcp.conf /etc/sysctl.d/
sudo sysctl -p /etc/sysctl.d/30-peertube-tcp.conf
sudo cp /var/www/peertube/peertube-latest/support/systemd/peertube.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable peertube
sudo systemctl start peertube
