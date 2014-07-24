sudo apt-get install -y postgresql postgresql-contrib

sudo -u postgres createuser --superuser koding
# this is only valid for Vagrant Env
sudo sed -i "s/timezone =.*/timezone = 'UTC'/" /etc/postgresql/9.3/main/postgresql.conf
sudo sed -i "s/#listen_addresses =.*/listen_addresses = '*'/" /etc/postgresql/9.3/main/postgresql.conf
