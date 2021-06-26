#!/bin/sh
set -e

# Script taken from https://github.com/uphold/docker-litecoin-core/blob/master/0.18/docker-entrypoint.sh 
# Running litecoind as this example does not need additional parameters. In a real world application, based on how this script will be used we could choose to receive parameters passed through CMD or command line parameters.

# Changing the permission of the litecoin data directory as it is a volume and should be changed once the container is run.
mkdir -p "$LITECOIN_DATA"
chmod 770 "$LITECOIN_DATA" || echo "Could not chmod $LITECOIN_DATA (may not have appropriate permissions)"
chown -R litecoin "$LITECOIN_DATA" || echo "Could not chown $LITECOIN_DATA (may not have appropriate permissions)"

echo "$0: setting data directory to $LITECOIN_DATA"

set -- gosu litecoin litecoind -datadir="$LITECOIN_DATA"

echo "Running litecoin using - $@"
exec "$@"