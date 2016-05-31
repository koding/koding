#!/usr/bin/env bash

readonly releaseChannel="%RELEASE_CHANNEL%"

readonly osxfuseUrl="http://downloads.sourceforge.net/project/osxfuse/osxfuse-2.8.0/osxfuse-2.8.0.dmg"
readonly virtualBoxUrlLinux="http://download.virtualbox.org/virtualbox/5.0.20/VirtualBox-5.0.20-106931-Linux_amd64.run"
readonly virtualBoxUrlDarwin="http://download.virtualbox.org/virtualbox/5.0.20/VirtualBox-5.0.20-106931-OSX.dmg"
readonly vagrantUrlLinux="https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb"
readonly vagrantUrlDarwin="https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1.dmg"

alias curl='curl -L --retry 5 --retry-delay 0'

isMacosx=$(uname | grep -c 'Darwin')
isVirtualbox=$(VBoxHeadless -h 2>&1 | grep -c 'Oracle VM VirtualBox Headless Interface')
isVagrant=$(vagrant version 2>&1 | grep -c 'Installed Version:')

# prompt_install <install info>
prompt_install() {
  echo
  read -p "${1} [y/N]" -n 1 -r < /dev/tty
  echo

  # default to no
  if [ -z "$REPLY" ]; then
    REPLY="n"
  fi

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  fi

  return 1
}

die() {
  echo $* 1>&2
  exit 1
}

installFuseOnDarwinOnly () {
  if [[ $isMacosx -eq 0 ]]; then
    return 0 # setup fuse on linux?
  fi

  # check if osxfuse is installed already
  if [ -d "/Library/Filesystems/osxfusefs.fs" ]; then
    return
  fi

  fuseDmg=/tmp/osxfuse-2.8.0.dmg

  if ! prompt_install "kd requires osxfuse to work. Do you want to install it now?"; then
    die "Installation failed. Please run the installer again."
  fi

  echo ""
  echo "Downloading osxfuse..."

  # download osxfuse
  if ! curl -o "$fuseDmg" "$osxfuseUrl"; then
    die "error: failed to download OSX Fuse" 2>&1
  fi

  echo

  # attach dmg as a volume
  sudo hdiutil attach "$fuseDmg"

  # run the osxfuse installer
  sudo installer -pkg "/Volumes/FUSE for OS X/Install OSXFUSE 2.8.pkg" -target "/"

  # unmount dmg after it's finished
  diskutil unmount force "/Volumes/FUSE for OS X"

  echo "Created /Library/Filesystems/osxfusefs.fs"
}

installVagrantProviderDeps() {
  if ! prompt_install "VirtualBox and Vagrant are needed in order to build Vagrant stack. Do you want to install them now?"; then
    return
  fi

  installVirtualBox
  installVagrant

  if ! vagrant box list | grep -c ubuntu/trusty64 >/dev/null; then
    vagrant box add ubuntu/trusty64
  fi
}

installVirtualBox() {
  if [[ $isVirtualbox -eq 1 ]]; then
    return 0
  fi

  if [[ ${isMacosx} -eq 0 ]]; then
    installVirtualBoxLinux
  else
    installVirtualBoxDarwin
  fi
}

installVirtualBoxLinux() {
  local vboxRun="/tmp/virtualbox-5.0.20.run"

  if ! curl -i $vboxRun "$virtualBoxUrlLinux"; then
    die "error: failed to download VirtualBox"
  fi

  chmod +x $vboxRun

  if ! sudo $vboxRun; then
    die "error: failed to install VirtualBox"
  fi
}

installVirtualBoxDarwin() {
  local vboxDmg="/tmp/virtualbox-5.0.20.dmg"

  if ! curl -o $vboxDmg "$virtualBoxUrlDarwin"; then
    die "error: failed to download VirtualBox"
  fi

  sudo hdiutil attach $vboxDmg
  sudo installer -pkg "/Volumes/VirtualBox/VirtualBox.pkg" -target /
  diskutil unmount force "/Volumes/VirtualBox"
}

installVagrant() {
  if [[ $isVagrant -eq 1 ]]; then
    return 0
  fi

  if [[ ${isMacosx} -eq 0 ]]; then
    installVagrantLinux
  else
    installVagrantDarwin
  fi
}

installVagrantLinux() {
  local vagrantDeb="/tmp/vagrant-1.8.1.deb"

  if ! curl -o $vagrantDeb "$vagrantUrlLinux"; then
    die "error: failed to download vagrant"
  fi

  if ! sudo dpkg -i $vagrantDeb; then
    die "error: failed to install vagrant"
  fi
}

installVagrantDarwin() {
  local vagrantDmg="/tmp/vagrant-1.8.1.dmg"

  if ! curl -o $vagrantDmg "$vagrantUrlDarwin"; then
    die "error: failed to download vagrant"
  fi

  sudo hdiutil attach $vagrantDmg
  sudo installer -pkg "/Volumes/Vagrant/Vagrant.pkg" -target /
  diskutil unmount force "/Volumes/Vagrant"
}

if [ -z "$1" ]; then
  cat << EOF
The Koding application installer requires an authentication token from
Koding. Please make sure to copy the full command when running this script.

EOF
# Disabled until learn article exists.
#For documentation on this process, please visit the following URL:
#
#    http://learn.koding.com/guides/kd
#
#EOF
  exit 1
fi


echo "Hello, this is the Koding application (kd) installer."
echo "This installer requires sudo permissions, please input password if prompted..."
sudo -l > /dev/null 2> /dev/null
err=$?; if [ "$err" -ne 0 ]; then
    cat << EOF
