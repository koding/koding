#!/bin/bash

# remove .ssh directories for all users
# since a user may have home outside /home,
# we need to lookup it first
cut -d: -f1 /etc/passwd |
while read username; do
	eval echo ~$username |
	while read homedir; do
		if [[ -x "${homedir}/.ssh" ]]; then
			rm -rf "${homedir}/.ssh"
		fi
	done
done

# add kloud key for root
mkdir -p /root/.ssh
chmod 644 /root/.ssh
cat >/root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCwAxo9snzynloid3J1pif7obIYHqWcjr1Q2/QTHkjDP3sC/4wMhIGxBAs07YkaUEZ0je1cH9IIU07KbFsOg4Rx9MlOVouhJ8GsjxuYTSGs1WzeLJ4oGLrMIwipEK+RhiA8kEyGKyKGQLTbrbHSzXYF4S8lxJaitE7Vfg4yNZEb8x5G1Wysi/GewanvQDytn5UhOBUqVU4PTeVi/D1YeVrXKtol7hTNRtsw1aRUIGnqskEp4LkuQKCY71rcfbIkjfa/GsaF04/4My0+DBIZAYOkgghDA8ROZPFyvB75JDrJGVG/keh3DtX4sl/XjGjTvOBosRVesCK13RtDpEe6sYS0rtg1iCqv5bimxbKAqBqHJkOjPB7Xo+7I5k1dvVm49Ktq6hFHMzGA/2cnotIYE9KHeAjnnYdBxjygSb7f8pnV4FfFkJ9m42GdRXy+lYewEXHz99GT84ExdpuNrI1mDobDyRDPmBJqmvlq6U8mxwBz0pXjRbpYJxe4iyCkEqTbCK5T8YHSBp4OE201Fkub4Z/bOlhG0WTBq2otHxx61AcscH+cSPZHaDSi8ebUGwWM4E8E5Hu0DXuCP3+1tcvct9FQxpvMVHG2zo+jHTlxSkfzvzPhGjWJbFloEG0Ri2cJAkfO0q7H/i2aPPyC4Ez8brRz+eoNujGBVk+KZG2a4ITfEQ== hello@koding.com
EOF
chmod 600 /root/.ssh/authorized_keys

# remove all other keys and restart openssh-server
/bin/rm -rf /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

for i in /home/*; do
	user=$(basename "$i")
	echo "reseting password for user $user"
	( echo Ao3kenoibi6U; echo Ao3kenoibi6U ) | passwd "$user"
done

restart ssh
