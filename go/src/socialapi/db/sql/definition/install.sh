sudo add-apt-repository ppa:pitti/postgresql
sudo apt-get update
sudo apt-get -y install postgresql postgresql-contrib

sudo -u postgres createuser --superuser koding
# this is only valid for Vagrant Env
sudo sed -i "s/timezone =.*/timezone = 'UTC'/" /etc/postgresql/9.3/main/postgresql.conf
sudo sed -i "s/#listen_addresses =.*/listen_addresses = '*'/" /etc/postgresql/9.3/main/postgresql.conf
sudo echo "host    all             all             192.0.0.1/10            md5" >> /etc/postgresql/9.3/main/pg_hba.conf
sudo echo "host    all             all             10.0.0.1/10             md5" >> /etc/postgresql/9.3/main/pg_hba.conf

sudo service postgresql restart
