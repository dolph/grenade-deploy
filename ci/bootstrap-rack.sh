#!/bin/bash
set -ex

RACK_USERNAME=$1
RACK_API_KEY=$2
RACK_REGION=$3

apt-get install -y curl

# Download the rack client if it's not already.
if [ ! -f rack ]; then
    echo "Downloading the rack client..."
    case "$(uname -s)" in
    Linux)
        # Linux 64-bit binary
        curl https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.2/Linux/amd64/rack > rack
        ;;
    Darwin)
        # OS X 64-bit binary
        curl https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.2/Darwin/amd64/rack > rack
        ;;
    esac

    chmod +x rack
fi

# Configure rack client if it's not already
if [ $# -eq 3 ]; then
    echo "Configuring the rack client..."
    mkdir ~/.rack/
    echo "username = $RACK_USERNAME" > ~/.rack/config
    echo "api-key = $RACK_API_KEY" >> ~/.rack/config
    echo "region = $RACK_REGION" >> ~/.rack/config
elif [ ! -f ~/.rack/config ]; then
    echo "Configuring the rack client (interactive)..."
    ./rack configure
fi
