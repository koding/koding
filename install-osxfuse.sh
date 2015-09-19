#!/bin/sh

if [[ ! "$(uname -s)" = "Darwin" ]]; then
  echo "This installer script is only required for Mac OSX. Linux comes with Fuse."
  exit 1
fi

if [[ -d "/Library/Filesystems/osxfusefs.fs" ]]; then
  echo "Fuse already installed...exiting."
  exit 0
fi

# download osxfuse
curl -L "http://downloads.sourceforge.net/project/osxfuse/osxfuse-2.8.0/osxfuse-2.8.0.dmg" > osxfuse-2.8.0.dmg

# attach dmg as a volume
sudo hdiutil attach osxfuse-2.8.0.dmg

# run the installer
cd "/Volumes/FUSE for OS X"
sudo installer -pkg "Install OSXFUSE 2.8.pkg" -target "/Volumes/Macintosh HD"

# unmount dmg after it's finished
diskutil unmount force "/Volumes/FUSE for OS X"
