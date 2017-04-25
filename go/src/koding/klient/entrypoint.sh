#!/bin/bash

# TODO (acbodine): it would be ideal to remove this file entirely, so we don't
# have to be the middle between Docker and klient process.

if [[ -z "$KONTROL" ]]; then
    export KONTROL=https://koding.com/kontrol/kite
fi

# TODO (acbodine): when this container restarts, it will fail to register.
# It would be better if we skipped registration if we are already registered.

# Register and authenticate klient with kite backend.
klient \
    -kontrol-url $KONTROL \
    -register \
    -token $TOKEN

sleep 2

# Run klient
klient \
    -debug \
    -kontrol-url $KONTROL
