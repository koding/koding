

if [ -z $1 ]; then
  cat << EOF
Please provide the host that you want to connect Fuse to. Note that
you must have your ssh pubkey in the ~/.ssh/authorized_keys for the
provided user and host.
EOF
  exit 1
fi


if [ "$1" == "-h" ]; then
  cat << EOF
Usage:

    ./install-alpha.sh [-h] [user@]host

Examples:

    ./install-alpha.sh 192.168.0.100
    ./install-alpha.sh root@192.168.0.100


Custom ssh ident:

A custom ssh key can be specified by using the IDENT env var. On Bash,
this would look like:

    IDENT=~/.ssh/custom_rsa.pub ./install-alpha user@host

On Fish, it would look like:

    env IDENT=~/.ssh/custom_rsa.pub ./install-alpha user@host
EOF
  exit 0
fi
HOST="$1"


# Get the IP by stripping the user from the HOST, if any.
IP=`echo $HOST | sed 's/^\w*@//'`


# The file we want to save the key to
mkdir -p ~/.fuseproto/keys
KEYFILE=~/.fuseproto/keys/"$IP.kite.key"


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



cat << EOF
Success! Please run the following command whenever you want to start
fuseproto:

    ./fuseproto --klientip=$IP --externalpath=/home/your/remote/dir --internalpath=/your/local/dir --debug=true
EOF
