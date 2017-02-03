#!/bin/bash
set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/common-functions.sh

bootstrap

apt-get install -y wget git python-pip
bash rally/install_rally.sh
