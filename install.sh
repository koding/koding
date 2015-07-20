#!/usr/bin/env bash

if [[ ! "$(uname)" = "Linux" ]]; then
    echo "Currenty only Ubuntu Linux is supported"
    exit 1
fi

if [ -z "$KONTROLURL" ]; then
    KONTROLURL="https://koding.com/kontrol/kite"
fi


# TODO: Why are we defaulting to development?
if [ -z "$CHANNEL" ]; then
    CHANNEL="development"
fi

LATESTVERSION=$(curl -s https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest-version.txt)
LATESTURL="https://s3.amazonaws.com/koding-klient/${CHANNEL}/latest/klient_0.1.${LATESTVERSION}_${CHANNEL}_amd64.deb"

if [ ! -f klient.deb ]; then
    cat << EOF
Downloading Koding Service 0.1.${LATESTVERSION}...

EOF
    curl -s $LATESTURL -o klient.deb
fi

cat << EOF
Installing the Koding Service package...
EOF
sudo dpkg -i --force-confnew klient.deb > /dev/null

KITE_USERNAME=""
if [ ! -z "$2" ]; then
    KITE_USERNAME=$2
fi

# Using an extra newline at the end of this message, because Klient
# might need to communicate with the user - so the extra line helps any
# klient prompts stand out.
cat << EOF
Authenticating Koding Service

EOF
# It's ok $1 to be empty, in that case it'll try to register via password input
sudo -E /opt/kite/klient/klient -register -kite-home "/etc/kite" --kontrol-url "$KONTROLURL" -token $1 -username "$KITE_USERNAME" < /dev/tty
err=$?; if [ "$err" -ne 0 ]; then
    cat << EOF
Error $err: Service failed to register with Koding
EOF
    exit $err
fi

if [ ! -f /etc/kite/kite.key ]; then
    echo "Error: Koding Service key not found. Aborting installation"
    exit -1
fi

# Production kontrol might return a different kontrol URL. Let us control this aspect.
escaped_var=$(printf '%s\n' "$KONTROLURL" | sed 's:[/&\]:\\&:g;s/$/\\/')
sudo sed -i "s/\.\/klient/\.\/klient -kontrol-url $escaped_var -env managed /g" "/etc/init/klient.conf"


cat << EOF
Starting Koding Service..

EOF
# We need to restart it so it pick up the new environment variable
sudo service klient restart > /dev/null 2> /dev/null


# TODO: Confirm that klient is running, before displaying success message
# to user. (Trying to find the best method for confirming this, rather
# than just grepping)


# Print user friendly message.
cat << EOF
Success! Your machine has been connected to Koding, and
will show up shortly in your Koding sidebar.

You may switch back to Koding now. Remember, Please do
not close the Add Your Own VM modal until your Machine
appears in the sidebar.

If your Machine does not show up soon, please contact
Koding support at:

    support@koding.com

EOF
