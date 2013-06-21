#!/bin/bash

# these are supposed to be run in vagrant...
grep 'local.koding.com' /etc/hosts
if [ $? -ne 0 ]
then echo "192.168.1.250 local.koding.com" >> /etc/hosts
fi

# vmroot needs the address too
grep 'local.koding.com' /var/lib/lxc/vmroot/rootfs/etc/hosts
if [ $? -ne 0 ]
then echo "192.168.1.250 local.koding.com" >> /var/lib/lxc/vmroot/rootfs/etc/hosts
fi

if [ ! -f /var/lib/lxc/vmroot/config-template ]; then 
    cp /opt/koding/kites/bin/lxc-config-template /var/lib/lxc/vmroot/config-template
fi

# fix vmroot config
cp /var/lib/lxc/vmroot/config-template /var/lib/lxc/vmroot/config
sed -i "s/#NAME#/vmroot/" /var/lib/lxc/vmroot/config
sed -i "s/#IP#/2/" /var/lib/lxc/vmroot/config

cp /opt/koding/kites/bin/create-lxc /usr/sbin/create-lxc

# copy .kd folder to vmroot
cp -vr /root/.kd /var/lib/lxc/vmroot/rootfs/root/

cd /opt/kd && npm link

# copy kd directory to vm root
cp -vr /opt/kd /var/lib/lxc/vmroot/rootfs/usr/lib/node_modules/

cp /opt/koding/kites/bin/deployer /usr/bin/deployer && chmod 755 /usr/bin/deployer

cp /opt/koding/kites/bin/prepare-vmroot.sh /var/lib/lxc/vmroot/rootfs/opt/
lxc-start -n vmroot "/opt/prepare-vmroot.sh"

echo "\n"
echo "now you can run /usr/bin/deployer"

