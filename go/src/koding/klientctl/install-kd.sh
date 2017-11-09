#!/usr/bin/env bash

readonly releaseChannel="%RELEASE_CHANNEL%"

readonly OSXFUSE_URL="https://s3.amazonaws.com/koding-dl/osxfuse-3.5.2.dmg"
readonly VIRTUALBOX_URL_LINUX="http://download.virtualbox.org/virtualbox/5.1.8/VirtualBox-5.1.8-111374-Linux_amd64.run"
readonly VIRTUALBOX_URL_DARWIN="http://download.virtualbox.org/virtualbox/5.1.8/VirtualBox-5.1.8-111374-OSX.dmg"
readonly VAGRANT_URL_LINUX="https://releases.hashicorp.com/vagrant/1.8.7/vagrant_1.8.7_x86_64.deb"
readonly VAGRANT_URL_DARWIN="https://releases.hashicorp.com/vagrant/1.8.7/vagrant_1.8.7.dmg"

VERSION="$(curl -sSL https://koding-kd.s3.amazonaws.com/${releaseChannel}/latest-version.txt)"
PLATFORM="$(uname | tr '[:upper:]' '[:lower:]')"
KD_URL="https://koding-kd.s3.amazonaws.com/${releaseChannel}/kd-0.1.${VERSION}.${PLATFORM}_amd64.gz"

is_virtualbox() {
  VBoxHeadless -h 2>&1 | grep -c 'Oracle VM VirtualBox Headless Interface' >/dev/null
}

is_vagrant() {
  vagrant version 2>&1 | grep -c 'Installed Version:' >/dev/null
}

# download_file <url> <output file>
download_file() {
  curl --location --retry 5 --retry-delay 0 --output "$2" "$1"
}

# prompt_install <install info>
prompt_install() {
  if [ -z ${KD_NONINTERACTIVE:-} ]; then
    echo
    read -p "${1} [y/N] " -n 1 -r < /dev/tty
    echo
  else
    REPLY=$KD_NONINTERACTIVE
  fi

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

install_fuse_darwin() {
  local fuseDir="/Library/Filesystems/osxfuse.fs"
  local fuseDmg=/tmp/osxfuse.dmg

  if [[ $PLATFORM == "linux" ]]; then
    return 0 # setup fuse on linux?
  fi

  # check if osxfuse is installed already
  if [ -d "$fuseDir" ]; then
    return
  fi

  if ! prompt_install "kd requires osxfuse to work. Do you want to install it now?"; then
    die "Installation failed. Please run the installer again."
  fi

  echo ""
  echo "Downloading osxfuse..."

  # download osxfuse
  if ! download_file "$OSXFUSE_URL" "$fuseDmg"; then
    die "error: failed to download OSX Fuse" 2>&1
  fi

  echo

  # attach dmg as a volume
  sudo hdiutil attach $fuseDmg

  # run the osxfuse installer
  sudo installer -pkg "/Volumes/FUSE for macOS/Extras/FUSE for macOS 3.5.2.pkg" -target "/"

  # unmount dmg after it's finished
  diskutil unmount force "/Volumes/FUSE for macOS"

  rm -f "$fuseDmg"

  echo "Created $fuseDir"
}

install_vagrant_deps() {
  if ! prompt_install "VirtualBox and Vagrant are needed in order to build Vagrant stack. Do you want to install them now?"; then
    return
  fi

  install_virtualbox
  install_vagrant

  if ! vagrant box list | grep ubuntu/trusty64 >/dev/null; then
    vagrant box add ubuntu/trusty64
  fi
}

install_virtualbox() {
  if is_virtualbox; then
    return 0
  fi

  case "$PLATFORM" in
  linux)
      install_virtualbox_linux
    ;;
  darwin)
      install_virtualbox_darwin
    ;;
  *)
    die "error: platform not supported: $PLATFORM"
    ;;
  esac
}

install_virtualbox_linux() {
  local vboxRun="/tmp/virtualbox.run"

  if command -v apt-get >/dev/null; then
    sudo apt-get install -q -y dkms linux-headers-$(uname -r) make build-essential screen
  fi

  if ! download_file "$VIRTUALBOX_URL_LINUX" "$vboxRun"; then
    die "error: failed to download VirtualBox"
  fi

  chmod +x "$vboxRun"

  if ! sudo "$vboxRun"; then
    die "error: failed to install VirtualBox"
  fi

  rm -f "$vboxRun"
}

install_virtualbox_darwin() {
  local vboxDmg="/tmp/virtualbox.dmg"

  if ! download_file "$VIRTUALBOX_URL_DARWIN" "$vboxDmg"; then
    die "error: failed to download VirtualBox"
  fi

  sudo hdiutil attach "$vboxDmg"
  sudo installer -pkg "/Volumes/VirtualBox/VirtualBox.pkg" -target /
  diskutil unmount force "/Volumes/VirtualBox"

  rm -f "$vboxDmg"
}

