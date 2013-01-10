[ -n "$DEBUG" ] && set -o xtrace
set -o nounset
set -o errexit
shopt -s nullglob

# packages are installed with debootstrap
# additional packages are installed later on with apt-get
packages="ssh,curl,iputils-ping,iputils-tracepath,telnet,vim,rsync"
additional_packages="lighttpd htop iotop iftop nodejs nodejs-legacy php5-cgi \
                     erlang ghc swi-prolog clisp ruby ruby-dev ri rake golang python \
                     mercurial git subversion cvs bzr \
                     fish sudo net-tools wget aptitude emacs \
                     ldap-auth-client nscd"
suite="quantal"
variant="buildd"
target="/var/lib/lxc/vmroot/rootfs"
VM_upstart="/etc/init"

mirror="http://ftp.halifax.rwth-aachen.de/ubuntu/"

# Make sure only root can run our script
#if [[ $EUID -ne 0 ]]; then
#   echo "This script must be run as root!" 1>&2
#   exit 1
#fi

function debootstrap() {
   if [ -d $target ]
   then
    echo "Target exists... stopping vmroot VM and deleting old VMRoot dir"
    lxc-stop -n vmroot;
    sleep 1;
    rm -rf $target;
   fi

  $(which debootstrap) --include $packages --variant=$variant $suite $target $mirror
}

function write() {
  [ -z "$1" ] && return 1

  mkdir -p $target/$(dirname $1)
  cat > $target/$1
}

function run_in_vmroot() {
  echo "lxc-attach -n vmroot -- $@";
  lxc-attach -n vmroot -- $@;
}

#function chroot() {
#  $(which chroot) $target env -i $(cat $target/etc/environment) /bin/bash
#}

function configure_upstart() {
   run_in_vmroot /usr/bin/rename s/\.conf/\.conf\.disabled/ $VM_upstart/tty*;
   run_in_vmroot /usr/bin/rename s/\.conf/\.conf\.disabled/ $VM_upstart/udev*;
   run_in_vmroot /usr/bin/rename s/\.conf/\.conf\.disabled/ $VM_upstart/upstart-*;
   # run_in_vmroot /usr/bin/rename s/\.conf/\.conf\.disabled/ $VM_upstart/mountall*;
   run_in_vmroot /bin/mv $VM_upstart/ssh.conf $VM_upstart/ssh.conf.disabled;
   # run_in_vmroot /bin/mv $VM_upstart/console.conf $VM_upstart/console.conf.disabled;
}

debootstrap

write "etc/apt/sources.list" <<-EOS
deb $mirror $suite main universe multiverse
deb $mirror $suite-updates main universe multiverse
deb $mirror $suite-security main universe multiverse
EOS

/opt/koding/go/bin/idshift $target;

# Disable interactive dpkg
#chroot <<-EOS
#echo debconf debconf/frontend select noninteractive |
# debconf-set-selections
#EOS
lxc-start -n vmroot -d;
echo waiting for VM to wake up....;
sleep 5;

# Generate and setup default locale (en_US.UTF-8)
echo "Fixing locale";
run_in_vmroot /usr/sbin/locale-gen en_US.UTF-8;
run_in_vmroot /usr/sbin/update-locale LANG="en_US.UTF-8";

#Modify fstab so lxc will start
/bin/sed -i 's!none            /sys/fs/fuse/connections!#none            /sys/fs/fuse/connections!' $target/lib/init/fstab
/bin/sed -i 's!none            /sys/kernel/!#none            /sys/kernel/!' $target/lib/init/fstab

configure_upstart;
lxc-stop -n vmroot;
sleep 1;
lxc-start -n vmroot -d;
sleep 5;

# Set hostname
run_in_vmroot /bin/hostname vmroot
# Update packages
echo "Doing APT-GET Stuff"
run_in_vmroot /usr/bin/apt-get update
export DEBIAN_FRONTEND=noninteractive
run_in_vmroot /usr/bin/apt-get install $additional_packages -y -qq
# Install Sun Java
run_in_vmroot /bin/mkdir -p /usr/share/update-sun-jre
run_in_vmroot /usr/bin/wget http://www.duinsoft.nl/pkg/pool/all/update-sun-jre.bin -O /root/update-sun-jre.bin
run_in_vmroot /bin/sh /root/update-sun-jre.bin
# Use LDAP server for lookup
run_in_vmroot /usr/sbin/auth-client-config -t nss -p lac_ldap

