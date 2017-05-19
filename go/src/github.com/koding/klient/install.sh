#!/usr/bin/env bash


if [[ ! "$(uname)" = "Linux" ]]; then
    echo "Error: Currenty only Ubuntu Linux is supported"
    exit 1
fi


if [[ `lsb_release -si 2> /dev/null` != "Ubuntu" ]]; then
    echo "Error: Currenty only Ubuntu Linux is supported"
    exit 1
fi


lsbRelease=`lsb_release -sr 2> /dev/null`
if [ "$lsbRelease" == "15.04" ] || [ "$lsbRelease" == "15.10" ]; then
  cat << EOF
Error: The Koding Service Connector is not currently supported on Ubuntu ${lsbRelease}.
EOF
  exit 1
fi


echo "Testing sudo permissions, please input password if prompted.."
sudo -l > /dev/null 2> /dev/null
err=$?; if [ "$err" -ne 0 ]; then
    cat << EOF
Error: Sudo (root) permission is required to install the Koding Service
Connector Please run this command from a Linux Account on this machine
with proper permissions.
EOF
    exit $err
fi


which screen > /dev/null
err=$?; if [ "$err" -ne 0 ]; then
    # If apt-get is not available, inform the user to install screen
    # themselves.
    which apt-get > /dev/null
    err=$?; if [ "$err" -ne 0 ]; then
        cat << EOF
Error: The Unix command 'screen' must be installed prior to installing
the Koding Service connector. Please install it, and retry this
installation.
EOF
        exit 1
    fi

    echo "Installing Screen..."

    # The `<&-` is used because .. i think, apt-get is swallowing
    # stdin for some odd reason. Which would then cause the pipe to break
    # and the entire rest of the script would just be printed.
    #
    # The only way i even figured it out, was
    # via: http://unix.stackexchange.com/a/182625
    # Unfortunately i have no more information on that.
    sudo apt-get install -qq -y screen <&-
fi


sudo route del -host 169.254.169.254 reject 2> /dev/null
routeErr=$?
awsApiResponse=`curl http://169.254.169.254/latest/dynamic/instance-identity/document --max-time 5 2> /dev/null`
if [ "$routeErr" -eq 0 ]; then
    sudo route add -host 169.254.169.254 reject 2> /dev/null
fi


if [[ $awsApiResponse == *"614068383889"* ]]; then
    cat << EOF
Error: This feature is for non-Koding machines
EOF
    exit 1
fi


if [ -z "$KONTROLURL" ]; then
    KONTROLURL="https://koding.com/kontrol/kite"
fi


if [ -z "$CHANNEL" ]; then
    CHANNEL="managed"
fi


# Make tmp if needed, then navigate to it.
mkdir -p /tmp
cd /tmp


LATESTVERSION=$(curl -s https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest-version.txt)
LATESTURL="https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest/klient_0.1.${LATESTVERSION}_${CHANNEL}_amd64.deb"

if [ ! -f klient.deb ]; then
    cat << EOF
Downloading Koding Service Connector 0.1.${LATESTVERSION}...

EOF
    curl -s $LATESTURL -o klient.deb
    err=$?; if [ "$err" -ne 0 ]; then
        cat << EOF
Error: Unable to download or save Koding Service Connector
package.
EOF
        exit $err
    fi
fi

cat << EOF
Installing the Koding Service Connector package...
EOF
sudo dpkg -i --force-confnew klient.deb > /dev/null
err=$?; if [ "$err" -ne 0 ]; then
    echo "Error: Failed to install Koding Service Connector package"
    exit $err
fi


# Clean the klient deb from the system
rm klient.deb


KITE_USERNAME=""
if [ ! -z "$2" ]; then
    KITE_USERNAME=$2
fi

# Using an extra newline at the end of this message, because Klient
# might need to communicate with the user - so the extra line helps any
# klient prompts stand out.
cat << EOF
Authenticating you to the Koding Service

EOF
# It's ok $1 to be empty, in that case it'll try to register via password input
sudo -E /opt/kite/klient/klient -register -kite-home "/etc/kite" --kontrol-url "$KONTROLURL" -token $1 -username "$KITE_USERNAME" < /dev/tty
err=$?; if [ "$err" -ne 0 ]; then
    cat << EOF
$err: Service failed to register with Koding. If this continues to happen,
please contact support@koding.com
EOF
    exit $err
fi

if sudo [ ! -f /etc/kite/kite.key ]; then
    echo "Error: Critical component missing. Aborting installation."
    exit -1
fi

# Production kontrol might return a different kontrol URL. Let us control this aspect.
escaped_var=$(printf '%s\n' "$KONTROLURL" | sed 's:[/&\]:\\&:g;s/$/\\/')
sudo sed -i "s/\.\/klient/\.\/klient -kontrol-url $escaped_var /g" "/etc/init/klient.conf"

# To be safe, silently remove a manual upstart override if it exists
rm /etc/init/klient.override 2> /dev/null


cat << EOF
Starting the Koding Service Connector...

EOF
# We need to restart it so it pick up the new environment variable
sudo service klient restart > /dev/null 2> /dev/null


# TODO: Confirm that klient is running, before displaying success message
# to user. (Trying to find the best method for confirming this, rather
# than just grepping)


# Print user friendly message.
cat << EOF





>>>>>>>>>>>>>>>Success!<<<<<<<<<<<<<<

This machine has been successfully connected to Koding and
should show up automatically on the sidebar of your Koding account
where your other machines are listed.

Please head over to koding.com now and remember to not close
the "Add Your Own Machine" dialogue box until you see this machine appear
in the sidebar.

For some reason if this machine does not show up on your koding account
in the next 2-3 minutes, please re-run the install script or contact us
at support@koding.com.



EOF