install_vagrant() {
  if is_vagrant; then
    return 0
  fi

  case "$PLATFORM" in
  linux)
    install_vagrant_linux
    ;;
  darwin)
    install_vagrant_darwin
    ;;
  *)
    die "error: platform not supported: $PLATFORM"
    ;;
  esac
}

install_vagrant_linux() {
  local vagrantDeb="/tmp/vagrant.deb"

  if ! download_file "$VAGRANT_URL_LINUX" "$vagrantDeb"; then
    die "error: failed to download vagrant"
  fi

  if ! sudo dpkg -i "$vagrantDeb"; then
    die "error: failed to install vagrant"
  fi

  rm -f "$vagrantDeb"
}

install_vagrant_darwin() {
  local vagrantDmg="/tmp/vagrant.dmg"

  if ! download_file "$VAGRANT_URL_DARWIN" "$vagrantDmg"; then
    die "error: failed to download vagrant"
  fi

  sudo hdiutil attach "$vagrantDmg"
  sudo installer -pkg "/Volumes/Vagrant/Vagrant.pkg" -target /
  diskutil unmount force "/Volumes/Vagrant"

  # Workaround for Vagrant 1.8.7, which fails to "box add".
  sudo rm -f /opt/vagrant/embedded/bin/curl || true

  rm -f "$vagrantDmg"
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
if ! sudo -l 2>&1 >/dev/null; then
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
if ! which curl &>/dev/null; then
  echo "Error: curl is required to install kd. Please install curl and run this installer again."
  exit 1
fi


case "$PLATFORM" in
  darwin|linux)
    installDir="/usr/local/bin"
    kdFile="/tmp/kd"
    kdGz="${kdFile}.gz"

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

    echo
    echo "Downloading kd..."

    if ! download_file "$KD_URL" "$kdGz"; then
      cat << EOF
Error: Failed to download kd binary. Please check your internet
connection or try again.
EOF
      exit 1
    fi

    if ! sudo gzip -d -f "$kdGz"; then
      echo "Error: Failed to extract kd binary." 2>&1
      exit 1
    fi

    sudo chmod +x $kdFile

    # TODO(rjeczalik): revisit if we really need to uninstall
    # or whether install should handle overwrite instead
    sudo $kdFile stop > /dev/null 2>&1
    sudo $kdFile uninstall > /dev/null 2>&1

    sudo mv $kdFile "${installDir}/kd"

    echo "Created ${installDir}/kd"

    if [[ "$PLATFORM" == "darwin" ]]; then
      # Ensure old klient is not running.
      sudo launchctl unload -w /Library/LaunchDaemons/com.koding.klient &>/dev/null || true
      rm -f /Library/LaunchDaemons/com.koding.klient &>/dev/null || true

      # Check if fuse is needed, and install it if it is.
      install_fuse_darwin
    fi

    if ! is_virtualbox || ! is_vagrant; then
      install_vagrant_deps
    fi

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

kontrolFlag="--baseurl=https://sandbox.koding.com"

if [ "$releaseChannel" = "production" ]; then
  kontrolFlag="--baseurl=https://koding.com"
fi

if [ -n "$KONTROLURL" ]; then
  echo "Installing with custom Kontrol Url... '$KONTROLURL'"
  kontrolFlag="--baseurl=${KONTROLURL%/kontrol/kite}"
fi

# Ignore false negative.
#
# shellcheck disable=SC2024
if ! sudo /usr/local/bin/kd install $kontrolFlag --token "$1" < /dev/tty; then
  exit $err
fi

cat << EOF
Success! kd (version ${VERSION}, channel ${releaseChannel}) has been successfully installed.
Please run the following command for more information:

    kd -h

EOF

kiteQueryID=$(kd version 2>/dev/null | grep 'Kite Query ID' | cut -d: -f 2 | tr -s ' ')

if ! is_virtualbox && ! is_vagrant; then
  cat << EOF
No VirtualBox nor Vagrant is present on your system. In order to use local provisioning
with Vagrant provider ensure they are installed:

    * VirtualBox 5.0+ (https://www.virtualbox.org/wiki/Downloads)
    * Vagrant 1.7.4+ (https://www.vagrantup.com/downloads.html)

EOF

elif ! is_virtualbox; then
  cat << EOF
No VirtualBox is present on your system. In order to use local provisioning
with Vagrant provider ensure it is installed:

    * VirtualBox 5.0+ (https://www.virtualbox.org/wiki/Downloads)

EOF

elif ! is_vagrant; then
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
