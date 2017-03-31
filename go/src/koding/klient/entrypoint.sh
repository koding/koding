#!/bin/bash

# TODO (acbodine): if these two can be condensed to a single command
# we won't even need an entrypoint.sh. Check to make sure we have
# to explicitly register before running.

# Register klient with kite backend.
/opt/kite/klient/klient \
    -register \
    -kontrol-url ${KONTROL} \
    -token ${TOKEN}

# Run klient
/opt/kite/klient/klient \
    -kontrol-url ${KONTROL}
