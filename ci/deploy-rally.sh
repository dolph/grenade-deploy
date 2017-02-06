#!/bin/bash
set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/common-functions.sh

bootstrap

apt-get install -y \
    git \
    iputils-ping \
    libffi-dev \
    libpq-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    python-pip \
    wget \
    ;
bash rally/install_rally.sh
