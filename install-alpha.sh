#!/usr/bin/env bash

if [ -z "$SSHHOST" ]; then
  cat << EOF
Please provide the Koding VM's ip that you want to mount. Note that
you must have your ssh pubkey in the ~/.ssh/authorized_keys for the
provided user and host. (Note: this step will be removed in 1.0)
EOF
  exit 1
fi


# The file we want to save the key to
mkdir -p ~/.fuseklient/keys
KEYFILE=~/.fuseklient/keys/"$SSHHOST".kite.key


# If the key already exists, this script doesn't need to do anything.
if [ -f $KEYFILE ]; then
  exit 0
fi


HOST="$SSHHOST"


if [ -n "$SSHUSER" ]; then
  HOST="$SSHUSER@$HOST"
fi


# If the IDENT var is not null, add a ident flag to scp/ssh
if [ -n "$IDENT" ]; then
  IDENT_FLAG="-i $IDENT"
fi


# Test the ssh credentials
echo "Testing your ssh credentials..."
ssh $IDENT_FLAG "$HOST" echo "" 2>&1 > /dev/null
err=$?; if [ "$err" -ne 0 ]; then
  cat << EOF
Error $err: Could not connect to the provided host '$HOST'. Please ensure
that you have the correct user and that your pubkey is in that user's
~/.ssh/authorized_keys file.
EOF
  exit $err
fi


# TODO: SSH into the machine here, download a custom klient, and
# install it.


# Now scp into the machine to copy its kite key
scp $IDENT_FLAG "$HOST:/etc/kite/kite.key" "$KEYFILE"
err=$?; if [ "$err" -ne 0 ]; then
  echo "Error $err: There was an error SCPing to the remote machine"
  exit $err
fi


if [ ! -f $KEYFILE ]; then
  echo "Error 200: kite.key at $KEYFILE was not copied correctly"
  exit 200
fi