Error: Sudo (root) permission is required to install kd. Please run this
command from an account on this machine with proper permissions.
EOF
    exit $err
fi


# For now i'm testing on KodingVMs, so i'm allowing KodingVMs
#sudo route del -host 169.254.169.254 reject 2> /dev/null
#routeErr=$?
#awsApiResponse=`curl http://169.254.169.254/latest/dynamic/instance-identity/document --max-time 5 2> /dev/null`
#if [ "$routeErr" -eq 0 ]; then
#    sudo route add -host 169.254.169.254 reject 2> /dev/null
#fi
#if [[ $awsApiResponse == *"614068383889"* ]]; then
#    cat << EOF
#Error: This feature is for non-Koding machines
#EOF
#    exit 1
#fi


# This check helps us prevent kd from being installed over a managed vm
# where kd would have trouble replacing klient in an unknown environment.
#
# TODO: renable this after oldder version of kd has replaced with self
# updateable one.
#
# if sudo [ -f /opt/kite/klient/klient ]; then
  # cat << EOF
# Error: Klient is already installed. Please remove it before installing kd.
# If you are attempting to update kd, please run the following command:

    # sudo kd update
# EOF
  # exit 1
# fi


# TODO: Support both wget and curl
which curl > /dev/null
err=$?; if [ "$err" -ne 0 ]; then
  echo "Error: curl is required to install kd. Please install curl and run this installer again."
  exit 1
fi


# Stop kd.
# TODO: remove this
if which kd > /dev/null; then
  sudo kd stop      > /dev/null 2>&1
  sudo kd uninstall > /dev/null 2>&1
fi

version=$(curl -sSL https://koding-kd.s3.amazonaws.com/${releaseChannel}/latest-version.txt)

platform=`uname | tr '[:upper:]' '[:lower:]'`
case "$platform" in
  darwin|linux)
    installDir="/usr/local/bin"

    # On some OSX systems, /usr/local/bin doesn't seem to exist. Create it.
    if sudo [ ! -d "$installDir" ]; then
      sudo mkdir -p $installDir
      # /usr/local/bin is normally chowned as `user:admin`,
      # eg: `jake:admin` on osx
      if [ -n "$USER" ]; then
        sudo chown $USER $installDir
      fi
      echo "Created $installDir"
    fi

    echo ""
    echo "Downloading kd..."


  sudo curl -SLo /usr/local/bin/kd.gz "https://koding-kd.s3.amazonaws.com/${releaseChannel}/kd-0.1.${version}.${platform}_amd64.gz"
    err=$?; if [ "$err" -ne 0 ]; then
      cat << EOF
Error: Failed to download kd binary. Please check your internet
connection or try again.
EOF
      exit 1
    fi

  if ! sudo gzip -d -f /usr/local/bin/kd.gz; then
    echo "Error: Failed to extract kd binary." 2>&1
    exit 1
  fi

  sudo rm -f /usr/local/bin/kd.gz
  sudo chmod +x /usr/local/bin/kd

  echo "Created /usr/local/bin/kd"

  if [[ "$platform" == "darwin" ]]; then
    # Ensure old klient is not running.
    sudo launchctl unload -w /Library/LaunchDaemons/com.koding.klient &>/dev/null || true
    rm -f /Library/LaunchDaemons/com.koding.klient &>/dev/null || true

    # Check if fuse is needed, and install it if it is.
    installFuseOnDarwinOnly
  fi

  installVagrantProviderDeps

  echo
  ;;
  windows)
    cat << EOF
Error: This platform is not supported at this time.
EOF
    exit 2
    ;;
  *)
    cat << EOF
Error: Failed to identify which platform you are installing from.
EOF
    exit 2
    ;;
esac


kontrolFlag=""
if [ -n "$KONTROLURL" ]; then
  echo "Installing with custom Kontrol Url... '$KONTROLURL'"
  kontrolFlag="--kontrol=$KONTROLURL"
fi

# No need to print Creating foo... because kd install handles that.

# Install klient, piping stdin (the tty) to kd
if ! sudo kd install $kontrolFlag "$1" < /dev/tty; then
  exit $err
fi


cat << EOF
Success! kd (version ${version}, channel ${releaseChannel}) has been successfully installed.
Please run the following command for more information:

    kd -h

EOF

kiteQueryID=$(kd version 2>/dev/null | grep 'Kite Query ID' | cut -d: -f 2 | tr -s ' ')

if [[ $isVirtualbox -eq 0 && $isVagrant -eq 0 ]]; then
  cat << EOF
No VirtualBox nor Vagrant is present on your system. In order to use local provisioning
with Vagrant provider ensure they are installed:

    * VirtualBox 5.0+ (https://www.virtualbox.org/wiki/Downloads)
    * Vagrant 1.7.4+ (https://www.vagrantup.com/downloads.html)

EOF

elif [[ $isVirtualbox -eq 0 ]]; then
  cat << EOF
No VirtualBox is present on your system. In order to use local provisioning
with Vagrant provider ensure it is installed:

    * VirtualBox 5.0+ (https://www.virtualbox.org/wiki/Downloads)

EOF

elif [[ $isVagrant -eq 0 ]]; then
  cat << EOF
No Vagrant is present on your system. In order to use local provisioning
with Vagrant provider ensure it is installed:

    * Vagrant 1.7.4+ (https://www.vagrantup.com/downloads.html)

EOF

fi

if [[ -n "$kiteQueryID" ]]; then
  cat << EOF
Your Kite Query ID, which you can use as a credential for local provisioning, is:

    $kiteQueryID

EOF
fi
