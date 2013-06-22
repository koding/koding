apt-get remove apparmor -f
update-rc.d -f apache2 remove
rm /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
touch /opt/runner && chmod 755 /opt/runner && ln -s /opt/runner /etc/init.d/runner && update-rc.d runner defaults