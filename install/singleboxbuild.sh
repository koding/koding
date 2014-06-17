if [[ -n $1 ]]; then
  echo $1 >/etc/hostname
  hostname $1
else
  HOSTNAME=`hostname`
fi

read -p "Hostname is `hostname` - Press [Enter] key to continue install..."


echo "127.0.0.1 "$HOSTNAME >> /etc/hosts

echo '#!/bin/sh -e' >/etc/rc.local
echo "iptables -F" >>/etc/rc.local
echo "iptables -A INPUT -i lo -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 208.72.139.54 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 208.87.56.148 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -s 12.130.117.34 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -p tcp --dport 4000 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -p tcp --dport 3999 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -p tcp --dport 3000 -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT" >>/etc/rc.local
echo "iptables -A INPUT -j DROP" >>/etc/rc.local
/etc/rc.local

echo "export GOPATH=/opt/koding/go" >> /etc/profile
source /etc/profile

echo "UTC" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

mkdir -p /root/.ssh

echo "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAxJUfKx05K3kymTkgISnFOoh1PY/jJ3dlUnAUE8WqCXlDQi+C
FIJO+pKGNNyo8z2fF43iCGfc9h3a0qvhvyWY4f6tkllSBdWLWwV2O8edRJXIwMyu
ku8SIXeNg0Qg0+iqZKUZJEnv6MSUcDNejFS0AVz4Dw3pSfLT+xTEWD4j9hM6I8BQ
qEYM2wqkyqjjIVS0bGQE0buohLiWymI4J95B5MbKuofo5eAUxkFOA+vTt66RSbWB
BAFVg0jIDMJ4bXU28JBO8GXt0N7GkpLRPd1IEjoJ8d0iKghT6KMtwzEWyr2k6Qta
3FybcFbjhKJneitK+ln5BXiU917p3cYAG3xRDwIDAQABAoIBACyBKiZDnm7GKHth
4HFBmKIwxIIkciO8Nxcbwp/bTyyH5H82bDeibKjzxShwkFtJJxxZBcQrZ23cwm6R
dTEmHN+FHdyVFim196+qo+LSxTsCwglMDXW8ZBlpjIMcSGZRNUpFylRZ3NOQtZ5V
MuGIR5xLZOlbl+Yi8HTWdcEYiGGsAPemKTaalSAK91ak1kkb0wDpUJU/NK01glSk
HqqsUAzmGmd19VLJhRRKNVpGbI+zhJbgl7rn0CynTdJDDtuwYwQZYjxtHDp3/UiW
lLkBToe74L7WrNH6ZZgCCFDFx9nUAnbHPEvh6vnN5s+Ce46F69pKWihvBEyH23UT
8wzl3IECgYEA7AnHjlK0buZLJr1IQ5YD8vd7LIK7wwHeaPOh+dhZrvn3twfibSRu
55ew/2wmd/E5yyzgdDBGQCjPKwfs/2FnPg01KlMObAkGn0KG8j0/NecQdlv9PJgv
lriLY7rm5O40aKMevdQ3PinvkS+KTUdbd6GfVyC77zh9HnIhW2xllc8CgYEA1TUg
pzKQSwn8fxyKctKFf+4QEogdUPIWLgJCF8kgJGaSAl1r/wwEbQIhF8SeTEL199Cm
5uk8w6oGlsNbPgZkF8PBuwFS3x2cbIbC+/HdWZmiPmx96o/pEZ9sWKQyX46nN9es
5HqxULgB0m/9AxzAtFZTwV5pBWkXdIwBQuyroMECgYEAwB7JpeddY7Lg0nxYeGJ/
fmC/iiAy8evwet5rJbBadxiQ7xJk009HUgvfDleaDCB1WRGC9C9iztAop67A0bEX
VqNrdbK612aVVEXTDxKZA6e6d4wyWALLIVO+aQN08juMvuqemAZGnLuHelYGrRX6
tioARuum7HS/KmvdCMv293MCgYEAhS8x3aAFaQqs8w52IfIGOPsSiTED9yuy1TzN
4qPd8z8rmFSZgPIV1a6N05YcOJFfq1Vo3Tf3oFaW1Rjl52IApqO/Yj0acovByj2I
ke/tkOoa4pnNMniBZGPNP7YaTX0EUirlMri+CSlY4gbY61fLvRtsKI/8VMfoQgKv
Swoi0EECgYAHjz0jBVfpGLkkYAcaYOMcV4yFxkax4ZiuBMK4TcsrL6/KiietjmdK
mxiIASXhNP0ZEEdAHgBr6o3EQHnJksXo7VTTBRcXOSmE7httIRrOC06qAB0kV4Ub
qoNO+NWbDkfJB/YtKtRdUtW6QmmdUHowT10TZH24Ig7CdrdrV46X3A==
-----END RSA PRIVATE KEY-----" >/root/.ssh/id_rsa

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDElR8rHTkreTKZOSAhKcU6iHU9j+Mnd2VScBQTxaoJeUNCL4IUgk76koY03KjzPZ8XjeIIZ9z2HdrSq+G/JZjh/q2SWVIF1YtbBXY7x51ElcjAzK6S7xIhd42DRCDT6KpkpRkkSe/oxJRwM16MVLQBXPgPDelJ8tP7FMRYPiP2EzojwFCoRgzbCqTKqOMhVLRsZATRu6iEuJbKYjgn3kHkxsq6h+jl4BTGQU4D69O3rpFJtYEEAVWDSMgMwnhtdTbwkE7wZe3Q3saSktE93UgSOgnx3SIqCFPooy3DMRbKvaTpC1rcXJtwVuOEomd6K0r6WfkFeJT3XundxgAbfFEP ubuntu@kodingme" >/root/.ssh/id_rsa.pub

