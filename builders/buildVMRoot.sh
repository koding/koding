#!/bin/sh
[ -n "$DEBUG" ] && set -o xtrace
set -o nounset
set -o errexit
shopt -s nullglob

# packages are installed with debootstrap
# additional packages are installed later on with apt-get
packages="ssh,curl,iputils-ping,iputils-tracepath,telnet,vim,rsync"
additional_packages="lighttpd htop sudo net-tools"
suite="quantal"
variant="buildd"
target="/var/lib/lxc/vmroot/rootfs"
VM_upstart="/etc/init"

mirror="http://10.158.65.166/ubuntu/"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!" 1>&2
   exit 1
fi

function debootstrap() {
  if [ -d $target ]
  then
    read -p "Target directory $target already exists. Erase it? [Ny] "
    if [[ $REPLY =~ ^[Yy].*$ ]]
    then
      lxc-stop -n vmroot
      rm -rf $target
    else
      echo "Aborting..."
      exit 1
    fi
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
   run_in_vmroot /usr/bin/rename s/\.conf/\.conf\.disabled/ $VM_upstart/mountall*;
   run_in_vmroot /bin/mv $VM_upstart/ssh.conf $VM_upstart/ssh.conf.disabled;
   run_in_vmroot /bin/mv $VM_upstart/console.conf $VM_upstart/console.conf.disabled;
}

debootstrap

write "etc/apt/sources.list" <<-EOS
deb $mirror $suite main universe multiverse
deb $mirror $suite-updates main universe multiverse
deb $mirror $suite-security main universe multiverse
EOS

./idshift $target;

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
run_in_vmroot /usr/bin/apt-get install $additional_packages -y

