#!/usr/bin/env bash

installFuseOnDarwinOnly () {
  if [ ! "$(uname -s)" = "Darwin" ]; then
    return
  fi

  # check if osxfuse is installed already
  if [ -d "/Library/Filesystems/osxfusefs.fs" ]; then
    return
  fi

  fuseDmg=/tmp/osxfuse-2.8.0.dmg

  echo ""
  read -p "kd requires osxfuse to work. Do you want to install it now? [y/N]" -n 1 -r < /dev/tty
  echo ""

  # default to no
  if [ -z "$REPLY" ]; then
    REPLY="n"
  fi

  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Installation failed. Please run the installer again."
    exit 1
  fi

  echo ""
  echo "Downloading osxfuse..."

  # download osxfuse
  curl -L -o "$fuseDmg" "http://downloads.sourceforge.net/project/osxfuse/osxfuse-2.8.0/osxfuse-2.8.0.dmg"
  err=$?; if [ "$err" -ne 0 ]; then
    echo "Error: Failed to download OSX Fuse."
    exit 1
  fi

  echo ""

  # attach dmg as a volume
  sudo hdiutil attach "$fuseDmg"

  # run the osxfuse installer
  sudo installer -pkg "/Volumes/FUSE for OS X/Install OSXFUSE 2.8.pkg" -target "/"

  # unmount dmg after it's finished
  diskutil unmount force "/Volumes/FUSE for OS X"

  echo "Created /Library/Filesystems/osxfusefs.fs"
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

    sudo curl -SLo /usr/local/bin/kd "https://koding-kd.s3.amazonaws.com/klientctl-$platform"
    err=$?; if [ "$err" -ne 0 ]; then
      cat << EOF
Error: Failed to download kd binary. Please check your internet
connection or try again.
EOF
      exit 1
    fi

    sudo chmod +x /usr/local/bin/kd

    echo "Created /usr/local/bin/kd"

    # Check if fuse is needed, and install it if it is.
    installFuseOnDarwinOnly
    echo ""
    ;;
  windows|linux)
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
sudo kd install $kontrolFlag "$1" < /dev/tty
err=$?; if [ "$err" -ne 0 ]; then
  exit $err
fi


cat << EOF
Success! kd has been successfully installed. Please run the
following command for more information:

    kd -h

EOF