echo "|1|KJ2CvsrRClkfR52SKkmi6wJGks8=|AKgtdjkpxcLBoZ5PPC/eIukHYs0= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGvN9gZ2BtULXGo3fMaZJgbbNbsED7KEirN+KwPso82ydiO9jeVDQ/feNR5xH6/lqiuDZCA7mZek/njpWxeAYBk=
|1|lXvT04jC94yCSNAkFiYqkNyx9o8=|cT9C1yYSCWkDqY/601HucfBjMOw= ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGvN9gZ2BtULXGo3fMaZJgbbNbsED7KEirN+KwPso82ydiO9jeVDQ/feNR5xH6/lqiuDZCA7mZek/njpWxeAYBk=" >>/root/.ssh/known_hosts

echo "Host github.com" >> ~/.ssh/config
echo "  StrictHostKeyChecking no" >> ~/.ssh/config

chmod 600 /root/.ssh/id_rsa


apt-get update
apt-get install -y golang nodejs npm git mongodb graphicsmagick
cp /usr/bin/nodejs /usr/bin/node


### redis install ###
apt-add-repository -y ppa:chris-lea/redis-server
apt-get install -y redis-server
#####################

### RABBITMQ INSTALL ###
apt-get install -y rabbitmq-server=3.2.4-1
########################


cd /opt
git clone git@git.sj.koding.com:koding/koding.git
cd koding
git checkout cake-rewrite
git submodule init
git submodule update
npm i gulp stylus coffee-script -g
npm i --unsafe-perm


### Kontrol key initialization #####
go run /opt/koding/go/src/github.com/koding/kite/kontrol/kontrol/main.go -init -public-key /opt/koding/certs/test_kontrol_rsa_public.pem -private-key /opt/koding/certs/test_kontrol_rsa_private.pem -username koding  -kontrol-url "ws://$HOSTNAME:4000"

### rabbit x-presence ###
cp /opt/koding/install/rabbit_presence_exchange-3.2.3-20140220.ez /usr/lib/rabbitmq/lib/rabbitmq_server-3.2.4/plugins/
rabbitmq-plugins enable rabbit_presence_exchange
service rabbitmq-server restart
#########################





cd /opt/koding
cake -c kodingme -r kodingme buildEverything
# make now wraps cake run.
# cake -c kodingme -r kodingme run

### SOCIAL API ###
bash ./go/src/socialapi/db/sql/definition/install.sh
bash ./go/src/socialapi/db/sql/definition/create.sh
sed -i "s/#timezone =.*/timezone = 'UTC'/" /etc/postgresql/9.3/main/postgresql.conf
service postgresql restart
cd /opt/koding/go/src/socialapi/
make configure
make develop -j
##################



